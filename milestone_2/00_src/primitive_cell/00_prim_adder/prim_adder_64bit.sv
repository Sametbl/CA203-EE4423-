module prim_adder_64bit(
    input  logic [63:0] i_a,
    input  logic [63:0] i_b,
    input  logic        i_sub,
    output logic [63:0] o_sum,
    output logic        o_cout
);

prim_carry_lookahead_adder #(.WIDTH(64)) Adder(
    .i_a   (i_a)   ,
    .i_b   (i_b)   ,
    .i_sub (i_sub) ,
    .o_sum (o_sum) ,
    .o_cout(o_cout)
);



endmodule : prim_adder_64bit
