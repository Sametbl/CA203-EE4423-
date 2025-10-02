module prim_multiplier_32x32(
    input  logic [31:0] i_a,
    input  logic [31:0] i_b,
    output logic [63:0] o_product
);


// Partial Products
logic [31:0] p0;     // A[15:0]  × B[15:0]
logic [31:0] p1;     // A[31:16] × B[15:0]
logic [31:0] p2;     // A[15:0]  × B[31:16]
logic [31:0] p3;     // A[31:16] × B[31:16]

logic [63:0] s1;     // Sum of (p1 << 16) and (p2 << 16)
logic [63:0] s2;     // Sum of s1 and (p3 << 32)
logic [63:0] s3;     // Final product high bits

prim_multiplier_16x16  P1_calc (.i_a(i_a[15:0] ),  .i_b(i_b[15:0]),   .o_product(p0) );
prim_multiplier_16x16  P2_calc (.i_a(i_a[31:16]),  .i_b(i_b[15:0]),   .o_product(p1) );
prim_multiplier_16x16  P3_calc (.i_a(i_a[15:0] ),  .i_b(i_b[31:16]),  .o_product(p2) );
prim_multiplier_16x16  P4_calc (.i_a(i_a[31:16]),  .i_b(i_b[31:16]),  .o_product(p3) );


// Add (p1 << 16) + (p2 << 16)
prim_adder_64bit       Add_low (
    .i_a    ({16'h0000, p1, 16'h0000} ),
    .i_b    ({16'h0000, p2, 16'h0000} ),
    .i_sub  (1'b0                     ),
    .o_sum  (s1                       ),
    .o_cout (                         )
);


// Add s1 + (p3 << 32)
prim_adder_64bit       Add_high (
    .i_a    (s1               ),
    .i_b    ({p3, 32'h0000}   ),
    .i_sub  (1'b0             ),
    .o_sum  (s2               ),
    .o_cout (                 )
);


// Add s2 + p0[15:0]
prim_adder_64bit       Combine (
    .i_a    (s2                             ),
    .i_b    ({48'h0000_0000_0000, p0[15:0]} ),
    .i_sub  (1'b0                           ),
    .o_sum  (s3                             ),
    .o_cout (                               )
);


// Output assignment
assign o_product = s3;


endmodule : prim_multiplier_32x32
