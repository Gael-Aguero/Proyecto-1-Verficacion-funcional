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
    this.emul_fifo = {};
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
      $display("[%g] CHECKER DEBUG: FIFO size=%0d, tipo=%s", $time, emul_fifo.size(), transaccion.tipo.name());
      
      case(transaccion.tipo)
        
        //  CASO: LECTURA
        lectura: begin
          if(emul_fifo.size() > 0) begin    // si hay datos en el FIFO emulado
            auxiliar = emul_fifo.pop_front(); // saca el dato esperado
            
            //  DEBUG: Comparación
            $display("[%g] CHECKER: Esperado=%h, Recibido=%h", $time, auxiliar.dato, transaccion.dato_out);
            
            //  Comparación dato esperado vs recibido
            if(transaccion.dato_out === auxiliar.dato) begin
              to_sb.dato_enviado = auxiliar.dato;
              to_sb.tiempo_push = auxiliar.tiempo;
              to_sb.tiempo_pop = transaccion.tiempo;
              to_sb.completado = 1;
              to_sb.calc_latencia();        // calcula latencia
              chkr_sb_mbx.put(to_sb);       // envía resultado al scoreboard
              $display("[%g] CHECKER: ✓ Lectura exitosa - dato=0x%h", $time, auxiliar.dato);
            end else begin
              //  Error de datos
              $error("ERROR en [%g]: esperado=%h recibido=%h", $time, auxiliar.dato, transaccion.dato_out);
              $finish;
            end
          end else begin
            //  Underflow: lectura sin datos
            to_sb.clean();
            to_sb.underflow = 1;
            to_sb.tiempo_pop = transaccion.tiempo;
            chkr_sb_mbx.put(to_sb);
            $display("[%g] CHECKER: ⚠ UNDERFLOW detectado en lectura", $time);
          end
        end
        
        // CASO: ESCRITURA
        escritura: begin
          if(emul_fifo.size() == depth) begin
            //  Overflow: FIFO lleno
            to_sb.clean();
            to_sb.overflow = 1;
            to_sb.dato_enviado = transaccion.dato;
            to_sb.tiempo_push = transaccion.tiempo;
            chkr_sb_mbx.put(to_sb);
            $display("[%g] CHECKER: ⚠ OVERFLOW detectado - dato=0x%h no se pudo escribir", $time, transaccion.dato);
          end else begin
            //  Inserta dato en FIFO emulado
            transaccion.tiempo = $time;  // Marcar tiempo de entrada
            emul_fifo.push_back(transaccion);
            $display("[%g] CHECKER: ✓ Escritura exitosa - dato=0x%h, FIFO size=%0d/%0d", $time, transaccion.dato, emul_fifo.size(), depth);
          end
        end
        
        //  CASO: RESET
        reset: begin
          contador_auxiliar = emul_fifo.size();
          
          if(contador_auxiliar > 0) begin
            $display("[%g] CHECKER: ⚠ RESET detectado - se pierden %0d datos", $time, contador_auxiliar);
            
            // Reportar cada dato perdido al scoreboard
            for(int i = 0; i < contador_auxiliar; i++) begin
              auxiliar = emul_fifo.pop_front();
              to_sb = new();
              to_sb.clean();
              to_sb.reset = 1;
              to_sb.dato_enviado = auxiliar.dato;
              to_sb.tiempo_push = auxiliar.tiempo;
              to_sb.tiempo_pop = $time;
              chkr_sb_mbx.put(to_sb);
            end
          end else begin
            $display("[%g] CHECKER: RESET detectado - FIFO ya estaba vacía", $time);
            // También reportamos el reset aunque no haya datos
            to_sb.clean();
            to_sb.reset = 1;
            chkr_sb_mbx.put(to_sb);
          end
        end
        
        //  CASO: ESCRITURA_LECTURA (Pop y Push simultáneo)
        escritura_lectura: begin
          $display("[%g] CHECKER: Escritura/Lectura simultánea detectada - FIFO size=%0d", $time, emul_fifo.size());
          
          if(emul_fifo.size() == 0) begin
            // FIFO vacía: el DUT hace bypass - el dato nuevo aparece en la salida
            $display("[%g] CHECKER: FIFO vacía - bypass: dato=0x%h", $time, transaccion.dato);
            
            // Verificar que el dato leído es el mismo que se escribió (bypass)
            if(transaccion.dato_out === transaccion.dato) begin
              to_sb.dato_enviado = transaccion.dato;
              to_sb.tiempo_push = $time;
              to_sb.tiempo_pop = $time;
              to_sb.completado = 1;
              to_sb.calc_latencia();
              $display("[%g] CHECKER: ✓ Bypass exitoso - dato=0x%h", $time, transaccion.dato);
            end else begin
              $error("ERROR en [%g]: bypass vacío - esperado=%h recibido=%h", $time, transaccion.dato, transaccion.dato_out);
              $finish;
            end
            chkr_sb_mbx.put(to_sb);
            
          end else if(emul_fifo.size() == depth) begin
            // FIFO llena: el DUT hace bypass - el dato nuevo sale, el más antiguo se pierde (overflow)
            $display("[%g] CHECKER: FIFO llena - bypass con pérdida del dato más antiguo", $time);
            
            // El dato más antiguo se pierde (overflow)
            auxiliar = emul_fifo.pop_front();
            to_sb = new();
            to_sb.clean();
            to_sb.overflow = 1;
            to_sb.dato_enviado = auxiliar.dato;
            to_sb.tiempo_push = auxiliar.tiempo;
            chkr_sb_mbx.put(to_sb);
            $display("[%g] CHECKER: ⚠ OVERFLOW - dato antiguo 0x%h se pierde", $time, auxiliar.dato);
            
            // Verificar que el dato leído es el nuevo (bypass)
            to_sb = new();
            to_sb.clean();
            if(transaccion.dato_out === transaccion.dato) begin
              to_sb.dato_enviado = transaccion.dato;
              to_sb.tiempo_push = $time;
              to_sb.tiempo_pop = $time;
              to_sb.completado = 1;
              to_sb.calc_latencia();
              $display("[%g] CHECKER: ✓ Bypass exitoso en FIFO llena - dato=0x%h", $time, transaccion.dato);
            end else begin
              $error("ERROR en [%g]: FIFO llena bypass - esperado=%h recibido=%h", $time, transaccion.dato, transaccion.dato_out);
              $finish;
            end
            chkr_sb_mbx.put(to_sb);
            
          end else begin
            // FIFO a medio llenar: comportamiento FIFO normal (NO bypass)
            // Sale el dato más antiguo, entra el nuevo
            $display("[%g] CHECKER: FIFO medio (%0d/%0d) - comportamiento FIFO normal", $time, emul_fifo.size(), depth);
            
            auxiliar = emul_fifo.pop_front();
            transaccion.tiempo = $time;
            emul_fifo.push_back(transaccion);
            
            $display("[%g] CHECKER: FIFO medio - dato_sale=0x%h, dato_entra=0x%h", $time, auxiliar.dato, transaccion.dato);
            
            // Verificar que el dato leído es el más antiguo
            if(transaccion.dato_out === auxiliar.dato) begin
              to_sb.dato_enviado = auxiliar.dato;
              to_sb.tiempo_push = auxiliar.tiempo;
              to_sb.tiempo_pop = $time;
              to_sb.completado = 1;
              to_sb.calc_latencia();
              $display("[%g] CHECKER: ✓ Lectura/escritura simultánea exitosa - dato=0x%h", $time, auxiliar.dato);
            end else begin
              $error("ERROR en [%g]: FIFO medio - esperado=%h recibido=%h", $time, auxiliar.dato, transaccion.dato_out);
              $finish;
            end
            chkr_sb_mbx.put(to_sb);
          end
        end
        
        //  CASO: ERROR
        default: begin
          $display("[%g] Checker Error: tipo desconocido %s", $time, transaccion.tipo.name());
          $finish;
        end
      endcase    
    end
  endtask

endclass