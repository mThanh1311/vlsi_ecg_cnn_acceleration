`timescale 1ns/1ps

`define PATTERN "C:/Users/AD/Thesis_ECG/thesis_ver_07/database/pe_test_patterns.txt"
`define PATTERN_NUM 10

module pe_int8_tb;

    localparam N = 8;
    localparam SUM_WIDTH = (N * 2) + 4;

    reg clk, rst;
    reg signed [N-1:0] xin_8, w0, w1, w2, w3, w4, w5, w6;
    reg signed [SUM_WIDTH-1:0] expected_sum, expected_sum1;
    reg signed [N*7-1:0] win_packed;

    wire signed [SUM_WIDTH-1:0] sum, sum1;
    wire signed [N-1:0] xout_8;

    integer i, fd, err_count = 0;
    integer bit_width;

    // Instantiate PE
    PE #(.n(N), .SUM_WIDTH(SUM_WIDTH)) DUT (
        .clk(clk),
        .rst(rst),
        .xin(xin_8),
        .win(win_packed),
        .sum(sum),
        .sum1(sum1),
        .xout(xout_8)
    );

    // Clock 100MHz
    always #5 clk = ~clk;

    initial begin
        fd = $fopen(`PATTERN, "r");
        if (fd == 0) begin
            $display("ERROR: Cannot open pattern file: %s", `PATTERN);
            $finish;
        end

        clk = 0;
        rst = 1;
        #20 rst = 0;
        err_count = 0;

        for (i = 0; i < `PATTERN_NUM; i = i + 1) begin
            // Đọc 11 giá trị từ file (xin, w0..w6, expected_sum, expected_sum1, bit_width)
            $fscanf(fd, "%d %d %d %d %d %d %d %d %d %d %d\n",
                xin_8, w0, w1, w2, w3, w4, w5, w6,
                expected_sum, expected_sum1, bit_width);

            // Cấp packed weights
            win_packed = {w6, w5, w4, w3, w2, w1, w0}; 
            
            // Reset hệ thống
            rst = 1; #10; rst = 0;

            // Chờ pipeline đầy (tối thiểu 7 MACs → 9 chu kỳ cho an toàn)
            repeat (9) @(posedge clk);

            // So sánh kết quả
            $display("[INFO] Test %0d: Xin=%0d, Weights={%0d,%0d,%0d,%0d,%0d,%0d,%0d}",
                     i, xin_8, w0, w1, w2, w3, w4, w5, w6);

            if (sum !== expected_sum || sum1 !== expected_sum1) begin
                err_count = err_count + 1;
                $display("[ERROR] Expected: sum=%0d, sum1=%0d not match with Actual: sum=%0d, sum1=%0d",
                         expected_sum, expected_sum1, sum, sum1);
            end else begin
                $display("[INFO] Expected: sum=%0d, sum1=%0d is matching with Actual: sum=%0d, sum1=%0d",
                         expected_sum, expected_sum1, sum, sum1);
            end

            $display("-----------------------------");
        end

        $display("Test done. Total errors: %d", err_count);
        $fclose(fd);
        #10 $finish;
    end

    initial begin
        $dumpfile("pe_int8_tb.vcd");
        $dumpvars(0, pe_int8_tb);
    end

endmodule