module prim_multiplier_8x8(
    input  logic [7:0]  i_a,
    input  logic [7:0]  i_b,
    output logic [15:0] o_product
);


logic [7:0]  p0;        // Partial Product 1: A[3:0] x  B[3:0]
logic [7:0]  p1;        // Partial Product 2: A[7:4] x  B[3:0]
logic [7:0]  p2;        // Partial Product 3: A[3:0] x  B[7:4]
logic [7:0]  p3;        // Partial Product 4: A[7:4] x  B[7:4]

logic [7:0]  s1;     // Partial Sum 1: p0 + p1
logic [15:0] s2;     // Partial Sum 2: p2 + p3
logic [15:0] s3;     // Partial Sum 3: [Partial Sum 1] + [Partial Sum 2]

prim_multiplier_4x4  P1_cal (.i_a(i_a[3:0]), .i_b(i_b[3:0]), .o_product(p0) );
prim_multiplier_4x4  P2_cal (.i_a(i_a[7:4]), .i_b(i_b[3:0]), .o_product(p1) );
prim_multiplier_4x4  P3_cal (.i_a(i_a[3:0]), .i_b(i_b[7:4]), .o_product(p2) );
prim_multiplier_4x4  P4_cal (.i_a(i_a[7:4]), .i_b(i_b[7:4]), .o_product(p3) );


prim_adder_8bit   Add_low (
    .i_a   (p1               ),
    .i_b   ({4'h0, p0[7:4]}  ),
    .i_sub (1'b0             ),
    .o_sum (s1               ),
    .o_cout()
);

prim_adder_16bit  Add_high (
    .i_a   ({4'h0,  p3, 4'h0}  ),
    .i_b   ({8'h00, p2}        ),
    .i_sub (1'b0               ),
    .o_sum (s2                 ),
    .o_cout()
);

prim_adder_16bit  Combine (
    .i_a   (s2           ),
    .i_b   ({8'h00, s1}  ),
    .i_sub (1'b0         ),
    .o_sum (s3           ),
    .o_cout()
);

// Output
assign o_product[3:0]  = p0[3:0];
assign o_product[15:4] = s3[11:0];



endmodule : prim_multiplier_8x8


