`timescale 1ns/1ps

`define PATTERN "C:/Users/AD/Thesis_ECG/thesis_ver_07/database/mac_int_test_patterns.txt"
`define PATTERN_NUM 10

module mac_unit_int8_tb;

    localparam N = 8;
    localparam SUM_WIDTH = (N * 2) + 4;

    reg clk, rst;
    reg signed [N-1:0] xin_8, win_8;
    reg signed [SUM_WIDTH-1:0] acc_in_8;

    wire signed [SUM_WIDTH-1:0] mac_out_8;
    wire signed [N-1:0] xout_8;

    reg signed [SUM_WIDTH-1:0] expected;
    integer i, fd, err_count = 0;
    integer bit_width;

    // Instantiate MAC Unit
    mac_unit #(.n(N), .SUM_WIDTH(SUM_WIDTH)) DUT (
        .clk(clk),
        .rst(rst),
        .xin(xin_8),
        .win(win_8),
        .acc_in(acc_in_8),
        .mac_out(mac_out_8),
        .xout(xout_8)
    );

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
            $fscanf(fd, "%d %d %d %d %d\n", xin_8, win_8, acc_in_8, expected, bit_width);

            #10;

            $display("[INFO] Test %0d: Xin=%0d, Win=%0d, ACC_IN=%0d, Mode=8", i, xin_8, win_8, acc_in_8);

            if (mac_out_8 !== expected) begin
                err_count = err_count + 1;
                $display("[ERROR] Mismatch! Expected=%0d but actual=%0d", expected, mac_out_8);
            end else begin
                $display("[INFO] Passed. Expected=%0d with actual=%0d", expected, mac_out_8);
            end

            $display("----------------------------");
        end

        $display("Test done. Total errors: %d", err_count);
        $fclose(fd);
        #10 $finish;
    end

    initial begin
        $dumpfile("mac_unit_int8_tb.vcd");
        $dumpvars(0, mac_unit_int8_tb);
    end

endmodule