//////////////////////////////////////////////////////////////////////////////////////////////////
// Monitor:                                                                                     //
// Este bloque es un observador pasivo. No mueve ninguna señal; simplemente "escucha" la        //
// interfaz y traduce los cambios de voltajes/niveles lógicos en objetos de transacción         //
// para que el Checker pueda validarlos.                                                        //
//////////////////////////////////////////////////////////////////////////////////////////////////

class monitor#(parameter width = 16);
  // --- Interfaz Virtual ---
  virtual fifo_if #(.width(width)) vif; // Conexión a las señales físicas del DUT
  
  // --- Canal de comunicación ---
  trans_fifo_mbx mon_chkr_mbx;          // Mailbox para enviar lo observado al Checker

  // --- Tarea Principal: Observación continua ---
  task run();
    $display("[%g] El monitor fue inicializado", $time);
    
    forever begin
      trans_fifo #(.width(width)) transaction;
      
      // Sincronización con el flanco de reloj
      @(posedge vif.clk);
      
      // RETARDO CRÍTICO (#2):
      // Se espera un pequeño tiempo después del flanco de reloj para asegurar que 
      // las señales combinacionales (como dato_out) ya se hayan estabilizado. 
      // Sin esto, el monitor podría capturar el dato viejo.
      #2; 

      // 1. Detección de RESET
      if (vif.rst) begin
        transaction = new();
        transaction.tipo = reset;
        transaction.tiempo = $time;
        mon_chkr_mbx.put(transaction);
      end else begin
        
        // 2. Detección de ESCRITURA (PUSH)
        if (vif.push) begin
          transaction = new();
          transaction.tipo = escritura;
          transaction.dato = vif.dato_in; // Captura el dato que está entrando
          transaction.tiempo = $time;
          mon_chkr_mbx.put(transaction);
        end 

        // 3. Detección de LECTURA (POP)
        if (vif.pop) begin
          transaction = new();
          transaction.tipo = lectura;
          transaction.tiempo = $time;
          // Captura el dato que está saliendo de la FIFO
          transaction.dato_out = vif.dato_out; 
          mon_chkr_mbx.put(transaction);
          void'(transaction.print("Monitor: Lectura detectada"));
        end
      end
    end
  endtask
endclass
