// ===================== MODULE: MaxPooling =====================
module MaxPooling #(
    parameter WIDTH = 32
)(
    input clk,
    input rst,
    input signed [WIDTH-1:0] data_in,
    input S3, // 1: Max2, 0: Max3
    output signed [WIDTH-1:0] data_out
);

    wire signed [WIDTH-1:0] r1_out, r2_out, r3_out;

    // Shift register chain using register module
    register #(.WIDTH(WIDTH)) reg1 (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(r1_out)
    );

    register #(.WIDTH(WIDTH)) reg2 (
        .clk(clk),
        .rst(rst),
        .data_in(r1_out),
        .data_out(r2_out)
    );

    register #(.WIDTH(WIDTH)) reg3 (
        .clk(clk),
        .rst(rst),
        .data_in(r2_out),
        .data_out(r3_out)
    );

    // Max pooling logic
    wire signed [WIDTH-1:0] max2, max3;
    assign max2 = (r1_out > r2_out) ? r1_out : r2_out;
    wire signed [WIDTH-1:0] temp_max = (r1_out > r2_out) ? r1_out : r2_out;
    assign max3 = (temp_max > r3_out) ? temp_max : r3_out;

    assign data_out = (S3 == 1'b1) ? max2 : max3;

endmodule