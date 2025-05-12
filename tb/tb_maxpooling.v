`timescale 1ns/1ps
`define PATTERN_FILE "C:/Users/AD/Thesis_ECG/thesis_ver_07/database/maxpool_test_patterns.txt"
`define NUM_PATTERNS 30

module maxpooling_tb;

    localparam WIDTH = 32;

    reg clk, rst, S3;
    reg signed [WIDTH-1:0] din;
    wire signed [WIDTH-1:0] dout;

    integer fd, i, ret;
    integer err_count = 0;
    reg signed [WIDTH-1:0] expected_output;

    // Input values read from file (applied over 3 clock cycles)
    reg signed [WIDTH-1:0] r1_val, r2_val, r3_val;

    // Instantiate DUT
    MaxPooling #(.WIDTH(WIDTH)) dut (
        .clk(clk),
        .rst(rst),
        .data_in(din),
        .S3(S3),
        .data_out(dout)
    );

    // Clock
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1; #10; rst = 0;

        fd = $fopen(`PATTERN_FILE, "r");
        if (fd == 0) begin
            $display("[FATAL] Cannot open pattern file.");
            $finish;
        end

        for (i = 0; i < `NUM_PATTERNS; i = i + 1) begin
            ret = $fscanf(fd, "%d %d %d %d %d\n", r1_val, r2_val, r3_val, S3, expected_output);
            if (ret != 5) begin
                $display("[ERROR] Pattern line %0d malformed (ret = %0d)", i, ret);
                $finish;
            end

            // Apply inputs in reverse order due to register pipeline
            @(posedge clk); din = r3_val;
            @(posedge clk); din = r2_val;
            @(posedge clk); din = r1_val;

            @(posedge clk); // wait one extra cycle for pipeline to settle

            $display("Test %0d: Inputs={%0d, %0d, %0d}, S3=%d", 
                i, r1_val, r2_val, r3_val, S3);

            if (dout !== expected_output) begin
                $display("[ERROR] Expected=%0d and Actual=%0d ==> Mismactch", expected_output, dout);
                err_count = err_count + 1;
            end
            else begin
                $display("[INFO] Expected=%0d and Actual=%0d ==> Matching", expected_output, dout);
            end 
        end

        $fclose(fd);
        $display("Test completed. Total errors: %0d", err_count);
        repeat (5) @(posedge clk);
        $finish;
    end

    initial begin
        $dumpfile("maxpooling_tb.vcd");
        $dumpvars(0, maxpooling_tb);
    end

endmodule
