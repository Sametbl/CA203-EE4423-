
// Right shift by 16 (64-bit)
module right_shift16_64bit(
    input  logic [63:0] i_data,
    input  logic        i_bit_in,
    output logic [63:0] o_data
);

assign o_data[63:48] = {16{i_bit_in}};
assign o_data[47:0]  = i_data[63:16];
endmodule : right_shift16_64bit


