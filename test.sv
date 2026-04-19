//////////////////////////////////////////////////////////////////////////////////////////////////
// Test:                                                                                        //
// Este bloque controla la ejecución de la prueba. Es el nivel más alto de la lógica de         //
// verificación, encargado de configurar los parámetros, enviar instrucciones a los             //
// componentes y decidir cuándo termina la simulación.                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////

class test #(parameter width = 16, parameter depth = 8);
  
  // --- Mailboxes de Control (Salidas del Test) ---
  comando_test_sb_mbx    test_sb_mbx;    // Para enviar órdenes al Scoreboard (ej: reporte)
  comando_test_agent_mbx test_agent_mbx; // Para enviar órdenes al Agente (ej: generar datos)

  // --- Parámetros de la prueba ---
  parameter num_transacciones = depth;   // Por defecto, llena la FIFO según su profundidad
  parameter max_retardo = 4;             // Límite de ciclos de espera por defecto
  
  // --- Variables de comando ---
  solicitud_sb orden;         
  solicitud_sb instr_sb;
  instrucciones_agente instr_agent; 

  // --- Variables para configuración dinámica (Plusargs) ---
  int max_retardo_cfg; 
  int num_trans_cfg;
  int solo_escrituras_cfg;

  // --- Instancia del Ambiente y la Interfaz Virtual ---
  ambiente #(.depth(depth),.width(width)) ambiente_inst;
  virtual fifo_if #(.width(width)) _if;

  // --- Constructor: Configuración inicial de conexiones ---
  function new; 
    // 1. Instanciación de los Mailboxes de control
    test_sb_mbx  = new();
    test_agent_mbx = new();
    
    // 2. Creación del ambiente completo
    ambiente_inst = new();  
    
    // 3. Conexión de los canales de control del Test hacia los componentes internos
    ambiente_inst.test_sb_mbx = test_sb_mbx;
    ambiente_inst.scoreboard_inst.test_sb_mbx = test_sb_mbx;
    ambiente_inst.test_agent_mbx = test_agent_mbx;
    ambiente_inst.agent_inst.test_agent_mbx = test_agent_mbx;
    
    // 4. Configuración inicial del Agente
    ambiente_inst.agent_inst.num_transacciones = num_transacciones;
  endfunction

  // --- Tarea Run: Lógica de ejecución de la prueba ---
  task run;
    // Conexión final de la interfaz antes de arrancar
    ambiente_inst._if = _if;
  
    // ==========================================================
    // 1. LECTURA DE PLUSARGS (Configuración desde la terminal)
    // Permite modificar la prueba sin recompilar el código.
    // ==========================================================
    
    // Configuración de retardo máximo
    if (!$value$plusargs("MAX_RETARDO=%d", max_retardo_cfg))
      max_retardo_cfg = 4;

    // Configuración de cantidad de transacciones
    if (!$value$plusargs("NUM_TRANS=%d" , num_trans_cfg))
      num_trans_cfg = num_transacciones; 

    // Configuración para pruebas de "Solo Escritura" (Stress test)
    if (!$value$plusargs("SOLO_ESCRITURAS=%d" , solo_escrituras_cfg))
      solo_escrituras_cfg = 0;

    // ==========================================================
    // 2. APLICACIÓN DE CONFIGURACIÓN AL AGENTE
    // ==========================================================
    ambiente_inst.agent_inst.max_retardo = max_retardo_cfg; 
    ambiente_inst.agent_inst.num_transacciones = num_trans_cfg; 
    ambiente_inst.agent_inst.solo_escrituras = solo_escrituras_cfg; 

    // 3. Debug: Mostrar configuración actual en consola
    $display("--- CONFIGURACIÓN DE PRUEBA ---");
    $display("MAX_RETARDO     = %0d", max_retardo_cfg);
    $display("NUM_TRANS       = %0d", num_trans_cfg);
    $display("SOLO_ESCRITURAS = %0d", solo_escrituras_cfg);
    $display("-------------------------------");
    $display("[%g]  El Test fue inicializado",$time);
  
    // ==========================================================
    // 4. ARRANQUE DEL AMBIENTE
    // ==========================================================
    fork 
      ambiente_inst.run(); // Inicia Driver, Monitor, Checker, etc. en paralelo
    join_none

    // ==========================================================
    // 5. SECUENCIA DE ESTÍMULOS (Plan de Verificación)
    // ==========================================================
    
    // Paso A: Llenado aleatorio inicial
    instr_agent = llenado_aleatorio;
    test_agent_mbx.put(instr_agent);
    $display("[%g]  Test: Enviada instrucción: LLENADO ALEATORIO (%0d trans)",$time, num_trans_cfg);

    // Paso B: Transacción aleatoria individual
    instr_agent = trans_aleatoria;
    test_agent_mbx.put(instr_agent);
    $display("[%g]  Test: Enviada instrucción: TRANSACCIÓN ALEATORIA",$time);

    // Paso C: Transacción específica (Caso de esquina manual)
    // Definimos un dato manual para verificar valores conocidos
    ambiente_inst.agent_inst.ret_spec = 3;
    ambiente_inst.agent_inst.tpo_spec = escritura;
    ambiente_inst.agent_inst.dto_spec = {width/4{4'h5}}; // Crea un patrón 0x5555...
    instr_agent = trans_especifica;
    test_agent_mbx.put(instr_agent);
    $display("[%g]  Test: Enviada instrucción: TRANSACCIÓN ESPECÍFICA",$time);

    // Paso D: Secuencia masiva de transacciones
    instr_agent = sec_trans_aleatorias;
    test_agent_mbx.put(instr_agent);
    $display("[%g]  Test: Enviada instrucción: SECUENCIA ALEATORIA (%0d trans)",$time, num_trans_cfg);

    // ==========================================================
    // 6. CIERRE Y REPORTES FINALIZADOS
    // ==========================================================
    #10000 // Tiempo de espera para que se procesen los datos
    $display("[%g]  Test: Se alcanza el tiempo límite de la prueba",$time);
    
    // Pedir reporte de latencia
    instr_sb = retardo_promedio; 
    test_sb_mbx.put(instr_sb);
    
    // Pedir reporte histórico completo
    instr_sb = reporte;  
    test_sb_mbx.put(instr_sb);
    
    #20 // Tiempo de cortesía para imprimir
    $finish; // Finaliza la simulación
  endtask
endclass
