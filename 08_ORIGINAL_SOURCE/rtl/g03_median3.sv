module g03_median3 #(
    parameter int W = 8
) (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       valid_in,
    input  logic [W-1:0] sample_in,
    output logic       valid_out,
    output logic [W-1:0] median_out
);

    logic [W-1:0] hist0_q;
    logic [W-1:0] hist1_q;
    logic [1:0] count_q;

    logic [W-1:0] a,b,c;
    logic [W-1:0] lo1,hi1,lo2,hi2,lo3,med3;

    // Compare-exchange stage 1: a,b
    assign lo1 = (a <= b) ? a : b;
    assign hi1 = (a <= b) ? b : a;

    // Compare-exchange stage 2: hi1,c
    assign lo2 = (hi1 <= c) ? hi1 : c;
    assign hi2 = (hi1 <= c) ? c : hi1;

    // Compare-exchange stage 3: lo1,lo2
    assign lo3 = (lo1 <= lo2) ? lo1 : lo2;
    assign med3 = (lo1 <= lo2) ? lo2 : lo1;

    assign a = hist0_q;
    assign b = hist1_q;
    assign c = sample_in;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            hist0_q <= '0;
            hist1_q <= '0;
            count_q <= 2'd0;
            valid_out <= 1'b0;
            median_out <= '0;
        end else begin
            valid_out <= 1'b0;

            if (valid_in) begin
                hist0_q <= hist1_q;
                hist1_q <= sample_in;

                if (count_q < 2'd2)
                    count_q <= count_q + 2'd1;

                if (count_q >= 2'd1) begin
                    valid_out <= 1'b1;
                    median_out <= med3;
                end
            end
        end
    end

endmodule
