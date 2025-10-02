
// Primitive Cell: Counter number of leading Zero (# of bit-0 before the first bit-1)

module prim_leading_zero_counter_32bit(
    input  logic [31:0] i_data,
    output logic [4:0]  o_nlz,       // Number of leading zero (0 to 31)
    output logic        o_all_zero   // High if all 32-bit are bit-0
);

logic [7:0] a;   // Indicate whether if each section full of zeros
logic [1:0] z0;  // Number of zero for each 4-bit section ([31:28])
logic [1:0] z1;  // Number of zero for each 4-bit section ([27:24])
logic [1:0] z2;  // Number of zero for each 4-bit section ([23:20])
logic [1:0] z3;  // Number of zero for each 4-bit section ([19:16])
logic [1:0] z4;  // Number of zero for each 4-bit section ([15:12])
logic [1:0] z5;  // Number of zero for each 4-bit section ([11:8] )
logic [1:0] z6;  // Number of zero for each 4-bit section ([7:4]  )
logic [1:0] z7;  // Number of zero for each 4-bit section ([3:0]  )

logic [4:0] NLZ; // Number of Leading Zero
logic       all_zero;

nlc_4bit    NLC_7 (.i_X(i_data[31:28]), .o_zero(z7), .o_all_zero(a[7]) );
nlc_4bit    NLC_6 (.i_X(i_data[27:24]), .o_zero(z6), .o_all_zero(a[6]) );
nlc_4bit    NLC_5 (.i_X(i_data[23:20]), .o_zero(z5), .o_all_zero(a[5]) );
nlc_4bit    NLC_4 (.i_X(i_data[19:16]), .o_zero(z4), .o_all_zero(a[4]) );
nlc_4bit    NLC_3 (.i_X(i_data[15:12]), .o_zero(z3), .o_all_zero(a[3]) );
nlc_4bit    NLC_2 (.i_X(i_data[11:8] ), .o_zero(z2), .o_all_zero(a[2]) );
nlc_4bit    NLC_1 (.i_X(i_data[7:4]  ), .o_zero(z1), .o_all_zero(a[1]) );
nlc_4bit    NLC_0 (.i_X(i_data[3:0]  ), .o_zero(z0), .o_all_zero(a[0]) );

// Check if all 4-bit local section for zeros
bne   Boundary_Nibble_Encoder (.i_a(a), .o_y(NLZ[4:2]), .o_all_zero(all_zero) );

prim_mux_8x1 #(.WIDTH(1))  bit0_NLZ (
    .i_sel(NLZ[4:2]),
    .i_0  (z7[0]   ),
    .i_1  (z6[0]   ),
    .i_2  (z5[0]   ),
    .i_3  (z4[0]   ),
    .i_4  (z3[0]   ),
    .i_5  (z2[0]   ),
    .i_6  (z1[0]   ),
    .i_7  (z0[0]   ),
    .o_mux(NLZ[0]  )   // NLZ = NLZ + 1
);
prim_mux_8x1 #(.WIDTH(1))  bit1_NLZ (
    .i_sel(NLZ[4:2]),
    .i_0  (z7[1]   ),
    .i_1  (z6[1]   ),
    .i_2  (z5[1]   ),
    .i_3  (z4[1]   ),
    .i_4  (z3[1]   ),
    .i_5  (z2[1]   ),
    .i_6  (z1[1]   ),
    .i_7  (z0[1]   ),
    .o_mux(NLZ[1]  )   // NLZ = NLZ + 2
);


assign o_nlz      = NLZ;
assign o_all_zero = all_zero;


endmodule : prim_leading_zero_counter_32bit


