class monitor#(parameter width = 16);

  // Interfaz virtual hacia el DUT (FIFO)
  virtual fifo_if #(.width(width)) vif;
  
  // Mailbox para enviar transacciones al checker
  trans_fifo_mbx mon_chkr_mbx;
  
  // Variables para debounce (evitar múltiples detecciones)
  bit last_push, last_pop, last_rst;

  task run();
    $display("[%g] El monitor fue inicializado", $time);
    
    // Inicializar variables
    last_push = 0;
    last_pop = 0;
    last_rst = 0;
    
    //////////////////////////////////////////////////////
    // LOOP PRINCIPAL DE MONITOREO
    //////////////////////////////////////////////////////
    forever begin
      
      //////////////////////////////////////////////////////
      // SINCRONIZACIÓN CON EL RELOJ
      //////////////////////////////////////////////////////
      @(posedge vif.clk);
      
      // 🔧 Pequeño delay para asegurar estabilidad de señales
      //#1;  // Reducido de 5 a 1 para mejor sincronización
      
      //////////////////////////////////////////////////////
      // DETECCIÓN DE EVENTOS (con detección de flanco)
      //////////////////////////////////////////////////////
      
      //  RESET (detección por flanco positivo)
      if (vif.rst && !last_rst) begin
        trans_fifo #(.width(width)) transaction;
        transaction = new();
        transaction.tipo = reset;
        transaction.tiempo = $time;
        
        $display("[%g] MONITOR: Reset detectado", $time);
        mon_chkr_mbx.put(transaction);
      end
      
      //  ESCRITURA (PUSH) - detección por flanco
      if (vif.push && !last_push) begin
        trans_fifo #(.width(width)) transaction;
        transaction = new();
        transaction.tipo = escritura;
        
        // Captura el dato que entra a la FIFO
        transaction.dato = vif.dato_in;
        transaction.tiempo = $time;
        
        $display("[%g] MONITOR: Escritura detectada - dato=0x%h", $time, transaction.dato);
        mon_chkr_mbx.put(transaction);
      end 

      //  LECTURA (POP) - detección por flanco
      if (vif.pop && !last_pop) begin
        trans_fifo #(.width(width)) transaction;
        transaction = new();
        transaction.tipo = lectura;
        transaction.tiempo = $time;
        
        // Captura el dato que sale de la FIFO
        transaction.dato_out = vif.dato_out;
        
        $display("[%g] MONITOR: Lectura detectada - dato_out=0x%h", $time, transaction.dato_out);
        mon_chkr_mbx.put(transaction);
      end
      
      // Actualizar últimos valores
      last_push = vif.push;
      last_pop = vif.pop;
      last_rst = vif.rst;
    end
  endtask
endclass