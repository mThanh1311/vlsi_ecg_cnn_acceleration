`timescale 1ns/1ps

module ECG_Top_multi_tb;
    parameter N = 16;
    parameter SUM_WIDTH = (N*2)+4;
    parameter NUM_PATTERNS = 3;
    parameter MAX_INPUTS = 100; // tối đa per pattern

    reg clk, rst, start;
    reg signed [N-1:0] xin, win;
    wire signed [N-1:0] detection_out;
    wire done;

    wire signed [SUM_WIDTH-1:0] sum, sum1, relu_out, pool_out, ctrl_out;
    wire [3:0] state;

    // Instantiate DUT
    ECG_Top #(.N(N), .SUM_WIDTH(SUM_WIDTH)) dut (
        .clk(clk), .rst(rst), .start(start),
        .xin(xin), .win(win),
        .detection_out(detection_out),
        .done(done),
        .sum(sum), .sum1(sum1),
        .relu_out(relu_out),
        .pool_out(pool_out),
        .ctrl_out(ctrl_out),
        .state(state)
    );

    // Clock
    always #5 clk = ~clk;

    // Test pattern storage
    reg signed [N-1:0] xin_pattern[NUM_PATTERNS-1:0][0:MAX_INPUTS-1];
    reg [7:0] xin_len[NUM_PATTERNS-1:0];

    integer i, p;

    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        xin = 0;
        win = 2;

        // Setup test data
        // Pattern 0: tăng dần
        for (i = 0; i < 66; i = i + 1)
            xin_pattern[0][i] = i * 10;
        xin_len[0] = 66;

        // Pattern 1: giảm dần
        for (i = 0; i < 66; i = i + 1)
            xin_pattern[1][i] = 660 - i * 10;
        xin_len[1] = 66;

        // Pattern 2: sóng hình sin (giả lập)
        for (i = 0; i < 66; i = i + 1)
            xin_pattern[2][i] = $rtoi(100.0 * $sin(i * 3.14 / 16.0));
        xin_len[2] = 66;

        // Wait before start
        #20;
        rst = 0;
        #20;

        // Loop through each pattern
        for (p = 0; p < NUM_PATTERNS; p = p + 1) begin
            $display("\n=== PATTERN %0d START ===", p);

            // Reset state
            start = 1;
            #10;
            start = 0;

            i = 0;
            while (!done) begin
                @(negedge clk);
                if (state == 4'd1 || state == 4'd3 || state == 4'd4) begin
                    if (i < xin_len[p]) begin
                        xin = xin_pattern[p][i];
                        i = i + 1;
                    end else begin
                        xin = 0;
                    end
                end else begin
                    xin = 0;
                end
            end

            // Output
            @(posedge clk);
            $display("[PATTERN %0d] DETECTION_OUT = %0d", p, detection_out);

            // Small delay between patterns
            #20;

            // Reset system for next pattern
            rst = 1;
            #20;
            rst = 0;
        end

        $display("\n[TEST] Multi-pattern test done.");
        #20;
        $finish;
    end

    // Debug
    always @(posedge clk) begin
        $display("t=%0t | st=%0d | xin=%0d | sum=%0d | relu=%0d | pool=%0d | ctrl=%0d | out=%0d",
            $time, state, xin, sum, relu_out, pool_out, ctrl_out, detection_out);
    end

    // VCD
    initial begin
        $dumpfile("ecg_top_multi.vcd");
        $dumpvars(0, ECG_Top_multi_tb);
    end

endmodule
