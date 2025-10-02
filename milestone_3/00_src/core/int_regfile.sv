// ============================================================
// Filename           : riscv_int_regfile.sv
// Module Name        : riscv_int_regfile
// Author             : Luong Thanh Vy (CA203 - K22)
// Created On         : 31-07-2025  (DD-MM-YYYY)
// Module Description : Integer register file Model with 32 entries
// Version            : 1.0.0
// ============================================================



module int_regfile   import pipeline_pkg::*;
(
    input  logic         i_clk     ,
    input  logic         i_rstn    ,
    input  pipe_t        i_wb_pkg  ,

    input  logic [4:0]   i_rs1_addr,
    input  logic [4:0]   i_rs2_addr,

    output logic [31:0]  o_rs1_data,  // Combinational read
    output logic [31:0]  o_rs2_data   // Combinational read
);

// 32 general-purpose 32-bit registers
logic [31:0][31:0] R;

// Aliases
logic [31:0] rs1_data;
logic [31:0] rs2_data;

logic [31:0] rd_data;
logic [4:0]  rd_addr;
logic        wren;
logic        valid;
logic        rd_is_int;

logic        rd_addr_zero;
logic        write_valid;

always_comb begin : signal_alias_and_rename
    rd_addr   = i_wb_pkg.rd_addr;
    rd_data   = i_wb_pkg.rd_data;
    wren      = i_wb_pkg.wren;
    valid     = i_wb_pkg.valid;
    rd_is_int = i_wb_pkg.rd_is_int;
end

assign rd_addr_zero = (rd_addr == 5'b00000);
assign write_valid  = (wren & valid & rd_is_int & ~rd_addr_zero);

// Read and Write
always_ff @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn)            R            <= '{default: 32'h0000_0000};
    else if (write_valid)   R[rd_addr]   <= rd_data;
    else                    R            <= R;
end


// Combinational reads
assign rs1_data = R[i_rs1_addr];
assign rs2_data = R[i_rs2_addr];


// Outputs
assign o_rs1_data = rs1_data;
assign o_rs2_data = rs2_data;



// DEBUG

`ifdef DEBUG
    // Aliases for Debugging
    logic [31:0] R0, R8,  R16, R24;
    logic [31:0] R1, R9,  R17, R25;
    logic [31:0] R2, R10, R18, R26;
    logic [31:0] R3, R11, R19, R27;
    logic [31:0] R4, R12, R20, R28;
    logic [31:0] R5, R13, R21, R29;
    logic [31:0] R6, R14, R22, R30;
    logic [31:0] R7, R15, R23, R31;

    assign R0  = R[0] ;
    assign R1  = R[1] ;
    assign R2  = R[2] ;
    assign R3  = R[3] ;
    assign R4  = R[4] ;
    assign R5  = R[5] ;
    assign R6  = R[6] ;
    assign R7  = R[7] ;
    assign R8  = R[8] ;
    assign R9  = R[9] ;
    assign R10 = R[10];
    assign R11 = R[11];
    assign R12 = R[12];
    assign R13 = R[13];
    assign R14 = R[14];
    assign R15 = R[15];
    assign R16 = R[16];
    assign R17 = R[17];
    assign R18 = R[18];
    assign R19 = R[19];
    assign R20 = R[20];
    assign R21 = R[21];
    assign R22 = R[22];
    assign R23 = R[23];
    assign R24 = R[24];
    assign R25 = R[25];
    assign R26 = R[26];
    assign R27 = R[27];
    assign R28 = R[28];
    assign R29 = R[29];
    assign R30 = R[30];
    assign R31 = R[31];


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


    assign db_instr         = i_wb_pkg.debug_pkg.instr;
    assign db_pc            = i_wb_pkg.debug_pkg.pc;
    assign db_imm           = i_wb_pkg.debug_pkg.imm;
    assign db_rs1_addr      = i_wb_pkg.debug_pkg.rs1_addr;
    assign db_rs2_addr      = i_wb_pkg.debug_pkg.rs2_addr;
    assign db_rd_addr       = i_wb_pkg.debug_pkg.rd_addr;
    assign db_alu_en        = i_wb_pkg.debug_pkg.alu_en;
    assign db_branch_en     = i_wb_pkg.debug_pkg.branch_en;
    assign db_load_en       = i_wb_pkg.debug_pkg.load_en;
    assign db_store_en      = i_wb_pkg.debug_pkg.store_en;
    assign db_mul_en        = i_wb_pkg.debug_pkg.mul_en;
    assign db_div_en        = i_wb_pkg.debug_pkg.div_en;
    assign db_fpu_en        = i_wb_pkg.debug_pkg.fpu_en;
    assign db_use_pc        = i_wb_pkg.debug_pkg.use_pc;
    assign db_use_imm       = i_wb_pkg.debug_pkg.use_imm;
    assign db_use_rs1       = i_wb_pkg.debug_pkg.use_rs1;
    assign db_use_rs2       = i_wb_pkg.debug_pkg.use_rs2;
    assign db_wren          = i_wb_pkg.debug_pkg.wren;
    assign db_valid         = i_wb_pkg.debug_pkg.valid;
    assign db_is_predicted  = i_wb_pkg.debug_pkg.is_predicted;


`endif


endmodule
