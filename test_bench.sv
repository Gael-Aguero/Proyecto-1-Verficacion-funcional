//////////////////////////////////////////////////////////////////////////////////////////////////
// Test Bench (Top Level):                                                                      //
// Este es el nivel más alto de la jerarquía. Instancia el hardware (DUT), la interfaz y        //
// el objeto de prueba (Test), además de generar la señal de reloj global.                      //
//////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

// ==========================================================
// DEFINICIÓN DE PARÁMETROS DESDE LÍNEA DE COMANDOS
// ==========================================================
// Estos valores pueden ser sobreescritos durante la compilación
// usando +define+WIDTH=<valor> +define+DEPTH=<valor>
`ifndef WIDTH
  `define WIDTH 16
`endif

`ifndef DEPTH
  `define DEPTH 8
`endif

// Inclusión de todos los archivos necesarios para el ambiente de verificación
`include "fifo.sv"
`include "interface_transactions.sv"
`include "driver.sv"
`include "monitor.sv"
`include "checker.sv"
`include "score_board.sv"
`include "agent.sv"
`include "ambiente.sv"
`include "test.sv"

module test_bench; 
  // --- Señales de control y parámetros ---
  reg clk;
  parameter width = `WIDTH;
  parameter depth = `DEPTH;
  
  // Instancia de la clase de prueba (el cerebro de la verificación)
  test #(.depth(depth),.width(width)) t0;

  // --- Instancia de la Interfaz ---
  // Conecta el banco de pruebas con las señales físicas del módulo
  fifo_if #(.width(width)) _if(.clk(clk));

  // Generación del Reloj: Período de 10ns (frecuencia de 100MHz)
  always #5 clk = ~clk;

  // --- Instancia de la Unidad Bajo Prueba (UUT / DUT) ---
  // Se conecta la FIFO genérica a las señales de la interfaz
  fifo_generic #(.Depth(depth),.DataWidth(width)) uut (
    .writeData(_if.dato_in),
    .readData (_if.dato_out),
    .writeEn  (_if.push),
    .readEn   (_if.pop),
    .clk      (_if.clk),
    .full     (_if.full),
    .pndng    (_if.pndng),
    .rst      (_if.rst)
  );

  // --- Bloque Inicial: Arranque de la simulación ---
  initial begin
    clk = 0;
    
    // Mostrar configuración actual
    $display("========================================");
    $display("  CONFIGURACIÓN DEL TESTBENCH");
    $display("========================================");
    $display("  WIDTH = %0d bits", width);
    $display("  DEPTH = %0d palabras", depth);
    $display("========================================");
    
    // 1. Creación del objeto de prueba
    t0 = new();
    
    // 2. Conexión de interfaces (Puntos de control críticos)
    // Se asigna la interfaz física a los punteros virtuales del ambiente
    t0._if = _if;
    t0.ambiente_inst._if = _if; 
    t0.ambiente_inst.driver_inst.vif = _if;
    t0.ambiente_inst.monitor_inst.vif = _if;
    
    // 3. Ejecución de la prueba
    // fork/join_none lanza el proceso y permite que el simulador siga activo
    fork
      t0.run();
    join_none
  end
 
  // --- Watchdog (Perro guardián) ---
  // Monitorea el tiempo de simulación para evitar que el proceso se quede 
  // pegado en un bucle infinito si algo falla en el hardware.
  always@(posedge clk) begin
    if ($time > 100000) begin
      $display("Test_bench: Tiempo límite de prueba en el test_bench alcanzado");
      $finish;
    end
  end

endmodule