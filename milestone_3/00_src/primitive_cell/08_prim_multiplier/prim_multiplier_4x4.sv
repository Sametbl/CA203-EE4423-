module prim_multiplier_4x4(
    input  logic [3:0] i_a      ,
    input  logic [3:0] i_b      ,
    output logic [7:0] o_product
);

// Partial Product computation
logic [3:0] P0;  // Partial product 0
logic [3:0] P1;  // Partial product 1
logic [3:0] P2;  // Partial product 2
logic [3:0] P3;  // Partial product 3

assign P0[0] = i_b[0] & i_a[0];
assign P0[1] = i_b[0] & i_a[1];
assign P0[2] = i_b[0] & i_a[2];
assign P0[3] = i_b[0] & i_a[3];

assign P1[0] = i_b[1] & i_a[0];
assign P1[1] = i_b[1] & i_a[1];
assign P1[2] = i_b[1] & i_a[2];
assign P1[3] = i_b[1] & i_a[3];

assign P2[0] = i_b[2] & i_a[0];
assign P2[1] = i_b[2] & i_a[1];
assign P2[2] = i_b[2] & i_a[2];
assign P2[3] = i_b[2] & i_a[3];

assign P3[0] = i_b[3] & i_a[0];
assign P3[1] = i_b[3] & i_a[1];
assign P3[2] = i_b[3] & i_a[2];
assign P3[3] = i_b[3] & i_a[3];



//                              A3     A2     A1     A0
//                              B3     B2     B1     B0
//------------------------------------------------------------
//                              P0[3]  P0[2]  P0[1]  P0[0]       ; Row 1
//                       P1[3]  P1[2]  P1[1]  P1[0]              ; Row 2
//                P2[3]  P2[2]  P2[1]  P2[0]                     ; Row 3
//         P3[3]  P3[2]  P3[1]  P3[0]                            ; Row 4
//------------------------------------------------------------
//  C_out   S[6]   S[5]   S[4]   S[3]   S[2]   S[1]   S[0]

//   7      6      5      4      3      2      1       0         ; Column


logic T1_S0; // Stage 1: Sum 0
logic T1_S1; // Stage 1: Sum 1
logic T1_S2; // Stage 1: Sum 2
logic T1_S3; // Stage 1: Sum 3

logic T2_S0; // Stage 2: Sum 0
logic T2_S1; // Stage 2: Sum 1
logic T2_S2; // Stage 2: Sum 2
logic T2_S3; // Stage 2: Sum 3

logic T3_S0; // Stage 3: Sum 0
logic T3_S1; // Stage 3: Sum 1
logic T3_S2; // Stage 3: Sum 2
logic T3_S3; // Stage 3: Sum 3

logic T1_C0; // Stage 1: Carry out 0
logic T1_C1; // Stage 1: Carry out 1
logic T1_C2; // Stage 1: Carry out 2
logic T1_C3; // Stage 1: Carry out 3

logic T2_C0; // Stage 2: Carry out 0
logic T2_C1; // Stage 2: Carry out 1
logic T2_C2; // Stage 2: Carry out 2
logic T2_C3; // Stage 2: Carry out 3

logic T3_C0; // Stage 3: Carry out 0
logic T3_C1; // Stage 3: Carry out 1
logic T3_C2; // Stage 3: Carry out 2
logic T3_C3; // Stage 3: Carry out 3

// Stage 1 (S1): Add the first 2 or 3 PPs
prim_half_adder  a0 (.i_a(P0[1]), .i_b(P1[0]),                .o_sum(T1_S0), .o_cout(T1_C0) );
prim_full_adder  a1 (.i_a(P0[2]), .i_b(P1[1]), .i_cin(P2[0]), .o_sum(T1_S1), .o_cout(T1_C1) );
prim_full_adder  a2 (.i_a(P0[3]), .i_b(P1[2]), .i_cin(P2[1]), .o_sum(T1_S2), .o_cout(T1_C2) );
prim_half_adder  a3 (.i_a(P1[3]), .i_b(P2[2]),                .o_sum(T1_S3), .o_cout(T1_C3) );


// Stage 2 (S2): Continue adding the previous Sum with the next PPs and Carry out
prim_half_adder  b0 (.i_a(T1_C0), .i_b(T1_S1),                .o_sum(T2_S0), .o_cout(T2_C0) );
prim_full_adder  b1 (.i_a(T1_C1), .i_b(T1_S2), .i_cin(P3[0]), .o_sum(T2_S1), .o_cout(T2_C1) );
prim_full_adder  b2 (.i_a(T1_C2), .i_b(T1_S3), .i_cin(P3[1]), .o_sum(T2_S2), .o_cout(T2_C2) );
prim_full_adder  b3 (.i_a(T1_C3), .i_b(P2[3]), .i_cin(P3[2]), .o_sum(T2_S3), .o_cout(T2_C3) );


// Stage 3 (S3): Add the last P3[3] and all they Sum and Carries together
prim_half_adder  c0 (.i_a(T2_C0), .i_b(T2_S1),                .o_sum(T3_S0), .o_cout(T3_C0) );
prim_full_adder  c1 (.i_a(T2_C1), .i_b(T2_S2), .i_cin(T3_C0), .o_sum(T3_S1), .o_cout(T3_C1) );
prim_full_adder  c2 (.i_a(T2_C2), .i_b(T2_S3), .i_cin(T3_C1), .o_sum(T3_S2), .o_cout(T3_C2) );
prim_full_adder  c3 (.i_a(T2_C3), .i_b(P3[3]), .i_cin(T3_C2), .o_sum(T3_S3), .o_cout(T3_C3) );


// Output
assign o_product[0] = P0[0];
assign o_product[1] = T1_S0;
assign o_product[2] = T2_S0;
assign o_product[3] = T3_S0;
assign o_product[4] = T3_S1;
assign o_product[5] = T3_S2;
assign o_product[6] = T3_S3;
assign o_product[7] = T3_C3;

endmodule : prim_multiplier_4x4


