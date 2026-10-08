// top.v : PD_TOP (VDDH = 1.0V) 최상위
// top(1.0V) -> u_core(0.8V) : clk, rst_n, din  (High -> Low)
// u_core(0.8V) -> top(1.0V) : dout             (Low  -> High)
module top (
    input  wire clk,
    input  wire rst_n,
    input  wire din,
    output wire dout
);
    core u_core (
        .clk   (clk),
        .rst_n (rst_n),
        .din   (din),
        .dout  (dout)
    );
endmodule
