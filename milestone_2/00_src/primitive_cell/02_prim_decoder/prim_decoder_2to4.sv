module prim_decoder_2to4 (
    input  logic [1:0] i_bin,
    output logic [3:0] o_dec
);

assign o_dec[0] = ~i_bin[1] & ~i_bin[0];  // HIGH if i_bin == 2'b00
assign o_dec[1] = ~i_bin[1] &  i_bin[0];  // HIGH if i_bin == 2'b01
assign o_dec[2] =  i_bin[1] & ~i_bin[0];  // HIGH if i_bin == 2'b10
assign o_dec[3] =  i_bin[1] &  i_bin[0];  // HIGH if i_bin == 2'b11

// Alternative:
// assign o_dec = (4'b0001 << i_bin);

endmodule : prim_decoder_2to4



