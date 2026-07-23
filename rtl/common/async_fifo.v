// Parameterized dual-clock asynchronous FIFO (Cummings-style).
// Write and read pointers are kept as Gray code so that only a single bit
// changes per increment; crossing domains through gray_sync_ptr (2-flop) is
// therefore metastability-safe even when write and read happen the same
// "instant" as seen from the other domain.
module async_fifo #(
  parameter DATA_WIDTH = 8,
  parameter ADDR_WIDTH = 4   // FIFO depth = 2**ADDR_WIDTH
) (
  input  wire                  wr_clk,
  input  wire                  wr_rst_n,
  input  wire                  wr_en,
  input  wire [DATA_WIDTH-1:0] wr_data,
  output wire                  wr_full,
  output wire                  wr_almost_full,   // <=2 free slots remaining

  input  wire                  rd_clk,
  input  wire                  rd_rst_n,
  input  wire                  rd_en,
  output wire [DATA_WIDTH-1:0] rd_data,
  output wire                  rd_empty
);

  localparam DEPTH = (1 << ADDR_WIDTH);

  reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  // ---------------------------------------------------------------------
  // Write domain: binary + Gray pointer, memory write port
  // ---------------------------------------------------------------------
  reg  [ADDR_WIDTH:0] wr_bin;
  reg  [ADDR_WIDTH:0] wr_gray;
  wire [ADDR_WIDTH:0] wr_bin_next  = wr_bin + {{ADDR_WIDTH{1'b0}}, (wr_en && !wr_full)};
  wire [ADDR_WIDTH:0] wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;
  wire [ADDR_WIDTH-1:0] wr_addr    = wr_bin[ADDR_WIDTH-1:0];

  always @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
      wr_bin  <= {(ADDR_WIDTH+1){1'b0}};
      wr_gray <= {(ADDR_WIDTH+1){1'b0}};
    end else begin
      wr_bin  <= wr_bin_next;
      wr_gray <= wr_gray_next;
    end
  end

  always @(posedge wr_clk) begin
    if (wr_en && !wr_full)
      mem[wr_addr] <= wr_data;
  end

  // ---------------------------------------------------------------------
  // Read domain: binary + Gray pointer, combinational memory read port
  // ---------------------------------------------------------------------
  reg  [ADDR_WIDTH:0] rd_bin;
  reg  [ADDR_WIDTH:0] rd_gray;
  wire [ADDR_WIDTH:0] rd_bin_next  = rd_bin + {{ADDR_WIDTH{1'b0}}, (rd_en && !rd_empty)};
  wire [ADDR_WIDTH:0] rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;
  wire [ADDR_WIDTH-1:0] rd_addr    = rd_bin[ADDR_WIDTH-1:0];

  always @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
      rd_bin  <= {(ADDR_WIDTH+1){1'b0}};
      rd_gray <= {(ADDR_WIDTH+1){1'b0}};
    end else begin
      rd_bin  <= rd_bin_next;
      rd_gray <= rd_gray_next;
    end
  end

  assign rd_data = mem[rd_addr];

  // ---------------------------------------------------------------------
  // Cross-domain pointer synchronization (Gray-coded, 2-flop each)
  // ---------------------------------------------------------------------
  wire [ADDR_WIDTH:0] wr_gray_sync_to_rd;
  wire [ADDR_WIDTH:0] rd_gray_sync_to_wr;

  gray_sync_ptr #(.PTR_WIDTH(ADDR_WIDTH+1)) u_wr2rd_sync (
    .dst_clk           (rd_clk),
    .dst_rst_n         (rd_rst_n),
    .src_gray_ptr      (wr_gray),
    .dst_gray_ptr_sync (wr_gray_sync_to_rd)
  );

  gray_sync_ptr #(.PTR_WIDTH(ADDR_WIDTH+1)) u_rd2wr_sync (
    .dst_clk           (wr_clk),
    .dst_rst_n         (wr_rst_n),
    .src_gray_ptr      (rd_gray),
    .dst_gray_ptr_sync (rd_gray_sync_to_wr)
  );

  // ---------------------------------------------------------------------
  // Empty (read domain) / Full (write domain) flag generation
  // ---------------------------------------------------------------------
  wire rd_empty_next = (rd_gray_next == wr_gray_sync_to_rd);
  reg  rd_empty_r;
  always @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n)
      rd_empty_r <= 1'b1;
    else
      rd_empty_r <= rd_empty_next;
  end
  assign rd_empty = rd_empty_r;

  // Full when the next write pointer, in Gray code, equals the synchronized
  // read pointer with its two MSBs inverted (standard Cummings full-detect:
  // this is the Gray-code representation of "write has wrapped exactly one
  // more time than read").
  wire wr_full_next = (wr_gray_next == {~rd_gray_sync_to_wr[ADDR_WIDTH:ADDR_WIDTH-1],
                                          rd_gray_sync_to_wr[ADDR_WIDTH-2:0]});
  reg wr_full_r;
  always @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n)
      wr_full_r <= 1'b0;
    else
      wr_full_r <= wr_full_next;
  end
  assign wr_full = wr_full_r;

  // ---------------------------------------------------------------------
  // Almost-full (write domain): binary occupancy count from the
  // synchronized (Gray) read pointer, converted back to binary.
  // ---------------------------------------------------------------------
  function [ADDR_WIDTH:0] gray2bin;
    input [ADDR_WIDTH:0] gray;
    integer i;
    begin
      gray2bin[ADDR_WIDTH] = gray[ADDR_WIDTH];
      for (i = ADDR_WIDTH - 1; i >= 0; i = i - 1)
        gray2bin[i] = gray2bin[i+1] ^ gray[i];
    end
  endfunction

  wire [ADDR_WIDTH:0] rd_bin_sync_to_wr = gray2bin(rd_gray_sync_to_wr);
  wire [ADDR_WIDTH:0] wr_count          = wr_bin - rd_bin_sync_to_wr;

  assign wr_almost_full = wr_full || (wr_count >= (DEPTH - 2));

endmodule
