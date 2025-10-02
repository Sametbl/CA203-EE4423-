// Right shift by 4 (32-bit)
module right_shift4_32bit(
    input  logic [31:0] i_data,
    input  logic        i_bit_in,
    output logic [31:0] o_data
);

assign o_data[31]   = i_bit_in;
assign o_data[30]   = i_bit_in;
assign o_data[29]   = i_bit_in;
assign o_data[28]   = i_bit_in;

assign o_data[27:0] = i_data[31:4];
endmodule : right_shift4_32bit

