/////////////////////////////////////////////////////////////////////////////
// Monitor: Responsable de observar el DUT pasivamente
/////////////////////////////////////////////////////////////////////////////
class monitor #(parameter width = 16);
  virtual fifo_if #(.width(width)) vif;
  trans_fifo_mbx mon_chkr_mbx; 

  typedef enum {idle, escritura_active, lectura_active, reset_active} monitor_state;
  monitor_state state;

  task run();
    state = idle;
    $display("[%g] El monitor fue inicializado", $time);

    forever begin
      trans_fifo #(.width(width)) transaction;
      @(posedge vif.clk);

      if (vif.rst) begin // Reset detectado
        if (state != reset_active) begin
          transaction = new();
          transaction.tipo = reset;
          transaction.tiempo = $time;
          mon_chkr_mbx.put(transaction);
          transaction.print("Monitor: Reset detectado");
          state = reset_active;
        end
      end 
      else if (vif.push) begin // Escritura detectada
        if (state != escritura_active) begin
          transaction = new();
          transaction.tipo = escritura;
          transaction.dato = vif.dato_in;
          transaction.tiempo = $time;
          mon_chkr_mbx.put(transaction);
          transaction.print("Monitor: Escritura detectada");
          state = escritura_active;  
        end
      end 
      else if (vif.pop) begin // Lectura detectada
        if (state != lectura_active) begin
          transaction = new();
          transaction.tipo = lectura;
          transaction.dato = vif.dato_out;
          transaction.tiempo = $time;
          mon_chkr_mbx.put(transaction);
          transaction.print("Monitor: Lectura detectada");
          state = lectura_active;  //
        end
      end
      else begin 
        state = idle;
      end
    end
  endtask 
endclass