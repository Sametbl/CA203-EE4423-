module prim_cmp_lt_16bit (
    input  logic [15:0] i_a         ,
    input  logic [15:0] i_b         ,
    input  logic        i_signed_en ,
    output logic        o_lt
);

// 4-bit comparisons
logic [3:0] eq_4;
logic [3:0] sm_4;

logic [1:0] eq_8;
logic [1:0] sm_8;

logic       eq_16;
logic       sm_16;

logic       A_neg_B_pos;
logic       A_pos_B_neg;
logic       same_sign;
logic       signed_less_than;
logic       unsigned_less_than;

// Primitive comparators
prim_cmp_mag_4bit cmp_3 (.i_a(i_a[15:12]), .i_b(i_b[15:12]), .o_eq(eq_4[3]), .o_lt(sm_4[3]), .o_gt());
prim_cmp_mag_4bit cmp_2 (.i_a(i_a[11:8] ), .i_b(i_b[11:8] ), .o_eq(eq_4[2]), .o_lt(sm_4[2]), .o_gt());
prim_cmp_mag_4bit cmp_1 (.i_a(i_a[7:4]  ), .i_b(i_b[7:4]  ), .o_eq(eq_4[1]), .o_lt(sm_4[1]), .o_gt());
prim_cmp_mag_4bit cmp_0 (.i_a(i_a[3:0]  ), .i_b(i_b[3:0]  ), .o_eq(eq_4[0]), .o_lt(sm_4[0]), .o_gt());

// Merge level 1: 8-bit
assign eq_8[1] = eq_4[3] & eq_4[2];
assign eq_8[0] = eq_4[1] & eq_4[0];

assign sm_8[1] = sm_4[3] | (eq_4[3] & sm_4[2]);
assign sm_8[0] = sm_4[1] | (eq_4[1] & sm_4[0]);

// Merge level 2: 16-bit
assign eq_16 = eq_8[1] & eq_8[0];
assign sm_16 = sm_8[1] | (eq_8[1] & sm_8[0]);

// Signed logic
assign A_neg_B_pos =   i_a[15] & ~i_b[15];
assign A_pos_B_neg =  ~i_a[15] &  i_b[15];
assign same_sign   = ~(i_a[15] ^  i_b[15]);

assign unsigned_less_than = sm_16 & ~i_signed_en;
assign signed_less_than   = (i_signed_en & A_neg_B_pos & ~A_pos_B_neg) |
                            (i_signed_en & same_sign   & sm_16);

assign o_lt = unsigned_less_than | signed_less_than;

endmodule : prim_cmp_lt_16bit
