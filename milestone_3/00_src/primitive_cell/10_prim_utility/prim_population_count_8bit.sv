
// // Primitice Cell: Count amount of logic 1's in input word

// module prim_population_count_8bit(
//     input    logic   [7:0]  i_data,
//     output   logic   [3:0]  o_count
// );

// logic [1:0] stage_1_sum [4];
// logic [3:0] stage_2_sum [2];
// logic [3:0] stage_3_sum;


// // Stage 1:
// prim_adder_2bit   stage_1_1  (
//     .i_a   (i_data[0]      ),
//     .i_b   (i_data[1]      ),
//     .i_sub (1'b0           ),
//     .o_sum (stage_1_sum[0] ),
//     .o_cout()
// );

// prim_adder_2bit   stage_1_2  (
//     .i_a   (i_data[2]      ),
//     .i_b   (i_data[3]      ),
//     .i_sub (1'b0           ),
//     .o_sum (stage_1_sum[1] ),
//     .o_cout()
// );

// prim_adder_2bit   stage_1_3  (
//     .i_a   (i_data[4]      ),
//     .i_b   (i_data[5]      ),
//     .i_sub (1'b0           ),
//     .o_sum (stage_1_sum[2] ),
//     .o_cout()
// );

// prim_adder_2bit   stage_1_4  (
//     .i_a   (i_data[5]      ),
//     .i_b   (i_data[7]      ),
//     .i_sub (1'b0           ),
//     .o_sum (stage_1_sum[3] ),
//     .o_cout()
// );

// // Stage 2:
// prim_adder_4bit   stage_2_1  (
//     .i_a   ({2'b00, stage_1_sum[0]}  ),
//     .i_b   ({2'b00, stage_1_sum[1]}  ),
//     .i_sub (1'b0                     ),
//     .o_sum (stage_2_sum[0]           ),
//     .o_cout()
// );
// prim_adder_4bit   stage_2_2  (
//     .i_a   ({2'b00, stage_1_sum[2]}  ),
//     .i_b   ({2'b00, stage_1_sum[3]}  ),
//     .i_sub (1'b0                     ),
//     .o_sum (stage_2_sum[1]           ),
//     .o_cout()
// );



// // Stage 3:
// prim_adder_4bit   stage_3  (
//     .i_a   (stage_2_sum[0]  ),
//     .i_b   (stage_2_sum[1]  ),
//     .i_sub (1'b0            ),
//     .o_sum (stage_3_sum     ),
//     .o_cout()
// );


// // Ouptut
// assign o_count = stage_3_sum;


// endmodule : prim_population_count_8bit



