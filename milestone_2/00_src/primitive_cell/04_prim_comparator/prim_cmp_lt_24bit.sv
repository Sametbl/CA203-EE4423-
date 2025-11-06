module prim_cmp_lt_24bit (
    input  logic [23:0] i_a         ,
    input  logic [23:0] i_b         ,
    input  logic        i_signed_en , // High to enable signed comparison
    output logic        o_lt
);

// 4-bit group comparisons
logic [5:0] eq_4;
logic [5:0] sm_4;

// Merge stage 1: 8-bit groups
logic [2:0] eq_8;
logic [2:0] sm_8;

// Merge stage 2: Final 24-bit result
logic       eq_24;
logic       sm_24;

// Sign comparison
logic A_neg_B_pos;
logic A_pos_B_neg;
logic same_sign;
logic signed_less_than;
logic unsigned_less_than;

// Primitive 4-bit comparators
prim_cmp_mag_4bit cmp_5 (.i_a(i_a[23:20]), .i_b(i_b[23:20]), .o_eq(eq_4[5]), .o_lt(sm_4[5]), .o_gt());
prim_cmp_mag_4bit cmp_4 (.i_a(i_a[19:16]), .i_b(i_b[19:16]), .o_eq(eq_4[4]), .o_lt(sm_4[4]), .o_gt());
prim_cmp_mag_4bit cmp_3 (.i_a(i_a[15:12]), .i_b(i_b[15:12]), .o_eq(eq_4[3]), .o_lt(sm_4[3]), .o_gt());
prim_cmp_mag_4bit cmp_2 (.i_a(i_a[11:8] ), .i_b(i_b[11:8] ), .o_eq(eq_4[2]), .o_lt(sm_4[2]), .o_gt());
prim_cmp_mag_4bit cmp_1 (.i_a(i_a[7:4]  ), .i_b(i_b[7:4]  ), .o_eq(eq_4[1]), .o_lt(sm_4[1]), .o_gt());
prim_cmp_mag_4bit cmp_0 (.i_a(i_a[3:0]  ), .i_b(i_b[3:0]  ), .o_eq(eq_4[0]), .o_lt(sm_4[0]), .o_gt());

// Merge 4-bit groups into 8-bit segments
assign eq_8[2] = eq_4[5] & eq_4[4];
assign eq_8[1] = eq_4[3] & eq_4[2];
assign eq_8[0] = eq_4[1] & eq_4[0];

assign sm_8[2] = sm_4[5] | (eq_4[5] & sm_4[4]);
assign sm_8[1] = sm_4[3] | (eq_4[3] & sm_4[2]);
assign sm_8[0] = sm_4[1] | (eq_4[1] & sm_4[0]);

// Merge 8-bit segments to final 24-bit result
assign eq_24 = eq_8[2] & eq_8[1] & eq_8[0];
assign sm_24 = sm_8[2] | (eq_8[2] & sm_8[1]) | (eq_8[2] & eq_8[1] & sm_8[0]);

// Signed logic
assign A_neg_B_pos =   i_a[23] & ~i_b[23];
assign A_pos_B_neg = ~ i_a[23] &  i_b[23];
assign same_sign   = ~(i_a[23] ^  i_b[23]);

assign unsigned_less_than = sm_24 & ~i_signed_en;
assign signed_less_than   = (i_signed_en & A_neg_B_pos & ~A_pos_B_neg) |
                            (i_signed_en & same_sign   & sm_24);

// Final result
assign o_lt = unsigned_less_than | signed_less_than;

endmodule : prim_cmp_lt_24bit
