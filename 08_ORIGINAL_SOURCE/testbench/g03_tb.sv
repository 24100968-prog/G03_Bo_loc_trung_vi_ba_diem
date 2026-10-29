module g03_tb;
    logic clk,rst_n,valid_in;
    logic [7:0] sample_in;
    logic valid_out;
    logic [7:0] median_out;

    g03_median3 dut(
        .clk(clk), .rst_n(rst_n), .valid_in(valid_in),
        .sample_in(sample_in), .valid_out(valid_out),
        .median_out(median_out)
    );

    always #5 clk=~clk;

    task automatic send(input logic [7:0] x,
                        input logic exp_valid,
                        input logic [7:0] exp_y);
        begin
            sample_in=x;
            valid_in=1'b1;
            @(posedge clk); #1;
            assert(valid_out==exp_valid)
                else $fatal(1,"valid mismatch x=%0d",x);
            if (exp_valid)
                assert(median_out==exp_y)
                    else $fatal(1,"median mismatch got=%0d expected=%0d",
                                median_out,exp_y);
            valid_in=1'b0;
        end
    endtask

    initial begin
        clk=0; rst_n=0; valid_in=0; sample_in=0;
        repeat(2) @(posedge clk);
        rst_n=1;

        // Warm-up.
        send(10,0,0);
        send(11,0,0);
        send(250,1,11);

        // Permutation.
        send(3,1,11); // window 11,250,3 -> 11
        send(1,1,3);  // window 250,3,1 -> 3
        send(2,1,2);  // window 3,1,2 -> 2

        // Ties.
        send(2,1,2);
        send(9,1,2);
        send(2,1,2);

        // valid gap.
        valid_in=0;
        @(posedge clk); #1;
        assert(!valid_out) else $fatal(1,"gap generated output");

        // Boundary.
        send(0,1,2);
        send(255,1,2);
        send(128,1,128);

        $display("G03 TB completed");
        $finish;
    end
endmodule
