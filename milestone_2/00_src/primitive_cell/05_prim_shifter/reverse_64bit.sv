module reverse_64bit(
    input  logic [63:0] i_data,
    output logic [63:0] o_data
);

assign o_data[0]  = i_data[63];
assign o_data[1]  = i_data[62];
assign o_data[2]  = i_data[61];
assign o_data[3]  = i_data[60];
assign o_data[4]  = i_data[59];
assign o_data[5]  = i_data[58];
assign o_data[6]  = i_data[57];
assign o_data[7]  = i_data[56];
assign o_data[8]  = i_data[55];
assign o_data[9]  = i_data[54];
assign o_data[10] = i_data[53];
assign o_data[11] = i_data[52];
assign o_data[12] = i_data[51];
assign o_data[13] = i_data[50];
assign o_data[14] = i_data[49];
assign o_data[15] = i_data[48];
assign o_data[16] = i_data[47];
assign o_data[17] = i_data[46];
assign o_data[18] = i_data[45];
assign o_data[19] = i_data[44];
assign o_data[20] = i_data[43];
assign o_data[21] = i_data[42];
assign o_data[22] = i_data[41];
assign o_data[23] = i_data[40];
assign o_data[24] = i_data[39];
assign o_data[25] = i_data[38];
assign o_data[26] = i_data[37];
assign o_data[27] = i_data[36];
assign o_data[28] = i_data[35];
assign o_data[29] = i_data[34];
assign o_data[30] = i_data[33];
assign o_data[31] = i_data[32];
assign o_data[32] = i_data[31];
assign o_data[33] = i_data[30];
assign o_data[34] = i_data[29];
assign o_data[35] = i_data[28];
assign o_data[36] = i_data[27];
assign o_data[37] = i_data[26];
assign o_data[38] = i_data[25];
assign o_data[39] = i_data[24];
assign o_data[40] = i_data[23];
assign o_data[41] = i_data[22];
assign o_data[42] = i_data[21];
assign o_data[43] = i_data[20];
assign o_data[44] = i_data[19];
assign o_data[45] = i_data[18];
assign o_data[46] = i_data[17];
assign o_data[47] = i_data[16];
assign o_data[48] = i_data[15];
assign o_data[49] = i_data[14];
assign o_data[50] = i_data[13];
assign o_data[51] = i_data[12];
assign o_data[52] = i_data[11];
assign o_data[53] = i_data[10];
assign o_data[54] = i_data[9];
assign o_data[55] = i_data[8];
assign o_data[56] = i_data[7];
assign o_data[57] = i_data[6];
assign o_data[58] = i_data[5];
assign o_data[59] = i_data[4];
assign o_data[60] = i_data[3];
assign o_data[61] = i_data[2];
assign o_data[62] = i_data[1];
assign o_data[63] = i_data[0];


endmodule : reverse_64bit










