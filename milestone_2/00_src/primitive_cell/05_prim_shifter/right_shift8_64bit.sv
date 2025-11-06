// Right shift by 8 (64-bit)
module right_shift8_64bit(
    input  logic [63:0] i_data,
    input  logic        i_bit_in,
    output logic [63:0] o_data
);

assign o_data[63:56] = {8{i_bit_in}};
assign o_data[55:0]  = i_data[63:8];
endmodule : right_shift8_64bit

