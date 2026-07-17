// Toggle-based request/acknowledge pulse crossing (used by the handshake
// AXI4 bridge). A single control bit (req_toggle) flips once per transfer
// and is 2-flop synchronized into the destination domain, where the edge is
// detected to produce a 1-cycle pulse; the destination replies by flipping
// ack_toggle -- but only when it explicitly pulses dst_done_in, which lets
// the calling channel wrapper delay the acknowledge until it has actually
// drained the payload to its downstream consumer (rd_ready), not merely
// captured it. Only 1 transfer may be in flight at a time (src_busy gates a
// new src_pulse_in until the previous one is acknowledged).
//
// This primitive only carries a single control bit across domains. Any
// payload associated with a transfer must be held stable in the source
// domain for the whole round trip and sampled by the destination only after
// dst_pulse_out fires (see axi4_cdc_channel_handshake.v) -- never sampled
// combinationally from a raw multi-bit bus.
module cdc_pulse_toggle (
  input  wire src_clk,
  input  wire src_rst_n,
  input  wire src_pulse_in,
  output wire src_busy,

  input  wire dst_clk,
  input  wire dst_rst_n,
  output wire dst_pulse_out,
  input  wire dst_done_in
);

  // ---------------- source domain ----------------
  reg req_toggle;
  reg busy_r;
  reg ack_toggle;   // driven in the destination-domain block below

  wire ack_toggle_sync;

  always @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
      req_toggle <= 1'b0;
      busy_r     <= 1'b0;
    end else if (src_pulse_in && !busy_r) begin
      req_toggle <= ~req_toggle;
      busy_r     <= 1'b1;
    end else if (busy_r && (ack_toggle_sync == req_toggle)) begin
      busy_r     <= 1'b0;
    end
  end

  assign src_busy = busy_r;

  cdc_2ff_sync u_ack_sync (
    .clk   (src_clk),
    .rst_n (src_rst_n),
    .d_in  (ack_toggle),
    .d_out (ack_toggle_sync)
  );

  // ---------------- destination domain ----------------
  wire req_toggle_sync;
  reg  req_toggle_sync_d;

  cdc_2ff_sync u_req_sync (
    .clk   (dst_clk),
    .rst_n (dst_rst_n),
    .d_in  (req_toggle),
    .d_out (req_toggle_sync)
  );

  always @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n)
      req_toggle_sync_d <= 1'b0;
    else
      req_toggle_sync_d <= req_toggle_sync;
  end

  assign dst_pulse_out = (req_toggle_sync != req_toggle_sync_d);

  always @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n)
      ack_toggle <= 1'b0;
    else if (dst_done_in)
      ack_toggle <= ~ack_toggle;
  end

endmodule
