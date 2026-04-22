class test #(parameter width = 16, parameter depth = 8);
  
  comando_test_sb_mbx    test_sb_mbx;
  comando_test_agent_mbx test_agent_mbx;

  parameter num_transacciones = depth;
  parameter max_retardo = 4;
  
  solicitud_sb orden;
  solicitud_sb instr_sb;
  instrucciones_agente instr_agent;

  int max_retardo_cfg;
  int num_trans_cfg;
  int solo_escrituras_cfg;

  ambiente #(.depth(depth),.width(width)) ambiente_inst;
  virtual fifo_if #(.width(width)) _if;

  function new; 
    test_sb_mbx  = new();
    test_agent_mbx = new();
    ambiente_inst = new();
    
    ambiente_inst.test_sb_mbx = test_sb_mbx;
    ambiente_inst.scoreboard_inst.test_sb_mbx = test_sb_mbx;
    ambiente_inst.test_agent_mbx = test_agent_mbx;
    ambiente_inst.agent_inst.test_agent_mbx = test_agent_mbx;
    
    ambiente_inst.agent_inst.num_transacciones = num_transacciones;
  endfunction

  // ==========================================================
  // TAREAS DE TEST ESPECÍFICOS (CASOS DE ESQUINA)
  // ==========================================================
  
  task test_patron_alternante();
    trans_fifo #(.width(width)) t;
    $display("\n[%g] ========== TEST: Patrón Alternante 0xAAAA/0x5555 ==========", $time);
    
    // Escribir AAAA... (Todos unos en bits pares)
    t = new(); 
    t.tipo = escritura; 
    t.retardo = 1; 
    t.dato = {width{1'b1}}; // As
    t.print("TEST: Enviando patrón 0xA...");
    ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    
    // Escribir 5555... (Todos unos en bits impares)
    t = new(); 
    t.tipo = escritura; 
    t.retardo = 1; 
    t.dato = {width/2{2'b01}}; // 5s
    t.print("TEST: Enviando patrón 0x5...");
    ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    
    // Escribir 0000...
    t = new(); 
    t.tipo = escritura; 
    t.retardo = 1; 
    t.dato = 0;
    t.print("TEST: Enviando patrón 0x0...");
    ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    
    // Escribir FFFF...
    t = new(); 
    t.tipo = escritura; 
    t.retardo = 1; 
    t.dato = {width{1'b1}};
    t.print("TEST: Enviando patrón 0xF...");
    ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    
    #200;
    
    // Leer y verificar
    repeat(4) begin
      t = new(); 
      t.tipo = lectura; 
      t.retardo = 1;
      ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    end
  endtask

  task test_overflow_determinista();
    trans_fifo #(.width(width)) t;
    $display("\n[%g] ========== TEST: Overflow Determinista ==========", $time);
    
    // Reset para empezar limpio
    t = new(); 
    t.tipo = reset; 
    ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    #50;
    
    // Llenar la FIFO exactamente
    $display("[%g] TEST: Llenando FIFO con %0d elementos...", $time, depth);
    for (int i=0; i<depth; i++) begin
      t = new(); 
      t.tipo = escritura; 
      t.dato = i + 16'hA000; 
      t.retardo = 0;
      ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    end
    
    #100;
    
    // Intento de escritura extra (debe generar OVERFLOW)
    $display("[%g] TEST: Intentando escribir en FIFO llena (debe causar OVERFLOW)...", $time);
    t = new(); 
    t.tipo = escritura; 
    t.dato = 'hDEAD; 
    t.retardo = 0;
    ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    
    #100;
  endtask

  task test_underflow_determinista();
    trans_fifo #(.width(width)) t;
    $display("\n[%g] ========== TEST: Underflow Determinista ==========", $time);
    
    t = new(); 
    t.tipo = reset; 
    ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    #50;
    
    // Leer de FIFO vacía
    $display("[%g] TEST: Intentando leer de FIFO vacía (debe causar UNDERFLOW)...", $time);
    t = new(); 
    t.tipo = lectura; 
    t.retardo = 0;
    ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    
    #100;
  endtask

  task test_reset_en_medio();
    trans_fifo #(.width(width)) t;
    $display("\n[%g] ========== TEST: Reset en Medio de Ráfaga ==========", $time);
    
    // Escribir 3 datos
    for (int i=0; i<3; i++) begin
      t = new(); 
      t.tipo = escritura; 
      t.dato = i + 16'hB000;
      t.retardo = 1;
      ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    end
    
    #50;
    
    // RESET!
    $display("[%g] TEST: Aplicando RESET en medio de escrituras...", $time);
    t = new(); 
    t.tipo = reset; 
    ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    
    #50;
    
    // Escribir 2 datos nuevos
    for (int i=0; i<2; i++) begin
      t = new(); 
      t.tipo = escritura; 
      t.dato = i + 16'hC000;
      t.retardo = 1;
      ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    end
    
    #100;
    
    // Leer los 2 datos nuevos
    repeat(2) begin
      t = new(); 
      t.tipo = lectura; 
      t.retardo = 1;
      ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    end
  endtask

  task test_fifo_mitad();
    trans_fifo #(.width(width)) t;
    $display("\n[%g] ========== TEST: FIFO Exactamente a la Mitad ==========", $time);
    
    t = new(); 
    t.tipo = reset; 
    ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    #50;
    
    // Llenar hasta depth/2
    for (int i=0; i<depth/2; i++) begin
      t = new(); 
      t.tipo = escritura; 
      t.dato = i + 16'hD000; 
      t.retardo = 1;
      ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    end
    
    $display("[%g] TEST: FIFO al 50%% de capacidad (%0d/%0d)", $time, depth/2, depth);
    #50;
    
    // Leer y escribir intercalado en este estado
    for (int i=0; i<3; i++) begin
      t = new(); 
      t.tipo = lectura; 
      t.retardo = 1;
      ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
      
      t = new(); 
      t.tipo = escritura; 
      t.dato = i + 16'hE000; 
      t.retardo = 1;
      ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    end
    
    #100;
  endtask

  task test_push_pop_simultaneo();
    trans_fifo #(.width(width)) t;
    $display("\n[%g] ========== TEST: Push y Pop Simultáneo ==========", $time);
    
    // Caso 1: FIFO vacía
    t = new(); 
    t.tipo = reset; 
    ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    #50;
    
    $display("[%g] TEST: Push/Pop simultáneo en FIFO VACÍA", $time);
    t = new(); 
    t.tipo = escritura_lectura; 
    t.dato = 16'h1234; 
    t.retardo = 1;
    ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    #50;
    
    // Caso 2: FIFO medio llena
    for (int i=0; i<depth/2; i++) begin
      t = new(); 
      t.tipo = escritura; 
      t.dato = i + 16'h1000; 
      t.retardo = 1;
      ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    end
    #50;
    
    $display("[%g] TEST: Push/Pop simultáneo en FIFO MEDIO LLENA", $time);
    t = new(); 
    t.tipo = escritura_lectura; 
    t.dato = 16'h5678; 
    t.retardo = 1;
    ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    #50;
    
    // Caso 3: FIFO llena
    for (int i=depth/2; i<depth; i++) begin
      t = new(); 
      t.tipo = escritura; 
      t.dato = i + 16'h1000; 
      t.retardo = 1;
      ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    end
    #50;
    
    $display("[%g] TEST: Push/Pop simultáneo en FIFO LLENA", $time);
    t = new(); 
    t.tipo = escritura_lectura; 
    t.dato = 16'h9ABC; 
    t.retardo = 1;
    ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    
    #200;
  endtask

  // ==========================================================
  // TAREA PRINCIPAL
  // ==========================================================
  task run;
    ambiente_inst._if = _if;
  
    // Leer plusargs
    if (!$value$plusargs("MAX_RETARDO=%d", max_retardo_cfg))
      max_retardo_cfg = 4;
    if (!$value$plusargs("NUM_TRANS=%d" , num_trans_cfg))
      num_trans_cfg = num_transacciones;
    if (!$value$plusargs("SOLO_ESCRITURAS=%d" , solo_escrituras_cfg))
      solo_escrituras_cfg = 0;

    ambiente_inst.agent_inst.max_retardo = max_retardo_cfg;
    ambiente_inst.agent_inst.num_transacciones = num_trans_cfg;
    ambiente_inst.agent_inst.solo_escrituras = solo_escrituras_cfg;

    $display("\n========================================");
    $display("     CONFIGURACIÓN DE PRUEBA");
    $display("========================================");
    $display("MAX_RETARDO     = %0d", max_retardo_cfg);
    $display("NUM_TRANS       = %0d", num_trans_cfg);
    $display("SOLO_ESCRITURAS = %0d", solo_escrituras_cfg);
    $display("WIDTH           = %0d", width);
    $display("DEPTH           = %0d", depth);
    $display("========================================\n");
    $display("[%g] El Test fue inicializado",$time);
  
    fork 
      ambiente_inst.run();
    join_none

    #100;
  
    // ==========================================================
    // SECUENCIA COMPLETA DE PRUEBAS
    // ==========================================================
    
    // 1. Prueba básica de llenado aleatorio
    instr_agent = llenado_aleatorio;
    test_agent_mbx.put(instr_agent);
    $display("[%g] Test: Enviada instrucción: LLENADO ALEATORIO",$time);
    #500;

    // 2. Patrón de alternancia máxima (0xAAAA, 0x5555, etc.)
    test_patron_alternante();
    #200;

    // 3. Overflow determinista
    test_overflow_determinista();
    #200;

    // 4. Underflow determinista
    test_underflow_determinista();
    #200;

    // 5. Reset en medio de ráfaga
    test_reset_en_medio();
    #200;

    // 6. FIFO exactamente a la mitad
    test_fifo_mitad();
    #200;

    // 7. Push y Pop simultáneo (vacío, medio, lleno)
    test_push_pop_simultaneo();
    #200;

    // 8. Transacción aleatoria
    instr_agent = trans_aleatoria;
    test_agent_mbx.put(instr_agent);
    $display("[%g] Test: Enviada instrucción: TRANSACCIÓN ALEATORIA",$time);
    #100;

    // 9. Transacción específica (5s)
    ambiente_inst.agent_inst.ret_spec = 3;
    ambiente_inst.agent_inst.tpo_spec = escritura;
    ambiente_inst.agent_inst.dto_spec = {width/4{4'h5}};
    instr_agent = trans_especifica;
    test_agent_mbx.put(instr_agent);
    $display("[%g] Test: Enviada instrucción: TRANSACCIÓN ESPECÍFICA (0x55...)",$time);
    #100;

    // 10. Secuencia masiva
    instr_agent = sec_trans_aleatorias;
    test_agent_mbx.put(instr_agent);
    $display("[%g] Test: Enviada instrucción: SECUENCIA ALEATORIA",$time);

    // ==========================================================
    // REPORTES FINALES
    // ==========================================================
    #20000;
    
    $display("\n[%g] ========== REPORTES FINALES ==========", $time);
    
    instr_sb = retardo_promedio;
    test_sb_mbx.put(instr_sb);
    #10;
    
    instr_sb = reporte;
    test_sb_mbx.put(instr_sb);
    #50;
    
    $display("\n[%g] ========== FIN DE SIMULACIÓN ==========", $time);
    $finish;
  endtask
endclass