`timescale 1ns/1ps
`define PATTERN_FILE "C:/Users/AD/Thesis_ECG/thesis_ver_07/database/relu_test_patterns.txt"
`define NUM_PATTERNS 30

module relu_tb;

    localparam WIDTH = 32;

    reg clk, rst, S2;
    reg signed [WIDTH-1:0] sum, sum1;
    reg signed [WIDTH-1:0] expected_output;
    wire signed [WIDTH-1:0] relu_out;

    integer fd, i, err_count, ret;
    reg stop_test;

    // Instantiate ReLU DUT
    ReLU #(.WIDTH(WIDTH)) dut (
        .clk(clk),
        .rst(rst),
        .sum(sum),
        .sum1(sum1),
        .S2(S2),
        .relu_out(relu_out)
    );

    // Clock 100MHz
    always #5 clk = ~clk;

    initial begin
        // Init signals
        clk = 0;
        rst = 1;
        err_count = 0;
        stop_test = 0;
        #10 rst = 0;

        // Open file
        fd = $fopen(`PATTERN_FILE, "r");
        if (fd == 0) begin
            $display("[FATAL] Cannot open pattern file: %s", `PATTERN_FILE);
            $finish;
        end

        // Main pattern loop
        for (i = 0; i < `NUM_PATTERNS && !stop_test; i = i + 1) begin
            ret = $fscanf(fd, "%d %d %d %d\n", sum, sum1, S2, expected_output);
            if (ret != 4) begin
                $display("[ERROR] fscanf failed at i=%0d (only read %0d items).", i, ret);
                stop_test = 1;
            end else begin
                @(posedge clk);  // cycle 1: apply inputs
                @(posedge clk);  // cycle 2: reg_1x1 stores value
                @(posedge clk);  // cycle 3: relu_out ready

                $display("Test %0d: sum=%0d, sum1=%0d, S2=%b", i, sum, sum1, S2);

                if (relu_out !== expected_output) begin
                    err_count = err_count + 1;
                    $display("[ERROR] Expected=%0d but got Actual=%0d", expected_output, relu_out);
                end else begin
                    $display("[INFO] Expected=%0d and Actual=%0d", expected_output, relu_out);
                end
            end
        end

        $fclose(fd);
        $display("Test completed. Total errors: %0d", err_count);
        repeat (10) @(posedge clk);  // chờ thêm vài xung để đảm bảo wave ổn định
        $finish;
    end

    // Waveform dump
    initial begin
        $dumpfile("relu_tb.vcd");
        $dumpvars(0, relu_tb);
    end

endmodule