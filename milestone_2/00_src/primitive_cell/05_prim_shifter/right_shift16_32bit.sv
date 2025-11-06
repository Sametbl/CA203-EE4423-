// Right shift by 16 (32-bit)
module right_shift16_32bit(
    input  logic [31:0] i_data,
    input  logic        i_bit_in,
    output logic [31:0] o_data
);

assign o_data[31:16] = {16{i_bit_in}};
assign o_data[15:0]  = i_data[31:16];
endmodule : right_shift16_32bit







