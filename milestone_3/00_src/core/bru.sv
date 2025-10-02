
module bru   import pipeline_pkg::*;
(
    input  logic          i_clk               ,
    input  logic          i_rstn              ,
    input  logic          i_stall             ,
    input  bru_t          i_bru_pkg           , // Input data

    output branch_t       o_bru_prd_pkg       , // Output data package to updating Branch Prediction
    output pipe_t         o_bru_pkg           ,
    output logic          o_prd_miss_t        , // Branch "Taken" Misprecition
    output logic          o_prd_miss_nt       , // Branch "Not Taken" Misprecition
    output logic          o_prd_miss_target     // Wrong Predicted Target

);


// DECODE to BRU (EX) stage buffer
bru_t  bru_pkg_q;

prim_register_clr #(.WIDTH($bits(bru_pkg_q))) bru_stage_buffer (
            .i_clk  (i_clk                      ),
            .i_rstn (i_rstn                     ),
            .i_en   (~i_stall                   ),
            .i_clear(~i_stall & ~i_bru_pkg.valid),
            .i_d    (i_bru_pkg                  ),
            .o_q    (bru_pkg_q                  )
);


// Alias
logic [7:0]   branch_op;
logic [31:0]  pc;
logic [31:0]  offset;
logic [31:0]  rs1_data;
logic [31:0]  rs2_data;
logic [4:0]   rd_addr;
logic         wren;
logic         valid;
logic         is_predicted;
logic [31:0]  predicted_target;


// Branch_op interpretation
logic         beq;
logic         bne;
logic         blt;
logic         bge;
logic         bltu;
logic         bgeu;
logic         jal;
logic         jalr;

always_comb begin : signal_alias_and_rename
    branch_op        = bru_pkg_q.branch_op;
    pc               = bru_pkg_q.pc;
    offset           = bru_pkg_q.offset;
    rs1_data         = bru_pkg_q.rs1_data;
    rs2_data         = bru_pkg_q.rs2_data;
    rd_addr          = bru_pkg_q.rd_addr;
    wren             = bru_pkg_q.wren;
    valid            = bru_pkg_q.valid;
    is_predicted     = bru_pkg_q.is_predicted;
    predicted_target = bru_pkg_q.predicted_target;
end

always_comb begin : branch_op_interpretation
    beq    = branch_op[0];
    bne    = branch_op[1];
    blt    = branch_op[2];
    bge    = branch_op[3];
    bltu   = branch_op[4];
    bgeu   = branch_op[5];
    jal    = branch_op[6];
    jalr   = branch_op[7];
end

// ======================  BRANCH COMPARISON ========================
logic br_signed_cmp;    // Indicate RS1 and RS2 comparison is unsigned
logic rs1_eq_rs2;       // Indicate RS1 equal        RS2
logic rs1_lt_rs2;       // Indicate RS1 less than    RS2
logic rs1_gt_rs2;       // Indicate RS1 greater than RS2

assign br_signed_cmp = ~bltu & ~bgeu;

prim_cmp_mag_32bit  Branch_comparison(
    .i_a         (rs1_data        ),
    .i_b         (rs2_data        ),
    .i_signed_en (br_signed_cmp   ),
    .o_eq        (rs1_eq_rs2      ),
    .o_gt        (rs1_gt_rs2      ),
    .o_lt        (rs1_lt_rs2      )
);

// ======================  TARGET CALCULATION ========================
logic [31:0] base_addr;   // Base address to calculate Branch Target (PC or rs1)
logic [31:0] target;
logic [31:0] pc_plus4;

prim_mux_2x1   mux_sel_base_addr(
    .i_sel(jalr      ),
    .i_0  (pc        ),
    .i_1  (rs1_data  ),
    .o_mux(base_addr )  // PC or rs1
);

prim_adder_32bit  Adder_Target_Cal (
    .i_a    (base_addr  ),
    .i_b    (offset     ),
    .i_sub  (1'b0       ),
    .o_sum  (target     ),
    .o_cout ()
);

prim_adder_32bit  Adder_PC_plus4 (
    .i_a    (pc           ),  // current PC
    .i_b    (32'h0000_0004),
    .i_sub  (1'b0         ),
    .o_sum  (pc_plus4     ),  // PC + 4
    .o_cout ()
);


// ======================  BRANCH CONLUSION ========================
logic br_taken;  // Indicate the Branch instruction is result in Taken

assign br_taken =  (beq  &  rs1_eq_rs2) |   // 1. Brnach if Equal
                   (bne  & ~rs1_eq_rs2) |   // 2. Branch if Not Equal
                   (blt  &  rs1_lt_rs2) |   // 3. Branch if Less Than
                   (bge  &  rs1_gt_rs2) |   // 4. Branch if Greater or Equal
                   (bge  &  rs1_eq_rs2) |   // 4. Branch if Greater or Equal
                   (bltu &  rs1_lt_rs2) |   // 5. Branch if Less Than - Unsigned
                   (bgeu &  rs1_gt_rs2) |   // 6. Branch if Greater or Equal - Unsigned
                   (bgeu &  rs1_eq_rs2) |   // 6. Branch if Greater or Equal - Unsigned
                   (jal | jalr);            // 7. Unconditional branch




// ======================= BRANCH MISPREDICITON DETECTION ========================
logic br_miss_t;
logic br_miss_nt;
logic br_mispredict_target;
logic predicted_target_matched;


prim_cmp_eq #(.WIDTH(32)) predicted_target_cmp (
    .i_a (predicted_target         ),
    .i_b (target                   ),
    .o_eq(predicted_target_matched )
);

assign br_miss_t             = (valid & ~br_taken) & ( is_predicted);
assign br_miss_nt            = (valid &  br_taken) & (~is_predicted);
assign br_mispredict_target  = (valid &  br_taken) & ( is_predicted) & (~predicted_target_matched);


// ====================== BRU stage buffer ========================
// Output
// To Branch Prediction Unit
assign o_bru_prd_pkg.br_update_pc          = pc;
assign o_bru_prd_pkg.br_pc_plus4           = pc_plus4;
assign o_bru_prd_pkg.br_target             = target;
assign o_bru_prd_pkg.br_taken              = br_taken;
assign o_bru_prd_pkg.br_valid              = valid;



// To Writeback
assign o_bru_pkg.rd_data   = pc_plus4;
assign o_bru_pkg.rd_addr   = rd_addr;
assign o_bru_pkg.wren      = wren;
assign o_bru_pkg.valid     = valid;
assign o_bru_pkg.rd_is_int = 1'b1;     // Used to differentiate data from FPU



// Brnach Misprediction
assign o_prd_miss_t      = br_miss_t;
assign o_prd_miss_nt     = br_miss_nt;
assign o_prd_miss_target = br_mispredict_target;


// =====================================================================
// ============================= DEBUG =================================
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


assign db_instr         = bru_pkg_q.debug_pkg.instr;
assign db_pc            = bru_pkg_q.debug_pkg.pc;
assign db_imm           = bru_pkg_q.debug_pkg.imm;
assign db_rs1_addr      = bru_pkg_q.debug_pkg.rs1_addr;
assign db_rs2_addr      = bru_pkg_q.debug_pkg.rs2_addr;
assign db_rd_addr       = bru_pkg_q.debug_pkg.rd_addr;
assign db_alu_en        = bru_pkg_q.debug_pkg.alu_en;
assign db_branch_en     = bru_pkg_q.debug_pkg.branch_en;
assign db_load_en       = bru_pkg_q.debug_pkg.load_en;
assign db_store_en      = bru_pkg_q.debug_pkg.store_en;
assign db_mul_en        = bru_pkg_q.debug_pkg.mul_en;
assign db_div_en        = bru_pkg_q.debug_pkg.div_en;
assign db_fpu_en        = bru_pkg_q.debug_pkg.fpu_en;
assign db_use_pc        = bru_pkg_q.debug_pkg.use_pc;
assign db_use_imm       = bru_pkg_q.debug_pkg.use_imm;
assign db_use_rs1       = bru_pkg_q.debug_pkg.use_rs1;
assign db_use_rs2       = bru_pkg_q.debug_pkg.use_rs2;
assign db_wren          = bru_pkg_q.debug_pkg.wren;
assign db_valid         = bru_pkg_q.debug_pkg.valid;
assign db_is_predicted  = bru_pkg_q.debug_pkg.is_predicted;

assign o_bru_pkg.debug_pkg = bru_pkg_q.debug_pkg;

`endif


endmodule


