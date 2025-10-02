module prim_cmp_mag_8bit (
    input  logic [7:0]  i_a         ,
    input  logic [7:0]  i_b         ,
    input  logic        i_signed_en ,
    output logic        o_eq        ,
    output logic        o_gt        ,
    output logic        o_lt
);

logic [1:0] eq_4;
logic [1:0] la_4;
logic [1:0] sm_4;

logic       eq_8;
logic       la_8;
logic       sm_8;

logic       A_pos_B_neg;
logic       A_neg_B_pos;
logic       same_sign;

logic       signed_larger;
logic       signed_smaller;
logic       unsigned_larger;
logic       unsigned_smaller;

// Primitive comparisons
prim_cmp_mag_4bit cmp_1 (.i_a(i_a[7:4]), .i_b(i_b[7:4]), .o_eq(eq_4[1]), .o_gt(la_4[1]), .o_lt(sm_4[1]));
prim_cmp_mag_4bit cmp_0 (.i_a(i_a[3:0]), .i_b(i_b[3:0]), .o_eq(eq_4[0]), .o_gt(la_4[0]), .o_lt(sm_4[0]));

// Merge
assign eq_8 = eq_4[1] & eq_4[0];
assign la_8 = la_4[1] | (eq_4[1] & la_4[0]);
assign sm_8 = sm_4[1] | (eq_4[1] & sm_4[0]);

// Sign
assign A_pos_B_neg =  ~i_a[7] &  i_b[7];
assign A_neg_B_pos =   i_a[7] & ~i_b[7];
assign same_sign   = ~(i_a[7] ^  i_b[7]);

assign unsigned_larger  = la_8 & ~i_signed_en;
assign unsigned_smaller = sm_8 & ~i_signed_en;

assign signed_larger  = i_signed_en & (A_pos_B_neg | (same_sign & la_8));
assign signed_smaller = i_signed_en & (A_neg_B_pos | (same_sign & sm_8));

assign o_eq = eq_8;
assign o_gt = unsigned_larger | signed_larger;
assign o_lt = unsigned_smaller | signed_smaller;

endmodule : prim_cmp_mag_8bit
