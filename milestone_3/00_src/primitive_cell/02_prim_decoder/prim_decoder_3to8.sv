module prim_decoder_3to8 (
    input  logic [2:0] i_bin,
    output logic [7:0] o_dec
);

assign o_dec[0] = ~i_bin[2] & ~i_bin[1] & ~i_bin[0];  // HIGH if i_bin == 3'b000
assign o_dec[1] = ~i_bin[2] & ~i_bin[1] &  i_bin[0];  // HIGH if i_bin == 3'b001
assign o_dec[2] = ~i_bin[2] &  i_bin[1] & ~i_bin[0];  // HIGH if i_bin == 3'b010
assign o_dec[3] = ~i_bin[2] &  i_bin[1] &  i_bin[0];  // HIGH if i_bin == 3'b011
assign o_dec[4] =  i_bin[2] & ~i_bin[1] & ~i_bin[0];  // HIGH if i_bin == 3'b100
assign o_dec[5] =  i_bin[2] & ~i_bin[1] &  i_bin[0];  // HIGH if i_bin == 3'b101
assign o_dec[6] =  i_bin[2] &  i_bin[1] & ~i_bin[0];  // HIGH if i_bin == 3'b110
assign o_dec[7] =  i_bin[2] &  i_bin[1] &  i_bin[0];  // HIGH if i_bin == 3'b111

// Alternative:
// assign o_dec = (8'b00000001 << i_bin);

endmodule : prim_decoder_3to8
