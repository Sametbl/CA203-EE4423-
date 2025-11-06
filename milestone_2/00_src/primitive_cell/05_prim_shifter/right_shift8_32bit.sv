// Right shift by 8 (32-bit)
module right_shift8_32bit(
    input  logic [31:0] i_data,
    input  logic        i_bit_in,
    output logic [31:0] o_data
);

assign o_data[31:24] = {8{i_bit_in}};
assign o_data[23:0]  = i_data[31:8];
endmodule : right_shift8_32bit


