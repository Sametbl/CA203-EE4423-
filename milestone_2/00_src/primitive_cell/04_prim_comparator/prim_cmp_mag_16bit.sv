module prim_cmp_mag_16bit (
    input  logic [15:0] i_a         ,
    input  logic [15:0] i_b         ,
    input  logic        i_signed_en ,
    output logic        o_eq        ,
    output logic        o_gt        ,
    output logic        o_lt
);

logic [3:0] eq_4;
logic [3:0] la_4;
logic [3:0] sm_4;

logic [1:0] eq_8;
logic [1:0] la_8;
logic [1:0] sm_8;

logic       eq_16;
logic       la_16;
logic       sm_16;

logic       A_pos_B_neg;
logic       A_neg_B_pos;
logic       same_sign;

logic       signed_larger;
logic       signed_smaller;
logic       unsigned_larger;
logic       unsigned_smaller;

// 4-bit comparisons
prim_cmp_mag_4bit cmp_3 (.i_a(i_a[15:12]), .i_b(i_b[15:12]), .o_eq(eq_4[3]), .o_gt(la_4[3]), .o_lt(sm_4[3]));
prim_cmp_mag_4bit cmp_2 (.i_a(i_a[11:8]),  .i_b(i_b[11:8]),  .o_eq(eq_4[2]), .o_gt(la_4[2]), .o_lt(sm_4[2]));
prim_cmp_mag_4bit cmp_1 (.i_a(i_a[7:4]),   .i_b(i_b[7:4]),   .o_eq(eq_4[1]), .o_gt(la_4[1]), .o_lt(sm_4[1]));
prim_cmp_mag_4bit cmp_0 (.i_a(i_a[3:0]),   .i_b(i_b[3:0]),   .o_eq(eq_4[0]), .o_gt(la_4[0]), .o_lt(sm_4[0]));

// Merge 4 → 8
assign eq_8[1] = eq_4[3] & eq_4[2];
assign la_8[1] = la_4[3] | (eq_4[3] & la_4[2]);
assign sm_8[1] = sm_4[3] | (eq_4[3] & sm_4[2]);

assign eq_8[0] = eq_4[1] & eq_4[0];
assign la_8[0] = la_4[1] | (eq_4[1] & la_4[0]);
assign sm_8[0] = sm_4[1] | (eq_4[1] & sm_4[0]);

// Merge 8 → 16
assign eq_16 = eq_8[1] & eq_8[0];
assign la_16 = la_8[1] | (eq_8[1] & la_8[0]);
assign sm_16 = sm_8[1] | (eq_8[1] & sm_8[0]);

// Sign
assign A_pos_B_neg =  ~i_a[15] &  i_b[15];
assign A_neg_B_pos =   i_a[15] & ~i_b[15];
assign same_sign   = ~(i_a[15] ^  i_b[15]);

assign unsigned_larger  = la_16 & ~i_signed_en;
assign unsigned_smaller = sm_16 & ~i_signed_en;

assign signed_larger  = i_signed_en & (A_pos_B_neg | (same_sign & la_16));
assign signed_smaller = i_signed_en & (A_neg_B_pos | (same_sign & sm_16));

assign o_eq = eq_16;
assign o_gt = unsigned_larger | signed_larger;
assign o_lt = unsigned_smaller | signed_smaller;

endmodule : prim_cmp_mag_16bit
