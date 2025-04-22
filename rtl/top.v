`timescale 1ns/1ps

module ECG_Top #(
    parameter N = 16,
    parameter SUM_WIDTH = (N*2)+4
)(
    input clk,
    input rst,
    input start,
    input signed [N-1:0] xin,
    input signed [N-1:0] win,
    output signed [N-1:0] detection_out,
    output done,

    // Debug outputs
    output wire signed [SUM_WIDTH-1:0] sum,
    output wire signed [SUM_WIDTH-1:0] sum1,
    output wire signed [SUM_WIDTH-1:0] relu_out,
    output wire signed [SUM_WIDTH-1:0] pool_out,
    output wire signed [SUM_WIDTH-1:0] ctrl_out,
    output wire [3:0] state
);

    // FSM States
    localparam IDLE    = 4'd0;
    localparam CONV1   = 4'd1;
    localparam MP1     = 4'd2;
    localparam CONV2   = 4'd3;
    localparam CONV3   = 4'd4;
    localparam MP2     = 4'd5;
    localparam FLATTEN = 4'd6;
    localparam FC1     = 4'd7;
    localparam FC2     = 4'd8;
    localparam DONE    = 4'd9;

    reg [3:0] state_reg, next_state;
    assign state = state_reg;

    // FSM sequential
    always @(posedge clk or posedge rst) begin
        if (rst) state_reg <= IDLE;
        else     state_reg <= next_state;
    end

    // FSM transition logic
    integer cycle_count;
    always @(*) begin
        next_state = state_reg;
        case (state_reg)
            IDLE:    if (start) next_state = CONV1;
            CONV1:   if (cycle_count == 21) next_state = MP1;
            MP1:     next_state = CONV2;
            CONV2:   if (cycle_count == 21) next_state = CONV3;
            CONV3:   if (cycle_count == 21) next_state = MP2;
            MP2:     next_state = FLATTEN;
            FLATTEN: next_state = FC1;
            FC1:     if (cycle_count == 21) next_state = FC2;
            FC2:     if (cycle_count == 21) next_state = DONE;
            DONE:    next_state = DONE;
        endcase
    end

    // Cycle counter
    always @(posedge clk or posedge rst) begin
        if (rst || state_reg != next_state)
            cycle_count <= 0;
        else if (state_reg != IDLE && state_reg != MP1 && state_reg != MP2 && state_reg != FLATTEN && state_reg != DONE)
            cycle_count <= cycle_count + 1;
    end

    // Control logic
    reg S1, S2, S3;
    reg [1:0] S5, S6;
    reg accumulate_en, store_en;
    reg softmax_en;
    
    always @(*) begin
        // Default values
        S1 = 0; S2 = 0; S3 = 0;
        S5 = 2'b00; S6 = 2'b00;
        accumulate_en = 0;
        store_en = 0;
        softmax_en = 0;

        case (state_reg)
            CONV1: begin S1 = 0; S2 = 1; end
            MP1:   begin S3 = 1; end
            CONV2: begin S1 = 1; S2 = 0; S5 = 2'b00; S6 = 2'b00; end
            CONV3: begin S2 = 1; S5 = 2'b10; S6 = 2'b10; end
            MP2:   begin S3 = 0; end
            FC1:   begin S5 = 2'b00; S6 = 2'b11; accumulate_en = 1; softmax_en = 1; end
            FC2:   begin S5 = 2'b00; S6 = 2'b01; accumulate_en = 1; store_en = 1; softmax_en = 1; end
        endcase
    end

    // Module wiring
    wire signed [N-1:0] xout;
    wire signed [SUM_WIDTH-1:0] sum_wire, sum1_wire, relu_wire, pool_wire, ctrl_wire;

    assign sum       = sum_wire;
    assign sum1      = sum1_wire;
    assign relu_out  = relu_wire;
    assign pool_out  = pool_wire;
    assign ctrl_out  = ctrl_wire;

    PE #(N, SUM_WIDTH) pe_inst (
        .clk(clk), .rst(rst),
        .xin(xin), .win({7{win}}),
        .sum(sum_wire), .sum1(sum1_wire),
        .xout(xout)
    );

    ReLU #(SUM_WIDTH) relu_inst (
        .clk(clk), .rst(rst),
        .sum(sum_wire), .sum1(sum1_wire), .S2(S2),
        .relu_out(relu_wire)
    );

    MaxPooling #(SUM_WIDTH) mp_inst (
        .clk(clk), .rst(rst),
        .data_in(relu_wire), .S3(S3),
        .data_out(pool_wire)
    );

    ControlBuffer #(SUM_WIDTH) ctrl_inst (
        .clk(clk), .rst(rst),
        .data_in(pool_wire),
        .S5(S5), .S6(S6),
        .data_out(ctrl_wire)
    );

    Softmax #(SUM_WIDTH) softmax_inst (
        .clk(clk), .rst(rst),
        .sum(ctrl_wire),
        .accumulate_en(accumulate_en),
        .store_en(store_en),
        .softmax_en(softmax_en), // NEW
        .detection_out(detection_out)
    );

    assign done = (state_reg == DONE);

endmodule