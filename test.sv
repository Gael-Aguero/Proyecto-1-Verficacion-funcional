class test #(parameter width = 16, parameter depth = 8);
  
  int runtime_width = width;
  int runtime_depth = depth;
  
  comando_test_sb_mbx    test_sb_mbx;
  comando_test_agent_mbx test_agent_mbx;
  solicitud_sb instr_sb;
  instrucciones_agente instr_agente;
  
  ambiente #(.depth(depth),.width(width)) ambiente_inst;
  virtual fifo_if #(.width(width)) _if;

  // Configuración desde plusargs
  int cfg_semilla;
  int cfg_num_trans;
  int cfg_retardo_min, cfg_retardo_max;
  int cfg_peso_lectura, cfg_peso_escritura, cfg_peso_simultaneo, cfg_peso_reset;
  string cfg_patron;
  string cfg_estado_inicial;

  function new; 
    test_sb_mbx  = new();
    test_agent_mbx = new();
    ambiente_inst = new();
    ambiente_inst.test_sb_mbx = test_sb_mbx;
    ambiente_inst.test_agent_mbx = test_agent_mbx;
    ambiente_inst.scoreboard_inst.test_sb_mbx = test_sb_mbx;
    ambiente_inst.agent_inst.test_agent_mbx = test_agent_mbx;
    
    cfg_semilla = 1;
    cfg_num_trans = 200;
    cfg_retardo_min = 0;
    cfg_retardo_max = 10;
    cfg_peso_lectura = 30;
    cfg_peso_escritura = 30;
    cfg_peso_simultaneo = 20;
    cfg_peso_reset = 20;
    cfg_patron = "RANDOM";
    cfg_estado_inicial = "ALEATORIO";
  endfunction

  function void leer_plusargs();
    $value$plusargs("SEMILLA=%d", cfg_semilla);
    $value$plusargs("NUM_TRANS=%d", cfg_num_trans);
    $value$plusargs("RETARDO_MIN=%d", cfg_retardo_min);
    $value$plusargs("RETARDO_MAX=%d", cfg_retardo_max);
    $value$plusargs("PESO_L=%d", cfg_peso_lectura);
    $value$plusargs("PESO_E=%d", cfg_peso_escritura);
    $value$plusargs("PESO_S=%d", cfg_peso_simultaneo);
    $value$plusargs("PESO_R=%d", cfg_peso_reset);
    $value$plusargs("PATRON=%s", cfg_patron);
    $value$plusargs("ESTADO_INI=%s", cfg_estado_inicial);
  endfunction

  function void imprimir_configuracion();
    int total = cfg_peso_lectura + cfg_peso_escritura + cfg_peso_simultaneo + cfg_peso_reset;
    real pL, pE, pS, pR;
    
    pL = (total > 0) ? (cfg_peso_lectura * 100.0 / total) : 0;
    pE = (total > 0) ? (cfg_peso_escritura * 100.0 / total) : 0;
    pS = (total > 0) ? (cfg_peso_simultaneo * 100.0 / total) : 0;
    pR = (total > 0) ? (cfg_peso_reset * 100.0 / total) : 0;
    
    $display("╔════════════════════════════════════════════════════════╗");
    $display("║           CONFIGURACIÓN DEL TEST                      ║");
    $display("╠════════════════════════════════════════════════════════╣");
    $display("║ Dimensiones:                                          ║");
    $display("║   WIDTH           = %-4d bits                          ║", runtime_width);
    $display("║   DEPTH           = %-4d palabras                      ║", runtime_depth);
    $display("╠════════════════════════════════════════════════════════╣");
    $display("║ Estímulos:                                            ║");
    $display("║   SEMILLA         = %-8d                              ║", cfg_semilla);
    $display("║   NUM_TRANS       = %-4d                              ║", cfg_num_trans);
    $display("║   RETARDO         = [%0d : %0d]                        ║", cfg_retardo_min, cfg_retardo_max);
    $display("║   ESTADO INICIAL  = %-10s                             ║", cfg_estado_inicial);
    $display("║   PATRÓN DATOS    = %-10s                             ║", cfg_patron);
    $display("╠════════════════════════════════════════════════════════╣");
    $display("║ Pesos de Operación:                                   ║");
    $display("║   LECTURA         = %-4d  (%4.1f%%)                    ║", cfg_peso_lectura, pL);
    $display("║   ESCRITURA       = %-4d  (%4.1f%%)                    ║", cfg_peso_escritura, pE);
    $display("║   SIMULTÁNEO      = %-4d  (%4.1f%%)                    ║", cfg_peso_simultaneo, pS);
    $display("║   RESET           = %-4d  (%4.1f%%)                    ║", cfg_peso_reset, pR);
    $display("╚════════════════════════════════════════════════════════╝");
    $display("");
  endfunction

  task estado_inicial();
    trans_fifo #(.width(width)) t;
    int n;
    
    // Reset inicial
    t = new(); 
    t.tipo = reset; 
    t.retardo = 1;
    ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    #20;
    
    // Calcular elementos según estado
    case(cfg_estado_inicial)
      "LLENO": n = runtime_depth;
      "MITAD": n = runtime_depth / 2;
      "VACIO": n = 0;
      default: n = $urandom() % (runtime_depth + 1);
    endcase
    
    // Llenar FIFO
    for (int i = 0; i < n; i++) begin
      t = new(); 
      t.tipo = escritura; 
      t.dato = $urandom(); 
      t.retardo = 1;
      ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
      #2;
    end
    
    $display("[%g] Estado inicial: %s (%0d/%0d elementos)", $time, cfg_estado_inicial, n, runtime_depth);
    #50;
  endtask

  task run;
    // Conectar interfaz y leer configuración
    ambiente_inst._if = _if;
    leer_plusargs();
    $value$plusargs("WIDTH_ARG=%d", runtime_width);
    $value$plusargs("DEPTH_ARG=%d", runtime_depth);
    $srandom(cfg_semilla);
    
    // Mostrar configuración general
    imprimir_configuracion();
    
    // Lanzar ambiente
    fork ambiente_inst.run(); join_none
    #100;
    
    // Configurar agente
    ambiente_inst.agent_inst.num_transacciones = cfg_num_trans;
    ambiente_inst.agent_inst.max_retardo = cfg_retardo_max;
    ambiente_inst.agent_inst.patron_datos = cfg_patron;
    ambiente_inst.agent_inst.contador_patron = 0;
    ambiente_inst.agent_inst.peso_lectura = cfg_peso_lectura;
    ambiente_inst.agent_inst.peso_escritura = cfg_peso_escritura;
    ambiente_inst.agent_inst.peso_simultaneo = cfg_peso_simultaneo;
    ambiente_inst.agent_inst.peso_reset = cfg_peso_reset;
    
    // Establecer estado inicial
    estado_inicial();
    
    // Enviar instrucción al agente
    instr_agente = sec_trans_aleatorias;
    test_agent_mbx.put(instr_agente);
    
    // Esperar que se complete el tráfico
    #(cfg_num_trans * (cfg_retardo_max + 5) * 10);
    #200;
    
    // Solicitar reportes
    $display("\n[%g] ========== REPORTES FINALES ==========", $time);
    instr_sb = retardo_promedio; test_sb_mbx.put(instr_sb); #50;
    instr_sb = reporte; test_sb_mbx.put(instr_sb); #100;
    $display("[%g] ========== FIN ==========\n", $time);
    $finish;
  endtask
  
endclass