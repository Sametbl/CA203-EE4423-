// ============================================================
// Filename           : fetch_unit.sv
// Module Name        : fetch_unit
// Author             : Luong Thanh Vy (CA203 - K22)
// Created On         : 04-09-2025  (DD-MM-YYYY)
// Version            : 2.0.0
// ============================================================


import pipeline_pkg::branch_t;
import pipeline_pkg::fetch_t;

module fetch_unit(
        input  logic        i_clk            ,
        input  logic        i_rstn           ,
        input  logic        i_stall          ,  // Stall signal for the Fetch Stage buffer
        input  branch_t     i_bru_prd_pkg    ,  // Input Data package from BRU

        // Branch Misprediction signal from BRU
        input  logic        i_prd_miss_t     ,  // Branch "Taken" Misprecition
        input  logic        i_prd_miss_nt    ,  // Branch "Not Taken" Misprecition
        input  logic        i_prd_miss_target,  // Wrong Predicted Target

        // Instruction cache interface
        input  logic [31:0] i_imem_data      ,  // Input data from Instruciton Memory
        input  logic        i_imem_valid     ,  // Indicate instruction refill has completed
        input  logic        i_imem_ready     ,  // Indicate IMEM is ready to accept new request

        output logic [31:0] o_imem_addr      ,  // Output PC vbrue
        output logic [3:0]  o_imem_bytemask  ,  // Output bytemask
        output logic        o_imem_valid     ,  // Initiate a refill/fetch request
        output logic        o_imem_ready     ,  // Initiate fetch unit ready to accept memory data

        output fetch_t      o_fetch_pkg      ,  // Output PC for Instruction Fetch stages
        output logic        o_error             // Indicate PC mis-aligned
);


typedef enum bit [1:0] {
        INIT      ,   // Initial state after reset (Disable PC + 4)
        NORMAL    ,   // Normal state
        IMEM_MISS ,   // State to wait for data from IMEM or resolve Cache Miss
        ERROR         // PC is misaligned, reset requried

} state_t;

state_t Pre_State;
state_t Next_State;

logic NORMAL_stage;
logic ERROR_stage;

logic pc_misaligned;
logic instr_valid;

assign NORMAL_stage  = (Pre_State == NORMAL    );
assign ERROR_stage   = (Pre_State == ERROR     );

always_ff@ (posedge i_clk, negedge i_rstn) begin
    if (!i_rstn)         Pre_State   <=   INIT;
    else                 Pre_State   <=   Next_State;
end

always_comb begin
    case(Pre_State)
        INIT:                                 Next_State = IMEM_MISS;

        IMEM_MISS:   if (pc_misaligned)       Next_State = ERROR;
                     else if (i_imem_ready)   Next_State = NORMAL;
                     else                     Next_State = IMEM_MISS;

        NORMAL:      if (pc_misaligned)       Next_State = ERROR;
                     else if (!i_imem_valid)  Next_State = IMEM_MISS;
                     else                     Next_State = NORMAL;

        ERROR:                                Next_State = ERROR; // Infinite loop (wait for reset)

        default:                              Next_State = INIT;
    endcase
end


// ---------------------------- BRANCH PREDICTION -----------------------------
logic [31:0] prd_br_target;       // Predicted Target from BTB
logic        prd_br_taken;        // Branch Prediction signal

logic [31:0] bru_update_pc;       // PC     of the executing Branch instrion from BRU
logic [31:0] bru_pc_plus_4;       // PC + 4 of the executing Branch instrion from BRU
logic [31:0] bru_update_target;   // Target of the executing Branch instrion from BRU
logic        bru_update_taken;    // Indicate result of Branch instr from BRU is Taken
logic        bru_update_valid;    // Indicate Branch instr data from BRU is Valid

logic [31:0] next_pc_d;      // Next PC before PC register
logic [31:0] next_pc_q;      // Next PC after  PC register
logic [31:0] pc_plus_4;      // PC + 4 of current PC

logic        branch_miss;    // Branch misprediction signal (general)

always_comb begin : br_prd_signal_aliases
        bru_update_pc            = i_bru_prd_pkg.br_update_pc;
        bru_pc_plus_4            = i_bru_prd_pkg.br_pc_plus4;
        bru_update_target        = i_bru_prd_pkg.br_target;
        bru_update_valid         = i_bru_prd_pkg.br_valid;
        bru_update_taken         = i_bru_prd_pkg.br_taken;
end

assign branch_miss = (i_prd_miss_t) | (i_prd_miss_nt) | (i_prd_miss_target);


branch_prediction_unit  PRD(
        .i_clk              (i_clk            ),
        .i_rstn             (i_rstn           ),
        .i_current_pc       (next_pc_q        ),  // Current program counter for prediction
        .i_br_update_pc     (bru_update_pc    ),
        .i_br_update_target (bru_update_target),  // Actual branch target provided by BRU
        .i_br_update_valid  (bru_update_valid ),
        .i_br_update_taken  (bru_update_taken ),  // HIGH if Branch result from BRU is TAKEN
        .o_prd_target       (prd_br_target    ),  // Predicted branch target address
        .o_prd_taken        (prd_br_taken     )   // Indicates a prediction is made
);


// -------------------------------- PC + 4 computation --------------------------

prim_adder_32bit adder_pc_plus4 (
    .i_a    (next_pc_q                                         ),
    .i_b    (({29'h0000_0000, NORMAL_stage & ~i_stall, 2'b00}) ), // Current PC
    .i_sub  (1'b0                                              ),
    .o_sum  (pc_plus_4                                         ), // PC + 4
    .o_cout (                                                  )
);


// -------------------------------- PC selection  -------------------------------
logic [1:0]  pc_sel;  // Select signal to select the next PC from MUX

logic        bru_jump_to_target;   // Indicate Next_PC = BRU's [Target result]
logic        bru_restore_pc_plus4; // Indicate Next_PC = BRU's [PC+4]

// PC_sel == 2'b00 : Next PC = PC + 4           (default)
// PC_sel == 2'b01 : Next PC = Target from BRU  (When "Not Taken" misprediction, or Predicted Target Mismatch)
// PC_sel == 2'b10 : Next PC = PC + 4 from BRU  (Restore PC from "Taken" misprediction)
// PC_sel == 2'b11 : Next PC = Target from PRD  (When Predicted by PRD)

assign bru_restore_pc_plus4 = (i_prd_miss_t);
assign bru_jump_to_target   = (i_prd_miss_nt) | (i_prd_miss_target);

assign pc_sel[0] = (bru_jump_to_target  ) | (prd_br_taken & ~bru_restore_pc_plus4);
assign pc_sel[1] = (bru_restore_pc_plus4) | (prd_br_taken & ~bru_jump_to_target  );


prim_mux_4x1   pc_mux (
        .i_sel(pc_sel           ),
        .i_0  (pc_plus_4        ),
        .i_1  (bru_update_target),
        .i_2  (bru_pc_plus_4    ),
        .i_3  (prd_br_target    ),
        .o_mux(next_pc_d        )
);


prim_register pc_register (
    .i_clk   (i_clk                   ),
    .i_rstn  (i_rstn                  ),
    .i_en    (~i_stall | branch_miss  ), // Enable register even when being stalled
    .i_d     (next_pc_d               ),
    .o_q     (next_pc_q               )
);


// ----------------------- Fetching Instruction from Memory Cache --------------------

// Validation: PC is divisible by 4 - PC[1:0] = 2'b00
assign pc_misaligned = (next_pc_q[1] | next_pc_q[0]);
assign instr_valid   = (|i_imem_data) & (~pc_misaligned) & (i_imem_valid) & (NORMAL_stage);



// --------------------------------- Fetch Stage Buffer ------------------------------
fetch_t   fetch_pkg_d;

assign fetch_pkg_d.instr            = i_imem_data;
assign fetch_pkg_d.pc               = next_pc_q;
assign fetch_pkg_d.valid            = instr_valid;
assign fetch_pkg_d.is_predicted     = prd_br_taken;
assign fetch_pkg_d.predicted_target = prd_br_target;


// Output: IF Buffer
// Sill request IMEM if branch mispredicted while stalling
always_comb begin : imem_request_control
    o_imem_addr     = next_pc_d;
    o_imem_bytemask = 4'b1111;    // Always fetch 4-byte
    o_imem_valid    = ~i_stall | branch_miss;
    o_imem_ready    = ~i_stall | branch_miss;
end


// Register with clear pin
prim_register_clr #(.WIDTH($bits(o_fetch_pkg))) fetch_stage_buffer (
    .i_clk   (i_clk        ),
    .i_rstn  (i_rstn       ),
    .i_clear (branch_miss  ),
    .i_en    (~i_stall     ),
    .i_d     (fetch_pkg_d  ),
    .o_q     (o_fetch_pkg  )
);

assign o_error       = ERROR_stage;  // PC mis-aligned, reset requried


endmodule : fetch_unit



