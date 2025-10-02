
module mul_unit    import pipeline_pkg::*;
(
    input  logic          i_clk           ,
    input  logic          i_rstn          ,
    input  logic          i_wb_ack        ,  // HIGH if writeback request is granted
    input  logic          i_discard       ,  // HIGH to discard the current operation
    input  mul_t          i_mul_pkg       ,
    output pipe_t         o_mul_pkg       ,
    output logic          o_ready
);


// Instruction data packed to held while executing multiplication
typedef struct packed  {
        logic [4:0]   rd_addr;
        logic [1:0]   mul_op;
        logic         wren;
        logic         valid;
`ifdef DEBUG
        debug_t       debug_pkg;
`endif
} mul_ctrl_t;  // Destination control signals

// FSM
typedef enum logic [1:0] {
    IDLE,
    EXECUTE,
    REQUEST
}  state_t;

state_t      Pre_state;
state_t      Next_state;

mul_ctrl_t   mul_ctrl_d;
mul_ctrl_t   mul_ctrl_q;

logic        IDLE_stage;
logic        REQUEST_stage;

logic [63:0] mul_product;
logic        mul_op_a_signed_en;
logic        mul_op_b_signed_en;
logic        mul_done;           // Indicate the MUL is DONE (result availables in next cycle)

logic [31:0] mul_product_low;
logic [31:0] mul_product_high;
logic [31:0] mul_data;
logic        mul_data_sel;


logic [1:0]  pre_mul_op;
logic        pre_valid;
logic        mul_start;

assign pre_mul_op = i_mul_pkg.mul_op;
assign pre_valid  = i_mul_pkg.valid;

// mul_op = 2'b00: rd = (rs1 * rs2) [31:0]  (signed   x signed)
// mul_op = 2'b01: rd = (rs1 * rs2) [63:32] (signed   x signed)
// mul_op = 2'b10: rd = (rs1 * rs2) [63:32] (signed   x unsigned)
// mul_op = 2'b11: rd = (rs1 * rs2) [63:32] (unsigned x unsigned)

assign IDLE_stage         = (Pre_state == IDLE      );
assign REQUEST_stage      = (Pre_state == REQUEST   );

always_comb begin : start_mul_configuration
    mul_op_a_signed_en = ~(pre_mul_op[1] & pre_mul_op[0]);
    mul_op_b_signed_en = ~(pre_mul_op[1]);
    mul_start = ~i_discard & (pre_valid) & (IDLE_stage | REQUEST_stage & i_wb_ack);
end


always_comb begin: register_input_assignment
    mul_ctrl_d.rd_addr =  i_mul_pkg.rd_addr;
    mul_ctrl_d.mul_op  =  pre_mul_op;
    mul_ctrl_d.valid   =  pre_valid;
    mul_ctrl_d.wren    =  i_mul_pkg.wren;
end


always_comb begin : result_mux_selection_signal
    mul_product_low    = mul_product[31:0];
    mul_product_high   = mul_product[63:32];
    mul_data_sel       = mul_ctrl_q.mul_op[0] | mul_ctrl_q.mul_op[1];
end


prim_register_clr #(.WIDTH($bits(mul_ctrl_q)))   mul_instr_ctrl_buffer(
    .i_clk   (i_clk                                               ),
    .i_rstn  (i_rstn                                              ),
    .i_clear (i_discard | (REQUEST_stage & i_wb_ack & ~pre_valid) ),
    .i_en    (mul_start                                           ),
    .i_d     (mul_ctrl_d                                          ),
    .o_q     (mul_ctrl_q                                          )
);


// State transition
always_ff @(posedge i_clk, negedge i_rstn)
    if (!i_rstn)        Pre_state <= IDLE;
    else                Pre_state <= Next_state;

always_comb begin
    case (Pre_state)
        IDLE:      if (mul_start)           Next_state = EXECUTE;
                   else                     Next_state = IDLE;

        EXECUTE:   if      (i_discard)      Next_state = IDLE;
                   else if (mul_done)       Next_state = REQUEST;
                   else                     Next_state = EXECUTE;

        REQUEST:   if      (i_discard)      Next_state = IDLE;
                   else if (mul_start)      Next_state = EXECUTE;
                   else if (i_wb_ack )      Next_state = IDLE;
                   else                     Next_state = REQUEST;

        default:                            Next_state = IDLE;
    endcase
end


prim_multiplier_32x32_pipelined  Multiplier (
    .i_clk            (i_clk                   ),
    .i_rstn           (i_rstn                  ),
    .i_start          (mul_start               ),
    .i_stop           (i_discard               ),
    .i_op_b_signed_en (mul_op_b_signed_en      ),   // HIGH to signed enable operand B
    .i_op_a_signed_en (mul_op_a_signed_en      ),   // HIGH to signed enable operand A
    .i_a              (i_mul_pkg.multiplicand  ),
    .i_b              (i_mul_pkg.multiplier    ),
    .o_product        (mul_product             ),
    .o_done           (mul_done                ),
    .o_ready          ()   // HIGH to indicate IDLE
);

prim_mux_2x1   mux_mul_data_select (
        .i_sel(mul_data_sel      ),
        .i_0  (mul_product_low   ),
        .i_1  (mul_product_high  ),
        .o_mux(mul_data          )
);


// ============================== Stage buffer ====================
pipe_t      mul_wb_pkg;

assign mul_wb_pkg.rd_data   = mul_data;
assign mul_wb_pkg.rd_addr   = mul_ctrl_q.rd_addr;
assign mul_wb_pkg.wren      = mul_ctrl_q.wren;
assign mul_wb_pkg.valid     = mul_ctrl_q.valid & REQUEST_stage & ~i_discard;
assign mul_wb_pkg.rd_is_int = 1'b1;





// Ouptut
assign o_mul_pkg = mul_wb_pkg;
assign o_ready   = IDLE_stage | (REQUEST_stage & i_wb_ack); //| i_discard;


`ifdef DEBUG
assign mul_ctrl_d.debug_pkg = i_mul_pkg.debug_pkg;

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


assign db_instr         = mul_ctrl_q.debug_pkg.instr;
assign db_pc            = mul_ctrl_q.debug_pkg.pc;
assign db_imm           = mul_ctrl_q.debug_pkg.imm;
assign db_rs1_addr      = mul_ctrl_q.debug_pkg.rs1_addr;
assign db_rs2_addr      = mul_ctrl_q.debug_pkg.rs2_addr;
assign db_rd_addr       = mul_ctrl_q.debug_pkg.rd_addr;
assign db_alu_en        = mul_ctrl_q.debug_pkg.alu_en;
assign db_branch_en     = mul_ctrl_q.debug_pkg.branch_en;
assign db_load_en       = mul_ctrl_q.debug_pkg.load_en;
assign db_store_en      = mul_ctrl_q.debug_pkg.store_en;
assign db_mul_en        = mul_ctrl_q.debug_pkg.mul_en;
assign db_div_en        = mul_ctrl_q.debug_pkg.div_en;
assign db_fpu_en        = mul_ctrl_q.debug_pkg.fpu_en;
assign db_use_pc        = mul_ctrl_q.debug_pkg.use_pc;
assign db_use_imm       = mul_ctrl_q.debug_pkg.use_imm;
assign db_use_rs1       = mul_ctrl_q.debug_pkg.use_rs1;
assign db_use_rs2       = mul_ctrl_q.debug_pkg.use_rs2;
assign db_wren          = mul_ctrl_q.debug_pkg.wren;
assign db_valid         = mul_ctrl_q.debug_pkg.valid;
assign db_is_predicted  = mul_ctrl_q.debug_pkg.is_predicted;

assign mul_wb_pkg.debug_pkg = mul_ctrl_q.debug_pkg;    // Don't care

`endif


endmodule





