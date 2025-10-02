// module prim_multiplier_64x64(
//     input  logic [63:0]  i_a,
//     input  logic [63:0]  i_b,
//     output logic [127:0] o_product
// );

// // Partial Products
// logic [63:0]  p0;     // A[31:0]  × B[31:0]
// logic [63:0]  p1;     // A[63:32] × B[31:0]
// logic [63:0]  p2;     // A[31:0]  × B[63:32]
// logic [63:0]  p3;     // A[63:32] × B[63:32]

// logic [63:0]  s1;     // Sum of shifted p0[63:32] and p1
// logic [127:0] s2;     // Sum of shifted p2 and p3
// logic [127:0] s3;     // Final product high bits

// prim_multiplier_32x32  P1_calc (.i_a(i_a[31:0]),   .i_b(i_b[31:0]),   .o_product(p0) );
// prim_multiplier_32x32  P2_calc (.i_a(i_a[63:32]),  .i_b(i_b[31:0]),   .o_product(p1) );
// prim_multiplier_32x32  P3_calc (.i_a(i_a[31:0]),   .i_b(i_b[63:32]),  .o_product(p2) );
// prim_multiplier_32x32  P4_calc (.i_a(i_a[63:32]),  .i_b(i_b[63:32]),  .o_product(p3) );

// prim_adder_64bit       Add_low (
//     .i_a    (p1                 ),
//     .i_b    ({32'b0, p0[63:32]} ),
//     .i_sub  (1'b0               ),
//     .o_sum  (s1                 ),
//     .o_cout (                   )
// );


// prim_adder_128bit      Add_high (
//     .i_a    ({32'b0, p3, 32'b0} ),
//     .i_b    ({64'b0, p2}        ),
//     .i_sub  (1'b0               ),
//     .o_sum  (s2                 ),
//     .o_cout (                   )
// );


// prim_adder_128bit      Combine (
//     .i_a    (s2           ),
//     .i_b    ({64'b0, s1}  ),
//     .i_sub  (1'b0         ),
//     .o_sum  (s3           ),
//     .o_cout ()
// );


// // Output assignment
// assign o_product[31:0]   = p0[31:0];
// assign o_product[127:32] = s3[95:0];


// endmodule : prim_multiplier_64x64

