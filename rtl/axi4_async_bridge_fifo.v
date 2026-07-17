`include "axi4_defs.vh"

// AXI4 asynchronous clock-domain-crossing bridge -- Version A.
// Each of the 5 AXI4 channels (AW, W, B, AR, R) crosses through its own
// dual-clock async FIFO (Gray-code pointer synchronization), giving up to
// FIFO_DEPTH outstanding beats in flight per channel. Port list is
// identical to axi4_async_bridge_handshake so the two are drop-in
// interchangeable.
module axi4_async_bridge_fifo #(
  parameter DATA_WIDTH   = 64,
  parameter ADDR_WIDTH   = 32,
  parameter ID_WIDTH     = 4,
  parameter AWUSER_WIDTH = 1,
  parameter WUSER_WIDTH  = 1,
  parameter BUSER_WIDTH  = 1,
  parameter ARUSER_WIDTH = 1,
  parameter RUSER_WIDTH  = 1,
  parameter FIFO_DEPTH   = 16
) (
  // ---------------- Slave-facing side (AXI4 master connects here) ----------------
  input  wire                      s_axi_aclk,
  input  wire                      s_axi_aresetn,

  input  wire [ID_WIDTH-1:0]       s_axi_awid,
  input  wire [ADDR_WIDTH-1:0]     s_axi_awaddr,
  input  wire [7:0]                s_axi_awlen,
  input  wire [2:0]                s_axi_awsize,
  input  wire [1:0]                s_axi_awburst,
  input  wire                      s_axi_awlock,
  input  wire [3:0]                s_axi_awcache,
  input  wire [2:0]                s_axi_awprot,
  input  wire [3:0]                s_axi_awqos,
  input  wire [AWUSER_WIDTH-1:0]   s_axi_awuser,
  input  wire                      s_axi_awvalid,
  output wire                      s_axi_awready,

  input  wire [DATA_WIDTH-1:0]     s_axi_wdata,
  input  wire [DATA_WIDTH/8-1:0]   s_axi_wstrb,
  input  wire                      s_axi_wlast,
  input  wire [WUSER_WIDTH-1:0]    s_axi_wuser,
  input  wire                      s_axi_wvalid,
  output wire                      s_axi_wready,

  output wire [ID_WIDTH-1:0]       s_axi_bid,
  output wire [1:0]                s_axi_bresp,
  output wire [BUSER_WIDTH-1:0]    s_axi_buser,
  output wire                      s_axi_bvalid,
  input  wire                      s_axi_bready,

  input  wire [ID_WIDTH-1:0]       s_axi_arid,
  input  wire [ADDR_WIDTH-1:0]     s_axi_araddr,
  input  wire [7:0]                s_axi_arlen,
  input  wire [2:0]                s_axi_arsize,
  input  wire [1:0]                s_axi_arburst,
  input  wire                      s_axi_arlock,
  input  wire [3:0]                s_axi_arcache,
  input  wire [2:0]                s_axi_arprot,
  input  wire [3:0]                s_axi_arqos,
  input  wire [ARUSER_WIDTH-1:0]   s_axi_aruser,
  input  wire                      s_axi_arvalid,
  output wire                      s_axi_arready,

  output wire [ID_WIDTH-1:0]       s_axi_rid,
  output wire [DATA_WIDTH-1:0]     s_axi_rdata,
  output wire [1:0]                s_axi_rresp,
  output wire                      s_axi_rlast,
  output wire [RUSER_WIDTH-1:0]    s_axi_ruser,
  output wire                      s_axi_rvalid,
  input  wire                      s_axi_rready,

  // ---------------- Master-facing side (AXI4 slave connects here) ----------------
  input  wire                      m_axi_aclk,
  input  wire                      m_axi_aresetn,

  output wire [ID_WIDTH-1:0]       m_axi_awid,
  output wire [ADDR_WIDTH-1:0]     m_axi_awaddr,
  output wire [7:0]                m_axi_awlen,
  output wire [2:0]                m_axi_awsize,
  output wire [1:0]                m_axi_awburst,
  output wire                      m_axi_awlock,
  output wire [3:0]                m_axi_awcache,
  output wire [2:0]                m_axi_awprot,
  output wire [3:0]                m_axi_awqos,
  output wire [AWUSER_WIDTH-1:0]   m_axi_awuser,
  output wire                      m_axi_awvalid,
  input  wire                      m_axi_awready,

  output wire [DATA_WIDTH-1:0]     m_axi_wdata,
  output wire [DATA_WIDTH/8-1:0]   m_axi_wstrb,
  output wire                      m_axi_wlast,
  output wire [WUSER_WIDTH-1:0]    m_axi_wuser,
  output wire                      m_axi_wvalid,
  input  wire                      m_axi_wready,

  input  wire [ID_WIDTH-1:0]       m_axi_bid,
  input  wire [1:0]                m_axi_bresp,
  input  wire [BUSER_WIDTH-1:0]    m_axi_buser,
  input  wire                      m_axi_bvalid,
  output wire                      m_axi_bready,

  output wire [ID_WIDTH-1:0]       m_axi_arid,
  output wire [ADDR_WIDTH-1:0]     m_axi_araddr,
  output wire [7:0]                m_axi_arlen,
  output wire [2:0]                m_axi_arsize,
  output wire [1:0]                m_axi_arburst,
  output wire                      m_axi_arlock,
  output wire [3:0]                m_axi_arcache,
  output wire [2:0]                m_axi_arprot,
  output wire [3:0]                m_axi_arqos,
  output wire [ARUSER_WIDTH-1:0]   m_axi_aruser,
  output wire                      m_axi_arvalid,
  input  wire                      m_axi_arready,

  input  wire [ID_WIDTH-1:0]       m_axi_rid,
  input  wire [DATA_WIDTH-1:0]     m_axi_rdata,
  input  wire [1:0]                m_axi_rresp,
  input  wire                      m_axi_rlast,
  input  wire [RUSER_WIDTH-1:0]    m_axi_ruser,
  input  wire                      m_axi_rvalid,
  output wire                      m_axi_rready
);

  `include "axi4_clog2.vh"

  localparam AW_WIDTH = `AXI4_AW_WIDTH(ID_WIDTH, ADDR_WIDTH, AWUSER_WIDTH);
  localparam W_WIDTH  = `AXI4_W_WIDTH(DATA_WIDTH, WUSER_WIDTH);
  localparam B_WIDTH  = `AXI4_B_WIDTH(ID_WIDTH, BUSER_WIDTH);
  localparam AR_WIDTH = `AXI4_AR_WIDTH(ID_WIDTH, ADDR_WIDTH, ARUSER_WIDTH);
  localparam R_WIDTH  = `AXI4_R_WIDTH(ID_WIDTH, DATA_WIDTH, RUSER_WIDTH);

  localparam FIFO_ADDR_WIDTH = axi4_clog2(FIFO_DEPTH);

  // ---------------------------------------------------------------------
  // Reset synchronizers, one per clock domain
  // ---------------------------------------------------------------------
  wire s_rst_n_sync;
  wire m_rst_n_sync;

  cdc_reset_sync u_s_rst_sync (.clk(s_axi_aclk), .async_rst_n(s_axi_aresetn), .sync_rst_n(s_rst_n_sync));
  cdc_reset_sync u_m_rst_sync (.clk(m_axi_aclk), .async_rst_n(m_axi_aresetn), .sync_rst_n(m_rst_n_sync));

  // ---------------------------------------------------------------------
  // AW channel: s_axi_aclk (source) -> m_axi_aclk (dest)
  // ---------------------------------------------------------------------
  wire [AW_WIDTH-1:0] aw_wr_payload = {s_axi_awid, s_axi_awaddr, s_axi_awlen, s_axi_awsize,
                                        s_axi_awburst, s_axi_awlock, s_axi_awcache, s_axi_awprot,
                                        s_axi_awqos, s_axi_awuser};
  wire [AW_WIDTH-1:0] aw_rd_payload;

  assign {m_axi_awid, m_axi_awaddr, m_axi_awlen, m_axi_awsize,
          m_axi_awburst, m_axi_awlock, m_axi_awcache, m_axi_awprot,
          m_axi_awqos, m_axi_awuser} = aw_rd_payload;

  axi4_cdc_channel_fifo #(.WIDTH(AW_WIDTH), .ADDR_WIDTH(FIFO_ADDR_WIDTH)) u_aw_ch (
    .wr_clk    (s_axi_aclk), .wr_rst_n(s_rst_n_sync), .wr_valid(s_axi_awvalid), .wr_ready(s_axi_awready), .wr_payload(aw_wr_payload),
    .rd_clk    (m_axi_aclk), .rd_rst_n(m_rst_n_sync), .rd_valid(m_axi_awvalid), .rd_ready(m_axi_awready), .rd_payload(aw_rd_payload)
  );

  // ---------------------------------------------------------------------
  // W channel: s_axi_aclk (source) -> m_axi_aclk (dest)
  // ---------------------------------------------------------------------
  wire [W_WIDTH-1:0] w_wr_payload = {s_axi_wdata, s_axi_wstrb, s_axi_wlast, s_axi_wuser};
  wire [W_WIDTH-1:0] w_rd_payload;

  assign {m_axi_wdata, m_axi_wstrb, m_axi_wlast, m_axi_wuser} = w_rd_payload;

  axi4_cdc_channel_fifo #(.WIDTH(W_WIDTH), .ADDR_WIDTH(FIFO_ADDR_WIDTH)) u_w_ch (
    .wr_clk    (s_axi_aclk), .wr_rst_n(s_rst_n_sync), .wr_valid(s_axi_wvalid), .wr_ready(s_axi_wready), .wr_payload(w_wr_payload),
    .rd_clk    (m_axi_aclk), .rd_rst_n(m_rst_n_sync), .rd_valid(m_axi_wvalid), .rd_ready(m_axi_wready), .rd_payload(w_rd_payload)
  );

  // ---------------------------------------------------------------------
  // AR channel: s_axi_aclk (source) -> m_axi_aclk (dest)
  // ---------------------------------------------------------------------
  wire [AR_WIDTH-1:0] ar_wr_payload = {s_axi_arid, s_axi_araddr, s_axi_arlen, s_axi_arsize,
                                        s_axi_arburst, s_axi_arlock, s_axi_arcache, s_axi_arprot,
                                        s_axi_arqos, s_axi_aruser};
  wire [AR_WIDTH-1:0] ar_rd_payload;

  assign {m_axi_arid, m_axi_araddr, m_axi_arlen, m_axi_arsize,
          m_axi_arburst, m_axi_arlock, m_axi_arcache, m_axi_arprot,
          m_axi_arqos, m_axi_aruser} = ar_rd_payload;

  axi4_cdc_channel_fifo #(.WIDTH(AR_WIDTH), .ADDR_WIDTH(FIFO_ADDR_WIDTH)) u_ar_ch (
    .wr_clk    (s_axi_aclk), .wr_rst_n(s_rst_n_sync), .wr_valid(s_axi_arvalid), .wr_ready(s_axi_arready), .wr_payload(ar_wr_payload),
    .rd_clk    (m_axi_aclk), .rd_rst_n(m_rst_n_sync), .rd_valid(m_axi_arvalid), .rd_ready(m_axi_arready), .rd_payload(ar_rd_payload)
  );

  // ---------------------------------------------------------------------
  // B channel: m_axi_aclk (source) -> s_axi_aclk (dest)
  // ---------------------------------------------------------------------
  wire [B_WIDTH-1:0] b_wr_payload = {m_axi_bid, m_axi_bresp, m_axi_buser};
  wire [B_WIDTH-1:0] b_rd_payload;

  assign {s_axi_bid, s_axi_bresp, s_axi_buser} = b_rd_payload;

  axi4_cdc_channel_fifo #(.WIDTH(B_WIDTH), .ADDR_WIDTH(FIFO_ADDR_WIDTH)) u_b_ch (
    .wr_clk    (m_axi_aclk), .wr_rst_n(m_rst_n_sync), .wr_valid(m_axi_bvalid), .wr_ready(m_axi_bready), .wr_payload(b_wr_payload),
    .rd_clk    (s_axi_aclk), .rd_rst_n(s_rst_n_sync), .rd_valid(s_axi_bvalid), .rd_ready(s_axi_bready), .rd_payload(b_rd_payload)
  );

  // ---------------------------------------------------------------------
  // R channel: m_axi_aclk (source) -> s_axi_aclk (dest)
  // ---------------------------------------------------------------------
  wire [R_WIDTH-1:0] r_wr_payload = {m_axi_rid, m_axi_rdata, m_axi_rresp, m_axi_rlast, m_axi_ruser};
  wire [R_WIDTH-1:0] r_rd_payload;

  assign {s_axi_rid, s_axi_rdata, s_axi_rresp, s_axi_rlast, s_axi_ruser} = r_rd_payload;

  axi4_cdc_channel_fifo #(.WIDTH(R_WIDTH), .ADDR_WIDTH(FIFO_ADDR_WIDTH)) u_r_ch (
    .wr_clk    (m_axi_aclk), .wr_rst_n(m_rst_n_sync), .wr_valid(m_axi_rvalid), .wr_ready(m_axi_rready), .wr_payload(r_wr_payload),
    .rd_clk    (s_axi_aclk), .rd_rst_n(s_rst_n_sync), .rd_valid(s_axi_rvalid), .rd_ready(s_axi_rready), .rd_payload(r_rd_payload)
  );

endmodule
