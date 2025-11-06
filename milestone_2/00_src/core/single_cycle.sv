// ============================================================
// Filename           : Untitled-1.sv
// Module Name        : Untitled-1
// Author             : Luong Thanh Vy (CA203 - K22)
// Created On         : 06-08-2025  (DD-MM-YYYY)
// Module Description :
// Module Purpose     :
// Notes              :
// Version            : 1.0.0
// ============================================================



`define IMEM_INTI_FILE "./../02_test/isa_1b.hex"
`define DMEM_INIT_FILE "./../02_test/dmem_init_file.hex"
`define IMEM_SIZE   16
`define DMEM_SIZE   16



module single_cycle (
    input  logic         i_clk       ,    // Global clock, active on the rising edge
    input  logic         i_reset     ,    // Global low active reset
    // Input peripheral
    input  logic [31:0]  i_io_sw     ,    // Input for switches
    //input  logic [3:0]   i_io_btn    ,    // Input for buttons
    // Output peripheral
    output logic [31:0]  o_io_lcd    ,    // Output for driving the LCD register
    output logic [31:0]  o_io_ledr   ,    // Output for driving red LEDs
    output logic [31:0]  o_io_ledg   ,    // Output for driving green LEDs
    output logic [6:0]   o_io_hex0   ,    // Output for driving 7-segment LED displays (HEX0)
    output logic [6:0]   o_io_hex1   ,    // Output for driving 7-segment LED displays (HEX1)
    output logic [6:0]   o_io_hex2   ,    // Output for driving 7-segment LED displays (HEX2)
    output logic [6:0]   o_io_hex3   ,    // Output for driving 7-segment LED displays (HEX3)
    output logic [6:0]   o_io_hex4   ,    // Output for driving 7-segment LED displays (HEX4)
    output logic [6:0]   o_io_hex5   ,    // Output for driving 7-segment LED displays (HEX5)
    output logic [6:0]   o_io_hex6   ,    // Output for driving 7-segment LED displays (HEX6)
    output logic [6:0]   o_io_hex7   ,    // Output for driving 7-segment LED displays (HEX7)
    // DEBUG
    output logic [31:0]  o_pc_debug  ,    // Debug program counter
    output logic         o_insn_vld       // Instruction valid
);

logic instr_valid; // Valid bit for instruction


// ================================ Selecting next PC ==========================
logic [31:0] imem_data;
logic [31:0] pc_plus4;
logic [31:0] alu_data;
logic        pc_plus4_enable;

logic [31:0] next_pc;
logic [31:0] pc;
logic        pc_sel;

assign pc_plus4_enable = 1'b1; // (Reserved) Used to enable PC + 4 adder


// PC + 4 adder
prim_adder_32bit pc_plus4_adder (
    .i_a    (pc                                      ),
    .i_b    ({29'h0000_0000, pc_plus4_enable, 2'b00} ),
    .i_sub  (1'b0                                    ),
    .o_sum  (pc_plus4                                ),
    .o_cout ()
);

// if (pc_sel)     next_pc = alu_data
// else            next_pc = pc_plus4       (default)
prim_mux_2x1 #(.WIDTH(32)) next_pc_mux (
    .i_sel  (pc_sel        ),
    .i_0    (pc_plus4      ),
    .i_1    (alu_data      ),
    .o_mux  (next_pc       )
);


prim_register_clr #(.WIDTH(32)) pc_reg (
    .i_clk   (i_clk    ),
    .i_rstn  (i_reset  ),
    .i_clear (1'b0     ),
    .i_en    (1'b1     ),
    .i_d     (next_pc  ),
    .o_q     (pc       )
);


// =========================== Fetching new instruction (Async) ==========================

imem_model #(.PROGRAMFILE(`IMEM_INTI_FILE), .MEM_DEPTH(`IMEM_SIZE) ) imem (
    .i_addr(pc       ),    // Word address (PC)
    .o_data(imem_data)     // Instruction word
);




// =========================== Accessing Regfile ==========================

logic [31:0] rs1_data;
logic [31:0] rs2_data;
logic [ 4:0] regfile_rs1_addr;
logic [ 4:0] regfile_rs2_addr;
logic        rs1_eq_rs2;  // High if RS1 equal     RS2
logic        rs1_lt_rs2;  // High if RS1 less than RS2


logic [31:0] regfile_rd_data;
logic [ 4:0] regfile_rd_addr;
logic        regfile_rd_wren;



regfile   register_file(
    .i_clk      (i_clk           ),
    .i_rstn     (i_reset         ),
    // Read Address
    .i_rs1_addr (regfile_rs1_addr),
    .i_rs2_addr (regfile_rs2_addr),
    // Write signals
    .i_rd_data  (regfile_rd_data ),
    .i_rd_addr  (regfile_rd_addr ),
    .i_rd_wren  (regfile_rd_wren ),
    // Asynchronous Read Data
    .o_rs1_data (rs1_data        ),  // Combinational read
    .o_rs2_data (rs2_data        )   // Combinational read
);






// =========================== Executing instruction ==========================
logic [31:0] alu_operand_a;
logic [31:0] alu_operand_b;
logic [31:0] immediate;
logic [ 1:0] alu_opa_sel;
logic        alu_opb_sel;

//
logic [ 2:0] alu_op;
logic [ 1:0] alu_shifter_ctrl;
logic        alu_signed_cmp_en;
logic        alu_sub_en;

logic        brcmp_unsigned_en;


// ALU: Operand A selection
prim_mux_4x1 #(.WIDTH(32)) alu_operand_a_sel (
    .i_sel  (alu_opa_sel    ),
    .i_0    (rs1_data       ),
    .i_1    (pc             ),
    .i_2    (32'h0000_0000  ), // For LUI and AUIPC
    .i_3    (32'h0000_0000  ), // Reserved
    .o_mux  (alu_operand_a  )
);


// ALU: Operand B selection
prim_mux_2x1 #(.WIDTH(32)) alu_operand_b_sel (
    .i_sel  (alu_opb_sel    ),
    .i_0    (rs2_data       ),
    .i_1    (immediate      ),
    .o_mux  (alu_operand_b  )
);


// BRU: Branch comparison
prim_cmp_mag_32bit  BRC (
    .i_a        (rs1_data           ),
    .i_b        (rs2_data           ),
    .i_signed_en(~brcmp_unsigned_en ),
    .o_eq       (rs1_eq_rs2         ),
    .o_lt       (rs1_lt_rs2         ),
    .o_gt       ()
);

// ALU
alu ALU (
    .i_alu_op        (alu_op            ),  // ALU operation select
    .i_operand_a     (alu_operand_a     ),  // Operand A data
    .i_operand_b     (alu_operand_b     ),  // Operand B data
    .i_shifter_ctrl  (alu_shifter_ctrl  ),  // Shift operation control
    .i_is_signed_cmp (alu_signed_cmp_en ),  // Compare operation control
    .i_sub_en        (alu_sub_en        ),  // Adder control (Enable substraction)

    .o_alu_data      (alu_data          )   // Data package to Writeback stage (Not registered)
);





// =========================== Accessing Memory ==========================
logic [31:0] lsu_load_data;
logic [3:0]  lsu_bytemask;
logic        lsu_ld_unsigned;
logic        lsu_st_en;



lsu #(.MEM_DEPTH(`DMEM_SIZE), .DMEM_INIT_FILE(`DMEM_INIT_FILE))   LSU (
    .i_clk              (i_clk           ),
    .i_rstn             (i_reset         ),
    // LSU control
    .i_instr_valid      (instr_valid     ), // Indicate a valid instruction is executing
    .i_lsu_addr         (alu_data        ), // Address from ALU
    .i_lsu_st_data      (rs2_data        ), // Store dat
    .i_lsu_bytemask     (lsu_bytemask    ), // Bytemask for store operation
    .i_lsu_st_en        (lsu_st_en       ), // Store enable
    .i_lsu_ld_unsigned  (lsu_ld_unsigned ),
    // Input peripheral
    .i_io_sw            (i_io_sw         ),
    // Ouptut peripheral
    .o_io_ledg          (o_io_ledg       ),
    .o_io_ledr          (o_io_ledr       ),
    .o_io_lcd           (o_io_lcd        ),
    .o_io_hex0          (o_io_hex0       ),
    .o_io_hex1          (o_io_hex1       ),
    .o_io_hex2          (o_io_hex2       ),
    .o_io_hex3          (o_io_hex3       ),
    .o_io_hex4          (o_io_hex4       ),
    .o_io_hex5          (o_io_hex5       ),
    .o_io_hex6          (o_io_hex6       ),
    .o_io_hex7          (o_io_hex7       ),
    // Load data
    .o_lsu_ld_data      (lsu_load_data   )           // Load data
);


// =========================== Writeback =================================
logic [1:0] writeback_sel;

prim_mux_4x1 #(.WIDTH(32)) writeback_mux (
    .i_sel  (writeback_sel   ),
    .i_0    (alu_data        ),  // ALU data (default)
    .i_1    (pc_plus4        ),  // PC + 4
    .i_2    (lsu_load_data   ),  // LSU load data
    .i_3    (32'h0000_0000   ),  // Reserved
    .o_mux  (regfile_rd_data )
);




// =============================================================================
// ======================= Control Unit of entire CPU ==========================
// =============================================================================
control_unit decode_and_control_unit (
    // Input instruction binary data
    .i_instr                (imem_data         ), // Input  data package from Fetch Stage
    // Fetch control
    .i_br_equal             (rs1_eq_rs2        ),
    .i_br_less              (rs1_lt_rs2        ),
    .o_pc_sel               (pc_sel            ),
    // Immediate generation
    .o_immediate            (immediate         ),
    // ALU control
    .o_alu_op               (alu_op            ),
    .o_alu_opa_sel          (alu_opa_sel       ),
    .o_alu_opb_sel          (alu_opb_sel       ),
    .o_alu_shifter_ctrl     (alu_shifter_ctrl  ),
    .o_alu_signed_cmp_en    (alu_signed_cmp_en ),
    .o_alu_sub_en           (alu_sub_en        ),
    // BRC control
    .o_branch_cmp_unsigned  (brcmp_unsigned_en ),
    // LSU control
    .o_lsu_bytemask         (lsu_bytemask      ),  // Bytemask for Store operation
    .o_lsu_st_en            (lsu_st_en         ),     // Store enable
    .o_lsu_unsigned         (lsu_ld_unsigned   ),  // Unsigned extension for non-word load
    // Writeback control
    .o_wb_sel               (writeback_sel     ),
    .o_rd_wren              (regfile_rd_wren   ),
    .o_rs1_addr             (regfile_rs1_addr  ),
    .o_rs2_addr             (regfile_rs2_addr  ),
    .o_rd_addr              (regfile_rd_addr   ),
    // General signal
    .o_instr_valid          (instr_valid       ),  // Instruction Valid
    .o_ecall                (),                    // Reserved
    .o_ebreak               (),                    // Reserved
    .o_pause                ()                     // Reserved

);




// DEBUG
prim_register #(.WIDTH(32)) debug_pc_reg (
    .i_clk   (i_clk     ),
    .i_rstn  (i_reset   ),
    .i_en    (1'b1      ),
    .i_d     (pc        ),
    .o_q     (o_pc_debug)
);

prim_register #(.WIDTH(1)) instr_valid_reg (
    .i_clk   (i_clk      ),
    .i_rstn  (i_reset    ),
    .i_en    (1'b1       ),
    .i_d     (instr_valid),
    .o_q     (o_insn_vld )
);




endmodule
