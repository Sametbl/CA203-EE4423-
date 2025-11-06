module prim_half_adder(
    input  logic i_a   ,
    input  logic i_b   ,
    output logic o_sum ,
    output logic o_cout
);

assign o_sum   = i_a ^ i_b;
assign o_cout  = i_a & i_b;

endmodule: prim_half_adder


