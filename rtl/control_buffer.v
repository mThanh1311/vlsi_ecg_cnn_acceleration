`timescale 1ns/1ps

module ControlBuffer #(parameter WIDTH = 32)(
    input clk,
    input rst,
    input signed [WIDTH-1:0] data_in,
    input [1:0] S5,
    input [1:0] S6,
    output reg signed [WIDTH-1:0] data_out
);

    // Define 54 registers
    wire signed [WIDTH-1:0] R_out [0:53];
    reg signed [WIDTH-1:0] R_data [0:53];

    integer i;

    // Shift-register operation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 54; i = i + 1)
                R_data[i] <= 0;
        end else begin
            R_data[0] <= data_in;
            for (i = 1; i < 54; i = i + 1)
                R_data[i] <= R_data[i-1];
        end
    end

    // Instantiate register.v for all R0-R53
    genvar gi;
    generate
        for (gi = 0; gi < 54; gi = gi + 1) begin : REG_ARRAY
            register #(.WIDTH(WIDTH)) reg_inst (
                .clk(clk),
                .rst(rst),
                .data_in(R_data[gi]),
                .data_out(R_out[gi])
            );
        end
    endgenerate

    // Multiplexer logic (S5 and S6)
    wire signed [WIDTH-1:0] mux_small_out;

    // S5 selects between R20, R35, and R53 for convolution layer 3
    assign mux_small_out = (S5 == 2'b00) ? R_out[20] :
                           (S5 == 2'b01) ? R_out[35] :
                           (S5 == 2'b10) ? R_out[53] : {WIDTH{1'b0}};

    // S6 selects the final output from different layers
    always @(posedge clk) begin
        case (S6)
            2'b00: data_out <= mux_small_out;    // CNN 1x1 layer 3 or default
            2'b01: data_out <= R_out[5];         // Fully Connected layer 8
            2'b10: data_out <= R_out[17];        // Convolution layer 4
            2'b11: data_out <= R_out[20];        // Fully Connected layer 7
            default: data_out <= {WIDTH{1'b0}};
        endcase
    end

endmodule