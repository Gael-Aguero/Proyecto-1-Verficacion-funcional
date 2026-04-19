//////////////////////////////////////////////////////////////////////////////////////////////////
// Checker:                                                                                     //
// Es el componente encargado de validar la integridad de los datos.                            //
// Mantiene una "FIFO emulada" (cola) para comparar lo que entra con lo que sale y              //
// reporta los resultados al Scoreboard.                                                        //
//////////////////////////////////////////////////////////////////////////////////////////////////

class checker_c #(parameter width = 16, parameter depth = 8);
  // --- Objetos de transacciones ---
  trans_fifo #(.width(width)) transaccion; // Transacción recibida del Monitor
  trans_fifo #(.width(width)) auxiliar;    // Para extraer datos de la cola emulada
  trans_sb   #(.width(width)) to_sb;       // Paquete de reporte para el Scoreboard
  
  // --- FIFO Emulada (Modelo de referencia) ---
  trans_fifo  emul_fifo[$];                // Cola que imita el comportamiento del hardware
  
  // --- Canales de comunicación (Mailboxes) ---
  trans_fifo_mbx mon_chkr_mbx;             // Entrada desde el Monitor
  trans_sb_mbx  chkr_sb_mbx;               // Salida hacia el Scoreboard
  
  int contador_auxiliar;                   // Útil para limpiar la FIFO en resets

  // --- Constructor: Inicializa la cola vacía ---
  function new();
    this.emul_fifo = {};
    this.contador_auxiliar = 0;
  endfunction 

  // --- Tarea Principal: Validación continua ---
  task run;
    $display("[%g] El checker fue inicializado", $time);
    
    forever begin
      to_sb = new();
      // 1. Recibe el reporte del Monitor
      mon_chkr_mbx.get(transaccion);
      transaccion.print("Checker: Se recibe transacción desde el monitor");
      to_sb.clean();
      
      // 2. Analiza el tipo de operación capturada
      case(transaccion.tipo)
        
        // --- CASO LECTURA ---
        lectura: begin
          if(emul_fifo.size() > 0) begin
            // Si hay datos, extrae el más antiguo y compara
            auxiliar = emul_fifo.pop_front();
            if(transaccion.dato_out == auxiliar.dato) begin
              to_sb.dato_enviado = auxiliar.dato;
              to_sb.tiempo_push = auxiliar.tiempo;
              to_sb.tiempo_pop = transaccion.tiempo;
              to_sb.completado = 1;
              to_sb.calc_latencia();
              to_sb.print("Checker: Transaccion Completada");
              chkr_sb_mbx.put(to_sb);
            end else begin
              // ERROR: El dato que salió del hardware no es el que esperábamos
              $error("Dato_leido=%h, Dato_Esperado=%h", transaccion.dato_out, auxiliar.dato);
              $finish;
            end
          end else begin
            // Si intenta leer y está vacía, reporta Underflow
            to_sb.tiempo_pop = transaccion.tiempo;
            to_sb.underflow = 1;
            to_sb.print("Checker: Underflow");
            chkr_sb_mbx.put(to_sb);
          end
        end
        
        // --- CASO ESCRITURA ---
        escritura: begin
          if(emul_fifo.size() == depth) begin
            // Si está llena y se intenta escribir, reporta Overflow
            auxiliar = emul_fifo.pop_front();
            to_sb.dato_enviado = auxiliar.dato;
            to_sb.tiempo_push = auxiliar.tiempo;
            to_sb.overflow = 1;
            to_sb.print("Checker: Overflow");
            chkr_sb_mbx.put(to_sb);
          end
          // Guarda el dato en la FIFO emulada para futuras comparaciones
          emul_fifo.push_back(transaccion);
          transaccion.print("Checker: Escritura");
        end
        
        // --- CASO SIMULTÁNEO (Escritura y Lectura al mismo tiempo) ---
        escritura_lectura: begin
          $display("[%t] Checker: Procesando escritura_lectura_simultanea", $time);
          
          if(emul_fifo.size() == 0) begin
            // SUB-CASO: BYPASS (FIFO vacía, el dato entra y sale de inmediato)
            $display("[%t] Checker: SIMULTÁNEA en FIFO vacía - BYPASS", $time);
            transaccion.dato_out = transaccion.dato;
            
            to_sb.dato_enviado = transaccion.dato;
            to_sb.tiempo_push = transaccion.tiempo;
            to_sb.tiempo_pop = transaccion.tiempo;
            to_sb.completado = 1;
            to_sb.latencia = 0; 
            to_sb.print("Checker: BYPASS detectado");
            chkr_sb_mbx.put(to_sb);
          end 
          else if(emul_fifo.size() == depth) begin
            // SUB-CASO: FULL (Se lee el antiguo, pero el nuevo no entra)
            $display("[%t] Checker: SIMULTÁNEA en FIFO llena - solo LECTURA", $time);
            auxiliar = emul_fifo.pop_front();
            to_sb.dato_enviado = auxiliar.dato;
            to_sb.tiempo_push = auxiliar.tiempo;
            to_sb.tiempo_pop = transaccion.tiempo;
            to_sb.completado = 1;
            to_sb.calc_latencia();
            chkr_sb_mbx.put(to_sb);
          end
          else begin
            // SUB-CASO: NORMAL (Se lee el viejo y se guarda el nuevo)
            auxiliar = emul_fifo.pop_front();
            emul_fifo.push_back(transaccion);
            
            to_sb.dato_enviado = auxiliar.dato;
            to_sb.tiempo_push = auxiliar.tiempo;
            to_sb.tiempo_pop = transaccion.tiempo;
            to_sb.completado = 1;
            to_sb.calc_latencia();
            chkr_sb_mbx.put(to_sb);
          end
        end
        
        // --- CASO RESET ---
        reset: begin
          // Limpia la FIFO emulada y reporta las transacciones como perdidas
          contador_auxiliar = emul_fifo.size();
          for(int i = 0; i < contador_auxiliar; i++) begin
            auxiliar = emul_fifo.pop_front();
            to_sb.clean();
            to_sb.dato_enviado = auxiliar.dato; 
            to_sb.tiempo_push = auxiliar.tiempo;
            to_sb.reset = 1;
            to_sb.print("Checker: Reset - Transaccion perdida");
            chkr_sb_mbx.put(to_sb);
          end
        end
        
        default: begin
          $display("[%g] Checker Error: tipo de transacción no válido", $time);
          $finish;
        end
      endcase    
    end
  endtask
endclass
