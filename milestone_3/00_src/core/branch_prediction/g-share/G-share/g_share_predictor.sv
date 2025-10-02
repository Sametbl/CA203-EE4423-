module g_share_predictor #(parameter int PHT_SIZE = 256)(
    input  logic        i_clk             ,
    input  logic        i_rstn            ,
    input  logic [31:0] i_current_pc      ,
    input  logic [31:0] i_br_update_pc    ,
    input  logic        i_br_update_valid ,
    input  logic        i_br_update_taken ,
    output logic        o_prediction_bit   // HIGH = predicted taken
);




// GHR size = 8.
// Larger GHR might improve accuracy but higher cost due to the size of PHT
// Size of PHT = 2^sizeof(GHR)
// The LSB of GHR is the oldest/newest bit. GHR shift in from LSB.

// ============================= INDEX CALCULATION ===========================
logic [7:0] GHR;                   // Global History Register      (Store recent branch pattern)
logic [1:0][PHT_SIZE-1:0] PHT ;    // Pattern History Table (PHT)  (Sotre 2-bit predictor)



prim_left_shift_register #(.WIDTH(8)) GHR_update (
    .i_clk       (i_clk             ),
    .i_rstn      (i_rstn            ),
    .i_en        (i_br_update_valid ),
    .i_shift_in  (i_br_update_taken ),
    .i_load      (1'b0              ),
    .i_load_data (32'h0000_0000     ),
    .o_q         (GHR               )
);



// ============================= UPDATE PHT ===========================
logic [7:0] pht_index_update;
logic [1:0] current_counter_update;
logic [1:0] new_counter;

// XORing to get Index sharing of PC and GHR
assign pht_index_update         = i_br_update_pc[9:2] ^ GHR;

// Get the current BHT counter
assign current_counter_update   = PHT[pht_index_update];


// Logic Optimized: i_br_update_valid must be set for changes
saturation_adder_2bit predictor_adder (
    .i_carry_in ( i_br_update_valid      ),  // HIGH to increment/decrement counter
    .i_sub_mode (~i_br_update_taken      ),  // HIGH to decrement saturate counter
    .i_data_in  ( current_counter_update ),
    .o_data_out ( new_counter            )
);


always_ff @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) PHT <= '{default: 2'b00};
    else         PHT[pht_index_update]  <= new_counter;
end



// ============================= PREDICTION ===========================
logic [7:0] pht_index_predict;
logic [1:0] current_counter_predict;

assign pht_index_predict        = i_current_pc[9:2] ^ GHR;   // XORing to get Index
assign current_counter_predict  = PHT[pht_index_predict];
assign o_prediction_bit         = current_counter_predict[1];



endmodule





