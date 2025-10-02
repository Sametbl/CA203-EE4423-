
module div_unit  import pipeline_pkg::*;
(
    input  logic          i_clk           ,
    input  logic          i_rstn          ,
    input  logic          i_wb_ack        ,  // HIGH if writeback request is granted
    input  logic          i_discard       ,  // HIGH to discard the current operation
    input  div_t          i_div_pkg       ,

    output pipe_t         o_div_pkg       ,
    output logic          o_ready         ,
    output logic          o_error            // Divide by 0
);

// Instruction data packed to held while executing division
typedef struct packed  {
        logic [4:0]   rd_addr;
        logic [1:0]   div_op;
        logic         wren;
        logic         valid;
`ifdef DEBUG
        debug_t       debug_pkg;
`endif
} div_ctrl_t;  // Destination control signals

typedef enum logic [1:0] {
    IDLE,
    EXECUTE,
    REQUEST
}  state_t;

state_t       Pre_state;
state_t       Next_state;

div_ctrl_t    div_ctrl_d;
div_ctrl_t    div_ctrl_q;

logic         IDLE_stage;
logic         REQUEST_stage;

logic         div_signed_en;
logic         div_done;    // Indicate the Division is DONE and the result ready in the next cycle
logic         div_error;   // Indicate a division by zero exception (FIXME: Havent used yet)

logic [31:0]  div_quotient;
logic [31:0]  div_remainder;
logic [31:0]  div_data;
logic         div_data_sel;

// div_op = 2'b00: DIV  -  rd = (rs1 / rs2)  (signed)
// div_op = 2'b01: DIVU -  rd = (rs1 / rs2)  (unsigned)
// div_op = 2'b10: REM  -  rd = (rs1 % rs2)  (signed)
// div_op = 2'b11: REMU -  rd = (rs1 % rs2)  (unsigned)

logic       div_start;
logic       pre_valid;
logic [1:0] pre_div_op;


assign IDLE_stage         = (Pre_state == IDLE      );
assign REQUEST_stage      = (Pre_state == REQUEST   );

always_comb begin : start_div_configuration
    pre_valid     =  i_div_pkg.valid;
    pre_div_op    =  i_div_pkg.div_op;
    div_signed_en = ~i_div_pkg.div_op[0];
    div_start = ~i_discard & (pre_valid) & (IDLE_stage | REQUEST_stage & i_wb_ack);
end

always_comb begin : register_input_assigment
    div_ctrl_d.div_op  =  pre_div_op;
    div_ctrl_d.rd_addr =  i_div_pkg.rd_addr;
    div_ctrl_d.wren    =  i_div_pkg.wren;
    div_ctrl_d.valid   =  pre_valid;
end


assign div_data_sel       =  div_ctrl_q.div_op[1];

prim_register_clr #(.WIDTH($bits(div_ctrl_q)))   div_instr_ctrl_buffer(
    .i_clk   (i_clk                                                ),
    .i_rstn  (i_rstn                                               ),
    .i_clear (i_discard | (REQUEST_stage & i_wb_ack & ~pre_valid)  ),
    .i_en    (div_start                                            ),
    .i_d     (div_ctrl_d                                           ),
    .o_q     (div_ctrl_q                                           )
);

// State transition
always_ff @(posedge i_clk, negedge i_rstn)
    if (!i_rstn)        Pre_state <= IDLE;
    else                Pre_state <= Next_state;



always_comb begin
    case (Pre_state)
        IDLE:      if (div_start)        Next_state = EXECUTE;
                   else                  Next_state = IDLE;

        EXECUTE:   if (i_discard)        Next_state = IDLE;
                   else if (div_done)    Next_state = REQUEST;
                   else                  Next_state = EXECUTE;

        REQUEST:   if (i_discard)        Next_state = IDLE;
                   else if (div_start)   Next_state = EXECUTE;
                   else if (i_wb_ack)    Next_state = IDLE;
                   else                  Next_state = REQUEST;

        default:                         Next_state = IDLE;
    endcase
end

prim_divider_32bit  Divider   (
    .i_clk       (i_clk               ),
    .i_rstn      (i_rstn              ),
    .i_start     (div_start           ),
    .i_stop      (i_discard           ),
    .i_signed_en (div_signed_en       ),
    .i_a         (i_div_pkg.dividend  ),
    .i_b         (i_div_pkg.divisor   ),
    .o_quotient  (div_quotient        ),
    .o_remainder (div_remainder       ),
    .o_done      (div_done            ),
    .o_error     (div_error           ),
    .o_ready     ()
);


prim_mux_2x1   mux_div_data_select (
    .i_sel(div_data_sel   ),
    .i_0  (div_quotient   ),
    .i_1  (div_remainder  ),
    .o_mux(div_data       )
);


// ======================= Output: Stage buffer ====================
pipe_t      div_wb_pkg;

always_comb begin : register_output_assigment
    div_wb_pkg.rd_data   = div_data;
    div_wb_pkg.rd_addr   = div_ctrl_q.rd_addr;
    div_wb_pkg.wren      = div_ctrl_q.wren;
    div_wb_pkg.valid     = div_ctrl_q.valid & REQUEST_stage & ~i_discard;
    div_wb_pkg.rd_is_int = 1'b1;
end

// Ouptut
assign o_div_pkg = div_wb_pkg;
assign o_ready   = IDLE_stage | (REQUEST_stage & i_wb_ack);// | i_discard;
assign o_error   = div_error;



// ======================================================================
// ============================= DEBUG ==================================

`ifdef DEBUG
assign div_ctrl_d.debug_pkg = i_div_pkg.debug_pkg;

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


assign db_instr         = div_ctrl_q.debug_pkg.instr;
assign db_pc            = div_ctrl_q.debug_pkg.pc;
assign db_imm           = div_ctrl_q.debug_pkg.imm;
assign db_rs1_addr      = div_ctrl_q.debug_pkg.rs1_addr;
assign db_rs2_addr      = div_ctrl_q.debug_pkg.rs2_addr;
assign db_rd_addr       = div_ctrl_q.debug_pkg.rd_addr;
assign db_alu_en        = div_ctrl_q.debug_pkg.alu_en;
assign db_branch_en     = div_ctrl_q.debug_pkg.branch_en;
assign db_load_en       = div_ctrl_q.debug_pkg.load_en;
assign db_store_en      = div_ctrl_q.debug_pkg.store_en;
assign db_mul_en        = div_ctrl_q.debug_pkg.mul_en;
assign db_div_en        = div_ctrl_q.debug_pkg.div_en;
assign db_fpu_en        = div_ctrl_q.debug_pkg.fpu_en;
assign db_use_pc        = div_ctrl_q.debug_pkg.use_pc;
assign db_use_imm       = div_ctrl_q.debug_pkg.use_imm;
assign db_use_rs1       = div_ctrl_q.debug_pkg.use_rs1;
assign db_use_rs2       = div_ctrl_q.debug_pkg.use_rs2;
assign db_wren          = div_ctrl_q.debug_pkg.wren;
assign db_valid         = div_ctrl_q.debug_pkg.valid;
assign db_is_predicted  = div_ctrl_q.debug_pkg.is_predicted;

assign div_wb_pkg.debug_pkg = div_ctrl_q.debug_pkg;    // Don't care

`endif


endmodule





