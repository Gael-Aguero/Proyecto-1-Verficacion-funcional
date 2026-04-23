class checker_c #(parameter width = 16, parameter depth = 8);

  //  Transacciones de entrada y auxiliares
  trans_fifo #(.width(width)) transaccion;
  trans_fifo #(.width(width)) auxiliar;
  trans_sb   #(.width(width)) to_sb;
  
  //  FIFO emulado
  trans_fifo #(.width(width)) emul_fifo[$];
  
  //  Mailboxes de comunicación
  trans_fifo_mbx mon_chkr_mbx;
  trans_sb_mbx  chkr_sb_mbx;
  
  int contador_auxiliar;

  function new();
    this.emul_fifo = {};
    this.contador_auxiliar = 0;
  endfunction 

  task run;
    $display("[%g] El checker fue inicializado", $time);
    
    // ✅ VARIABLES LOCALES DECLARADAS AL INICIO
    trans_fifo #(.width(width)) temp_trans;
    trans_fifo #(.width(width)) copy_trans;
    
    forever begin
      to_sb = new();
      mon_chkr_mbx.get(temp_trans);
      transaccion = temp_trans;
      to_sb.clean();
      
      $display("[%g] CHECKER DEBUG: FIFO size=%0d, tipo=%s", $time, emul_fifo.size(), transaccion.tipo.name());
      
      case(transaccion.tipo)
        
        lectura: begin
          if(emul_fifo.size() > 0) begin
            auxiliar = emul_fifo.pop_front();
            $display("[%g] CHECKER: Esperado=%h, Recibido=%h", $time, auxiliar.dato, transaccion.dato_out);
            
            if(transaccion.dato_out === auxiliar.dato) begin
              to_sb.dato_enviado = auxiliar.dato;
              to_sb.tiempo_push = auxiliar.tiempo;
              to_sb.tiempo_pop = transaccion.tiempo;
              to_sb.completado = 1;
              to_sb.calc_latencia();
              chkr_sb_mbx.put(to_sb);
              $display("[%g] CHECKER: ✓ Lectura exitosa - dato=0x%h", $time, auxiliar.dato);
            end else begin
              $error("ERROR en [%g]: esperado=%h recibido=%h", $time, auxiliar.dato, transaccion.dato_out);
              $finish;
            end
          end else begin
            to_sb.clean();
            to_sb.underflow = 1;
            to_sb.tiempo_pop = transaccion.tiempo;
            chkr_sb_mbx.put(to_sb);
            $display("[%g] CHECKER: ⚠ UNDERFLOW detectado en lectura", $time);
          end
        end
        
        escritura: begin
          if(emul_fifo.size() == depth) begin
            to_sb.clean();
            to_sb.overflow = 1;
            to_sb.dato_enviado = transaccion.dato;
            to_sb.tiempo_push = transaccion.tiempo;
            chkr_sb_mbx.put(to_sb);
            $display("[%g] CHECKER: ⚠ OVERFLOW detectado - dato=0x%h no se pudo escribir", $time, transaccion.dato);
          end else begin
            transaccion.tiempo = $time;
            
            // ✅ Usar la variable declarada al inicio
            copy_trans = new();
            copy_trans.tipo = transaccion.tipo;
            copy_trans.dato = transaccion.dato;
            copy_trans.tiempo = transaccion.tiempo;
            copy_trans.retardo = transaccion.retardo;
            copy_trans.dato_out = transaccion.dato_out;
            
            emul_fifo.push_back(copy_trans);
            $display("[%g] CHECKER: ✓ Escritura exitosa - dato=0x%h, FIFO size=%0d/%0d", $time, transaccion.dato, emul_fifo.size(), depth);
          end
        end
        
        reset: begin
          contador_auxiliar = emul_fifo.size();
          
          if(contador_auxiliar > 0) begin
            $display("[%g] CHECKER: ⚠ RESET detectado - se pierden %0d datos", $time, contador_auxiliar);
            
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
            to_sb.clean();
            to_sb.reset = 1;
            chkr_sb_mbx.put(to_sb);
          end
        end
        
        escritura_lectura: begin
          $display("[%g] CHECKER: Escritura/Lectura simultánea detectada - FIFO size=%0d", $time, emul_fifo.size());
          
          if(emul_fifo.size() == 0) begin
            $display("[%g] CHECKER: FIFO vacía - bypass: dato=0x%h", $time, transaccion.dato);
            
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
            $display("[%g] CHECKER: FIFO llena - bypass con pérdida del dato más antiguo", $time);
            
            auxiliar = emul_fifo.pop_front();
            to_sb = new();
            to_sb.clean();
            to_sb.overflow = 1;
            to_sb.dato_enviado = auxiliar.dato;
            to_sb.tiempo_push = auxiliar.tiempo;
            chkr_sb_mbx.put(to_sb);
            $display("[%g] CHECKER: ⚠ OVERFLOW - dato antiguo 0x%h se pierde", $time, auxiliar.dato);
            
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
            $display("[%g] CHECKER: FIFO medio (%0d/%0d) - comportamiento FIFO normal", $time, emul_fifo.size(), depth);
            
            auxiliar = emul_fifo.pop_front();
            
            // ✅ Usar la variable declarada al inicio
            copy_trans = new();
            copy_trans.tipo = transaccion.tipo;
            copy_trans.dato = transaccion.dato;
            copy_trans.tiempo = $time;
            copy_trans.retardo = transaccion.retardo;
            copy_trans.dato_out = transaccion.dato_out;
            emul_fifo.push_back(copy_trans);
            
            $display("[%g] CHECKER: FIFO medio - dato_sale=0x%h, dato_entra=0x%h", $time, auxiliar.dato, transaccion.dato);
            
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
        
        default: begin
          $display("[%g] Checker Error: tipo desconocido %s", $time, transaccion.tipo.name());
          $finish;
        end
      endcase    
    end
  endtask

endclass