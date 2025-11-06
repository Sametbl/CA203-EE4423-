module prim_carry_lookahead_adder #(parameter int WIDTH = 32)
(
    input  logic [WIDTH-1:0] i_a     ,
    input  logic [WIDTH-1:0] i_b     ,
    input  logic             i_sub   ,    // 0 = add, 1 = subtract
    output logic [WIDTH-1:0] o_sum   ,
    output logic             o_cout
);
/* verilator lint_off UNOPTFLAT */

logic [WIDTH-1:0] P;         // Propagate
logic [WIDTH-1:0] G;         // Generate
logic [WIDTH:0]   C;         // Carry chain
logic [WIDTH-1:0] b_inv;     // i_b XOR {i_sub}


assign b_inv = i_b ^ {WIDTH{i_sub}};
assign P     = i_a ^ b_inv;
assign G     = i_a & b_inv;

assign C[0]  = i_sub;

genvar i;
generate
    for (i = 0; i < WIDTH; i++) begin : gen_carry
        assign C[i+1] = G[i] | (P[i] & C[i]);
    end
endgenerate

assign o_sum  = P ^ C[WIDTH-1:0];
assign o_cout = C[WIDTH];

/* verilator lint_on UNOPTFLAT */

endmodule : prim_carry_lookahead_adder
