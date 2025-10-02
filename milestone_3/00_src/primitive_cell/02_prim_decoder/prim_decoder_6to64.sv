module prim_decoder_6to64 (
    input  logic [5:0]  i_bin,
    output logic [63:0] o_dec
);

logic [31:0] lower_32;
logic [31:0] upper_32;

// Instantiate lower half (when i_bin[5] == 0)
prim_decoder_5to32    Lower_dec (
    .i_bin ( i_bin[4:0] ),
    .o_dec ( lower_32   )
);

// Instantiate upper half (when i_bin[5] == 1)
prim_decoder_5to32    Higher_dec (
    .i_bin ( i_bin[4:0] ),
    .o_dec ( upper_32   )
);

// Output
prim_mux_2x1 #(.WIDTH(64)) mux_select_dec (
    .i_sel ( i_bin[5]             ),
    .i_0   ({32'b0, lower_32}     ),
    .i_1   ({upper_32, 32'b0}     ),
    .o_mux ( o_dec                )
);

endmodule : prim_decoder_6to64
