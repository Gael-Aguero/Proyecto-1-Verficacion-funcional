class score_board #(parameter width=16);
  // --- Canales de comunicación ---
  trans_sb_mbx  chkr_sb_mbx;
  comando_test_sb_mbx test_sb_mbx;

  // --- Estructuras de datos - ESPECIFICAR PARÁMETRO ---
  trans_sb #(.width(width)) transaccion_entrante;
  trans_sb #(.width(width)) scoreboard[$];      // Base de datos histórica
  trans_sb #(.width(width)) auxiliar_array[$];  // Cola auxiliar
  trans_sb #(.width(width)) auxiliar_trans;     // Puntero para manejo de objetos
  
  // --- Variables de métricas ---
  shortreal retardo_promedio;
  solicitud_sb orden;
  int tamano_sb = 0;
  int transacciones_completadas = 0;
  int retardo_total = 0;
  
  // --- Tarea Principal: Análisis y Reportes ---
  task run;
    $display("[%g] El Score Board fue inicializado", $time);
    
    forever begin
      #5;
      
      // 1. PROCESAMIENTO DE DATOS (Viene del Checker)
      if(chkr_sb_mbx.num() > 0) begin
        trans_sb #(.width(width)) temp_sb;  // Variable temporal del tipo correcto
        chkr_sb_mbx.get(temp_sb);
        transaccion_entrante = temp_sb;
        
        transaccion_entrante.print("Score Board: transacción recibida desde el checker");
        
        if(transaccion_entrante.completado) begin
          retardo_total = retardo_total + transaccion_entrante.latencia;
          transacciones_completadas++;
        end
        
        // Guardar en historial
        scoreboard.push_back(transaccion_entrante);
      end
      
      // 2. PROCESAMIENTO DE ÓRDENES (Viene del Test)
      if(test_sb_mbx.num() > 0) begin
        test_sb_mbx.get(orden);
        
        case(orden)
          retardo_promedio: begin
            $display("Score Board: Recibida Orden Retardo_Promedio");
            
            if (transacciones_completadas > 0)
              retardo_promedio = $itor(retardo_total) / transacciones_completadas;
            else
              retardo_promedio = 0;
              
            $display("[%g] Score board: el retardo promedio es: %0.3f", $time, retardo_promedio);
          end

          reporte: begin
            $display("Score Board: Recibida Orden Reporte");
            tamano_sb = scoreboard.size();

            for(int i = 0; i < tamano_sb; i++) begin
              scoreboard[i].print("SB_Report:");
            end
          end
        endcase
      end
    end
  endtask
  
endclass