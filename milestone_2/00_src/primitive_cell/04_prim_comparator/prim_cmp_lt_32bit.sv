// Primitive Cell: Magnitude comparator 32-bit

module prim_cmp_lt_32bit(
    input  logic [31:0] i_a,
    input  logic [31:0] i_b,
    input  logic        i_signed_en, // High to enable signed comparison
    output logic        o_lt         // High if Less than
);


// Compare each 4-bit groups
logic [7:0] eq_4;
logic [7:0] sm_4;
logic [3:0] eq_8;
logic [3:0] sm_8;
logic [1:0] eq_16;
logic [1:0] sm_16;
logic       sm_32;

prim_cmp_mag_4bit  cmp_7 (.i_a(i_a[31:28]), .i_b(i_b[31:28]), .o_eq(eq_4[7]), .o_lt(sm_4[7]), .o_gt());
prim_cmp_mag_4bit  cmp_6 (.i_a(i_a[27:24]), .i_b(i_b[27:24]), .o_eq(eq_4[6]), .o_lt(sm_4[6]), .o_gt());
prim_cmp_mag_4bit  cmp_5 (.i_a(i_a[23:20]), .i_b(i_b[23:20]), .o_eq(eq_4[5]), .o_lt(sm_4[5]), .o_gt());
prim_cmp_mag_4bit  cmp_4 (.i_a(i_a[19:16]), .i_b(i_b[19:16]), .o_eq(eq_4[4]), .o_lt(sm_4[4]), .o_gt());
prim_cmp_mag_4bit  cmp_3 (.i_a(i_a[15:12]), .i_b(i_b[15:12]), .o_eq(eq_4[3]), .o_lt(sm_4[3]), .o_gt());
prim_cmp_mag_4bit  cmp_2 (.i_a(i_a[11:8] ), .i_b(i_b[11:8] ), .o_eq(eq_4[2]), .o_lt(sm_4[2]), .o_gt());
prim_cmp_mag_4bit  cmp_1 (.i_a(i_a[7:4]  ), .i_b(i_b[7:4]  ), .o_eq(eq_4[1]), .o_lt(sm_4[1]), .o_gt());
prim_cmp_mag_4bit  cmp_0 (.i_a(i_a[3:0]  ), .i_b(i_b[3:0]  ), .o_eq(eq_4[0]), .o_lt(sm_4[0]), .o_gt());


// Compare each 4-bit groups with previous 4- segments
assign eq_8[3] = eq_4[7] &  eq_4[6];
assign eq_8[2] = eq_4[5] &  eq_4[4];
assign eq_8[1] = eq_4[3] &  eq_4[2];
assign eq_8[0] = eq_4[1] &  eq_4[0];

assign sm_8[3] = sm_4[7] | (eq_4[7] & sm_4[6]);
assign sm_8[2] = sm_4[5] | (eq_4[5] & sm_4[4]);
assign sm_8[1] = sm_4[3] | (eq_4[3] & sm_4[2]);
assign sm_8[0] = sm_4[1] | (eq_4[1] & sm_4[0]);

// Compare each 8- group
assign eq_16[1] = eq_8[3] & eq_8[2];
assign eq_16[0] = eq_8[1] & eq_8[0];

assign sm_16[1] = sm_8[3] | (eq_8[3] & sm_8[2]);
assign sm_16[0] = sm_8[1] | (eq_8[1] & sm_8[0]);


// Compare each 16_ groups
assign sm_32 = sm_16[1] | (eq_16[1] & sm_16[0]);


// Conclusion
logic signed_less_than;
logic unsigned_less_than;
logic A_neg_B_pos;         // Indicate A is Negative while B is Positive
logic A_pos_B_neg;         // Indicate A is Negative while B is Positive
logic same_sign;           // Indicate A and B are same in sign

assign A_neg_B_pos =   i_a[31] & ~i_b[31];
assign A_pos_B_neg =  ~i_a[31] &  i_b[31];
assign same_sign   = ~(i_a[31] ^  i_b[31]);

// Same sign ==> Compare normally
assign unsigned_less_than  = (sm_32 & ~i_signed_en);
assign signed_less_than    = (i_signed_en & A_neg_B_pos & ~A_pos_B_neg) |
                             (i_signed_en & same_sign   & sm_32);

// Output
assign o_lt = unsigned_less_than | signed_less_than;

endmodule : prim_cmp_lt_32bit

