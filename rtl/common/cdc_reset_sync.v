// Async-assert / sync-deassert reset synchronizer.
// Brings an asynchronous active-low reset into a target clock domain so
// that reset assertion is immediate (asynchronous) but release is aligned
// to the target clock via a 2-flop shift register, avoiding reset removal
// recovery/removal timing violations.
module cdc_reset_sync (
  input  wire clk,
  input  wire async_rst_n,
  output wire sync_rst_n
);

  reg [1:0] rst_sync;

  always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n)
      rst_sync <= 2'b00;
    else
      rst_sync <= {rst_sync[0], 1'b1};
  end

  assign sync_rst_n = rst_sync[1];

endmodule
