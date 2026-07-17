`include "axi4_defs.vh"

// Simple byte-addressable memory-model AXI4 slave BFM used by both
// testbenches. Accepts one write burst / one read burst at a time (single
// outstanding per direction), applies random ready-signal stalls, and
// honours AWBURST/ARBURST (FIXED/INCR/WRAP) address stepping so the CDC
// bridge under test is exercised with realistic traffic. Simulation-only:
// not intended to be synthesizable.
module axi4_bfm_slave #(
  parameter DATA_WIDTH = 64,
  parameter ADDR_WIDTH = 32,
  parameter ID_WIDTH   = 4,
  parameter MEM_WORDS  = 4096,
  parameter STALL_PCT  = 30     // 0-100, chance per cycle of deasserting a ready
) (
  input  wire                    aclk,
  input  wire                    aresetn,

  input  wire [ID_WIDTH-1:0]     awid,
  input  wire [ADDR_WIDTH-1:0]   awaddr,
  input  wire [7:0]              awlen,
  input  wire [2:0]              awsize,
  input  wire [1:0]              awburst,
  input  wire                    awvalid,
  output reg                     awready,

  input  wire [DATA_WIDTH-1:0]   wdata,
  input  wire [DATA_WIDTH/8-1:0] wstrb,
  input  wire                    wlast,
  input  wire                    wvalid,
  output reg                     wready,

  output wire [ID_WIDTH-1:0]     bid,
  output wire [1:0]              bresp,
  output wire                    bvalid,
  input  wire                    bready,

  input  wire [ID_WIDTH-1:0]     arid,
  input  wire [ADDR_WIDTH-1:0]   araddr,
  input  wire [7:0]              arlen,
  input  wire [2:0]              arsize,
  input  wire [1:0]              arburst,
  input  wire                    arvalid,
  output reg                     arready,

  output wire [ID_WIDTH-1:0]     rid,
  output wire [DATA_WIDTH-1:0]   rdata,
  output wire [1:0]              rresp,
  output wire                    rlast,
  output wire                    rvalid,
  input  wire                    rready
);

  localparam MEM_BYTES = MEM_WORDS * (DATA_WIDTH / 8);

  reg [7:0] mem [0:MEM_BYTES-1];
  integer   bi;

  function [ADDR_WIDTH-1:0] step_addr;
    input [ADDR_WIDTH-1:0] addr;
    input [2:0]            size;
    input [1:0]            burst;
    input [ADDR_WIDTH-1:0] wrap_base;
    input [ADDR_WIDTH-1:0] wrap_bound;
    reg   [ADDR_WIDTH-1:0] inc_addr;
    begin
      if (burst == `AXI4_BURST_FIXED) begin
        step_addr = addr;
      end else begin
        inc_addr = addr + (1 << size);
        if (burst == `AXI4_BURST_WRAP && inc_addr >= wrap_bound)
          step_addr = wrap_base;
        else
          step_addr = inc_addr;
      end
    end
  endfunction

  // ---------------------------------------------------------------------
  // Write side: AW -> W(*) -> B
  // ---------------------------------------------------------------------
  localparam W_IDLE = 2'd0, W_DATA = 2'd1, W_RESP = 2'd2;
  reg [1:0]             wstate;
  reg [ID_WIDTH-1:0]    cur_awid;
  reg [7:0]             cur_awlen;
  reg [2:0]             cur_awsize;
  reg [1:0]             cur_awburst;
  reg [7:0]             wbeat_cnt;
  reg [ADDR_WIDTH-1:0]  wcur_addr;
  reg [ADDR_WIDTH-1:0]  wwrap_base;
  reg [ADDR_WIDTH-1:0]  wwrap_bound;
  reg [ADDR_WIDTH-1:0]  w_block_bytes;

  // bvalid/bid/bresp are combinational functions of wstate/cur_awid so that
  // the "response accepted" check below (`bready` while wstate==W_RESP)
  // never races against a registered-but-not-yet-updated copy of bvalid
  // itself (a classic same-cycle stale-read bug).
  assign bvalid = (wstate == W_RESP);
  assign bid    = cur_awid;
  assign bresp  = `AXI4_RESP_OKAY;

  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      wstate  <= W_IDLE;
      awready <= 1'b0;
      wready  <= 1'b0;
    end else begin
      case (wstate)
        W_IDLE: begin
          awready <= ((($random & 32'h7fffffff) % 100) >= STALL_PCT);
          if (awvalid && awready) begin
            w_block_bytes = (awlen + 1) * (1 << awsize);
            cur_awid      <= awid;
            cur_awlen     <= awlen;
            cur_awsize    <= awsize;
            cur_awburst   <= awburst;
            wcur_addr     <= awaddr;
            wwrap_base    <= (awaddr / w_block_bytes) * w_block_bytes;
            wwrap_bound   <= (awaddr / w_block_bytes) * w_block_bytes + w_block_bytes;
            wbeat_cnt     <= 8'd0;
            awready       <= 1'b0;
            wstate        <= W_DATA;
          end
        end

        W_DATA: begin
          wready <= ((($random & 32'h7fffffff) % 100) >= STALL_PCT);
          if (wvalid && wready) begin
            for (bi = 0; bi < DATA_WIDTH/8; bi = bi + 1)
              if (wstrb[bi])
                mem[wcur_addr + bi] <= wdata[bi*8 +: 8];

            if (wbeat_cnt == cur_awlen) begin
              wready <= 1'b0;
              wstate <= W_RESP;
            end else begin
              wbeat_cnt <= wbeat_cnt + 8'd1;
              wcur_addr <= step_addr(wcur_addr, cur_awsize, cur_awburst, wwrap_base, wwrap_bound);
            end
          end
        end

        W_RESP: begin
          if (bready)
            wstate <= W_IDLE;
        end

        default: wstate <= W_IDLE;
      endcase
    end
  end

  // ---------------------------------------------------------------------
  // Read side: AR -> R(*)
  // ---------------------------------------------------------------------
  localparam R_IDLE = 1'd0, R_DATA = 1'd1;
  reg                   rstate;
  reg [ID_WIDTH-1:0]    cur_arid;
  reg [7:0]             cur_arlen;
  reg [2:0]             cur_arsize;
  reg [1:0]             cur_arburst;
  reg [7:0]             rbeat_cnt;
  reg [ADDR_WIDTH-1:0]  rcur_addr;
  reg [ADDR_WIDTH-1:0]  rwrap_base;
  reg [ADDR_WIDTH-1:0]  rwrap_bound;
  reg [ADDR_WIDTH-1:0]  r_block_bytes;

  // rvalid/rid/rresp/rlast are combinational functions of rstate/registered
  // fields for the same reason bvalid/bid/bresp are above -- see comment
  // near the W_RESP state.
  assign rvalid = (rstate == R_DATA);
  assign rid    = cur_arid;
  assign rresp  = `AXI4_RESP_OKAY;
  assign rlast  = (rbeat_cnt == cur_arlen);

  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      rstate  <= R_IDLE;
      arready <= 1'b0;
    end else begin
      case (rstate)
        R_IDLE: begin
          arready <= ((($random & 32'h7fffffff) % 100) >= STALL_PCT);
          if (arvalid && arready) begin
            r_block_bytes = (arlen + 1) * (1 << arsize);
            cur_arid      <= arid;
            cur_arlen     <= arlen;
            cur_arsize    <= arsize;
            cur_arburst   <= arburst;
            rcur_addr     <= araddr;
            rwrap_base    <= (araddr / r_block_bytes) * r_block_bytes;
            rwrap_bound   <= (araddr / r_block_bytes) * r_block_bytes + r_block_bytes;
            rbeat_cnt     <= 8'd0;
            arready       <= 1'b0;
            rstate        <= R_DATA;
          end
        end

        R_DATA: begin
          if (rready) begin
            if (rbeat_cnt == cur_arlen) begin
              rstate <= R_IDLE;
            end else begin
              rbeat_cnt <= rbeat_cnt + 8'd1;
              rcur_addr <= step_addr(rcur_addr, cur_arsize, cur_arburst, rwrap_base, rwrap_bound);
            end
          end
        end

        default: rstate <= R_IDLE;
      endcase
    end
  end

  genvar gi;
  generate
    for (gi = 0; gi < DATA_WIDTH/8; gi = gi + 1) begin : gen_rdata
      assign rdata[gi*8 +: 8] = mem[rcur_addr + gi];
    end
  endgenerate

endmodule
