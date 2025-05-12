`timescale 1ns/1ps

`define PATTERN "C:/Users/AD/Thesis_ECG/thesis_ver_07/database/pe_test_patterns.txt"
`define PATTERN_NUM 10  // Dòng 20-29: 32-bit patterns

module pe_int32_tb;

    localparam N = 32;
    localparam SUM_WIDTH = (N * 2) + 4;

    reg clk, rst;
    reg signed [N-1:0] xin, w0, w1, w2, w3, w4, w5, w6;
    reg signed [SUM_WIDTH-1:0] expected_sum, expected_sum1;
    reg signed [N*7-1:0] win_packed;

    wire signed [SUM_WIDTH-1:0] sum, sum1;
    wire signed [N-1:0] xout;

    integer i, fd, err_count = 0;
    integer bit_width;

    // Instantiate DUT
    PE #(.n(N), .SUM_WIDTH(SUM_WIDTH)) DUT (
        .clk(clk),
        .rst(rst),
        .xin(xin),
        .win(win_packed),
        .sum(sum),
        .sum1(sum1),
        .xout(xout)
    );

    // Clock 100MHz
    always #5 clk = ~clk;

    initial begin
        fd = $fopen(`PATTERN, "r");
        if (fd == 0) begin
            $display("ERROR: Cannot open pattern file.");
            $finish;
        end

        clk = 0;
        rst = 0;
        err_count = 0;

        // Skip 20 lines: 10 for 8-bit + 10 for 16-bit
        for (i = 0; i < 20; i = i + 1)
            $fscanf(fd, "%*d %*d %*d %*d %*d %*d %*d %*d %*d %*d %*d\n");

        // Read and test 10 patterns (lines 20-29)
        for (i = 0; i < `PATTERN_NUM; i = i + 1) begin
            $fscanf(fd, "%d %d %d %d %d %d %d %d %d %d %d\n",
                    xin, w0, w1, w2, w3, w4, w5, w6,
                    expected_sum, expected_sum1, bit_width);

            rst = 1; #10; rst = 0;
            win_packed = {w6, w5, w4, w3, w2, w1, w0};

            repeat (9) @(posedge clk);

            $display("[INFO] Test %0d (bit-width=%0d)", i + 20, bit_width);
            $display("       Xin=%0d, Weights={%0d,%0d,%0d,%0d,%0d,%0d,%0d}",
                     xin, w0, w1, w2, w3, w4, w5, w6);

            if (sum !== expected_sum || sum1 !== expected_sum1) begin
                err_count = err_count + 1;
                $display("[ERROR] Expected: sum=%0d, sum1=%0d not match with Actual: sum=%0d, sum1=%0d",
                         expected_sum, expected_sum1, sum, sum1);
            end else begin
                $display("[INFO] Expected: sum=%0d, sum1=%0d is matching with Actual: sum=%0d, sum1=%0d",
                         expected_sum, expected_sum1, sum, sum1);
            end

            $display("----------------------------");
        end

        $display("Test done. Total errors: %0d", err_count);
        $fclose(fd);
        #10 $finish;
    end

    initial begin
        $dumpfile("pe_int32_tb.vcd");
        $dumpvars(0, pe_int32_tb);
    end

endmodule