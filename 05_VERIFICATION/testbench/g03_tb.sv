`timescale 1ns/1ps

module g03_tb;
    logic clk;
    logic rst_n;
    logic valid_in;
    logic [7:0] sample_in;
    logic valid_out;
    logic [7:0] median_out;

    logic [7:0] ref_hist0;
    logic [7:0] ref_hist1;
    integer accepted_count;
    integer checks;

    g03_median3 dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .sample_in(sample_in),
        .valid_out(valid_out),
        .median_out(median_out)
    );

    always #5 clk = ~clk;

    function automatic [7:0] median3(
        input logic [7:0] x,
        input logic [7:0] y,
        input logic [7:0] z
    );
        logic [7:0] lo1, hi1, lo2;
        begin
            lo1 = (x <= y) ? x : y;
            hi1 = (x <= y) ? y : x;
            lo2 = (hi1 <= z) ? hi1 : z;
            median3 = (lo1 <= lo2) ? lo2 : lo1;
        end
    endfunction

    task automatic reset_dut;
        begin
            @(negedge clk);
            rst_n = 1'b0;
            valid_in = 1'b0;
            sample_in = '0;
            repeat (2) @(posedge clk);
            @(negedge clk);
            rst_n = 1'b1;
            ref_hist0 = '0;
            ref_hist1 = '0;
            accepted_count = 0;
        end
    endtask

    task automatic step(
        input logic enable,
        input logic [7:0] value
    );
        logic expected_valid;
        logic [7:0] expected_median;
        begin
            @(negedge clk);
            valid_in = enable;
            sample_in = value;

            expected_valid = enable && (accepted_count >= 2);
            expected_median = median3(ref_hist0, ref_hist1, value);

            @(posedge clk);
            #1;
            checks = checks + 1;

            if (valid_out !== expected_valid) begin
                $error("valid mismatch: enable=%0b value=%0d count=%0d got=%0b expected=%0b",
                       enable, value, accepted_count, valid_out, expected_valid);
                $fatal(1);
            end

            if (expected_valid && median_out !== expected_median) begin
                $error("median mismatch: value=%0d got=%0d expected=%0d",
                       value, median_out, expected_median);
                $fatal(1);
            end

            if (enable) begin
                ref_hist0 = ref_hist1;
                ref_hist1 = value;
                if (accepted_count < 2)
                    accepted_count = accepted_count + 1;
            end
        end
    endtask

    integer i;
    logic [7:0] random_value;

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        valid_in = 1'b0;
        sample_in = '0;
        ref_hist0 = '0;
        ref_hist1 = '0;
        accepted_count = 0;
        checks = 0;

        reset_dut();

        // Warm-up: output must remain invalid for the first two accepted samples.
        step(1'b1, 8'd10);
        step(1'b1, 8'd11);
        step(1'b1, 8'd250);

        // Descending/ascending permutations and an impulse-like outlier.
        step(1'b1, 8'd3);
        step(1'b1, 8'd1);
        step(1'b1, 8'd2);

        // Equal values and repeated-value corner cases.
        step(1'b1, 8'd2);
        step(1'b1, 8'd9);
        step(1'b1, 8'd2);
        step(1'b1, 8'd2);
        step(1'b1, 8'd2);

        // Invalid gaps must not shift the sample history and must suppress valid_out.
        step(1'b0, 8'd77);
        step(1'b0, 8'd0);
        step(1'b1, 8'd0);
        step(1'b1, 8'd255);
        step(1'b1, 8'd128);

        // Explicit reset while the stream is active must restart the warm-up.
        reset_dut();
        step(1'b1, 8'd200);
        step(1'b1, 8'd4);
        step(1'b1, 8'd99);

        // Deterministic-sequence random stress with intermittent valid gaps.
        for (i = 0; i < 300; i = i + 1) begin
            random_value = $urandom;
            step((i % 7) != 3, random_value);
        end

        $display("G03 TB PASS: %0d checks", checks);
        $finish;
    end
endmodule
