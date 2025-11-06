module prim_logic_left_shifter_32bit(
    input  logic [31:0] i_data,
    input  logic [4:0]  i_shamt,
    output logic [31:0] o_data
);

logic [31:0] shift_R1;   // Data that has been right shifted by 1  position
logic [31:0] shift_R2;   // Data that has been right shifted by 2  positions
logic [31:0] shift_R4;   // Data that has been right shifted by 4  positions
logic [31:0] shift_R8;   // Data that has been right shifted by 8  positions
logic [31:0] shift_R16;  // Data that has been right shifted by 16 positions

logic [31:0] mux_R1;     // Selected data of based on i_shamt[0] bit
logic [31:0] mux_R2;     // Selected data of based on i_shamt[1] bit
logic [31:0] mux_R4;     // Selected data of based on i_shamt[2] bit
logic [31:0] mux_R8;     // Selected data of based on i_shamt[3] bit
logic [31:0] mux_R16;    // Selected data of based on i_shamt[4] bit

logic [31:0] reversed_in;  // Initial 32-bit reversed Binary for Left shift
logic [31:0] reversed_out; // Final   32-bit reversed Binart for Left shift



//--------------------- Performing Right shift ---------------------
reverse_32bit    reverse_in (.i_data(i_data), .o_data(reversed_in));

right_shift1_32bit  shift_1 (.i_data(reversed_in), .i_bit_in(1'b0), .o_data(shift_R1) );
right_shift2_32bit  shift_2 (.i_data(mux_R1),      .i_bit_in(1'b0), .o_data(shift_R2) );
right_shift4_32bit  shift_4 (.i_data(mux_R2),      .i_bit_in(1'b0), .o_data(shift_R4) );
right_shift8_32bit  shift_8 (.i_data(mux_R4),      .i_bit_in(1'b0), .o_data(shift_R8) );
right_shift16_32bit shift_16(.i_data(mux_R8),      .i_bit_in(1'b0), .o_data(shift_R16));

prim_mux_2x1   mux_1   (.i_sel(i_shamt[0]), .i_0(reversed_in), .i_1(shift_R1),  .o_mux(mux_R1) );
prim_mux_2x1   mux_2   (.i_sel(i_shamt[1]), .i_0(mux_R1),      .i_1(shift_R2),  .o_mux(mux_R2) );
prim_mux_2x1   mux_4   (.i_sel(i_shamt[2]), .i_0(mux_R2),      .i_1(shift_R4),  .o_mux(mux_R4) );
prim_mux_2x1   mux_8   (.i_sel(i_shamt[3]), .i_0(mux_R4),      .i_1(shift_R8),  .o_mux(mux_R8) );
prim_mux_2x1   mux_16  (.i_sel(i_shamt[4]), .i_0(mux_R8),      .i_1(shift_R16), .o_mux(mux_R16));

reverse_32bit    reverse_out (.i_data(mux_R16), .o_data(reversed_out));



// Output
assign o_data = reversed_out;

endmodule : prim_logic_left_shifter_32bit


