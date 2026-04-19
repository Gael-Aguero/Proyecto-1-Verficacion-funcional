//////////////////////////////////////////////////////////////////////////////////////////////////
// FIFO GENÉRICA:                                                                               //
// Este es el DUT (Device Under Test). Es una memoria de tipo First-In, First-Out síncrona      //
// con soporte para operaciones simultáneas (Bypass) y parámetros configurables.                //
//////////////////////////////////////////////////////////////////////////////////////////////////

module fifo_generic #(
    parameter DataWidth = 16, // Ancho de la palabra de datos
    parameter Depth     = 8   // Capacidad máxima de la FIFO
)(
    input  logic [DataWidth-1:0] writeData, // Bus de entrada de datos
    output logic [DataWidth-1:0] readData,  // Bus de salida de datos
    input  logic                 writeEn,   // Habilitador de escritura (Push)
    input  logic                 readEn,    // Habilitador de lectura (Pop)
    input  logic                 clk,       // Señal de reloj global
    input  logic                 rst,       // Reset asíncrono activo en alto
    output logic                 full,      // Bandera de FIFO llena
    output logic                 pndng      // Bandera de dato pendiente (No vacía)
);

    // --- Memoria Interna y Punteros ---
    logic [DataWidth-1:0] mem [Depth-1:0]; // Matriz de memoria (Registros)
    logic [$clog2(Depth):0] wr_ptr;        // Puntero de escritura
    logic [$clog2(Depth):0] rd_ptr;        // Puntero de lectura
    logic [$clog2(Depth):0] count;         // Contador de elementos presentes en la FIFO

    // --- Lógica de Salida (Lectura Combinacional) ---
    // Implementa el modo "First-Word Fall Through" o Bypass:
    // 1. Si hay datos (count > 0), muestra lo que apunta rd_ptr.
    // 2. Si está vacía pero se está escribiendo (Bypass), el dato pasa directo de entrada a salida.
    // 3. Si no hay nada, la salida es cero.
    assign readData = (count > 0) ? mem[rd_ptr] : (writeEn ? writeData : '0);

    // --- Lógica Secuencial (Control de Punteros y Memoria) ---
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset de todos los registros internos
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
            for (int i = 0; i < Depth; i++) mem[i] <= '0;
        end else begin
            
            // 1. Lógica de Escritura
            // Si se solicita escribir y la FIFO no está llena, guarda el dato y avanza el puntero.
            if (writeEn && !full) begin
                mem[wr_ptr] <= writeData;
                wr_ptr <= (wr_ptr == Depth-1) ? 0 : wr_ptr + 1;
            end

            // 2. Lógica de Lectura
            // Se avanza el puntero si se pide lectura Y (hay datos O se está haciendo bypass).
            if (readEn && (count > 0 || writeEn)) begin
                rd_ptr <= (rd_ptr == Depth-1) ? 0 : rd_ptr + 1;
            end

            // 3. Gestión del Contador de Ocupación
            // Determina si el número de elementos sube, baja o se mantiene.
            case ({ (writeEn && !full), (readEn && (count > 0 || writeEn)) })
                2'b10: count <= count + 1;             // Solo escritura: aumenta
                2'b01: count <= (count > 0) ? count - 1 : 0; // Solo lectura: disminuye
                default: count <= count;               // 00 (nada) o 11 (E/L simultánea): se mantiene
            endcase
        end
    end

    // --- Banderas de Estado ---
    assign full  = (count == Depth);           // Llena cuando el contador alcanza el límite
    assign pndng = (count > 0) || writeEn;    // Hay datos pendientes si hay contenido o un bypass

endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////
// Módulos Auxiliares (Legacy):                                                                 //
// Estos bloques se mantienen por compatibilidad estructural con diseños previos.               //
//////////////////////////////////////////////////////////////////////////////////////////////////

// Flip-Flop tipo D con reset asíncrono
module dff_async_rst (input data, clk, reset, output reg q);
    always @ (posedge clk or posedge reset) 
        if (reset) q <= 0; 
        else q <= data;
endmodule

// Registro paralelo de N bits construido a partir de dff_async_rst
module prll_d_reg #(parameter bits = 32)(
    input clk, 
    input reset, 
    input [bits-1:0] D_in, 
    output [bits-1:0] D_out
);
    genvar i; 
    generate 
        for(i = 0; i < bits; i=i+1) begin:bit_ 
            dff_async_rst ff(.data(D_in[i]), .clk(clk), .reset(reset), .q(D_out[i])); 
        end 
    endgenerate
endmodule
