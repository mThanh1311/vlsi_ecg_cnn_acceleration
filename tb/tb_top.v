`timescale 1ns/1ps

module ECG_Top_tb;
    parameter N = 16;
    parameter SUM_WIDTH = (N*2)+4;

    reg clk, rst, start;
    reg signed [N-1:0] xin, win;
    wire signed [N-1:0] detection_out;
    wire done;

    wire signed [SUM_WIDTH-1:0] sum, sum1;
    wire signed [SUM_WIDTH-1:0] relu_out, pool_out, ctrl_out;
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

    // Clock generation
    always #5 clk = ~clk;

    integer i;

    initial begin
        // Init
        clk = 0;
        rst = 1;
        start = 0;
        xin = 0;
        win = 0;

        // Hold reset
        #20;
        rst = 0;

        // Trigger start
        #10;
        start = 1;
        #10;
        start = 0;

        // Feed xin/win only during CONV1/2/3
        i = 0;
        while (!done) begin
            @(negedge clk);
            if (state == 4'd1 || state == 4'd3 || state == 4'd4) begin // CONV1, CONV2, CONV3
                xin = i * 10;
                win = 2;
                i = i + 1;
            end else begin
                xin = 0;
                win = 0;
            end
        end

        // Print final output
        @(posedge clk);
        $display("[RESULT] Detection output: %0d", detection_out);
        #20;
        $finish;
    end

    // Debug every cycle
    always @(posedge clk) begin
        $display("t=%0t | state=%0d | xin=%0d | win=%0d | sum=%0d | sum1=%0d | relu=%0d | pool=%0d | ctrl=%0d | detect_out=%0d",
                 $time, state, xin, win, sum, sum1, relu_out, pool_out, ctrl_out, detection_out);
    end

    // Waveform dump
    initial begin
        $dumpfile("ecg_top_tb.vcd");
        $dumpvars(0, ECG_Top_tb);
    end

endmodule