module prim_decoder_5to32 (
    input  logic [4:0]  i_bin,
    output logic [31:0] o_dec
);

logic [15:0] lower_16;
logic [15:0] upper_16;

// Instantiate lower half (when i_bin[4] == 0)
prim_decoder_4to16    Lower_dec (
    .i_bin ( i_bin[3:0] ),
    .o_dec ( lower_16   )
);

// Instantiate upper half (when i_bin[4] == 1)
prim_decoder_4to16    Higher_dec (
    .i_bin ( i_bin[3:0] ),
    .o_dec ( upper_16   )
);


// Output
prim_mux_2x1 #(.WIDTH(32))   mux_select_dec(
    .i_sel (i_bin[4]           ),
    .i_0   ({16'b0, lower_16}  ),
    .i_1   ({upper_16, 16'b0}  ),
    .o_mux (o_dec              )
);


endmodule : prim_decoder_5to32

