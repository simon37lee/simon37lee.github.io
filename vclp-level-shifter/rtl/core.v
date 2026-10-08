// core.v : PD_CORE (VDDL = 0.8V) 에 속하는 블록
// 입력 1비트를 클럭에 맞춰 반전해서 내보내는 가장 단순한 플립플롭
module core (
    input  wire clk,
    input  wire rst_n,
    input  wire din,
    output reg  dout
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) dout <= 1'b0;
        else        dout <= ~din;
    end
endmodule
