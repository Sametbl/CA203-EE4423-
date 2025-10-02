// Right shift by 2 (64-bit)
module right_shift2_64bit(
    input  logic [63:0] i_data,
    input  logic        i_bit_in,
    output logic [63:0] o_data
);

assign o_data[63]   = i_bit_in;
assign o_data[62]   = i_bit_in;
assign o_data[61:0] = i_data[63:2];
endmodule : right_shift2_64bit


