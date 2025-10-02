module prim_decoder_7to128 (
    input  logic [6:0]   i_bin,
    output logic [127:0] o_dec
);

logic [63:0] lower_64;
logic [63:0] upper_64;

// Instantiate lower half (when i_bin[6] == 0)
prim_decoder_6to64    Lower_dec (
    .i_bin ( i_bin[5:0] ),
    .o_dec ( lower_64   )
);

// Instantiate upper half (when i_bin[6] == 1)
prim_decoder_6to64    Higher_dec (
    .i_bin ( i_bin[5:0] ),
    .o_dec ( upper_64   )
);

// Output
prim_mux_2x1 #(.WIDTH(128)) mux_select_dec (
    .i_sel ( i_bin[6]              ),
    .i_0   ({64'b0, lower_64}      ),
    .i_1   ({upper_64, 64'b0}      ),
    .o_mux ( o_dec                 )
);

endmodule : prim_decoder_7to128
