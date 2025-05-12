`timescale 1ns/1ps

`define PATTERN "C:/Users/AD/Thesis_ECG/thesis_ver_07/database/mac_int_test_patterns.txt"
`define PATTERN_NUM 20  // Dòng 10-19 chứa dữ liệu 16-bit

module mac_unit_int16_tb;

    localparam N = 16;
    localparam SUM_WIDTH = (N * 2) + 4;

    reg clk, rst;
    reg signed [N-1:0] xin_16, win_16;
    reg signed [SUM_WIDTH-1:0] acc_in_16;
    reg signed [SUM_WIDTH-1:0] expected;
    reg [255:0] dummy_line;

    wire signed [SUM_WIDTH-1:0] mac_out_16;
    wire signed [N-1:0] xout_16;

    integer i, fd, err_count = 0;
    integer bit_width;

    mac_unit #(.n(N), .SUM_WIDTH(SUM_WIDTH)) DUT (
        .clk(clk),
        .rst(rst),
        .xin(xin_16),
        .win(win_16),
        .acc_in(acc_in_16),
        .mac_out(mac_out_16),
        .xout(xout_16)
    );

    always #5 clk = ~clk;

    initial begin
        fd = $fopen(`PATTERN, "r");
        if (fd == 0) begin
            $display("ERROR: Cannot open pattern file.");
            $finish;
        end

        clk = 0;
        rst = 1;
        #20 rst = 0;

        err_count = 0;

        // Bỏ qua 10 dòng đầu (8-bit)
        for (i = 0; i < 10; i = i + 1)
            $fgets(dummy_line, fd);

        for (i = 10; i < `PATTERN_NUM; i = i + 1) begin
            $fscanf(fd, "%d %d %d %d %d\n", xin_16, win_16, acc_in_16, expected, bit_width);

            #10;

            $display("[INFO] Test %0d: Xin=%0d, Win=%0d, ACC_IN=%0d, Mode=16", i, xin_16, win_16, acc_in_16);

            if (mac_out_16 !== expected) begin
                err_count = err_count + 1;
                $display("[ERROR] Expected=%0d but actual=%0d", expected, mac_out_16);
            end else begin
                $display("[INFO] Expect=%0d and actual=%0d", expected, mac_out_16);
            end

            $display("----------------------------");
        end

        $display("Done. Total errors: %d", err_count);
        $fclose(fd);
        #10 $finish;
    end

    initial begin
        $dumpfile("mac_unit_int16_tb.vcd");
        $dumpvars(0, mac_unit_int16_tb);
    end

endmodule