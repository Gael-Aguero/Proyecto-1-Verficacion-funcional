class test #(parameter width = 16, parameter depth = 8);
  
  int runtime_width = width;
  int runtime_depth = depth;
  
  comando_test_sb_mbx    test_sb_mbx;
  comando_test_agent_mbx test_agent_mbx;
  solicitud_sb instr_sb;
  
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
    
    // Defaults
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

  function bit [width-1:0] gen_dato(int i);
    case(cfg_patron)
      "CERO":   return 0;
      "UNO":    return {width{1'b1}};
      "AA":     return {width/2{2'b10}};
      "55":     return {width/2{2'b01}};
      "SEC":    return i;
      default:  return $urandom();
    endcase
  endfunction

  function tipo_trans tipo_aleatorio();
    int total = cfg_peso_lectura + cfg_peso_escritura + cfg_peso_simultaneo + cfg_peso_reset;
    int r = (total > 0) ? ($urandom() % total) : 0;
    if (r < cfg_peso_lectura) return lectura;
    if (r < cfg_peso_lectura + cfg_peso_escritura) return escritura;
    if (r < cfg_peso_lectura + cfg_peso_escritura + cfg_peso_simultaneo) return escritura_lectura;
    return reset;
  endfunction

  task estado_inicial();
    trans_fifo #(.width(width)) t;
    int n;
    
    t = new(); t.tipo = reset; t.retardo = 1;
    ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
    #20;
    
    case(cfg_estado_inicial)
      "LLENO": n = runtime_depth;
      "MITAD": n = runtime_depth / 2;
      "VACIO": n = 0;
      default: n = $urandom() % (runtime_depth + 1);
    endcase
    
    for (int i = 0; i < n; i++) begin
      t = new(); t.tipo = escritura; t.dato = $urandom(); t.retardo = 0;
      ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
      #2;
    end
    $display("[%g] Estado inicial: %s (%0d/%0d elementos)", $time, cfg_estado_inicial, n, runtime_depth);
    #50;
  endtask

  task run;
    ambiente_inst._if = _if;
    leer_plusargs();
    $value$plusargs("WIDTH_ARG=%d", runtime_width);
    $value$plusargs("DEPTH_ARG=%d", runtime_depth);
    
    $srandom(cfg_semilla);
    
    // Imprimir la configuración completa
    imprimir_configuracion();
    
    fork ambiente_inst.run(); join_none
    #50;
    
    estado_inicial();
    
    for (int i = 0; i < cfg_num_trans; i++) begin
      trans_fifo #(.width(width)) t = new();
      
      t.tipo = tipo_aleatorio();
      t.retardo = cfg_retardo_min + ($urandom() % (cfg_retardo_max - cfg_retardo_min + 1));
      t.dato = gen_dato(i);
      
      ambiente_inst.agent_inst.agnt_drv_mbx.put(t);
      #($urandom() % 5 + 1);
    end
    
    #500;
    $display("\n[%g] ========== REPORTES FINALES ==========", $time);
    instr_sb = retardo_promedio; test_sb_mbx.put(instr_sb); #10;
    instr_sb = reporte; test_sb_mbx.put(instr_sb); #50;
    $display("[%g] ========== FIN ==========\n", $time);
    $finish;
  endtask
endclass