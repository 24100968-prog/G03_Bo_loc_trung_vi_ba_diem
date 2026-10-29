`ifdef G03_SVA

// Enable only after freezing exact cycle alignment from the official specification.
assert_valid_requires_input:
    assert property (@(posedge clk)
        valid_out |-> $past(valid_in));

`endif
