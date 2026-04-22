class monitor#(parameter width = 16);

  // Interfaz virtual hacia el DUT (FIFO)
  virtual fifo_if #(.width(width)) vif;
  
  // Mailbox para enviar transacciones al checker
  trans_fifo_mbx mon_chkr_mbx;
  
  // Variables para debounce
  bit last_push, last_pop, last_rst;

  task run();
    $display("[%g] El monitor fue inicializado", $time);
    
    // Inicializar variables
    last_push = 0;
    last_pop = 0;
    last_rst = 0;
    
    forever begin
      @(posedge vif.clk);
      
      //////////////////////////////////////////////////////
      // DETECCIÓN DE RESET (prioridad máxima)
      //////////////////////////////////////////////////////
      if (vif.rst && !last_rst) begin
        trans_fifo #(.width(width)) transaction;
        transaction = new();
        transaction.tipo = reset;
        transaction.tiempo = $time;
        
        $display("[%g] MONITOR: Reset detectado", $time);
        mon_chkr_mbx.put(transaction);
      end
      
      //////////////////////////////////////////////////////
      // DETECCIÓN DE PUSH Y POP SIMULTÁNEO (prioridad alta)
      //////////////////////////////////////////////////////
      if (vif.push && vif.pop && (!last_push || !last_pop)) begin
        trans_fifo #(.width(width)) transaction;
        transaction = new();
        transaction.tipo = escritura_lectura;
        transaction.tiempo = $time;
        transaction.dato = vif.dato_in;
        transaction.dato_out = vif.dato_out;
        
        $display("[%g] MONITOR: Escritura/Lectura simultánea detectada - dato_in=0x%h, dato_out=0x%h", 
                 $time, transaction.dato, transaction.dato_out);
        mon_chkr_mbx.put(transaction);
      end
      
      //////////////////////////////////////////////////////
      // DETECCIÓN DE ESCRITURA (PUSH) SOLAMENTE
      //////////////////////////////////////////////////////
      else if (vif.push && !vif.pop && !last_push) begin
        trans_fifo #(.width(width)) transaction;
        transaction = new();
        transaction.tipo = escritura;
        transaction.dato = vif.dato_in;
        transaction.tiempo = $time;
        
        $display("[%g] MONITOR: Escritura detectada - dato=0x%h", $time, transaction.dato);
        mon_chkr_mbx.put(transaction);
      end 
      
      //////////////////////////////////////////////////////
      // DETECCIÓN DE LECTURA (POP) SOLAMENTE
      //////////////////////////////////////////////////////
      else if (vif.pop && !vif.push && !last_pop) begin
        trans_fifo #(.width(width)) transaction;
        transaction = new();
        transaction.tipo = lectura;
        transaction.tiempo = $time;
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