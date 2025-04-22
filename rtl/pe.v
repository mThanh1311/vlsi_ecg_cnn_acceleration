// ===================== MODULE: PE =====================
module PE #(parameter n = 16, parameter SUM_WIDTH = (n*2)+4) (
    input clk,
    input rst,
    input signed [n-1:0] xin,
    input signed [n*7-1:0] win,
    output signed [SUM_WIDTH-1:0] sum,
    output signed [SUM_WIDTH-1:0] sum1,
    output signed [n-1:0] xout
);

    wire signed [SUM_WIDTH-1:0] mac_out[0:6];
    wire signed [n-1:0] x_reg[0:6];
    wire signed [SUM_WIDTH-1:0] acc_chain[0:7];

    assign acc_chain[0] = 0;

    genvar i;
    generate
        for (i = 0; i < 7; i = i + 1) begin : MAC_CHAIN
            wire signed [n-1:0] win_i = win[(i+1)*n-1 -: n];

            if (i == 0) begin
                mac_unit #(.n(n), .SUM_WIDTH(SUM_WIDTH)) MAC (
                    .clk(clk),
                    .rst(rst),
                    .xin(xin),
                    .win(win_i),
                    .acc_in(acc_chain[i]),
                    .mac_out(mac_out[i]),
                    .xout(x_reg[i])
                );
            end else begin
                mac_unit #(.n(n), .SUM_WIDTH(SUM_WIDTH)) MAC (
                    .clk(clk),
                    .rst(rst),
                    .xin(x_reg[i-1]),
                    .win(win_i),
                    .acc_in(acc_chain[i]),
                    .mac_out(mac_out[i]),
                    .xout(x_reg[i])
                );
            end

            assign acc_chain[i+1] = mac_out[i];
        end
    endgenerate

    assign sum = mac_out[6];
    assign sum1 = mac_out[5];

    reg signed [n-1:0] xout_reg;
    always @(posedge clk or posedge rst) begin
        if (rst)
            xout_reg <= 0;
        else
            xout_reg <= x_reg[6];
    end
    assign xout = xout_reg;

endmodule