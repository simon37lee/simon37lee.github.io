// Single AXI4 channel CDC wrapper (Version B: 2-flop + toggle handshake).
// Instantiated once per channel (AW/W/B/AR/R) by axi4_async_bridge_handshake
// with WIDTH set to that channel's packed payload width. Only one payload
// may be in flight at a time (wr_ready deasserts until the previous payload
// has been fully round-tripped and drained to the rd_ready consumer).
module axi4_cdc_channel_handshake #(
  parameter WIDTH = 8
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

  // ---------------- source (write) domain ----------------
  wire busy;
  wire src_pulse_in = wr_valid && wr_ready;

  assign wr_ready = !busy;

  reg [WIDTH-1:0] hold_reg;

  always @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n)
      hold_reg <= {WIDTH{1'b0}};
    else if (src_pulse_in)
      hold_reg <= wr_payload;
  end

  // ---------------- destination (read) domain ----------------
  wire dst_pulse_out;
  wire dst_done_in;

  reg [WIDTH-1:0] rd_payload_r;
  reg             rd_valid_r;

  assign dst_done_in = rd_valid_r && rd_ready;
  assign rd_valid    = rd_valid_r;
  assign rd_payload  = rd_payload_r;

  // hold_reg is read directly here (no synchronizer on the bus itself) --
  // this is safe because it is only ever updated once busy deasserts, which
  // cannot happen until dst_done_in has fired below, i.e. strictly after
  // this capture already happened; see cdc_pulse_toggle.v for the timing
  // argument (dst_pulse_out only fires once the toggle has been stable
  // across 2 dst_clk cycles, by which point hold_reg has been static since
  // before the request was even issued).
  always @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
      rd_valid_r   <= 1'b0;
      rd_payload_r <= {WIDTH{1'b0}};
    end else if (dst_pulse_out) begin
      rd_valid_r   <= 1'b1;
      rd_payload_r <= hold_reg;
    end else if (dst_done_in) begin
      rd_valid_r   <= 1'b0;
    end
  end

  cdc_pulse_toggle u_handshake (
    .src_clk       (wr_clk),
    .src_rst_n     (wr_rst_n),
    .src_pulse_in  (src_pulse_in),
    .src_busy      (busy),

    .dst_clk       (rd_clk),
    .dst_rst_n     (rd_rst_n),
    .dst_pulse_out (dst_pulse_out),
    .dst_done_in   (dst_done_in)
  );

endmodule
