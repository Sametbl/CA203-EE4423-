// Right shift by 1 (64bit)
module right_shift1_64bit(
    input  logic [63:0] i_data,
    input  logic        i_bit_in,
    output logic [63:0] o_data
);

assign o_data[63]   = i_bit_in;
assign o_data[62:0] = i_data[63:1];
endmodule : right_shift1_64bit

