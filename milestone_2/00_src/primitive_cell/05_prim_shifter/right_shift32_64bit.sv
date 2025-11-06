// Right shift by 32 (64-bit)
module right_shift32_64bit(
    input  logic [63:0] i_data,
    input  logic        i_bit_in,
    output logic [63:0] o_data
);

assign o_data[63:32] = {32{i_bit_in}};
assign o_data[31:0]  = i_data[63:32];
endmodule : right_shift32_64bit




