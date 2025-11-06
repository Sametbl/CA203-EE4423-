module prim_cmp_lt_8bit (
    input  logic [7:0]  i_a         ,
    input  logic [7:0]  i_b         ,
    input  logic        i_signed_en , // High to enable signed comparison
    output logic        o_lt
);

// 4-bit comparison
logic [1:0] eq_4;
logic [1:0] sm_4;

logic       eq_8;
logic       sm_8;

logic       A_neg_B_pos;
logic       A_pos_B_neg;
logic       same_sign;
logic       signed_less_than;
logic       unsigned_less_than;

// Primitive 4-bit comparators
prim_cmp_mag_4bit cmp_1 (.i_a(i_a[7:4]), .i_b(i_b[7:4]), .o_eq(eq_4[1]), .o_lt(sm_4[1]), .o_gt());
prim_cmp_mag_4bit cmp_0 (.i_a(i_a[3:0]), .i_b(i_b[3:0]), .o_eq(eq_4[0]), .o_lt(sm_4[0]), .o_gt());

// Merge
assign eq_8 = eq_4[1] & eq_4[0];
assign sm_8 = sm_4[1] | (eq_4[1] & sm_4[0]);

// Sign logic
assign A_neg_B_pos =   i_a[7] & ~i_b[7];
assign A_pos_B_neg =  ~i_a[7] &  i_b[7];
assign same_sign   = ~(i_a[7] ^  i_b[7]);

assign unsigned_less_than = sm_8 & ~i_signed_en;
assign signed_less_than   = (i_signed_en & A_neg_B_pos & ~A_pos_B_neg) |
                            (i_signed_en & same_sign   & sm_8);

assign o_lt = unsigned_less_than | signed_less_than;

endmodule : prim_cmp_lt_8bit
