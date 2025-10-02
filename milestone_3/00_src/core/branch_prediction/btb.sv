// ============================================================
// Filename           : btb.sv
// Module Name        : btb
// Author             : Luong Thanh Vy (CA203 - K22)
// Created On         : 15-08-2025  (DD-MM-YYYY)
// Module Description :
// Module Purpose     :
// Notes              :
// Version            : 1.0.0
// ============================================================


module btb #(parameter int ENTRIES = 64)(
    input  logic        i_clk,
    input  logic        i_rstn,
    input  logic [31:0] i_current_pc,       // PC from pc/fetch stage for branch prediction

    // Update from BRU after executing a branch
    input  logic        i_br_update_valid , // Indicate a valid Branch instruction just executed
    input  logic [31:0] i_br_update_pc    , // PC of the executed Brnach instruction
    input  logic [31:0] i_br_update_target, // Target of the executed Branch instruction
    input  logic        i_br_taken        , // Result of the excuted Branch instruction

    output logic [31:0] o_btb_target      , // Output predicted target
    output logic        o_pred_taken        // MSB of 2-bit counter, decide whether to Taken or not
);

localparam int IndexWidth = $clog2(ENTRIES);        // index width
localparam int TagWidth   = 32 - (IndexWidth + 2);  // tag width (ignore [1:0])

// BTB storage
logic [TagWidth-1:0] tag_mem   [ENTRIES];    // Tag
logic [31:0]         bta_mem   [ENTRIES];    // Branch Target Address
logic [1:0]          bht_mem   [ENTRIES];    // Branch History Table (2-bit saturating counter)
logic                valid_mem [ENTRIES];    // Valid-bit


// ============================= Index/tag extraction ================================
logic [IndexWidth-1:0] upd_idx;   // BTB update index (from i_br_update_pc)
logic [TagWidth-1:0]   upd_tag;   // BTB update tag   (from i_br_update_pc)

logic [IndexWidth-1:0] rd_idx;    // BTB update index (from i_current_pc)
logic [TagWidth-1:0]   rd_tag;    // BTB update tag   (from i_current_pc)

// Lookup (combinational)
logic tag_match;   // Indicate a Tag match from i_current_pc
logic valid_bit;   // Alias

assign upd_idx = i_br_update_pc[IndexWidth + 1 : 2];  // Ignore i_br_update_pc[1:0]
assign upd_tag = i_br_update_pc[31: 32 - TagWidth];   // Other bits used as Tag

assign rd_idx  = i_current_pc[IndexWidth + 1 : 2];    // Ignore i_current_pc[1:0]
assign rd_tag  = i_current_pc[31 : 32 - TagWidth];    // Other bits used as Tag

assign valid_bit  = valid_mem[rd_idx];
assign tag_match  = (tag_mem[rd_idx] == rd_tag);


// ============================= Index/tag extraction ================================
logic [1:0] pred_crnt_state;   // 2-bit predictor of current stage
logic [1:0] pred_next_state;   // 2-bit predictor of next stage

assign pred_crnt_state = bht_mem[upd_idx];

saturation_adder_2bit u_pred_sat2 (
    .i_carry_in (i_br_update_valid  ),  // HIGH to increment/decrement counter (acts like enable)
    .i_sub_mode (~i_br_taken        ),  // HIGH to decrement saturate counter
    .i_data_in  (pred_crnt_state    ),
    .o_data_out (pred_next_state    )
);



always_ff @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin : reset_btb
        for (int i = 0; i < ENTRIES; i++) begin
            tag_mem  [i]   <=   {(TagWidth){1'b0}};
            bta_mem  [i]   <=   32'h0000_0000;
            bht_mem  [i]   <=   2'b01;  // weakly not taken
            valid_mem[i]   <=   1'b0;
        end
    end

    else if (i_br_update_valid) begin : update_btb
        tag_mem  [upd_idx]    <=   upd_tag;
        bta_mem  [upd_idx]    <=   i_br_update_target;
        bht_mem  [upd_idx]    <=   pred_next_state;   // update via saturation module
        valid_mem[upd_idx]    <=   1'b1;
    end
end


// Output
assign hit = valid_bit & tag_match;

assign o_pred_taken  = hit & bht_mem[rd_idx][1];        // MSB decides taken/not taken
assign o_btb_target  = hit ? bta_mem[rd_idx] : 32'h0000_0000;

endmodule
