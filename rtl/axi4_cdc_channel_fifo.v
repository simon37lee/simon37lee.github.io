// Single AXI4 channel CDC wrapper (Version A: async FIFO). Instantiated
// once per channel (AW/W/B/AR/R) by axi4_async_bridge_fifo with WIDTH set
// to that channel's packed payload width.
module axi4_cdc_channel_fifo #(
  parameter WIDTH      = 8,
  parameter ADDR_WIDTH = 4    // FIFO depth = 2**ADDR_WIDTH
) (
  input  wire             wr_clk,
  input  wire             wr_rst_n,
  input  wire             wr_valid,
  output wire             wr_ready,
  input  wire [WIDTH-1:0] wr_payload,

  input  wire             rd_clk,
  input  wire             rd_rst_n,
  output wire             rd_valid,
  input  wire             rd_ready,
  output wire [WIDTH-1:0] rd_payload
);

  wire fifo_full;
  wire fifo_empty;
  wire wr_en = wr_valid && wr_ready;
  wire rd_en = rd_valid && rd_ready;

  assign wr_ready = !fifo_full;
  assign rd_valid = !fifo_empty;

  async_fifo #(
    .DATA_WIDTH (WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH)
  ) u_async_fifo (
    .wr_clk         (wr_clk),
    .wr_rst_n       (wr_rst_n),
    .wr_en          (wr_en),
    .wr_data        (wr_payload),
    .wr_full        (fifo_full),
    .wr_almost_full (),

    .rd_clk         (rd_clk),
    .rd_rst_n       (rd_rst_n),
    .rd_en          (rd_en),
    .rd_data        (rd_payload),
    .rd_empty       (fifo_empty)
  );

endmodule
