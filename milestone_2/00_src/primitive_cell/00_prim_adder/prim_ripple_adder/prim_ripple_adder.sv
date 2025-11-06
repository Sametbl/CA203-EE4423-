module prim_ripple_adder #(
    parameter int WIDTH = 32
) (
    input  logic [WIDTH-1:0] i_a     ,
    input  logic [WIDTH-1:0] i_b     ,
    input  logic             i_sub   ,    // 0 = add, 1 = subtract
    output logic [WIDTH-1:0] o_sum   ,
    output logic             o_cout
);

    logic [WIDTH-1:0] b_inv;         // i_b XOR {i_sub}
    logic [WIDTH-2:0] connect;       // Carry connections between FAs

    assign b_inv = i_b ^ {WIDTH{i_sub}};

    genvar i;
    generate
        for (i = 0; i < WIDTH; i++) begin : gen_FA
            if (i == 0) begin : gen_cin_FA
                prim_full_adder FA (
                    .i_a    (i_a[i]),
                    .i_b    (b_inv[i]),
                    .i_cin  (i_sub),
                    .o_sum  (o_sum[i]),
                    .o_cout (connect[i])
                );
            end else if (i < WIDTH - 1) begin : gen_mid_FA
                prim_full_adder FA (
                    .i_a    (i_a[i]),
                    .i_b    (b_inv[i]),
                    .i_cin  (connect[i-1]),
                    .o_sum  (o_sum[i]),
                    .o_cout (connect[i])
                );
            end else begin : gen_cout_FA
                prim_full_adder FA (
                    .i_a    (i_a[i]),
                    .i_b    (b_inv[i]),
                    .i_cin  (connect[i-1]),
                    .o_sum  (o_sum[i]),
                    .o_cout (o_cout)
                );
            end
        end
    endgenerate

endmodule : prim_ripple_adder
