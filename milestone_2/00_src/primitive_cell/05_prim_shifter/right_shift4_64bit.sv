// Right shift by 4 (64-bit)
module right_shift4_64bit(
    input  logic [63:0] i_data,
    input  logic        i_bit_in,
    output logic [63:0] o_data
);

assign o_data[63:60] = {4{i_bit_in}};
assign o_data[59:0]  = i_data[63:4];

endmodule : right_shift4_64bit

