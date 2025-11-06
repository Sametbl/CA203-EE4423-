module prim_cmp_mag_24bit (
    input  logic [23:0] i_a         ,
    input  logic [23:0] i_b         ,
    input  logic        i_signed_en ,
    output logic        o_eq        ,
    output logic        o_gt        ,
    output logic        o_lt
);

logic [5:0] eq_4, la_4, sm_4;
logic [2:0] eq_8, la_8, sm_8;
logic       eq_24, la_24, sm_24;

logic A_pos_B_neg, A_neg_B_pos, same_sign;
logic signed_larger, signed_smaller;
logic unsigned_larger, unsigned_smaller;

// 4-bit comparisons
prim_cmp_mag_4bit cmp_5 (.i_a(i_a[23:20]), .i_b(i_b[23:20]), .o_eq(eq_4[5]), .o_gt(la_4[5]), .o_lt(sm_4[5]));
prim_cmp_mag_4bit cmp_4 (.i_a(i_a[19:16]), .i_b(i_b[19:16]), .o_eq(eq_4[4]), .o_gt(la_4[4]), .o_lt(sm_4[4]));
prim_cmp_mag_4bit cmp_3 (.i_a(i_a[15:12]), .i_b(i_b[15:12]), .o_eq(eq_4[3]), .o_gt(la_4[3]), .o_lt(sm_4[3]));
prim_cmp_mag_4bit cmp_2 (.i_a(i_a[11:8]),  .i_b(i_b[11:8]),  .o_eq(eq_4[2]), .o_gt(la_4[2]), .o_lt(sm_4[2]));
prim_cmp_mag_4bit cmp_1 (.i_a(i_a[7:4]),   .i_b(i_b[7:4]),   .o_eq(eq_4[1]), .o_gt(la_4[1]), .o_lt(sm_4[1]));
prim_cmp_mag_4bit cmp_0 (.i_a(i_a[3:0]),   .i_b(i_b[3:0]),   .o_eq(eq_4[0]), .o_gt(la_4[0]), .o_lt(sm_4[0]));

// Merge 4 → 8
assign eq_8[2] = eq_4[5] & eq_4[4];
assign la_8[2] = la_4[5] | (eq_4[5] & la_4[4]);
assign sm_8[2] = sm_4[5] | (eq_4[5] & sm_4[4]);

assign eq_8[1] = eq_4[3] & eq_4[2];
assign la_8[1] = la_4[3] | (eq_4[3] & la_4[2]);
assign sm_8[1] = sm_4[3] | (eq_4[3] & sm_4[2]);

assign eq_8[0] = eq_4[1] & eq_4[0];
assign la_8[0] = la_4[1] | (eq_4[1] & la_4[0]);
assign sm_8[0] = sm_4[1] | (eq_4[1] & sm_4[0]);

// Merge 8 → 24
assign eq_24 = eq_8[2] & eq_8[1] & eq_8[0];
assign la_24 = la_8[2] | (eq_8[2] & la_8[1]) | (eq_8[2] & eq_8[1] & la_8[0]);
assign sm_24 = sm_8[2] | (eq_8[2] & sm_8[1]) | (eq_8[2] & eq_8[1] & sm_8[0]);

// Signed
assign A_pos_B_neg =  ~i_a[23] &  i_b[23];
assign A_neg_B_pos =   i_a[23] & ~i_b[23];
assign same_sign   = ~(i_a[23] ^  i_b[23]);

assign unsigned_larger  = la_24 & ~i_signed_en;
assign unsigned_smaller = sm_24 & ~i_signed_en;

assign signed_larger  = i_signed_en & (A_pos_B_neg | (same_sign & la_24));
assign signed_smaller = i_signed_en & (A_neg_B_pos | (same_sign & sm_24));

// Output
assign o_eq = eq_24;
assign o_gt = unsigned_larger  | signed_larger;
assign o_lt = unsigned_smaller | signed_smaller;

endmodule : prim_cmp_mag_24bit
