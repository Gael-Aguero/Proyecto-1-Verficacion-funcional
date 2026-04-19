//////////////////////////////////////////////////////////////////////////////////////////////////
// DEFINICIONES GLOBALES: Tipos, Clases de Transacción e Interface                              //
//////////////////////////////////////////////////////////////////////////////////////////////////

// --- Enumerado de Tipos de Transacción ---
// Define qué acciones puede realizar el ambiente sobre la FIFO.
typedef enum {
  lectura,           // Pop
  escritura,         // Push
  reset,             // Reinicio del DUT
  escritura_lectura  // Operación simultánea (Bypass/Corner case)
} tipo_trans; 

//////////////////////////////////////////////////////////////////////////////////////////////////
// Transacción:                                                                                 //
// Objeto que encapsula toda la información de un evento en la FIFO. Es lo que viaja            //
// desde el Agente hasta el Monitor.                                                            //
//////////////////////////////////////////////////////////////////////////////////////////////////
class trans_fifo #(parameter width = 16);
  // Variables aleatorias para generación de estímulos
  rand int retardo;           // Ciclos de espera antes de ejecutar la acción
  rand bit[width-1:0] dato;   // Dato que se desea escribir (input)
  rand tipo_trans tipo;       // Tipo de operación (lectura, escritura, etc.)
  
  bit [width-1:0] dato_out;   // Dato capturado a la salida de la FIFO
  int tiempo;                 // Marca de tiempo de la simulación
  int max_retardo;            // Límite superior para la aleatorización del retardo
 
  // Restricciones para que los valores generados sean realistas
  constraint const_retardo { retardo < max_retardo; retardo > 0; }

  // Constructor: Inicializa la transacción con valores base
  function new(int ret = 0, bit[width-1:0] dto = 0, int tmp = 0, tipo_trans tpo = lectura, int mx_rtrd = 10);
    this.retardo = ret;
    this.dato = dto;
    this.tiempo = tmp;
    this.tipo = tpo;
    this.max_retardo = mx_rtrd;
  endfunction
  
  // Limpia el objeto para ser reutilizado
  function clean;
    this.retardo = 0;
    this.dato = 0;
    this.tiempo = 0;
    this.tipo = lectura;
  endfunction
    
  // Imprime el estado actual de la transacción en la consola
  function void print(string tag = "");
    $display("[%g] %s Tiempo=%g Tipo=%s Retardo=%g dato=0x%h", $time, tag, tiempo, this.tipo, this.retardo, this.dato);
  endfunction
endclass

//////////////////////////////////////////////////////////////////////////////////////////////////
// Interface:                                                                                  //
// Es el bloque de conexión física que agrupa todas las señales que van hacia la FIFO.          //
//////////////////////////////////////////////////////////////////////////////////////////////////
interface fifo_if #(parameter width = 16) (
  input clk // El reloj es la única señal de entrada obligatoria
);
  logic rst;                  // Reset del sistema
  logic pndng;                // Indica que hay datos en la FIFO (No vacía)
  logic full;                 // Indica que la FIFO alcanzó su capacidad máxima
  logic push;                 // Habilitador de escritura
  logic pop;                  // Habilitador de lectura
  logic [width-1:0] dato_in;  // Bus de datos de entrada
  logic [width-1:0] dato_out; // Bus de datos de salida
endinterface

//////////////////////////////////////////////////////////////////////////////////////////////////
// Transacción Scoreboard (trans_sb):                                                           //
// Objeto especializado para el análisis de resultados y cálculo de latencias.                  //
//////////////////////////////////////////////////////////////////////////////////////////////////
class trans_sb #(parameter width = 16);
  bit [width-1:0] dato_enviado; // El dato que se esperaba ver
  int tiempo_push;              // Cuándo entró el dato
  int tiempo_pop;               // Cuándo salió el dato
  bit completado;               // Indica éxito en la comparación
  bit overflow;                 // Indica intento de escritura en FIFO llena
  bit underflow;                // Indica intento de lectura en FIFO vacía
  bit reset;                    // Indica si la transacción se perdió por un reset
  int latencia;                 // Tiempo transcurrido dentro de la FIFO
  
  function clean();
    this.dato_enviado = 0;
    this.tiempo_push = 0;
    this.tiempo_pop = 0;
    this.completado = 0;
    this.overflow = 0;
    this.underflow = 0;
    this.reset = 0;
    this.latencia = 0;
  endfunction

  // Calcula cuánto tiempo pasó el dato almacenado
  task calc_latencia;
    this.latencia = this.tiempo_pop - this.tiempo_push;
  endtask
  
  // Imprime el reporte detallado para el Scoreboard
  function print (string tag);
    $display("[%g] %s dato=%h,t_push=%g,t_pop=%g,cmplt=%g,ovrflw=%g,undrflw=%g,rst=%g,ltncy=%g", 
             $time, tag, this.dato_enviado, this.tiempo_push, this.tiempo_pop, 
             this.completado, this.overflow, this.underflow, this.reset, this.latencia);
  endfunction
endclass

//////////////////////////////////////////////////////////////////////////////////////////////////
// DEFINICIÓN DE COMANDOS Y MAILBOXES:                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////

// Comandos que el Test puede enviar al Scoreboard
typedef enum {retardo_promedio, reporte} solicitud_sb;

// Instrucciones que el Test puede enviar al Agente
typedef enum {llenado_aleatorio, trans_aleatoria, trans_especifica, sec_trans_aleatorias} instrucciones_agente;

// Definición de Mailboxes especializados para evitar errores de tipo (Type Safety)
typedef mailbox #(trans_fifo) trans_fifo_mbx;      // Para mover datos de FIFO
typedef mailbox #(trans_sb) trans_sb_mbx;          // Para mover reportes al SB
typedef mailbox #(solicitud_sb) comando_test_sb_mbx; // Para comandos de control SB
typedef mailbox #(instrucciones_agente) comando_test_agent_mbx; // Para comandos de control Agente
