//////////////////////////////////////////////////////////////////////////////////////////////////
// Ambiente:                                                                                    //
// Este módulo actúa como el contenedor principal. Su función es instanciar todos los           //
// componentes de verificación (Driver, Monitor, Checker, etc.) y establecer los canales de     //
// comunicación (Mailboxes) entre ellos para que el Test pueda controlarlos.                    //
//////////////////////////////////////////////////////////////////////////////////////////////////

class ambiente #(parameter width = 16, parameter depth = 8);
  // --- Instancias de los componentes del modelo estándar ---
  driver #(.width(width)) driver_inst;           // Empuja datos al DUT
  monitor #(.width(width)) monitor_inst;         // Observa las salidas del DUT
  checker_c #(.width(width),.depth(depth)) checker_inst; // Valida la lógica
  score_board #(.width(width)) scoreboard_inst;  // Lleva estadísticas y reportes
  agent #(.width(width),.depth(depth)) agent_inst; // Genera las secuencias

  // --- Interfaz Virtual ---
  // Es el puente físico/lógico hacia las señales de la FIFO
  virtual fifo_if #(.width(width)) _if;

  // --- Declaración de los Mailboxes (Canales de comunicación) ---
  trans_fifo_mbx agnt_drv_mbx;           // Comunicación: Agente -> Driver
  trans_fifo_mbx mon_chkr_mbx;           // Comunicación: Monitor -> Checker
  trans_sb_mbx chkr_sb_mbx;              // Comunicación: Checker -> Scoreboard
  comando_test_sb_mbx test_sb_mbx;       // Comunicación: Test -> Scoreboard
  comando_test_agent_mbx test_agent_mbx; // Comunicación: Test -> Agente

  // --- Constructor: Creación y conexión inicial ---
  function new();
    // 1. Instanciación de los mailboxes internos
    mon_chkr_mbx   = new();
    agnt_drv_mbx   = new();
    chkr_sb_mbx    = new();

    // 2. Instanciación de cada componente del ambiente
    driver_inst     = new();
    monitor_inst    = new();
    checker_inst    = new();
    scoreboard_inst = new();
    agent_inst      = new();

    // 3. Conexión de Mailboxes entre componentes
    // Nota: Los mailboxes del Test se conectan en el 'run' o vía el constructor del Test
    monitor_inst.mon_chkr_mbx    = mon_chkr_mbx;
    driver_inst.agnt_drv_mbx     = agnt_drv_mbx;
    checker_inst.mon_chkr_mbx    = mon_chkr_mbx;
    checker_inst.chkr_sb_mbx     = chkr_sb_mbx;
    scoreboard_inst.chkr_sb_mbx  = chkr_sb_mbx;
    agent_inst.agnt_drv_mbx      = agnt_drv_mbx;
  endfunction

  // --- Tarea Run: Puesta en marcha del ambiente ---
  virtual task run();
    $display("[%g]  El ambiente fue inicializado", $time);

    // Conexión de la interfaz virtual a los componentes que tocan señales físicas
    driver_inst.vif = _if;
    monitor_inst.vif = _if;

    // Conexión de los mailboxes de control que vienen desde el Test
    scoreboard_inst.test_sb_mbx = test_sb_mbx;
    agent_inst.test_agent_mbx   = test_agent_mbx;

    // Ejecución en paralelo de todos los componentes
    // join_none permite que el test siga ejecutándose mientras los componentes corren
    fork
      driver_inst.run();
      monitor_inst.run();
      checker_inst.run();
      scoreboard_inst.run();
      agent_inst.run();
    join_none
  endtask 
endclass
