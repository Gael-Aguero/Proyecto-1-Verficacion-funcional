//////////////////////////////////////////////////////////////////////////////////////////////////
// Driver:                                                                                      //
// Este componente traduce las transacciones abstractas (objetos) en señales eléctricas         //
// (niveles lógicos 0 y 1) que la FIFO puede entender. Se sincroniza con el reloj (clk).        //
//////////////////////////////////////////////////////////////////////////////////////////////////

class driver #(parameter width = 16);

  virtual fifo_if #(.width(width)) vif; 
  trans_fifo_mbx agnt_drv_mbx;          
  int espera;

  task run();
    $display("[%g]  El driver fue inicializado", $time);
    
    // Reset inicial
    vif.rst = 1;
    @(posedge vif.clk);
    vif.rst = 0;
    @(posedge vif.clk);
    
    forever begin
      trans_fifo #(.width(width)) transaction; 
      
      // Limpieza de señales
      vif.push    = 0;
      vif.pop     = 0;
      
      $display("[%g] el Driver espera por una transacción", $time);
      espera = 0;
      
      @(posedge vif.clk);
      agnt_drv_mbx.get(transaction);
      transaction.print("Driver: Transaccion recibida");
      
      // Manejo de retardo
      while(espera < transaction.retardo) begin
        @(posedge vif.clk);
        espera++;
        if(transaction.tipo == escritura) begin
          vif.dato_in = transaction.dato;
        end
      end
      
      case (transaction.tipo)
        
        lectura: begin
          vif.pop = 1;
          @(posedge vif.clk);
          
          //Capturar inmediatamente
          transaction.dato_out = vif.dato_out;
          
          vif.pop = 0;
          transaction.print("Driver: Transaccion ejecutada (LECTURA)");
          $display("[%g] DRIVER: Dato leído = 0x%h", $time, transaction.dato_out);
          
          // 🔧 AÑADIR: Enviar la transacción con el dato leído al checker
        end
        
        escritura: begin
          vif.dato_in = transaction.dato;
          vif.push = 1;
          @(posedge vif.clk);
          vif.push = 0;
          transaction.print("Driver: Transaccion ejecutada (ESCRITURA)");
          $display("[%g] DRIVER: Dato escrito = 0x%h", $time, transaction.dato);
        end
        
        escritura_lectura: begin
          vif.dato_in = transaction.dato;
          vif.push = 1;
          vif.pop  = 1;
          @(posedge vif.clk);
          transaction.dato_out = vif.dato_out;
          vif.push = 0;
          vif.pop  = 0;
          transaction.print("Driver: Transaccion ejecutada (ESCRITURA+LECTURA)");
        end
        
        reset: begin
          vif.rst = 1;
          @(posedge vif.clk);
          vif.rst = 0;
          transaction.print("Driver: Transaccion ejecutada (RESET)");
          $display("[%g] DRIVER: Reset ejecutado", $time);
        end
        
        default: begin
          $display("[%g] Driver Error: tipo invalido = %0d", $time, transaction.tipo);
          $finish;
        end 
      endcase    
      
      @(posedge vif.clk);
    end
  endtask
endclass