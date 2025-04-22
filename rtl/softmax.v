// ===================== MODULE: Softmax =====================
module Softmax #(parameter WIDTH = 32)(
    input clk,
    input rst,
    input signed [WIDTH-1:0] sum,              // đầu vào từ PE
    input accumulate_en,                       // cho phép tích lũy
    input store_en,                            // ghi giá trị vào Rn
    input softmax_en,                          // enable toàn bộ module
    output signed [WIDTH-1:0] detection_out    // output: max(R0~R5)
);

    reg signed [WIDTH-1:0] acc_reg;            // accumulator register
    reg [2:0] write_index;                     // để điều hướng ghi vào đúng thanh ghi Rn

    // ========== BUFFER cho R0~R5 ==========    
    reg signed [WIDTH-1:0] R_data [0:5];       // dữ liệu trung gian chờ ghi vào register.v
    wire signed [WIDTH-1:0] R_out [0:5];       // output của mỗi register

    integer i;

    // ===== TÍCH LŨY =====
    always @(posedge clk or posedge rst) begin
        if (rst)
            acc_reg <= 0;
        else if (softmax_en && accumulate_en)
            acc_reg <= acc_reg + sum;
    end

    // ===== CẬP NHẬT DỮ LIỆU R[i] =====
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 6; i = i + 1)
                R_data[i] <= 0;
            write_index <= 0;
        end else if (softmax_en && store_en) begin
            R_data[write_index] <= acc_reg;
            acc_reg <= 0;
            write_index <= (write_index == 5) ? 0 : write_index + 1;
        end
    end

    // ===== GÁN VÀO REGISTER.V =====
    genvar gi;
    generate
        for (gi = 0; gi < 6; gi = gi + 1) begin : REG_BLOCK
            register #(.WIDTH(WIDTH)) r_inst (
                .clk(clk),
                .rst(rst),
                .data_in(R_data[gi]),
                .data_out(R_out[gi])
            );
        end
    endgenerate

    // ===== TÌM MAX(R0~R5) =====
    reg signed [WIDTH-1:0] max_val;
    always @(*) begin
        max_val = R_out[0];
        for (i = 1; i < 6; i = i + 1) begin
            if (R_out[i] > max_val)
                max_val = R_out[i];
        end
    end

    assign detection_out = max_val;

endmodule
