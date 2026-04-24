//////////////////////////////////////////////////////////////////////////////////////////////////
// Agente / Generador:                                                                          //
// Este bloque es el "jefe" de tráfico. Se encarga de crear secuencias de datos (transacciones) //
// y enviarlas al Driver. Puede generar tráfico aleatorio, específico o de llenado/vaciado.     //
//////////////////////////////////////////////////////////////////////////////////////////////////

class agent #(parameter width = 16, parameter depth = 8);
  // --- Canales de comunicación (Mailboxes) ---
  trans_fifo_mbx agnt_drv_mbx;           // Canal para enviar transacciones al Driver
  comando_test_agent_mbx test_agent_mbx; // Canal para recibir órdenes desde el Test

  // --- Variables de configuración ---
  int num_transacciones;                 // Cantidad de paquetes a generar por instrucción
  int max_retardo;                       // Tiempo máximo de espera entre paquetes
  int solo_escrituras;                   // Switch controlado por Plusargs (1 = desactiva lecturas)
  
  // --- Variables para transacciones específicas (Casos de esquina) ---
  int ret_spec;                          // Retardo definido manualmente
  tipo_trans tpo_spec;                   // Tipo (Lectura/Escritura/Reset) definido manualmente
  bit [width-1:0] dto_spec;              // Dato definido manualmente
  
  // --- Variables de control de patrones ---
  string patron_datos;                   // Patrón de datos a generar (RANDOM, CERO, UNO, AA, 55, SEC)
  int contador_patron;                   // Contador para patrón secuencial
  
  // --- Variables de pesos para generación aleatoria ---
  int peso_lectura;                      // Peso para operaciones de lectura
  int peso_escritura;                    // Peso para operaciones de escritura
  int peso_simultaneo;                   // Peso para operaciones simultáneas
  int peso_reset;                        // Peso para operaciones de reset
  
  // --- Objetos de control ---
  instrucciones_agente instruccion;      // Almacena la orden actual enviada por el Test
  trans_fifo #(.width(width)) transaccion; // El paquete de datos que se está construyendo
   
  // --- Constructor: Define valores iniciales por defecto ---
  function new;
    this.num_transacciones = 2;
    this.max_retardo = 10;
    this.solo_escrituras = 0;            // Por defecto, el ambiente hace lecturas y escrituras
    this.patron_datos = "RANDOM";        // Por defecto, datos aleatorios
    this.contador_patron = 0;
    this.peso_lectura = 30;
    this.peso_escritura = 30;
    this.peso_simultaneo = 20;
    this.peso_reset = 20;
    this.ret_spec = 0;
    this.dto_spec = 0;
    this.tpo_spec = lectura;
  endfunction

  // --- Función para generar datos según patrón ---
  function bit [width-1:0] generar_dato(int indice = 0);
    case(patron_datos)
      "CERO":   return {width{1'b0}};
      "UNO":    return {width{1'b1}};
      "AA":     return {width{2'b10}};  // Patrón 1010...1010
      "55":     return {width{2'b01}};  // Patrón 0101...0101
      "SEC":    begin
                  contador_patron++;
                  return contador_patron[width-1:0];
                end
      default:  return $urandom();      // RANDOM
    endcase
  endfunction

  // --- Función para seleccionar tipo de operación según pesos ---
  function tipo_trans seleccionar_tipo();
    int total;
    int r;
    
    total = peso_lectura + peso_escritura + peso_simultaneo + peso_reset;
    
    if (total == 0) begin
      return escritura;  // Por defecto si no hay pesos
    end
    
    r = $urandom() % total;
    
    if (r < peso_lectura)
      return lectura;
    else if (r < peso_lectura + peso_escritura)
      return escritura;
    else if (r < peso_lectura + peso_escritura + peso_simultaneo)
      return escritura_lectura;
    else
      return reset;
  endfunction

  // --- Tarea Principal: Ejecución del Agente ---
  task run;
    $display("[%g]  El Agente fue inicializado - ESPERANDO INSTRUCCIONES", $time);
    
    forever begin
      #1 // Pequeña espera para no saturar el simulador
      
      // Revisa si el Test ha enviado una nueva orden al Mailbox
      if(test_agent_mbx.num() > 0) begin
        $display("[%g]  Agente: se recibe instruccion", $time);
        test_agent_mbx.get(instruccion); // Extrae la orden del Mailbox
        
        $display("[%g]  Agente: INSTRUCCIÓN RECIBIDA = %s", $time, instruccion.name());
        
        case(instruccion)
          
          // ORDEN 1: Llenado aleatorio (Prueba de balance o de saturación)
          llenado_aleatorio: begin
            $display("[%g]  Agente: Ejecutando LLENADO_ALEATORIO (%0d transacciones)", 
                     $time, num_transacciones);
            
            // --- Fase de Escrituras ---
            for(int i = 0; i < num_transacciones; i++) begin
              transaccion = new();                 // Crea un nuevo paquete
              transaccion.max_retardo = max_retardo;
              transaccion.randomize();             // Genera datos aleatorios
              transaccion.tipo = escritura;        // Fuerza el tipo a ESCRITURA
              transaccion.dato = generar_dato(i);  // Aplica patrón de datos
              transaccion.print("Agente: transacción creada (WRITE)");
              agnt_drv_mbx.put(transaccion);       // Envía el paquete al Driver
            end
            
            // --- Fase de Lecturas (Solo si el Plusarg no lo prohíbe) ---
            if (!solo_escrituras) begin
              $display("[%g]  Agente: Iniciando fase de lecturas", $time);
              for(int i = 0; i < num_transacciones; i++) begin
                transaccion = new(); 
                transaccion.max_retardo = max_retardo; 
                transaccion.randomize();
                transaccion.tipo = lectura;        // Fuerza el tipo a LECTURA
                transaccion.print("Agente: transacción creada (READ)");
                agnt_drv_mbx.put(transaccion);     // Envía el paquete al Driver
              end
            end
            
            $display("[%g]  Agente: LLENADO_ALEATORIO completado", $time);
          end

          // ORDEN 2: Una sola transacción 100% aleatoria
          trans_aleatoria: begin
            $display("[%g]  Agente: Ejecutando TRANS_ALEATORIA", $time);
            
            transaccion = new();
            transaccion.max_retardo = max_retardo;
            transaccion.randomize();
            transaccion.dato = generar_dato(0);    // Aplica patrón de datos
            transaccion.print("Agente: transacción creada");
            agnt_drv_mbx.put(transaccion);
            
            $display("[%g]  Agente: TRANS_ALEATORIA completada", $time);
          end

          // ORDEN 3: Transacción con datos manuales (Para probar valores exactos)
          trans_especifica: begin
            $display("[%g]  Agente: Ejecutando TRANS_ESPECIFICA", $time);
            $display("[%g]    tipo    = %s", $time, tpo_spec.name());
            $display("[%g]    dato    = 0x%h", $time, dto_spec);
            $display("[%g]    retardo = %0d", $time, ret_spec);
            
            transaccion = new();
            transaccion.tipo = tpo_spec;
            transaccion.dato = dto_spec;
            transaccion.retardo = ret_spec;
            transaccion.print("Agente: transacción creada");
            agnt_drv_mbx.put(transaccion);
            
            $display("[%g]  Agente: TRANS_ESPECIFICA completada", $time);
          end

          // ORDEN 4: Secuencia de múltiples transacciones aleatorias
          sec_trans_aleatorias: begin
            $display("[%g]  Agente: Ejecutando SEC_TRANS_ALEATORIAS (%0d transacciones)", 
                     $time, num_transacciones);
            $display("[%g]  Agente: Usando patrón de datos: %s", $time, patron_datos);
            $display("[%g]  Agente: Pesos - Lectura:%0d Escritura:%0d Simultáneo:%0d Reset:%0d", 
                     $time, peso_lectura, peso_escritura, peso_simultaneo, peso_reset);
            
            for(int i = 0; i < num_transacciones; i++) begin
              transaccion = new();
              transaccion.max_retardo = max_retardo;
              
              // Usar los pesos para seleccionar el tipo de operación
              transaccion.tipo = seleccionar_tipo();
              
              // Generar dato según el patrón configurado
              transaccion.dato = generar_dato(i);
              
              // El retardo se aleatoriza entre 1 y max_retardo
              transaccion.retardo = 1 + ($urandom() % max_retardo);
              
              transaccion.print("Agente: transacción creada");
              agnt_drv_mbx.put(transaccion);
            end
            
            $display("[%g]  Agente: SEC_TRANS_ALEATORIAS completado (%0d transacciones enviadas)", 
                     $time, num_transacciones);
          end
          
          default: begin
            $display("[%g]  Agente: ERROR - Instrucción desconocida", $time);
          end
          
        endcase
        
        $display("[%g]  Agente: Esperando siguiente instrucción...", $time);
      end
    end
  endtask
  
endclass