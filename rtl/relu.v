// ===================== MODULE: ReLU =====================
module ReLU #(
    parameter WIDTH = 32
)(
    input clk,
    input rst,
    input signed [WIDTH-1:0] sum,     // from PE (1x7 CNN)
    input signed [WIDTH-1:0] sum1,    // optional input (used in 1x1 CNN)
    input S2,                         // select: 1=use sum, 0=use sum+sum1
    output signed [WIDTH-1:0] relu_out
);

    wire signed [WIDTH-1:0] add_result;
    assign add_result = sum + sum1;

    reg signed [WIDTH-1:0] reg_1x1;
    always @(posedge clk or posedge rst) begin
        if (rst)
            reg_1x1 <= 0;
        else
            reg_1x1 <= add_result;
    end

    wire signed [WIDTH-1:0] relu_in;
    assign relu_in = (S2 == 1'b1) ? sum : reg_1x1;

    assign relu_out = (relu_in > 0) ? relu_in : 0;

endmodule
