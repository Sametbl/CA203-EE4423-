module prim_full_adder (
    input  logic  i_a   ,    // 1-bit input a
    input  logic  i_b   ,    // 1-bit input b
    input  logic  i_cin ,    // Carry-in
    output logic  o_sum ,    // sum output
    output logic  o_cout     // Carry-out
);

assign o_sum  = i_a ^ i_b ^ i_cin;                           // sum = a ⊕ b ⊕ cin
assign o_cout = (i_a & i_b) | (i_a & i_cin) | (i_b & i_cin); // Carry-out logic

endmodule : prim_full_adder
