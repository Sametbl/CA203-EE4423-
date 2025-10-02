// Primitive Cell: Parameterized Equal Comparator (Default: 5-bit)

module prim_cmp_eq #(parameter int WIDTH = 5)(
    input  logic [WIDTH-1:0] i_a,
    input  logic [WIDTH-1:0] i_b,
    output logic             o_eq  // High if Equal
);

genvar i;
logic [WIDTH-1:0] ab_eq;


generate
    for (i = 0; i < WIDTH; i++)     assign ab_eq[i] = ~(i_a[i] ^ i_b[i]);
endgenerate


assign o_eq = &ab_eq;

endmodule : prim_cmp_eq
