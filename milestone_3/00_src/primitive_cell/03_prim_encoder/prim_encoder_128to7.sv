module prim_encoder_128to7 (
    input  logic [127:0] i_bin,
    output logic [6:0]   o_enc
);

logic [5:0] encode_low;
logic [5:0] encode_high;
logic       sel_high;

assign sel_high = |(i_bin[127:64]);

prim_encoder_64to6 U0_Encode_low (
    .i_bin ( i_bin[63:0]   ),
    .o_enc ( encode_low    )
);

prim_encoder_64to6 U1_Encode_high (
    .i_bin ( i_bin[127:64] ),
    .o_enc ( encode_high   )
);



// Output
prim_mux_2x1 #(.WIDTH(7)) U2_Mux_sel_Encode (
    .i_sel ( sel_high              ),
    .i_0   ( {1'b0, encode_low}    ),
    .i_1   ( {1'b1, encode_high}   ),
    .o_mux ( o_enc                 )
);

endmodule : prim_encoder_128to7
