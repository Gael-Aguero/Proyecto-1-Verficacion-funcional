//////////////////////////////////////////////////////////////////////////////////////////////////
// DEFINICIONES GLOBALES: Tipos, Clases de Transacción e Interface                              //
//////////////////////////////////////////////////////////////////////////////////////////////////

// --- Enumerado de Tipos de Transacción ---
typedef enum {
  lectura,           // Pop
  escritura,         // Push
  reset,             // Reinicio del DUT
  escritura_lectura  // Operación simultánea (Bypass/Corner case)
} tipo_trans; 

//////////////////////////////////////////////////////////////////////////////////////////////////
// Transacción FIFO
//////////////////////////////////////////////////////////////////////////////////////////////////
class trans_fifo #(parameter width = 16);
  rand int retardo;
  rand bit[width-1:0] dato;
  rand tipo_trans tipo;
  
  bit [width-1:0] dato_out;
  int tiempo;
  int max_retardo;
 
  constraint const_retardo { retardo < max_retardo; retardo > 0; }
  
  // AHORA INCLUIMOS escritura_lectura
  constraint tipo_valido {
    tipo inside {lectura, escritura, reset, escritura_lectura};
  }

  function new(int ret = 0, bit[width-1:0] dto = 0, int tmp = 0, tipo_trans tpo = lectura, int mx_rtrd = 10);
    this.retardo = ret;
    this.dato = dto;
    this.tiempo = tmp;
    this.tipo = tpo;
    this.max_retardo = mx_rtrd;
  endfunction
  
  function void clean;
    this.retardo = 0;
    this.dato = 0;
    this.tiempo = 0;
    this.tipo = lectura;
  endfunction
    
  function void print(string tag = "");
    $display("[%g] %s Tiempo=%g Tipo=%s Retardo=%g dato=0x%h dato_out=0x%h", 
             $time, tag, tiempo, this.tipo.name(), this.retardo, this.dato, this.dato_out);
  endfunction
endclass

//////////////////////////////////////////////////////////////////////////////////////////////////
// Interface FIFO
//////////////////////////////////////////////////////////////////////////////////////////////////
interface fifo_if #(parameter width = 16) (
  input clk
);
  logic rst;
  logic pndng;
  logic full;
  logic push;
  logic pop;
  logic [width-1:0] dato_in;
  logic [width-1:0] dato_out;
endinterface

//////////////////////////////////////////////////////////////////////////////////////////////////
// Transacción Scoreboard
//////////////////////////////////////////////////////////////////////////////////////////////////
class trans_sb #(parameter width = 16);
  bit [width-1:0] dato_enviado;
  int tiempo_push;
  int tiempo_pop;
  bit completado;
  bit overflow;
  bit underflow;
  bit reset;
  int latencia;
  
  function void clean();
    this.dato_enviado = 0;
    this.tiempo_push = 0;
    this.tiempo_pop = 0;
    this.completado = 0;
    this.overflow = 0;
    this.underflow = 0;
    this.reset = 0;
    this.latencia = 0;
  endfunction

  task calc_latencia;
    this.latencia = this.tiempo_pop - this.tiempo_push;
  endtask
  
  function void print (string tag);
    $display("[%g] %s dato=%h,t_push=%g,t_pop=%g,cmplt=%g,ovrflw=%g,undrflw=%g,rst=%g,ltncy=%g", 
             $time, tag, this.dato_enviado, this.tiempo_push, this.tiempo_pop, 
             this.completado, this.overflow, this.underflow, this.reset, this.latencia);
  endfunction
endclass

//////////////////////////////////////////////////////////////////////////////////////////////////
// DEFINICIÓN DE COMANDOS Y MAILBOXES
//////////////////////////////////////////////////////////////////////////////////////////////////

typedef enum {retardo_promedio, reporte} solicitud_sb;
typedef enum {llenado_aleatorio, trans_aleatoria, trans_especifica, sec_trans_aleatorias} instrucciones_agente;

typedef mailbox #(trans_fifo) trans_fifo_mbx;
typedef mailbox #(trans_sb) trans_sb_mbx;
typedef mailbox #(solicitud_sb) comando_test_sb_mbx;
typedef mailbox #(instrucciones_agente) comando_test_agent_mbx;