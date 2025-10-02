module prim_decoder_4to16 (
    input  logic [3:0]  i_bin,
    output logic [15:0] o_dec
);

// Gate-level logic
assign o_dec[0]  = ~i_bin[3] & ~i_bin[2] & ~i_bin[1] & ~i_bin[0];  // HIGH if i_bin == 4'b0000
assign o_dec[1]  = ~i_bin[3] & ~i_bin[2] & ~i_bin[1] &  i_bin[0];  // HIGH if i_bin == 4'b0001
assign o_dec[2]  = ~i_bin[3] & ~i_bin[2] &  i_bin[1] & ~i_bin[0];  // HIGH if i_bin == 4'b0010
assign o_dec[3]  = ~i_bin[3] & ~i_bin[2] &  i_bin[1] &  i_bin[0];  // HIGH if i_bin == 4'b0011
assign o_dec[4]  = ~i_bin[3] &  i_bin[2] & ~i_bin[1] & ~i_bin[0];  // HIGH if i_bin == 4'b0100
assign o_dec[5]  = ~i_bin[3] &  i_bin[2] & ~i_bin[1] &  i_bin[0];  // HIGH if i_bin == 4'b0101
assign o_dec[6]  = ~i_bin[3] &  i_bin[2] &  i_bin[1] & ~i_bin[0];  // HIGH if i_bin == 4'b0110
assign o_dec[7]  = ~i_bin[3] &  i_bin[2] &  i_bin[1] &  i_bin[0];  // HIGH if i_bin == 4'b0111
assign o_dec[8]  =  i_bin[3] & ~i_bin[2] & ~i_bin[1] & ~i_bin[0];  // HIGH if i_bin == 4'b1000
assign o_dec[9]  =  i_bin[3] & ~i_bin[2] & ~i_bin[1] &  i_bin[0];  // HIGH if i_bin == 4'b1001
assign o_dec[10] =  i_bin[3] & ~i_bin[2] &  i_bin[1] & ~i_bin[0];  // HIGH if i_bin == 4'b1010
assign o_dec[11] =  i_bin[3] & ~i_bin[2] &  i_bin[1] &  i_bin[0];  // HIGH if i_bin == 4'b1011
assign o_dec[12] =  i_bin[3] &  i_bin[2] & ~i_bin[1] & ~i_bin[0];  // HIGH if i_bin == 4'b1100
assign o_dec[13] =  i_bin[3] &  i_bin[2] & ~i_bin[1] &  i_bin[0];  // HIGH if i_bin == 4'b1101
assign o_dec[14] =  i_bin[3] &  i_bin[2] &  i_bin[1] & ~i_bin[0];  // HIGH if i_bin == 4'b1110
assign o_dec[15] =  i_bin[3] &  i_bin[2] &  i_bin[1] &  i_bin[0];  // HIGH if i_bin == 4'b1111

// Alternative:
// assign o_dec = (16'b1 << i_bin);

endmodule : prim_decoder_4to16
