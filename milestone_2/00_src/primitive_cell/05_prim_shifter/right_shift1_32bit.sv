module right_shift1_32bit(
    input  logic [31:0] i_data,
    input  logic        i_bit_in,
    output logic [31:0] o_data
);

assign o_data[31]   = i_bit_in;
assign o_data[30:0] = i_data[31:1];
endmodule : right_shift1_32bit


