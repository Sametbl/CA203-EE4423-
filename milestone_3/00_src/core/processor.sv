// ============================================================
// Filename           : processor.sv
// Module Name        : processor
// Author             : Luong Thanh Vy (CA203 - K22)
// Created On         : 31-08-2025  (DD-MM-YYYY)
// Version            : 1.0.0
// ============================================================

module processor  import pipeline_pkg::*;
(
    input  logic        i_clk          ,
    input  logic        i_rstn         ,

    // Instruction memory interface
    input  logic [31:0] i_imem_data    ,
    input  logic        i_imem_valid   , // High if instruction refill has completed
    input  logic        i_imem_ready   , // High if I-cahce is ready to accept new request

    output logic [31:0] o_imem_addr    , // The PC value
    output logic [3:0]  o_imem_bytemask, // Hardwired to 4'b1111
    output logic        o_imem_valid   , // Asserted to initiate a refill/fetch request
    output logic        o_imem_ready   ,

    // Data memory interface
    input  logic [31:0] i_dmem_rdata   , // Read data from Data memory
    input  logic        i_dmem_valid   , // Data memory acknownledge
    input  logic        i_dmem_ready   , // Data memory is ready to receive request

    output logic [31:0] o_lsu_addr     , // Address for Load/Store operation
    output logic [31:0] o_lsu_wdata    , // Data for Store address
    output logic [3:0]  o_lsu_bmsk     , // Bytemask for Load/Store operation
    output logic        o_lsu_wren     , // Write enable for Store operation
    output logic        o_lsu_valid    , // Request signal to Data memory
    output logic        o_lsu_ready      // Indicate LSU is ready to receive data
);

// Pipeline Control
// Branch misprediction
logic branch_miss_taken;         // Assigned by BRU
logic branch_miss_not_taken;     // Assigned by BRU
logic branch_mispredict_target;  // Assigned by BRU
logic branch_miss;               // Branch Misprediction in General (all cases)

assign branch_miss = (branch_miss_taken) | (branch_miss_not_taken) | (branch_mispredict_target);


// Stall
logic fet_stage_stall;   // IF/ID  buffer stall
logic dcd_stage_stall;   // ID/EX  buffer stall
logic exe_stage_stall;   // EX/MEM buffer stall

logic stall_by_hazard_detection;
logic stall_from_wb;

assign fet_stage_stall   = (stall_from_wb | stall_by_hazard_detection);
assign dcd_stage_stall   = (stall_from_wb | stall_by_hazard_detection);
assign exe_stage_stall   = (stall_from_wb);


// Flush and Clear
logic dec_stage_flush;
logic exe_stage_flush;

assign dec_stage_flush  = (branch_miss);
assign exe_stage_flush  = 1'b0;


// ------------------------------- FETCH ----------------------------------------
branch_t  bru_prd_pkg;    // Data packge from BRU to PRD
fetch_t   fet_dec_pkg;    // Data packge from Fetch stage to Decode stage

fetch_unit  fetch_unit (
        .i_clk            (i_clk                   ),
        .i_rstn           (i_rstn                  ),
        .i_stall          (fet_stage_stall         ),  // Enable signal for the Fetch Stage buffer
        .i_bru_prd_pkg    (bru_prd_pkg             ),  // Input Data package from ALU
        // Branch Misprediction
        .i_prd_miss_t     (branch_miss_taken       ),
        .i_prd_miss_nt    (branch_miss_not_taken   ),
        .i_prd_miss_target(branch_mispredict_target),
        // Instruction cache interface
        .i_imem_data      (i_imem_data             ),  // Input Instruction data from Instruciton Memory
        .i_imem_valid     (i_imem_valid            ),  // Indicates instruction refill has completed
        .i_imem_ready     (i_imem_ready            ),  // Indicates IMEM is ready to accept new request

        .o_imem_addr      (o_imem_addr             ),  // The PC value
        .o_imem_bytemask  (o_imem_bytemask         ),  // Hardwired with 4'hF
        .o_imem_valid     (o_imem_valid            ),  // Initiate a refill/fetch request
        .o_imem_ready     (o_imem_ready            ),  // Initiate fetch unit ready to accept memory data

        .o_fetch_pkg      (fet_dec_pkg             ),  // Registered internally
        .o_error          ()                           // PC mis-aligned
);


// ------------------------------- DECODE (ID) ---------------------------------------
decode_t      dcd_abt_pkg;     // Decode data package in ID stages


logic [31:0]  rf_rs1_data;    // RS1 data from Regfile (rf)
logic [31:0]  rf_rs2_data;    // RS2 data from Regfile (rf)

logic [31:0]  dec_rs1_forwarded;
logic [31:0]  dec_rs2_forwarded;



// Forwarding
pipe_t  alu_wb_pkg_d;
pipe_t  alu_wb_pkg_q;
pipe_t  bru_wb_pkg_d;
pipe_t  bru_wb_pkg_q;
pipe_t  wb_rf_pkg;      // Writeback data package

// Hazard Detection
hazard_t      decode_hazard_pkg;
logic         lsu_ready;     // Indicate LSU is idle and ready to execute
logic         mul_ready;     // Indicate MUL is idle and ready to execute
logic         div_ready;     // Indicate DIV is idle and ready to execute

logic         discard_lsu;
logic         discard_mul;
logic         discard_div;


instruction_decoder    instr_decoder  (
    .i_flush            (dec_stage_flush     ), // Flush valid bit
    .i_fetch_pkg        (fet_dec_pkg         ), // Input  data package from Fetch Stage
    .o_decode_pkg       (dcd_abt_pkg         ), // Output decoded data package
    .o_decode_hazard_pkg(decode_hazard_pkg   ), // Output decoded data package
    .o_ecall            (),                  // Reserved
    .o_ebreak           (),                  // Reserved
    .o_pause            ()                   // Reserved
);


hazard_detection  hazard_detection_unit(
    .i_dcd_hazard_pkg(decode_hazard_pkg        ), // Data from decode for Hazard Detection

    .i_lsu_ready     (lsu_ready                ), // Indicate a AGU is currently idle
    .i_mul_ready     (mul_ready                ), // Indicate a MUL is currently idle
    .i_div_ready     (div_ready                ), // Indicate a DIV is currently idle

    .i_lsu_wren      (lsu_wb_pkg.wren          ), // Indicate Load instruction
    .i_rd_addr_lsu   (lsu_wb_pkg.rd_addr       ),
    .i_rd_addr_mul   (mul_wb_pkg.rd_addr       ),
    .i_rd_addr_div   (div_wb_pkg.rd_addr       ),

    .o_discard_lsu   (discard_lsu              ), // Cancel unnecessary LSU due to WAW hazard
    .o_discard_mul   (discard_mul              ), // Cancel unnecessary MUL due to WAW hazard
    .o_discard_div   (discard_div              ), // Cancel unnecessary DIV due to WAW hazard
    .o_stall         (stall_by_hazard_detection)  // Stall signal due to Hazard
);


int_regfile  int_regfile (
    .i_clk         (i_clk                ),
    .i_rstn        (i_rstn               ),
    .i_wb_pkg      (wb_rf_pkg            ),
    .i_rs1_addr    (dcd_abt_pkg.rs1_addr ),
    .i_rs2_addr    (dcd_abt_pkg.rs2_addr ),
    .o_rs1_data    (rf_rs1_data          ),  // Combinational read
    .o_rs2_data    (rf_rs2_data          )   // Combinational read
);


forwarding_unit  forwarding_unit (
    .i_valid         (dcd_abt_pkg.valid     ),  // The current instruction in ID stage is valid
    .i_use_rs1       (dcd_abt_pkg.use_rs1   ),  // The current instruction in ID stage uses RS1
    .i_use_rs2       (dcd_abt_pkg.use_rs2   ),  // The current instruction in ID stage uses RS2
    .i_rs1_addr      (dcd_abt_pkg.rs1_addr  ),  // Address of Source Register 1
    .i_rs2_addr      (dcd_abt_pkg.rs2_addr  ),  // Address of Source Register 2
    .i_rs1_data      (rf_rs1_data           ),  // Data of Source Register 1 from Regfile
    .i_rs2_data      (rf_rs2_data           ),  // Data of Source Register 2 from Regfile

    .i_alu_fwd_pkg   (alu_wb_pkg_d          ),
    .i_bru_pwd_pkg   (bru_wb_pkg_d          ),
    .i_wb_fwd_pkg    (wb_rf_pkg             ),

    .o_rs1_forwarded (dec_rs1_forwarded     ),
    .o_rs2_forwarded (dec_rs2_forwarded     )
);


// ---------------------------- DECODE STAGE: DISPATH -----------------------------
alu_t       abt_alu_pkg;   // Input data package to ALU
bru_t       abt_bru_pkg;   // Input data package to ALU
lsu_t       abt_lsu_pkg;   // Input data package to ALU
mul_t       abt_mul_pkg;   // Input data package to MUL/DIV
div_t       abt_div_pkg;   // Input data package to MUL/DIV

arbitrator   dispath_and_arbitration(
        .i_invalidate (dcd_stage_stall     ),  // HIGH to Invalidate instruction
        .i_decode_pkg (dcd_abt_pkg         ),  // Decode data package in EX stage
        .i_rs1_data   (dec_rs1_forwarded   ),  // RS1 data from Regfile
        .i_rs2_data   (dec_rs2_forwarded   ),  // RS2 data from Regfile
        .o_alu_pkg    (abt_alu_pkg         ),
        .o_bru_pkg    (abt_bru_pkg         ),
        .o_lsu_pkg    (abt_lsu_pkg         ),  // Output data Package to LSU
        .o_mul_pkg    (abt_mul_pkg         ),
        .o_div_pkg    (abt_div_pkg         )
);


// -------------------------------- EXECUTE -------------------------------
// Data package for Multi-cycle (unpredictable latency) modules
pipe_t  lsu_wb_pkg;  // Internally registered by the module, send to WB stage when fnished
pipe_t  mul_wb_pkg;  // Internally registered by the module, send to WB stage when fnished
pipe_t  div_wb_pkg;  // Internally registered by the module, send to WB stage when fnished

// Writeback acknownledge signal for Multi-cycle (unpredictable latency) modules
logic   wb_lsu_ack;
logic   wb_mul_ack;
logic   wb_div_ack;


alu execute_alu(
    .i_clk         (i_clk            ),
    .i_rstn        (i_rstn           ),
    .i_stall       (exe_stage_stall  ),
    .i_alu_pkg     (abt_alu_pkg      ),  // Input data
    .o_alu_pkg     (alu_wb_pkg_d     )   // Not Internally registered
);


bru  execute_bru (
    .i_clk             (i_clk                   ),
    .i_rstn            (i_rstn                  ),
    .i_stall           (exe_stage_stall         ),
    .i_bru_pkg         (abt_bru_pkg             ), // Input data
    .o_bru_prd_pkg     (bru_prd_pkg             ), // Output data package to Branch Prediction Unit
    .o_bru_pkg         (bru_wb_pkg_d            ), // Output data to writeback
    // Branch Misprediction signals
    .o_prd_miss_t      (branch_miss_taken       ), // Branch "Taken" Misprecition
    .o_prd_miss_nt     (branch_miss_not_taken   ), // Branch "Not Taken" Misprecition
    .o_prd_miss_target (branch_mispredict_target)  // Wrong Predicted Target

);



lsu  execute_lsu(
    .i_clk            (i_clk           ),
    .i_rstn           (i_rstn          ),
    .i_discard        (discard_lsu     ), // HIGH to discard current operation
    .i_lsu_pkg        (abt_lsu_pkg     ),
    .i_wb_ack         (wb_lsu_ack      ),

    // Memory interface (RX)
    .i_dmem_rdata     (i_dmem_rdata   ), // Read data from Data memory
    .i_dmem_valid     (i_dmem_valid   ), // Data memory acknownledge
    .i_dmem_ready     (i_dmem_ready   ), // Data memory is ready to receive request

    // Memory interface (TX)
    .o_lsu_dmem_addr  (o_lsu_addr     ), // Address for Load/Store operation
    .o_lsu_dmem_wdata (o_lsu_wdata    ), // Data for Store address
    .o_lsu_dmem_bmsk  (o_lsu_bmsk     ), // Bytemask for Load/Store operation
    .o_lsu_dmem_wren  (o_lsu_wren     ), // Write enable for Store operation
    .o_lsu_dmem_valid (o_lsu_valid    ), // Request signal to Data memory
    .o_lsu_dmem_ready (o_lsu_ready    ), // Indicate LSU is ready to receive data

    .o_lsu_pkg        (lsu_wb_pkg     ), // Output LSU data package to Writeback
    .o_lsu_ready      (lsu_ready      )
);


mul_unit  execute_mul(
    .i_clk     (i_clk            ),
    .i_rstn    (i_rstn           ),
    .i_discard (discard_mul      ),  // HIGH to discard the current operation
    .i_wb_ack  (wb_mul_ack       ),  // HIGH if writeback request is granted
    .i_mul_pkg (abt_mul_pkg      ),
    .o_mul_pkg (mul_wb_pkg       ),
    .o_ready   (mul_ready        )
);


div_unit  execute_div (
    .i_clk     (i_clk            ),
    .i_rstn    (i_rstn           ),
    .i_wb_ack  (wb_div_ack       ),  // HIGH if writeback request is granted
    .i_discard (discard_div      ),  // HIGH to discard the current operation
    .i_div_pkg (abt_div_pkg      ),
    .o_div_pkg (div_wb_pkg       ),
    .o_ready   (div_ready        ),
    .o_error   ()                // Divide by 0 (FIXME: Not used)
);


// ------------- EX to WB stage buffer (For ALU and BRU)
prim_register_clr #(.WIDTH($bits(alu_wb_pkg_q))) alu_ex_buffer (
    .i_clk   (i_clk            ),
    .i_rstn  (i_rstn           ),
    .i_clear (exe_stage_flush  ),
    .i_en    (~exe_stage_stall ),
    .i_d     (alu_wb_pkg_d     ),
    .o_q     (alu_wb_pkg_q     )
);

prim_register_clr #(.WIDTH($bits(bru_wb_pkg_q))) bru_ex_buffer (
    .i_clk   (i_clk            ),
    .i_rstn  (i_rstn           ),
    .i_clear (exe_stage_flush  ),
    .i_en    (~exe_stage_stall ),
    .i_d     (bru_wb_pkg_d     ),
    .o_q     (bru_wb_pkg_q     )
);


// -------------------------------- WRITEBACK ----------------------------------
writeback_arbiter  writeback_arbitrator (
    .i_alu_wb_pkg(alu_wb_pkg_q  ),
    .i_bru_wb_pkg(bru_wb_pkg_q  ),
    .i_lsu_wb_pkg(lsu_wb_pkg    ),
    .i_mul_wb_pkg(mul_wb_pkg    ),
    .i_div_wb_pkg(div_wb_pkg    ),

    .o_ack_wb_lsu(wb_lsu_ack    ),
    .o_ack_wb_mul(wb_mul_ack    ),
    .o_ack_wb_div(wb_div_ack    ),

    .o_wb_pkg    (wb_rf_pkg     ),
    .o_stall     (stall_from_wb )
);




endmodule



