module prim_shifter_64bit(
    input  logic [63:0] i_data,
    input  logic [5:0]  i_shamt,
    input  logic [1:0]  i_mode,
    output logic [63:0] o_data
);
logic [63:0] bin_in;       // 64-bit Binary for Right Shift operation
logic [63:0] reversed_in;  // Initial 64-bit reversed Binary for Left shift
logic [63:0] reversed_out; // Final   64-bit reversed Binart for Left shift

logic [63:0] shift_R1;   // Data that has been right shifted by 1  position
logic [63:0] shift_R2;   // Data that has been right shifted by 2  positions
logic [63:0] shift_R4;   // Data that has been right shifted by 4  positions
logic [63:0] shift_R8;   // Data that has been right shifted by 8  positions
logic [63:0] shift_R16;  // Data that has been right shifted by 16 positions
logic [63:0] shift_R32;  // Data that has been right shifted by 32 positions

logic [63:0] mux_R1;     // Selected data of based on i_shamt[0] bit
logic [63:0] mux_R2;     // Selected data of based on i_shamt[1] bit
logic [63:0] mux_R4;     // Selected data of based on i_shamt[2] bit
logic [63:0] mux_R8;     // Selected data of based on i_shamt[3] bit
logic [63:0] mux_R16;    // Selected data of based on i_shamt[4] bit
logic [63:0] mux_R32;    // Selected data of based on i_shamt[5] bit

logic left_logic_mode;  // indicate Logical Left shift i_mode
logic right_arith_mode; // indicate Right Arithmetic shift i_mode
logic reserved_mode;    // indicate Reserved i_mode
logic shift_in_bit;     // Specify shift-in bit

                                                     // i_mode = 2'b00 : shift Right logic (Default)
assign left_logic_mode  = ~i_mode[1] &  i_mode[0];   // i_mode = 2'b01 : shift Left  logic
assign right_arith_mode =  i_mode[1] & ~i_mode[0];   // i_mode = 2'b10 : shift Right Arithmetic
assign reserved_mode    =  i_mode[1] &  i_mode[0];   // i_mode = 2'b11 : reserved_mode

assign shift_in_bit = right_arith_mode & i_data[31];     // For Right shift arithmetic

//--------------------- Reverse input for Left shift -------------------
reverse_64bit    reverse_in (.i_data(i_data), .o_data(reversed_in));

prim_mux_2x1 #(.WIDTH(64))   mux_rev_in (
    .i_sel(left_logic_mode),
    .i_0  (i_data         ),
    .i_1  (reversed_in    ),
    .o_mux(bin_in         )
);

//--------------------- Performing Right shift ---------------------
right_shift1_64bit  shift_1  (.i_data(bin_in ), .i_bit_in(shift_in_bit), .o_data(shift_R1) );
right_shift2_64bit  shift_2  (.i_data(mux_R1 ), .i_bit_in(shift_in_bit), .o_data(shift_R2) );
right_shift4_64bit  shift_4  (.i_data(mux_R2 ), .i_bit_in(shift_in_bit), .o_data(shift_R4) );
right_shift8_64bit  shift_8  (.i_data(mux_R4 ), .i_bit_in(shift_in_bit), .o_data(shift_R8) );
right_shift16_64bit shift_16 (.i_data(mux_R8 ), .i_bit_in(shift_in_bit), .o_data(shift_R16));
right_shift32_64bit shift_32 (.i_data(mux_R16), .i_bit_in(shift_in_bit), .o_data(shift_R32));

prim_mux_2x1 #(.WIDTH(64)) mux_1   (.i_sel(i_shamt[0]), .i_0(bin_in ), .i_1(shift_R1),  .o_mux(mux_R1) );
prim_mux_2x1 #(.WIDTH(64)) mux_2   (.i_sel(i_shamt[1]), .i_0(mux_R1 ), .i_1(shift_R2),  .o_mux(mux_R2) );
prim_mux_2x1 #(.WIDTH(64)) mux_4   (.i_sel(i_shamt[2]), .i_0(mux_R2 ), .i_1(shift_R4),  .o_mux(mux_R4) );
prim_mux_2x1 #(.WIDTH(64)) mux_8   (.i_sel(i_shamt[3]), .i_0(mux_R4 ), .i_1(shift_R8),  .o_mux(mux_R8) );
prim_mux_2x1 #(.WIDTH(64)) mux_16  (.i_sel(i_shamt[4]), .i_0(mux_R8 ), .i_1(shift_R16), .o_mux(mux_R16));
prim_mux_2x1 #(.WIDTH(64)) mux_32  (.i_sel(i_shamt[5]), .i_0(mux_R16), .i_1(shift_R32), .o_mux(mux_R32));


//--------------------- reverse output for Left shift -----------------------
logic  mux_out_sel;
assign mux_out_sel = left_logic_mode;

reverse_64bit   reverse_out (.i_data(mux_R32), .o_data(reversed_out));



// Output
prim_mux_2x1 #(.WIDTH(64)) mux_out (
    .i_sel(mux_out_sel  ),
    .i_0  (mux_R32      ),
    .i_1  (reversed_out ),
    .o_mux(o_data       )
);


endmodule : prim_shifter_64bit

