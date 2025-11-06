module prim_encoder_16to4 (
    input  logic [15:0] i_bin,
    output logic [3:0]  o_enc
);

logic [2:0] encode_low;
logic [2:0] encode_high;
logic       sel_high;

assign sel_high = |(i_bin[15:8]);


prim_encoder_8to3 U0_Encode_low (
    .i_bin ( i_bin[7:0]  ),
    .o_enc ( encode_low  )
);

prim_encoder_8to3 U1_Encode_high (
    .i_bin ( i_bin[15:8] ),
    .o_enc ( encode_high )
);



// Ouptut
prim_mux_2x1 #(.WIDTH(4))  U3_Mux_sel_Encode(
  .i_sel(sel_high            ),
  .i_0  ({1'b0, encode_low}  ),
  .i_1  ({1'b1, encode_high} ),
  .o_mux(o_enc               )
);


endmodule : prim_encoder_16to4


