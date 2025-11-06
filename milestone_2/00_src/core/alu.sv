// ============================================================
// Filename           : alu.sv
// Module Name        : alu
// Author             : Luong Thanh Vy (CA203 - K22)
// Created On         : 02-09-2025  (DD-MM-YYYY)
// ============================================================


module alu (
    input  logic [31:0]  i_operand_a     ,  // Operand A data
    input  logic [31:0]  i_operand_b     ,  // Operand B data
    input  logic [2:0]   i_alu_op        ,  // ALU operation select
    input  logic [1:0]   i_shifter_ctrl  ,  // Shift operation control
    input  logic         i_is_signed_cmp ,  // Compare operation control
    input  logic         i_sub_en        ,  // Adder control (Enable substraction)

    output logic [31:0]  o_alu_data         // Data package to Writeback stage (Not registered)
);


// Alias
logic [31:0]  operand_a;
logic [31:0]  operand_b;

logic [2:0]   alu_op;
logic [1:0]   shifter_ctrl;
logic         is_signed_cmp;
logic         sub_en;


// shifter_crtl = 2'b00 : shift Right logical (default)
// shifter_crtl = 2;b01 : shift Left  logical
// shifter_crtl = 2'b10 : shift Right Arithmetic
// shifter_crtl = 2'b11 : Reserved

always_comb begin : signal_alias_and_rename
    operand_a     = i_operand_a;
    operand_b     = i_operand_b;
    alu_op        = i_alu_op;
    shifter_ctrl  = i_shifter_ctrl;
    is_signed_cmp = i_is_signed_cmp;
    sub_en        = i_sub_en;

end



// ------------------------------- ALU computation --------------------------
logic [31:0]  selected_result;     // Final result (selected output)

// Temporary Data signal
logic [31:0]  adder_result;        // Result of addition/subtraction (ADD, SUB)
logic [31:0]  cmp_result;          // Result of Comparison, 32-bit exteneded (SLT, SLTU)
logic [31:0]  shifter_result;      // Result of Shifter module (SRA, SLL, SRL)
logic [31:0]  and_result;          // Result of AND operation (AND)
logic [31:0]  or_result;           // Result of OR  operation (OR)
logic [31:0]  xor_result;          // Result of XOR operation (XOR)

// ADD - SUB instructions
prim_adder_32bit  alu_adder (
            .i_a    (operand_a    ),
            .i_b    (operand_b    ),
            .i_sub  (sub_en       ),
            .o_sum  (adder_result ),
            .o_cout ()
);

// SLT/SLTU instructions - Set if Less Than
prim_cmp_lt_32bit inst_name (
    .i_a        (operand_a    ),
    .i_b        (operand_b    ),
    .i_signed_en(is_signed_cmp),
    .o_lt       (cmp_result[0])
);


assign cmp_result[31:1] = 31'h0000_0000;


// SHIFTER instructions - LOGICAL - ARITHMETIC
prim_shifter_32bit     alu_shifter (
            .i_data (operand_a        ),
            .i_shamt(operand_b[4:0]   ),
            .i_mode (shifter_ctrl     ),
            .o_data (shifter_result   )
);


// Logical instructions - AND, OR, XOR
assign or_result  = (operand_a | operand_b);
assign and_result = (operand_a & operand_b);
assign xor_result = (operand_a ^ operand_b);


// -------------------------------- RESULT SELECTION -------------------------------
// D0 - alu_op = 3'b000:      output data = Adder   (default)
// D1 - alu_op = 3'b001:      output data = Comparator
// D2 - alu_op = 3'b010:      output data = Shifter
// D3 - alu_op = 3'b011:      output data = 32-bit XOR gate
// D4 - alu_op = 3'b100:      output data = 32-bit AND gate
// D5 - alu_op = 3'b101:      output data = 32-bit OR  gate
// D6 - alu_op = 3'b110:      RESERVED  or  output data = 0
// D7 - alu_op = 3'b111:      RESERVED  or  output data = 0

prim_mux_8x1  ALU_out(
        .i_sel(alu_op           ),
        .i_0  (adder_result     ),
        .i_1  (cmp_result       ),
        .i_2  (shifter_result   ),
        .i_3  (xor_result       ),
        .i_4  (and_result       ),
        .i_5  (or_result        ),
        .i_6  (32'h0000_0000    ),
        .i_7  (32'h0000_0000    ),
        .o_mux(selected_result  )
);



// Output
assign o_alu_data = selected_result;


endmodule

