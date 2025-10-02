// ============================================================
// Filename           : alu.sv
// Module Name        : alu
// Author             : Luong Thanh Vy (CA203 - K22)
// Created On         : 02-09-2025  (DD-MM-YYYY)
// ============================================================


module alu import pipeline_pkg::*;(
    input  logic          i_clk           ,
    input  logic          i_rstn          ,
    input  logic          i_stall         ,
    input  alu_t          i_alu_pkg       ,  // Input data
    output pipe_t         o_alu_pkg       // Data package to Writeback stage (Not registered)
);

// DECODE to ALU (EX) stage buffer
alu_t  alu_pkg_q;

prim_register_clr #(.WIDTH($bits(alu_pkg_q))) bru_stage_buffer (
            .i_clk  (i_clk                      ),
            .i_rstn (i_rstn                     ),
            .i_en   (~i_stall                   ),
            .i_clear(~i_stall & ~i_alu_pkg.valid),
            .i_d    (i_alu_pkg                  ),
            .o_q    (alu_pkg_q                  )
);


// ============================================================================

// Alias
logic [31:0]  operand_a;
logic [31:0]  operand_b;

logic [4:0]   rd_addr;
logic [2:0]   alu_op;
logic [1:0]   shifter_ctrl;
logic         is_signed_cmp;
logic         sub_en;
logic         wren;               // Enable forwarding (avoid operand == imm or PC)
logic         valid;

// shifter_crtl = 2'b00 : shift Right logical (default)
// shifter_crtl = 2;b01 : shift Left  logical
// shifter_crtl = 2'b10 : shift Right Arithmetic
// shifter_crtl = 2'b11 : Reserved

always_comb begin : signal_alias_and_rename
    alu_op        = alu_pkg_q.alu_op;
    operand_a     = alu_pkg_q.operand_a;
    operand_b     = alu_pkg_q.operand_b;
    is_signed_cmp = alu_pkg_q.is_signed_cmp;
    shifter_ctrl  = alu_pkg_q.shifter_ctrl;
    sub_en        = alu_pkg_q.sub_en;
    rd_addr       = alu_pkg_q.rd_addr;
    wren          = alu_pkg_q.wren;               // Enable forwarding (avoid operand == imm or PC)
    valid         = alu_pkg_q.valid;
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
            .i_shamt(operand_b        ),
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
assign o_alu_pkg.rd_data    = selected_result;
assign o_alu_pkg.rd_addr    = rd_addr;
assign o_alu_pkg.wren       = wren;
assign o_alu_pkg.valid      = valid;
assign o_alu_pkg.rd_is_int  = 1'b1;    // Used to differentiate data from FPU









// =============================================================================
// ===================================== DEBUG =================================
`ifdef DEBUG

instr_e                 db_instr;
logic [31:0]            db_pc;
logic [31:0]            db_imm;
register_idx_t          db_rs1_addr;
register_idx_t          db_rs2_addr;
register_idx_t          db_rd_addr;
logic                   db_alu_en;
logic                   db_branch_en;
logic                   db_load_en;
logic                   db_store_en;
logic                   db_mul_en;
logic                   db_div_en;
logic                   db_fpu_en;
logic                   db_use_pc;
logic                   db_use_imm;
logic                   db_use_rs1;
logic                   db_use_rs2;
logic                   db_wren;
logic                   db_valid;
logic                   db_is_predicted;


assign db_instr         = alu_pkg_q.debug_pkg.instr;
assign db_pc            = alu_pkg_q.debug_pkg.pc;
assign db_imm           = alu_pkg_q.debug_pkg.imm;
assign db_rs1_addr      = alu_pkg_q.debug_pkg.rs1_addr;
assign db_rs2_addr      = alu_pkg_q.debug_pkg.rs2_addr;
assign db_rd_addr       = alu_pkg_q.debug_pkg.rd_addr;
assign db_alu_en        = alu_pkg_q.debug_pkg.alu_en;
assign db_branch_en     = alu_pkg_q.debug_pkg.branch_en;
assign db_load_en       = alu_pkg_q.debug_pkg.load_en;
assign db_store_en      = alu_pkg_q.debug_pkg.store_en;
assign db_mul_en        = alu_pkg_q.debug_pkg.mul_en;
assign db_div_en        = alu_pkg_q.debug_pkg.div_en;
assign db_fpu_en        = alu_pkg_q.debug_pkg.fpu_en;
assign db_use_pc        = alu_pkg_q.debug_pkg.use_pc;
assign db_use_imm       = alu_pkg_q.debug_pkg.use_imm;
assign db_use_rs1       = alu_pkg_q.debug_pkg.use_rs1;
assign db_use_rs2       = alu_pkg_q.debug_pkg.use_rs2;
assign db_wren          = alu_pkg_q.debug_pkg.wren;
assign db_valid         = alu_pkg_q.debug_pkg.valid;
assign db_is_predicted  = alu_pkg_q.debug_pkg.is_predicted;

assign o_alu_pkg.debug_pkg = alu_pkg_q.debug_pkg;

`endif










endmodule: alu





