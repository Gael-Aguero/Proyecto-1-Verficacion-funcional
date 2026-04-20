class checker_c #(parameter width = 16, parameter depth = 8);

  //  Transacciones de entrada y auxiliares
  trans_fifo #(.width(width)) transaccion;   // transacción recibida del monitor
  trans_fifo #(.width(width)) auxiliar;      // para comparar en lecturas
  trans_sb   #(.width(width)) to_sb;         // objeto que se envía al scoreboard
  
  //  FIFO emulado (modelo de referencia)
  trans_fifo  emul_fifo[$];                  // cola dinámica que simula el FIFO ideal
  
  //  Mailboxes de comunicación
  trans_fifo_mbx mon_chkr_mbx;               // monitor → checker
  trans_sb_mbx  chkr_sb_mbx;                 // checker → scoreboard
  
  int contador_auxiliar;                     // usado en reset para vaciar la cola

  //  Constructor
  function new();
    this.emul_fifo = {};                    // inicializa FIFO vacío
    this.contador_auxiliar = 0;
  endfunction 

  //  Proceso principal del checker
  task run;
    $display("[%g] El checker fue inicializado", $time);
    
    forever begin
      to_sb = new();                        // crea nuevo objeto para scoreboard
      mon_chkr_mbx.get(transaccion);        // recibe transacción del monitor
      to_sb.clean();                        // limpia valores previos
      
      // DEBUG: Mostrar tamaño de FIFO emulada
      // $display("[%g] CHECKER DEBUG: FIFO size=%0d, tipo=%s", $time, emul_fifo.size(), transaccion.tipo);
      
      case(transaccion.tipo)
        
        //  CASO: LECTURA
        lectura: begin
          if(emul_fifo.size() > 0) begin    // si hay datos en el FIFO emulado
            auxiliar = emul_fifo.pop_front(); // saca el dato esperado
            
            //  DEBUG: Comparación
            // $display("[%g] CHECKER: Esperado=%h, Recibido=%h", $time, auxiliar.dato, transaccion.dato_out);
            
            //  Comparación dato esperado vs recibido
            if(transaccion.dato_out == auxiliar.dato) begin
              to_sb.dato_enviado = auxiliar.dato;
              to_sb.tiempo_push = auxiliar.tiempo;
              to_sb.tiempo_pop = transaccion.tiempo;
              to_sb.completado = 1;
              to_sb.calc_latencia();        // calcula latencia
              chkr_sb_mbx.put(to_sb);       // envía resultado al scoreboard
            end else begin
              //  Error de datos
              $error("ERROR en [%g]: esperado=%h recibido=%h", $time, auxiliar.dato, transaccion.dato_out);
              $finish;
            end
          end else begin
            //  Underflow: lectura sin datos
            to_sb.clean();                   // 🔧 LIMPIAR ANTES DE USAR
            to_sb.underflow = 1;
            to_sb.tiempo_pop = transaccion.tiempo;  // Registrar cuando ocurrió
            chkr_sb_mbx.put(to_sb);
            $display("[%g] CHECKER: UNDERFLOW detectado en lectura", $time);
          end
        end
        
        // CASO: ESCRITURA
        escritura: begin
          if(emul_fifo.size() == depth) begin
            //  Overflow: FIFO lleno
            to_sb.clean();
            to_sb.overflow = 1;
            to_sb.dato_enviado = transaccion.dato;  // Registrar qué dato se perdió
            to_sb.tiempo_push = transaccion.tiempo;
            chkr_sb_mbx.put(to_sb);
            $display("[%g] CHECKER: OVERFLOW detectado - dato=0x%h no se pudo escribir", $time, transaccion.dato);
          end else begin
            //  Inserta dato en FIFO emulado
            emul_fifo.push_back(transaccion);
            // $display("[%g] CHECKER: Escritura exitosa - dato=0x%h, FIFO size=%0d", $time, transaccion.dato, emul_fifo.size());
          end
        end
        
        //  CASO: RESET
        reset: begin
          contador_auxiliar = emul_fifo.size(); // guarda tamaño actual
        reset: begin
  contador_auxiliar = emul_fifo.size();
  
  if(contador_auxiliar > 0) begin  // 🔧 Solo reportar si hay datos perdidos
    $display("[%g] CHECKER: RESET detectado - se pierden %0d datos", $time, contador_auxiliar);
    
    for(int i = 0; i < contador_auxiliar; i++) begin
      auxiliar = emul_fifo.pop_front();
      to_sb.clean();
      to_sb.reset = 1;
      to_sb.dato_enviado = auxiliar.dato;
      to_sb.tiempo_push = auxiliar.tiempo;
      to_sb.tiempo_pop = $time;
      chkr_sb_mbx.put(to_sb);
    end
  end else begin
    $display("[%g] CHECKER: RESET detectado - FIFO ya estaba vacía", $time);
    // 🔧 NO enviar transacción si no hay datos perdidos
  end
end //si no había datos, igual notificar el reset
          if(contador_auxiliar == 0) begin
            to_sb.clean();
            to_sb.reset = 1;
            chkr_sb_mbx.put(to_sb);
          end
        end
        
        //  CASO: ERROR
        default: begin
          $display("[%g] Checker Error: tipo desconocido %s", $time, transaccion.tipo);
          $finish;
        end
      endcase    
    end
  endtask

endclass