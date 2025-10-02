// ============================================================
// Filename           : riscv_writeback_crossbar.sv
// Module Name        : riscv_writeback_crossbar
// Author             : Luong Thanh Vy (CA203 - K22)
// Created On         : 01-08-2025  (DD-MM-YYYY)
// Module Description : Re-ordering module for Register file write ports
// Version            : 1.0.0
// ============================================================

module writeback_arbiter import pipeline_pkg::*;
(
    input  pipe_t        i_alu_wb_pkg  ,
    input  pipe_t        i_bru_wb_pkg  ,
    input  pipe_t        i_lsu_wb_pkg  ,
    input  pipe_t        i_mul_wb_pkg  ,
    input  pipe_t        i_div_wb_pkg  ,

    output logic         o_ack_wb_lsu  ,
    output logic         o_ack_wb_mul  ,
    output logic         o_ack_wb_div  ,

    output logic         o_stall       ,
    output pipe_t        o_wb_pkg
);

// Alias
logic alu_valid;
logic bru_valid;
logic req_lsu;
logic req_mul;
logic req_div;

always_comb begin : signal_extraction_and_renaming
    alu_valid  = i_alu_wb_pkg.valid  & i_alu_wb_pkg.wren;
    bru_valid  = i_bru_wb_pkg.valid  & i_bru_wb_pkg.wren;
    req_lsu    = i_lsu_wb_pkg.valid  & i_lsu_wb_pkg.wren;
    req_mul    = i_mul_wb_pkg.valid  & i_mul_wb_pkg.wren;
    req_div    = i_div_wb_pkg.valid  & i_div_wb_pkg.wren;
end


// =============================== Request selection ========================
pipe_t wb_pkg_d;

logic [2:0] wb_mux_sel;
logic [2:0] wb_ack;  // wb_ack[0]: lsu writeback ack signal
                     // wb_ack[1]: mul writeback ack signal
                     // wb_ack[2]: div writeback ack signal



// Prioritize table: fpu1 has the highest while lsu has the lowest priority

// Prioritize table: fpu1 has the highest while lsu has the lowest priority
prim_mux_32x1  #(.WIDTH(6)) mux_writeback_truth_table (
    .i_sel ({req_div, req_mul, req_lsu, bru_valid, alu_valid} ),
    .i_0   ({3'b000, 3'b000}      ),
    .i_1   ({3'b001, 3'b000}      ),
    .i_2   ({3'b010, 3'b000}      ),
    .i_3   ({3'b111, 3'b000}      ),
    .i_4   ({3'b011, 3'b001}      ),
    .i_5   ({3'b011, 3'b001}      ),
    .i_6   ({3'b011, 3'b001}      ),
    .i_7   ({3'b111, 3'b001}      ),
    .i_8   ({3'b100, 3'b010}      ),
    .i_9   ({3'b100, 3'b010}      ),
    .i_10  ({3'b100, 3'b010}      ),
    .i_11  ({3'b111, 3'b010}      ),
    .i_12  ({3'b011, 3'b001}      ),
    .i_13  ({3'b011, 3'b001}      ),
    .i_14  ({3'b011, 3'b001}      ),
    .i_15  ({3'b111, 3'b001}      ),
    .i_16  ({3'b101, 3'b100}      ),
    .i_17  ({3'b101, 3'b100}      ),
    .i_18  ({3'b101, 3'b100}      ),
    .i_19  ({3'b111, 3'b100}      ),
    .i_20  ({3'b011, 3'b001}      ),
    .i_21  ({3'b011, 3'b001}      ),
    .i_22  ({3'b011, 3'b001}      ),
    .i_23  ({3'b111, 3'b001}      ),
    .i_24  ({3'b100, 3'b010}      ),
    .i_25  ({3'b100, 3'b010}      ),
    .i_26  ({3'b100, 3'b010}      ),
    .i_27  ({3'b111, 3'b010}      ),
    .i_28  ({3'b011, 3'b001}      ),
    .i_29  ({3'b011, 3'b001}      ),
    .i_30  ({3'b011, 3'b001}      ),
    .i_31  ({3'b111, 3'b001}      ),
    .o_mux ({wb_mux_sel, wb_ack}  )
);


prim_mux_8x1  #(.WIDTH($bits(wb_pkg_d)))  writeback_mux (
    .i_sel (wb_mux_sel                    ),
    .i_0   ({{($bits(wb_pkg_d)){1'b0}}}   ),  // No data to writeback (writeback pkg = 0)
    .i_1   (i_alu_wb_pkg                  ),
    .i_2   (i_bru_wb_pkg                  ),
    .i_3   (i_lsu_wb_pkg                  ),
    .i_4   (i_mul_wb_pkg                  ),
    .i_5   (i_div_wb_pkg                  ),
    .i_6   ({{($bits(wb_pkg_d)){1'b0}}}   ),  // Reserved
    .i_7   ({{($bits(wb_pkg_d)){1'b0}}}   ),  // Reserved
    .o_mux (wb_pkg_d                      )
);


// ========================= Regfile write data selection =============================
// Output
assign o_wb_pkg = wb_pkg_d;


// Ack signals for requested pipeline
assign o_ack_wb_lsu  = wb_ack[0];
assign o_ack_wb_mul  = wb_ack[1];
assign o_ack_wb_div  = wb_ack[2];


// Stall from Wrtieback when occupied by Multi-cycled (unpredictable latency) module
assign o_stall = (req_lsu | req_mul | req_div);





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


assign db_instr         = wb_pkg_d.debug_pkg.instr;
assign db_pc            = wb_pkg_d.debug_pkg.pc;
assign db_imm           = wb_pkg_d.debug_pkg.imm;
assign db_rs1_addr      = wb_pkg_d.debug_pkg.rs1_addr;
assign db_rs2_addr      = wb_pkg_d.debug_pkg.rs2_addr;
assign db_rd_addr       = wb_pkg_d.debug_pkg.rd_addr;
assign db_alu_en        = wb_pkg_d.debug_pkg.alu_en;
assign db_branch_en     = wb_pkg_d.debug_pkg.branch_en;
assign db_load_en       = wb_pkg_d.debug_pkg.load_en;
assign db_store_en      = wb_pkg_d.debug_pkg.store_en;
assign db_mul_en        = wb_pkg_d.debug_pkg.mul_en;
assign db_div_en        = wb_pkg_d.debug_pkg.div_en;
assign db_fpu_en        = wb_pkg_d.debug_pkg.fpu_en;
assign db_use_pc        = wb_pkg_d.debug_pkg.use_pc;
assign db_use_imm       = wb_pkg_d.debug_pkg.use_imm;
assign db_use_rs1       = wb_pkg_d.debug_pkg.use_rs1;
assign db_use_rs2       = wb_pkg_d.debug_pkg.use_rs2;
assign db_wren          = wb_pkg_d.debug_pkg.wren;
assign db_valid         = wb_pkg_d.debug_pkg.valid;
assign db_is_predicted  = wb_pkg_d.debug_pkg.is_predicted;

// Both ALU and BRU are valid
logic writeback_error;

assign writeback_error = (wb_mux_sel == 3'b111);

`endif



endmodule

