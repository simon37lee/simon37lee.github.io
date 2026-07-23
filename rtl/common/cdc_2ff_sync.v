// Generic single-bit 2-flop synchronizer.
// Only primitive (besides gray_sync_ptr and cdc_pulse_toggle) permitted to
// sample a signal that originates in another clock domain.
module cdc_2ff_sync #(
  parameter RESET_VALUE = 1'b0
) (
  input  wire clk,
  input  wire rst_n,
  input  wire d_in,
  output wire d_out
);

  reg [1:0] sync_ff;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      sync_ff <= {2{RESET_VALUE}};
    else
      sync_ff <= {sync_ff[0], d_in};
  end

  assign d_out = sync_ff[1];

endmodule
