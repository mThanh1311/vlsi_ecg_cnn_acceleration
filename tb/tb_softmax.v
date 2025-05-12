`timescale 1ns/1ps

`define PATTERN_FILE "C:/Users/AD/Thesis_ECG/thesis_ver_07/database/softmax_test_patterns.txt"
`define NUM_NODES 6
`define SUM_PER_NODE 3
`define NUM_TESTS 190

module softmax_tb;
    localparam WIDTH = 32;

    reg clk, rst;
    reg accumulate_en, store_en;
    reg signed [WIDTH-1:0] sum;
    wire signed [WIDTH-1:0] detection_out;

    integer fd, t, i, j, idx;
    integer err_count = 0;
    reg signed [WIDTH-1:0] expected_output;
    reg signed [WIDTH-1:0] sum_val;
    reg signed [WIDTH-1:0] all_inputs [0:17];

    // DUT
    Softmax #(.WIDTH(WIDTH)) dut (
        .clk(clk),
        .rst(rst),
        .sum(sum),
        .accumulate_en(accumulate_en),
        .store_en(store_en),
        .detection_out(detection_out)
    );

    // Clock
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1; accumulate_en = 0; store_en = 0; sum = 0;
        #12 rst = 0;

        fd = $fopen(`PATTERN_FILE, "r");
        if (fd == 0) begin
            $display("[ERROR] Cannot open pattern file!");
            $finish;
        end

        for (t = 0; t < `NUM_TESTS; t = t + 1) begin
            $display("========== Test %0d ==========", t);

            // Reset DUT trước mỗi test
            rst = 1;
            @(posedge clk);
            rst = 0;
            @(posedge clk);

            idx = 0;

            for (i = 0; i < `NUM_NODES; i = i + 1) begin
                for (j = 0; j < `SUM_PER_NODE; j = j + 1) begin
                    if ($fscanf(fd, "%d\n", sum_val) != 1) begin
                        $display("[ERROR] Unexpected EOF when reading sum at test %0d", t);
                        $finish;
                    end
                    sum = sum_val;
                    all_inputs[idx] = sum_val;  // save input
                    idx = idx + 1;
                    @(posedge clk);
                    accumulate_en = 1;
                    @(posedge clk);
                    accumulate_en = 0;
                    sum = 0;
                end

                @(posedge clk);
                store_en = 1;
                @(posedge clk);
                store_en = 0;
            end

            if ($fscanf(fd, "%d\n", expected_output) != 1) begin
                $display("[ERROR] Unexpected EOF when reading expected_output at test %0d", t);
                $finish;
            end

            repeat (3) @(posedge clk); // Đợi detection_out ổn định

            // Display all inputs
            $display("  [Input sums per node]");
            for (i = 0; i < `NUM_NODES; i = i + 1) begin
                $display("    Node %0d: %0d + %0d + %0d",
                         i,
                         all_inputs[i*3 + 0],
                         all_inputs[i*3 + 1],
                         all_inputs[i*3 + 2]);
            end

            $display("  => detection_out = %0d", detection_out);
            $display("  => expected_output = %0d", expected_output);

            if (detection_out !== expected_output) begin
                $display("[ERROR] Expected=%0d != Actual=%0d", expected_output, detection_out);
                err_count = err_count + 1;
            end else begin
                $display("[PASS] Expected=%0d == Actual=%0d", expected_output, detection_out);
            end
        end

        $fclose(fd);
        $display("Test done. Total errors: %0d", err_count);
        #10 $finish;
    end

    initial begin
        $dumpfile("softmax_tb.vcd");
        $dumpvars(0, softmax_tb);
    end

endmodule