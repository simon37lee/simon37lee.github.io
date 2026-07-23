// Shared self-checking testbench body for both AXI4 async bridge versions.
// The including file must `define DUT_MODULE to the bridge module name
// before `including this. Not synthesizable -- simulation only.
`include "axi4_defs.vh"

`ifndef DUT_MODULE
  `define DUT_MODULE axi4_async_bridge_fifo
`endif

module tb_top;

  localparam DATA_WIDTH   = 64;
  localparam ADDR_WIDTH   = 32;
  localparam ID_WIDTH     = 4;
  localparam AWUSER_WIDTH = 1;
  localparam WUSER_WIDTH  = 1;
  localparam BUSER_WIDTH  = 1;
  localparam ARUSER_WIDTH = 1;
  localparam RUSER_WIDTH  = 1;
  localparam FIFO_DEPTH   = 16;
  localparam MEM_WORDS    = 4096;
  localparam NUM_TXNS     = 60;

  localparam S_CLK_PERIOD = 10;  // 100 MHz
  localparam M_CLK_PERIOD = 7;   // ~142.9 MHz, deliberately non-harmonic with S_CLK_PERIOD

  `include "axi4_clog2.vh"
  localparam DATA_SIZE = axi4_clog2(DATA_WIDTH/8);

  // ---------------------------------------------------------------------
  // Clocks / resets
  // ---------------------------------------------------------------------
  reg s_axi_aclk = 1'b0;
  reg m_axi_aclk = 1'b0;
  reg s_axi_aresetn = 1'b0;
  reg m_axi_aresetn = 1'b0;

  always #(S_CLK_PERIOD/2) s_axi_aclk = ~s_axi_aclk;
  always #(M_CLK_PERIOD/2) m_axi_aclk = ~m_axi_aclk;

  // ---------------------------------------------------------------------
  // s_axi_* (master / DUT slave-facing side) driven by this testbench
  // ---------------------------------------------------------------------
  reg  [ID_WIDTH-1:0]      s_axi_awid;
  reg  [ADDR_WIDTH-1:0]    s_axi_awaddr;
  reg  [7:0]               s_axi_awlen;
  reg  [2:0]               s_axi_awsize;
  reg  [1:0]               s_axi_awburst;
  reg                      s_axi_awlock;
  reg  [3:0]               s_axi_awcache;
  reg  [2:0]               s_axi_awprot;
  reg  [3:0]               s_axi_awqos;
  reg  [AWUSER_WIDTH-1:0]  s_axi_awuser;
  reg                      s_axi_awvalid;
  wire                     s_axi_awready;

  reg  [DATA_WIDTH-1:0]    s_axi_wdata;
  reg  [DATA_WIDTH/8-1:0]  s_axi_wstrb;
  reg                      s_axi_wlast;
  reg  [WUSER_WIDTH-1:0]   s_axi_wuser;
  reg                      s_axi_wvalid;
  wire                     s_axi_wready;

  wire [ID_WIDTH-1:0]      s_axi_bid;
  wire [1:0]               s_axi_bresp;
  wire [BUSER_WIDTH-1:0]   s_axi_buser;
  wire                     s_axi_bvalid;
  reg                      s_axi_bready;

  reg  [ID_WIDTH-1:0]      s_axi_arid;
  reg  [ADDR_WIDTH-1:0]    s_axi_araddr;
  reg  [7:0]               s_axi_arlen;
  reg  [2:0]               s_axi_arsize;
  reg  [1:0]               s_axi_arburst;
  reg                      s_axi_arlock;
  reg  [3:0]               s_axi_arcache;
  reg  [2:0]               s_axi_arprot;
  reg  [3:0]               s_axi_arqos;
  reg  [ARUSER_WIDTH-1:0]  s_axi_aruser;
  reg                      s_axi_arvalid;
  wire                     s_axi_arready;

  wire [ID_WIDTH-1:0]      s_axi_rid;
  wire [DATA_WIDTH-1:0]    s_axi_rdata;
  wire [1:0]               s_axi_rresp;
  wire                     s_axi_rlast;
  wire [RUSER_WIDTH-1:0]   s_axi_ruser;
  wire                     s_axi_rvalid;
  reg                      s_axi_rready;

  // ---------------------------------------------------------------------
  // m_axi_* (DUT master-facing side / slave BFM) -- all wires
  // ---------------------------------------------------------------------
  wire [ID_WIDTH-1:0]      m_axi_awid;
  wire [ADDR_WIDTH-1:0]    m_axi_awaddr;
  wire [7:0]               m_axi_awlen;
  wire [2:0]               m_axi_awsize;
  wire [1:0]               m_axi_awburst;
  wire                     m_axi_awlock;
  wire [3:0]               m_axi_awcache;
  wire [2:0]               m_axi_awprot;
  wire [3:0]               m_axi_awqos;
  wire [AWUSER_WIDTH-1:0]  m_axi_awuser;
  wire                     m_axi_awvalid;
  wire                     m_axi_awready;

  wire [DATA_WIDTH-1:0]    m_axi_wdata;
  wire [DATA_WIDTH/8-1:0]  m_axi_wstrb;
  wire                     m_axi_wlast;
  wire [WUSER_WIDTH-1:0]   m_axi_wuser;
  wire                     m_axi_wvalid;
  wire                     m_axi_wready;

  wire [ID_WIDTH-1:0]      m_axi_bid;
  wire [1:0]               m_axi_bresp;
  wire [BUSER_WIDTH-1:0]   m_axi_buser;
  wire                     m_axi_bvalid;
  wire                     m_axi_bready;

  wire [ID_WIDTH-1:0]      m_axi_arid;
  wire [ADDR_WIDTH-1:0]    m_axi_araddr;
  wire [7:0]               m_axi_arlen;
  wire [2:0]               m_axi_arsize;
  wire [1:0]               m_axi_arburst;
  wire                     m_axi_arlock;
  wire [3:0]               m_axi_arcache;
  wire [2:0]               m_axi_arprot;
  wire [3:0]               m_axi_arqos;
  wire [ARUSER_WIDTH-1:0]  m_axi_aruser;
  wire                     m_axi_arvalid;
  wire                     m_axi_arready;

  wire [ID_WIDTH-1:0]      m_axi_rid;
  wire [DATA_WIDTH-1:0]    m_axi_rdata;
  wire [1:0]               m_axi_rresp;
  wire                     m_axi_rlast;
  wire [RUSER_WIDTH-1:0]   m_axi_ruser;
  wire                     m_axi_rvalid;
  wire                     m_axi_rready;

  // ---------------------------------------------------------------------
  // DUT
  // ---------------------------------------------------------------------
  `DUT_MODULE #(
    .DATA_WIDTH   (DATA_WIDTH),
    .ADDR_WIDTH   (ADDR_WIDTH),
    .ID_WIDTH     (ID_WIDTH),
    .AWUSER_WIDTH (AWUSER_WIDTH),
    .WUSER_WIDTH  (WUSER_WIDTH),
    .BUSER_WIDTH  (BUSER_WIDTH),
    .ARUSER_WIDTH (ARUSER_WIDTH),
    .RUSER_WIDTH  (RUSER_WIDTH),
    .FIFO_DEPTH   (FIFO_DEPTH)
  ) u_dut (
    .s_axi_aclk    (s_axi_aclk),
    .s_axi_aresetn (s_axi_aresetn),
    .s_axi_awid    (s_axi_awid),    .s_axi_awaddr (s_axi_awaddr),  .s_axi_awlen (s_axi_awlen),
    .s_axi_awsize  (s_axi_awsize),  .s_axi_awburst(s_axi_awburst), .s_axi_awlock(s_axi_awlock),
    .s_axi_awcache (s_axi_awcache), .s_axi_awprot (s_axi_awprot),  .s_axi_awqos (s_axi_awqos),
    .s_axi_awuser  (s_axi_awuser),  .s_axi_awvalid(s_axi_awvalid), .s_axi_awready(s_axi_awready),
    .s_axi_wdata   (s_axi_wdata),   .s_axi_wstrb  (s_axi_wstrb),   .s_axi_wlast (s_axi_wlast),
    .s_axi_wuser   (s_axi_wuser),   .s_axi_wvalid (s_axi_wvalid),  .s_axi_wready(s_axi_wready),
    .s_axi_bid     (s_axi_bid),     .s_axi_bresp  (s_axi_bresp),   .s_axi_buser (s_axi_buser),
    .s_axi_bvalid  (s_axi_bvalid),  .s_axi_bready (s_axi_bready),
    .s_axi_arid    (s_axi_arid),    .s_axi_araddr (s_axi_araddr),  .s_axi_arlen (s_axi_arlen),
    .s_axi_arsize  (s_axi_arsize),  .s_axi_arburst(s_axi_arburst), .s_axi_arlock(s_axi_arlock),
    .s_axi_arcache (s_axi_arcache), .s_axi_arprot (s_axi_arprot),  .s_axi_arqos (s_axi_arqos),
    .s_axi_aruser  (s_axi_aruser),  .s_axi_arvalid(s_axi_arvalid), .s_axi_arready(s_axi_arready),
    .s_axi_rid     (s_axi_rid),     .s_axi_rdata  (s_axi_rdata),   .s_axi_rresp (s_axi_rresp),
    .s_axi_rlast   (s_axi_rlast),   .s_axi_ruser  (s_axi_ruser),   .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready  (s_axi_rready),

    .m_axi_aclk    (m_axi_aclk),
    .m_axi_aresetn (m_axi_aresetn),
    .m_axi_awid    (m_axi_awid),    .m_axi_awaddr (m_axi_awaddr),  .m_axi_awlen (m_axi_awlen),
    .m_axi_awsize  (m_axi_awsize),  .m_axi_awburst(m_axi_awburst), .m_axi_awlock(m_axi_awlock),
    .m_axi_awcache (m_axi_awcache), .m_axi_awprot (m_axi_awprot),  .m_axi_awqos (m_axi_awqos),
    .m_axi_awuser  (m_axi_awuser),  .m_axi_awvalid(m_axi_awvalid), .m_axi_awready(m_axi_awready),
    .m_axi_wdata   (m_axi_wdata),   .m_axi_wstrb  (m_axi_wstrb),   .m_axi_wlast (m_axi_wlast),
    .m_axi_wuser   (m_axi_wuser),   .m_axi_wvalid (m_axi_wvalid),  .m_axi_wready(m_axi_wready),
    .m_axi_bid     (m_axi_bid),     .m_axi_bresp  (m_axi_bresp),   .m_axi_buser (m_axi_buser),
    .m_axi_bvalid  (m_axi_bvalid),  .m_axi_bready (m_axi_bready),
    .m_axi_arid    (m_axi_arid),    .m_axi_araddr (m_axi_araddr),  .m_axi_arlen (m_axi_arlen),
    .m_axi_arsize  (m_axi_arsize),  .m_axi_arburst(m_axi_arburst), .m_axi_arlock(m_axi_arlock),
    .m_axi_arcache (m_axi_arcache), .m_axi_arprot (m_axi_arprot),  .m_axi_arqos (m_axi_arqos),
    .m_axi_aruser  (m_axi_aruser),  .m_axi_arvalid(m_axi_arvalid), .m_axi_arready(m_axi_arready),
    .m_axi_rid     (m_axi_rid),     .m_axi_rdata  (m_axi_rdata),   .m_axi_rresp (m_axi_rresp),
    .m_axi_rlast   (m_axi_rlast),   .m_axi_ruser  (m_axi_ruser),   .m_axi_rvalid(m_axi_rvalid),
    .m_axi_rready  (m_axi_rready)
  );

  // ---------------------------------------------------------------------
  // Memory-model slave BFM on the master-facing (m_axi_*) side
  // ---------------------------------------------------------------------
  axi4_bfm_slave #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH),
    .ID_WIDTH   (ID_WIDTH),
    .MEM_WORDS  (MEM_WORDS),
    .STALL_PCT  (25)
  ) u_slave (
    .aclk    (m_axi_aclk),
    .aresetn (m_axi_aresetn),
    .awid    (m_axi_awid),   .awaddr(m_axi_awaddr), .awlen(m_axi_awlen), .awsize(m_axi_awsize),
    .awburst (m_axi_awburst),.awvalid(m_axi_awvalid),.awready(m_axi_awready),
    .wdata   (m_axi_wdata),  .wstrb (m_axi_wstrb),   .wlast (m_axi_wlast), .wvalid(m_axi_wvalid), .wready(m_axi_wready),
    .bid     (m_axi_bid),    .bresp (m_axi_bresp),   .bvalid(m_axi_bvalid),.bready(m_axi_bready),
    .arid    (m_axi_arid),   .araddr(m_axi_araddr),  .arlen (m_axi_arlen), .arsize(m_axi_arsize),
    .arburst (m_axi_arburst),.arvalid(m_axi_arvalid),.arready(m_axi_arready),
    .rid     (m_axi_rid),    .rdata (m_axi_rdata),   .rresp (m_axi_rresp), .rlast (m_axi_rlast),
    .rvalid  (m_axi_rvalid), .rready(m_axi_rready)
  );

  assign m_axi_buser = {BUSER_WIDTH{1'b0}};
  assign m_axi_ruser = {RUSER_WIDTH{1'b0}};

  // ---------------------------------------------------------------------
  // Scoreboard state
  // ---------------------------------------------------------------------
  reg [DATA_WIDTH-1:0] wr_data_buf [0:255];
  reg [DATA_WIDTH-1:0] rd_data_buf [0:255];
  integer errors;
  integer transactions;

  // ---------------------------------------------------------------------
  // Master driver tasks (run in the s_axi_aclk domain)
  // ---------------------------------------------------------------------
  task automatic axi_write_burst;
    input [ID_WIDTH-1:0]   id;
    input [ADDR_WIDTH-1:0] addr;
    input [7:0]             len;
    input [2:0]             size;
    input [1:0]             burst;
    integer beat;
    begin
      @(posedge s_axi_aclk);
      s_axi_awid    <= id;
      s_axi_awaddr  <= addr;
      s_axi_awlen   <= len;
      s_axi_awsize  <= size;
      s_axi_awburst <= burst;
      s_axi_awlock  <= 1'b0;
      s_axi_awcache <= 4'b0000;
      s_axi_awprot  <= 3'b000;
      s_axi_awqos   <= 4'b0000;
      s_axi_awuser  <= {AWUSER_WIDTH{1'b0}};
      s_axi_awvalid <= 1'b1;
      @(posedge s_axi_aclk);
      while (!s_axi_awready) @(posedge s_axi_aclk);
      s_axi_awvalid <= 1'b0;

      beat = 0;
      while (beat <= len) begin
        s_axi_wdata  <= wr_data_buf[beat];
        s_axi_wstrb  <= {(DATA_WIDTH/8){1'b1}};
        s_axi_wlast  <= (beat == len);
        s_axi_wuser  <= {WUSER_WIDTH{1'b0}};
        s_axi_wvalid <= 1'b1;
        @(posedge s_axi_aclk);
        while (!s_axi_wready) @(posedge s_axi_aclk);
        beat = beat + 1;
      end
      s_axi_wvalid <= 1'b0;

      s_axi_bready <= 1'b1;
      @(posedge s_axi_aclk);
      while (!s_axi_bvalid) @(posedge s_axi_aclk);
      if (s_axi_bid !== id) begin
        errors = errors + 1;
        $display("ERROR: B id mismatch exp=%0d got=%0d", id, s_axi_bid);
      end
      if (s_axi_bresp !== `AXI4_RESP_OKAY) begin
        errors = errors + 1;
        $display("ERROR: B resp not OKAY, got=%0d", s_axi_bresp);
      end
      s_axi_bready <= 1'b0;
    end
  endtask

  task automatic axi_read_burst;
    input [ID_WIDTH-1:0]   id;
    input [ADDR_WIDTH-1:0] addr;
    input [7:0]             len;
    input [2:0]             size;
    input [1:0]             burst;
    integer beat;
    begin
      @(posedge s_axi_aclk);
      s_axi_arid    <= id;
      s_axi_araddr  <= addr;
      s_axi_arlen   <= len;
      s_axi_arsize  <= size;
      s_axi_arburst <= burst;
      s_axi_arlock  <= 1'b0;
      s_axi_arcache <= 4'b0000;
      s_axi_arprot  <= 3'b000;
      s_axi_arqos   <= 4'b0000;
      s_axi_aruser  <= {ARUSER_WIDTH{1'b0}};
      s_axi_arvalid <= 1'b1;
      @(posedge s_axi_aclk);
      while (!s_axi_arready) @(posedge s_axi_aclk);
      s_axi_arvalid <= 1'b0;

      beat = 0;
      s_axi_rready <= 1'b1;
      while (beat <= len) begin
        @(posedge s_axi_aclk);
        if (s_axi_rvalid) begin
          if (s_axi_rid !== id) begin
            errors = errors + 1;
            $display("ERROR: R id mismatch exp=%0d got=%0d", id, s_axi_rid);
          end
          if (s_axi_rresp !== `AXI4_RESP_OKAY) begin
            errors = errors + 1;
            $display("ERROR: R resp not OKAY, got=%0d", s_axi_rresp);
          end
          if ((beat == len) && !s_axi_rlast) begin
            errors = errors + 1;
            $display("ERROR: RLAST not asserted on final beat (txn id=%0d)", id);
          end
          if ((beat != len) && s_axi_rlast) begin
            errors = errors + 1;
            $display("ERROR: RLAST asserted early (txn id=%0d beat=%0d)", id, beat);
          end
          rd_data_buf[beat] = s_axi_rdata;
          beat = beat + 1;
        end
      end
      s_axi_rready <= 1'b0;
    end
  endtask

  task automatic pick_burst_cfg;
    output [7:0]            len;
    output [1:0]             burst;
    output [ADDR_WIDTH-1:0] addr;
    integer len_beats;
    integer choice;
    integer align_bytes;
    begin
      choice = ($random & 32'h7fffffff) % 4;
      case (choice)
        0: len_beats = 1;
        1: len_beats = 2;
        2: len_beats = 4;
        default: len_beats = 8;
      endcase
      len = len_beats - 1;

      choice = ($random & 32'h7fffffff) % 3;
      case (choice)
        0: burst = `AXI4_BURST_FIXED;
        1: burst = `AXI4_BURST_INCR;
        default: burst = `AXI4_BURST_WRAP;
      endcase

      align_bytes = len_beats * (DATA_WIDTH/8);
      addr = (($random & 32'h7fffffff) % ((MEM_WORDS*(DATA_WIDTH/8)) / align_bytes)) * align_bytes;
    end
  endtask

  // ---------------------------------------------------------------------
  // Main stimulus / scoreboard
  // ---------------------------------------------------------------------
  integer txn;
  integer beat_idx;
  reg [7:0]               t_len;
  reg [1:0]                t_burst;
  reg [ADDR_WIDTH-1:0]    t_addr;
  reg [ID_WIDTH-1:0]      t_id;
  reg [DATA_WIDTH-1:0]    expected_data;

  initial begin
    errors        = 0;
    transactions  = 0;
    s_axi_awvalid = 1'b0;
    s_axi_wvalid  = 1'b0;
    s_axi_bready  = 1'b0;
    s_axi_arvalid = 1'b0;
    s_axi_rready  = 1'b0;

    s_axi_aresetn = 1'b0;
    m_axi_aresetn = 1'b0;
    repeat (10) @(posedge s_axi_aclk);
    repeat (10) @(posedge m_axi_aclk);
    s_axi_aresetn = 1'b1;
    m_axi_aresetn = 1'b1;
    repeat (5) @(posedge s_axi_aclk);

    for (txn = 0; txn < NUM_TXNS; txn = txn + 1) begin
      pick_burst_cfg(t_len, t_burst, t_addr);
      t_id = txn[ID_WIDTH-1:0];

      for (beat_idx = 0; beat_idx <= t_len; beat_idx = beat_idx + 1)
        wr_data_buf[beat_idx] = {$random, $random};

      axi_write_burst(t_id, t_addr, t_len, DATA_SIZE, t_burst);
      axi_read_burst (t_id, t_addr, t_len, DATA_SIZE, t_burst);

      for (beat_idx = 0; beat_idx <= t_len; beat_idx = beat_idx + 1) begin
        // A FIXED burst writes every beat to the same address, so only the
        // last write beat's data actually remains in memory; every read
        // beat should therefore return that same last-written value.
        if (t_burst == `AXI4_BURST_FIXED)
          expected_data = wr_data_buf[t_len];
        else
          expected_data = wr_data_buf[beat_idx];

        if (rd_data_buf[beat_idx] !== expected_data) begin
          errors = errors + 1;
          $display("ERROR: txn=%0d beat=%0d data mismatch exp=%h got=%h",
                    txn, beat_idx, expected_data, rd_data_buf[beat_idx]);
        end
      end
      transactions = transactions + 1;
    end

    repeat (50) @(posedge s_axi_aclk);

    if (errors == 0)
      $display("TEST PASSED: %0d transactions, 0 errors", transactions);
    else
      $display("TEST FAILED: %0d transactions, %0d errors", transactions, errors);

    $finish;
  end

  // Safety timeout in case of a deadlock (e.g. a handshake never completing)
  initial begin
    #200000;
    $display("TEST FAILED: global timeout, simulation did not complete");
    $finish;
  end

endmodule
