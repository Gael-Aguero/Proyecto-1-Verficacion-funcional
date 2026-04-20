//////////////////////////////////////////////////////////////////////////////////////////////////
// Scoreboard:                                                                                  //
// Es el centro de análisis y reportes. Recibe los resultados del Checker y genera              //
// estadísticas de rendimiento (latencia) y estado de las transacciones (completadas,            //
// errores, overflow/underflow).                                                                //
//////////////////////////////////////////////////////////////////////////////////////////////////

class score_board #(parameter width=16);
  // --- Canales de comunicación ---
  trans_sb_mbx  chkr_sb_mbx;         // Entrada: Reportes detallados desde el Checker
  comando_test_sb_mbx test_sb_mbx;   // Entrada: Órdenes de control desde el Test

  // --- Estructuras de datos ---
  trans_sb #(.width(width)) transaccion_entrante; 
  trans_sb scoreboard[$];            // Base de datos histórica de todas las transacciones
  trans_sb auxiliar_array[$];        // Cola auxiliar para procesamiento
  trans_sb auxiliar_trans;           // Puntero para manejo de objetos
  
  // --- Variables de métricas ---
  shortreal retardo_promedio;        // Latencia promedio (usamos shortreal para decimales)
  solicitud_sb orden;                // Instrucción actual recibida del Test
  int tamano_sb = 0;                 // Contador total de eventos registrados
  int transacciones_completadas = 0; // Contador de éxitos (Lectura correcta de dato)
  int retardo_total = 0;             // Acumulado de tiempo para el cálculo del promedio
  
  // --- Tarea Principal: Análisis y Reportes ---
  task run;
    $display("[%g] El Score Board fue inicializado", $time);
    
    forever begin
      // Pequeño retardo para evitar ciclos infinitos de consumo de CPU
      #5
      
      // 1. PROCESAMIENTO DE DATOS (Viene del Checker)
      if(chkr_sb_mbx.num() > 0) begin
        chkr_sb_mbx.get(transaccion_entrante);
        transaccion_entrante.print("Score Board: transacción recibida desde el checker");
        
        // Si la transacción fue exitosa (el dato coincidió), acumulamos para métricas
        if(transaccion_entrante.completado) begin
          retardo_total = retardo_total + transaccion_entrante.latencia;
          transacciones_completadas++;
        end
        
        // Guardamos todo en el historial para el reporte final
        scoreboard.push_back(transaccion_entrante);
      end
      
      // 2. PROCESAMIENTO DE ÓRDENES (Viene del Test)
      if(test_sb_mbx.num() > 0) begin
        test_sb_mbx.get(orden);
        
        case(orden)
          // Cálculo de latencia promedio de la FIFO
          retardo_promedio: begin
            $display("Score Board: Recibida Orden Retardo_Promedio");
            
            // Protección contra división por cero y uso de $itor para precisión decimal
            if (transacciones_completadas > 0)
              retardo_promedio = $itor(retardo_total) / transacciones_completadas;
            else
              retardo_promedio = 0;
              
            $display("[%g] Score board: el retardo promedio es: %0.3f", $time, retardo_promedio);
          end

          // Impresión masiva de todas las transacciones procesadas
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


