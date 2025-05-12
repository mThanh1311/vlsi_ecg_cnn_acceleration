`timescale 1ns/1ps

`define PATTERN_FILE "C:/Users/AD/Thesis_ECG/thesis_ver_07/database/control_buffer_pattern.txt"
`define RESULT_FILE "C:/Users/AD/Thesis_ECG/thesis_ver_07/database/control_buffer_results.txt"
`define NUM_PATTERNS 100

module control_buffer_tb;
    localparam WIDTH = 32;

    reg clk, rst;
    reg signed [WIDTH-1:0] data_in;
    reg [1:0] S5, S6;
    wire signed [WIDTH-1:0] data_out;

    integer fd_in, fd_out, i;
    integer err_count = 0;
    integer j;

    reg signed [WIDTH-1:0] pipe[0:53];

    reg signed [WIDTH-1:0] data_queue[0:99];
    reg [1:0] S5_queue[0:99], S6_queue[0:99];
    integer delay_queue[0:99];
    integer q_head = 0, q_tail = 0;

    reg signed [WIDTH-1:0] expected_out;
    integer local_delay;

    ControlBuffer #(.WIDTH(WIDTH)) dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .S5(S5),
        .S6(S6),
        .data_out(data_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        data_in = 0;
        S5 = 0; S6 = 0;

        for (i = 0; i < 54; i = i + 1)
            pipe[i] = 0;
        for (i = 0; i < 100; i = i + 1) begin
            data_queue[i] = 0;
            S5_queue[i] = 0;
            S6_queue[i] = 0;
            delay_queue[i] = -1;
        end

        #15 rst = 0;

        fd_in = $fopen(`PATTERN_FILE, "r");
        fd_out = $fopen(`RESULT_FILE, "w");

        if (fd_in == 0) begin
            $display("[ERROR] Cannot open pattern file!");
            $finish;
        end

        for (i = 0; i < `NUM_PATTERNS; i = i + 1) begin
            @(negedge clk);
            if ($fscanf(fd_in, "%d %b %b\n", data_in, S5, S6) != 3) begin
                $display("[ERROR] Unexpected EOF at pattern %0d", i);
                $finish;
            end

            for (j = 53; j > 0; j = j - 1)
                pipe[j] = pipe[j-1];
            pipe[0] = data_in;

            // Store current values into queue
            data_queue[q_tail] = data_in;
            S5_queue[q_tail] = S5;
            S6_queue[q_tail] = S6;

            case (S6)
                2'b00: begin
                    case (S5)
                        2'b00: local_delay = 21;
                        2'b01: local_delay = 36;
                        2'b10: local_delay = 54;
                        default: local_delay = 1;
                    endcase
                end
                2'b01: local_delay = 6;
                2'b10: local_delay = 18;
                2'b11: local_delay = 21;
                default: local_delay = 1;
            endcase

            delay_queue[q_tail] = local_delay;
            q_tail = (q_tail + 1) % 100;

            @(posedge clk); #1;

            if (delay_queue[q_head] > 0)
                delay_queue[q_head] = delay_queue[q_head] - 1;

            if (delay_queue[q_head] == 0 && i >= 54) begin
                case (S6_queue[q_head])
                    2'b00: begin
                        case (S5_queue[q_head])
                            2'b00: expected_out = pipe[20];
                            2'b01: expected_out = pipe[35];
                            2'b10: expected_out = pipe[53];
                            default: expected_out = 0;
                        endcase
                    end
                    2'b01: expected_out = pipe[5];
                    2'b10: expected_out = pipe[17];
                    2'b11: expected_out = pipe[20];
                    default: expected_out = 0;
                endcase

                if (data_out !== expected_out) begin
                    $display("[FAIL] Pattern %0d: data_out=%0d, expected=%0d", i, data_out, expected_out);
                    $display("        --> Delay=%0d, pipe20=%0d, pipe35=%0d, pipe53=%0d, S5=%b, S6=%b",
                             delay_queue[q_head], pipe[20], pipe[35], pipe[53], S5_queue[q_head], S6_queue[q_head]);
                    err_count = err_count + 1;
                end else begin
                    $display("[PASS] Pattern %0d: data_out=%0d", i, data_out);
                end
                delay_queue[q_head] = -1;
                q_head = (q_head + 1) % 100;
            end

            $fwrite(fd_out, "%d\n", data_out);
        end

        $fclose(fd_in);
        $fclose(fd_out);

        $display("[DONE] Simulation finished. Total errors: %0d", err_count);
        #10 $finish;
    end

    initial begin
        $dumpfile("control_buffer_tb.vcd");
        $dumpvars(0, control_buffer_tb);
    end
endmodule
