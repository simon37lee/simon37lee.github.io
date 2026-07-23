// N-bit 2-flop synchronizer for a Gray-coded pointer.
// Safe for multi-bit buses ONLY because the source guarantees the value is
// Gray-coded (at most 1 bit toggles per update), so a metastable capture of
// the synchronizer differs from the true value by at most one count -- this
// does NOT generalize to arbitrary multi-bit buses (see cdc_pulse_toggle.v
// for how the handshake bridge crosses arbitrary-width payloads instead).
module gray_sync_ptr #(
  parameter PTR_WIDTH = 5
) (
  input  wire                 dst_clk,
  input  wire                 dst_rst_n,
  input  wire [PTR_WIDTH-1:0] src_gray_ptr,
  output wire [PTR_WIDTH-1:0] dst_gray_ptr_sync
);

  reg [PTR_WIDTH-1:0] sync_ff1;
  reg [PTR_WIDTH-1:0] sync_ff2;

  always @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
      sync_ff1 <= {PTR_WIDTH{1'b0}};
      sync_ff2 <= {PTR_WIDTH{1'b0}};
    end else begin
      sync_ff1 <= src_gray_ptr;
      sync_ff2 <= sync_ff1;
    end
  end

  assign dst_gray_ptr_sync = sync_ff2;

endmodule
