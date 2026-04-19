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
  
  // --- Objetos de control ---
  instrucciones_agente instruccion;      // Almacena la orden actual enviada por el Test
  trans_fifo #(.width(width)) transaccion; // El paquete de datos que se está construyendo
   
  // --- Constructor: Define valores iniciales por defecto ---
  function new;
    this.num_transacciones = 2;
    this.max_retardo = 10;
    this.solo_escrituras = 0;            // Por defecto, el ambiente hace lecturas y escrituras
  endfunction

  // --- Tarea Principal: Ejecución del Agente ---
  task run;
    $display("[%g]  El Agente fue inicializado", $time);
    
    forever begin
      #1 // Pequeña espera para no saturar el simulador
      
      // Revisa si el Test ha enviado una nueva orden al Mailbox
      if(test_agent_mbx.num() > 0) begin
        $display("[%g]  Agente: se recibe instruccion", $time);
        test_agent_mbx.get(instruccion); // Extrae la orden del Mailbox
        
        case(instruccion)
          
          // ORDEN 1: Llenado aleatorio (Prueba de balance o de saturación)
          llenado_aleatorio: begin  
            // --- Fase de Escrituras ---
            for(int i = 0; i < num_transacciones; i++) begin
              transaccion = new;                 // Crea un nuevo paquete
              transaccion.max_retardo = max_retardo;
              transaccion.randomize();           // Genera datos aleatorios
              transaccion.tipo = escritura;      // Fuerza el tipo a ESCRITURA
              transaccion.print("Agente: transacción creada (WRITE)");
              agnt_drv_mbx.put(transaccion);     // Envía el paquete al Driver
            end
            
            // --- Fase de Lecturas (Solo si el Plusarg no lo prohíbe) ---
            if (!solo_escrituras) begin
              for(int i = 0; i < num_transacciones; i++) begin
                transaccion = new; 
                transaccion.max_retardo = max_retardo; 
                transaccion.randomize();
                transaccion.tipo = lectura;      // Fuerza el tipo a LECTURA
                transaccion.print("Agente: transacción creada (READ)");
                agnt_drv_mbx.put(transaccion);   // Envía el paquete al Driver
              end
            end
          end

          // ORDEN 2: Una sola transacción 100% aleatoria
          trans_aleatoria: begin  
            transaccion = new;
            transaccion.max_retardo = max_retardo;
            transaccion.randomize();
            transaccion.print("Agente: transacción creada");
            agnt_drv_mbx.put(transaccion);
          end

          // ORDEN 3: Transacción con datos manuales (Para probar valores exactos)
          trans_especifica: begin  
            transaccion = new;
            transaccion.tipo = tpo_spec;
            transaccion.dato = dto_spec;
            transaccion.retardo = ret_spec;
            transaccion.print("Agente: transacción creada");
            agnt_drv_mbx.put(transaccion);
          end

          // ORDEN 4: Secuencia de múltiples transacciones aleatorias
          sec_trans_aleatorias: begin 
            for(int i = 0; i < num_transacciones; i++) begin
              transaccion = new;
              transaccion.max_retardo = max_retardo;
              transaccion.randomize();
              transaccion.print("Agente: transacción creada");
              agnt_drv_mbx.put(transaccion);
            end
          end
          
        endcase
      end
    end
  endtask
endclass
