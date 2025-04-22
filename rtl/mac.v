// ===================== MODULE: mac_unit =====================
module mac_unit #(parameter n = 8, parameter SUM_WIDTH = (n*2)+4)(
    input clk,
    input rst,
    input signed [n-1:0] xin,
    input signed [n-1:0] win,
    input signed [SUM_WIDTH-1:0] acc_in,
    output reg signed [SUM_WIDTH-1:0] mac_out,
    output signed [n-1:0] xout
);

    wire signed [SUM_WIDTH-1:0] product;
    assign product = xin * win;

    always @(posedge clk or posedge rst) begin
        if (rst)
            mac_out <= 0;
        else
            mac_out <= product + acc_in;
    end

    register #(.WIDTH(n)) x_reg (
        .clk(clk),
        .rst(rst),
        .data_in(xin),
        .data_out(xout)
    );
endmodule