//////////////////////////////////////////////////////////////////////////////////////////////////
// Driver:                                                                                      //
// Este componente traduce las transacciones abstractas (objetos) en señales eléctricas         //
// (niveles lógicos 0 y 1) que la FIFO puede entender. Se sincroniza con el reloj (clk).        //
//////////////////////////////////////////////////////////////////////////////////////////////////

class driver #(parameter width = 16);
  // --- Interfaz Virtual ---
  virtual fifo_if #(.width(width)) vif; // Conexión física a los pines de la FIFO
  
  // --- Canal de comunicación ---
  trans_fifo_mbx agnt_drv_mbx;          // Mailbox para recibir paquetes del Agente
  
  int espera; // Contador para manejar los retardos entre transacciones

  // --- Tarea Principal: Ejecución del Driver ---
  task run();
    $display("[%g]  El driver fue inicializado", $time);
    
    // 1. Secuencia de Inicio / Reset Inicial
    vif.rst = 1;
    @(posedge vif.clk);
    vif.rst = 1;
    @(posedge vif.clk); // Asegura que el hardware inicie en un estado conocido (limpio)
    
    forever begin
      trans_fifo #(.width(width)) transaction; 
      
      // 2. Limpieza de señales (Estado inactivo por defecto)
      vif.push    = 0;
      vif.rst     = 0;
      vif.pop     = 0;
      vif.dato_in = 0;
      
      $display("[%g] el Driver espera por una transacción", $time);
      espera = 0;
      
      // 3. Obtención de la transacción desde el Agente
      @(posedge vif.clk);
      agnt_drv_mbx.get(transaction);
      transaction.print("Driver: Transaccion recibida");
      
      // 4. Manejo del Retardo (Delay)
      // Genera una espera de N ciclos de reloj antes de ejecutar la acción
      while(espera < transaction.retardo) begin
        @(posedge vif.clk);
        espera = espera + 1;
        vif.dato_in = transaction.dato; // Mantiene el dato en el bus durante la espera
      end
      
      // 5. Ejecución de la operación en el hardware (DUT)
      case(transaction.tipo)
        
        // OPERACIÓN: LECTURA
        lectura: begin
          vif.pop = 1;         // Activa la señal de lectura
          @(posedge vif.clk);  // Espera al flanco de reloj para que la FIFO reaccione
          transaction.dato_out = vif.dato_out; // Captura el dato que salió
          vif.pop = 0;         // Desactiva la señal inmediatamente (limpieza)
          transaction.print("Driver: Transaccion ejecutada");
        end
        
        // OPERACIÓN: ESCRITURA
        escritura: begin
          vif.push = 1;        // Activa la señal de escritura
          vif.dato_in = transaction.dato; // Pone el dato en el bus de entrada
          @(posedge vif.clk);  // Espera al flanco para que se guarde el dato
          vif.push = 0;        // Limpia la señal
          transaction.print("Driver: Transaccion ejecutada");
        end
        
        // OPERACIÓN: SIMULTÁNEA (Escritura y Lectura al mismo tiempo)
        // Crítico para probar el escenario de Bypass
        escritura_lectura: begin
          vif.dato_in = transaction.dato;
          vif.push = 1;
          vif.pop = 1;
          @(posedge vif.clk);
          transaction.dato_out = vif.dato_out;
          vif.push = 0;
          vif.pop = 0;
          transaction.print("Driver: transaccion ejecutada");
        end
        
        // OPERACIÓN: RESET (Manual)
        reset: begin
          vif.rst = 1;         // Activa el reset
          @(posedge vif.clk);  // Mantiene el reset por un ciclo completo
          vif.rst = 0;         // Desactiva el reset
          transaction.print("Driver: Transaccion ejecutada");
        end
        
        default: begin
          $display("[%g] Driver Error: la transacción recibida no tiene tipo valido", $time);
          $finish;
        end 
      endcase    
      
      @(posedge vif.clk); // Pequeño espacio de seguridad antes de la siguiente instrucción
    end
  endtask
endclass
