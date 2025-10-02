module prim_multiplier_16x16(
    input  logic [15:0] i_a,
    input  logic [15:0] i_b,
    output logic [31:0] o_product
);

// Partial Products
logic [15:0] p0;     // A[7:0]   × B[7:0]
logic [15:0] p1;     // A[15:8]  × B[7:0]
logic [15:0] p2;     // A[7:0]   × B[15:8]
logic [15:0] p3;     // A[15:8]  × B[15:8]

logic [15:0] s1;     // Sum of shifted p0[15:8] and p1
logic [31:0] s2;     // Sum of shifted p2 and p3
logic [31:0] s3;     // Final product high bits

prim_multiplier_8x8  P1_calc (.i_a(i_a[7:0] ),  .i_b(i_b[7:0]),   .o_product(p0) );
prim_multiplier_8x8  P2_calc (.i_a(i_a[15:8]),  .i_b(i_b[7:0]),   .o_product(p1) );
prim_multiplier_8x8  P3_calc (.i_a(i_a[7:0] ),  .i_b(i_b[15:8]),  .o_product(p2) );
prim_multiplier_8x8  P4_calc (.i_a(i_a[15:8]),  .i_b(i_b[15:8]),  .o_product(p3) );

prim_adder_16bit     Add_low (
    .i_a    (p1                ),
    .i_b    ({8'h00, p0[15:8]} ),
    .i_sub  (1'b0              ),
    .o_sum  (s1                ),
    .o_cout (                  )
);


// Partial Products for B[15:8]

prim_adder_32bit     Add_high (
    .i_a    ({8'h00, p3, 8'h00} ),
    .i_b    ({16'h0000, p2}     ),
    .i_sub  (1'b0               ),
    .o_sum  (s2                 ),
    .o_cout (                   )
);


// Final combination
prim_adder_32bit     Combine (
    .i_a    (s2              ),
    .i_b    ({16'h0000, s1}  ),
    .i_sub  (1'b0            ),
    .o_sum  (s3              ),
    .o_cout ()
);


// Output assignment
assign o_product[7:0]   = p0[7:0];
assign o_product[31:8]  = s3[23:0];


endmodule : prim_multiplier_16x16
