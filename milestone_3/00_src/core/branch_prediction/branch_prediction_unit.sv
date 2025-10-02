// ============================================================
// Filename           : basic_branch_prediction_unit.sv
// Module Name        : basic_branch_prediction_unit
// Author             : Luong Thanh Vy (CA203 - K22)
// Created On         : DD-MM-2025  (DD-MM-YYYY)
// Module Description : Basic Branch Prediction with 2-bit predictor
// Version            : 1.0.0
// ============================================================

// This module in integrated in "next_pc_unit"

module branch_prediction_unit (
    input  logic        i_clk              ,
    input  logic        i_rstn             ,
    input  logic [31:0] i_current_pc       ,  // Current program counter for prediction
    input  logic [31:0] i_br_update_pc     ,
    input  logic [31:0] i_br_update_target ,  // Actual branch target provided by BRU when updating
    input  logic        i_br_update_valid  ,
    input  logic        i_br_update_taken  ,  // HIGH when actual Branch result from BRU is TAKEN
    output logic [31:0] o_prd_target       ,  // Predicted branch target address
    output logic        o_prd_taken           // Indicates a prediction is made
);

logic [31:0] prd_target;
logic        prediction_bit;


btb #(.ENTRIES(1024))  btb  (
        .i_clk               (i_clk              ),
        .i_rstn              (i_rstn             ),
        .i_current_pc        (i_current_pc       ), // PC from pc/fetch stage for branch prediction
        // Update from BRU after executing a branch
        .i_br_update_pc      (i_br_update_pc     ), // PC of the executed Brnach instruction
        .i_br_update_target  (i_br_update_target ), // Target of the executed Branch instruction
        .i_br_update_valid   (i_br_update_valid  ), // Indicate a valid Branch instr just executed
        .i_br_taken          (i_br_update_taken  ), // Result of the excuted Branch instruction

        .o_btb_target        (prd_target         ), // Output predicted target
        .o_pred_taken        (prediction_bit     )  // MSB of 2-bit counter
);


// Output
 `ifdef NO_PREDICTION
    assign o_prd_taken   =  1'b0;           // Not taken when updating BTB
    assign o_prd_target  =  32'h0000_0000;
`else
    assign o_prd_taken   =  (prediction_bit);    // Not taken when updating BTB
    assign o_prd_target  =  (prd_target);
`endif


endmodule



