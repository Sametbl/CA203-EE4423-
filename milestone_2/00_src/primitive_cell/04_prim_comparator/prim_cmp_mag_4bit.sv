// Primitive Cell: Magnitude Comparator 4-bit 

module prim_cmp_mag_4bit(
    input  logic [3:0] i_a,
    input  logic [3:0] i_b,
    output logic       o_eq,  // High if Equal
    output logic       o_gt,  // High if Greater than
    output logic       o_lt   // High if Less than
);

logic [3:0] AB_eq;
assign AB_eq[3] = ~(i_a[3] ^ i_b[3]);
assign AB_eq[2] = ~(i_a[2] ^ i_b[2]);
assign AB_eq[1] = ~(i_a[1] ^ i_b[1]);
assign AB_eq[0] = ~(i_a[0] ^ i_b[0]);

assign o_gt = (i_a[3] & ~i_b[3]) |
                (i_a[2] & ~i_b[2] & AB_eq[3]) |
                (i_a[1] & ~i_b[1] & AB_eq[3] & AB_eq[2]) |
                (i_a[0] & ~i_b[0] & AB_eq[3] & AB_eq[2] & AB_eq[1]);

assign o_eq  = AB_eq[3] & AB_eq[2] & AB_eq[1] & AB_eq[0];
assign o_lt = ~(o_eq | o_gt);
endmodule : prim_cmp_mag_4bit




