// Boundary Nibble Encoder (bne)
module bne(
    input  logic [7:0] i_a,
    output logic [2:0] o_y,
    output logic       o_all_zero   // All local 4-bit section are zeros
);

wire [7:0] a;
assign a = i_a;

// All_zero: When all four-bit local counter modules are zeros
assign o_all_zero = a[7] & a[6] & a[5] & a[4] & a[3] & a[2] & a[1] & a[0];

// NLZ = NLZ + 16: When first 16 MSB are zero
assign o_y[2] =  a[7] & a[6] & a[5] & a[4];

// NLZ = NLZ + 8:
assign o_y[1] =  a[7] &  a[6] & (~a[5] | ~a[4] | (a[3] & a[2]) );

// NLZ = NLZ + 4:
assign o_y[0] = (a[7] & (~a[6] | (a[5] & ~a[4]))) | (a[7] & a[5] & a[3] & (~a[2] | a[1]));

endmodule : bne

