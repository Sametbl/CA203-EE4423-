
module lsu
import pipeline_pkg::*;
(
    input  logic            i_clk               ,
    input  logic            i_rstn              ,
    input  logic            i_discard           , // HIGH to discard current operation
    input  lsu_t            i_lsu_pkg           ,
    input  logic            i_wb_ack            ,
    // Memory interface (RX)
    input  logic [31:0]     i_dmem_rdata        , // Read data from Data memory
    input  logic            i_dmem_valid        , // Data memory acknownledge
    input  logic            i_dmem_ready        , // Data memory is ready to receive request
    // Memory interface (TX)
    output logic [31:0]     o_lsu_dmem_addr     , // Address for Load/Store operation
    output logic [31:0]     o_lsu_dmem_wdata    , // Data for Store address
    output logic [3:0]      o_lsu_dmem_bmsk     , // Bytemask for Load/Store operation
    output logic            o_lsu_dmem_wren     , // Write enable for Store operation
    output logic            o_lsu_dmem_valid    , // Request signal to Data memory
    output logic            o_lsu_dmem_ready    , // Indicate LSU is ready to receive data

    output pipe_t           o_lsu_pkg           , // Output LSU data package to Writeback
    output logic            o_lsu_ready
);



// ==================== State Machine =========================
typedef enum logic [1:0] {
        IDLE   , // Wait for valid Load/Store instruction
        ADDR   , // Calculate Address and Request Data Memory
        LOAD   ,
        STORE
} state_t;


state_t  Pre_State;
state_t  Next_State;

logic    IDLE_stage;
logic    ADDR_stage;
logic    LOAD_stage;
logic    STORE_stage;

always_comb begin : state_indication_signal
    IDLE_stage    = (Pre_State == IDLE   );
    ADDR_stage    = (Pre_State == ADDR   );
    LOAD_stage    = (Pre_State == LOAD   );
    STORE_stage   = (Pre_State == STORE  );
end


// DECODE to EX (LSU) stage buffer
lsu_t    lsu_pkg_q;

logic    pre_valid;
logic    buffer_en;
logic    buffer_clear;


prim_register_clr #(.WIDTH($bits(lsu_pkg_q)))  LSU_stage_buffer (
    .i_clk  (i_clk        ),
    .i_rstn (i_rstn       ),
    .i_en   (buffer_en    ),
    .i_clear(buffer_clear ),
    .i_d    (i_lsu_pkg    ),
    .o_q    (lsu_pkg_q    )
);

// ======================== DECODE to EX stage control ===================
// Alias
logic [31:0] effective_addr;
logic [31:0] base_addr;
logic [31:0] offset_addr;
logic [31:0] store_data;
logic [4:0]  rd_addr;
logic [3:0]  bytemask;
logic        lsu_signed;
logic        load_en;
logic        store_en;
logic        wren;
logic        valid;

always_comb begin : signal_extraction_and_renaming
    base_addr          = lsu_pkg_q.base_addr;
    offset_addr        = lsu_pkg_q.offset_addr;

    store_data         = lsu_pkg_q.store_data;
    bytemask           = lsu_pkg_q.lsu_bytemask;
    lsu_signed         = lsu_pkg_q.lsu_signed;

    rd_addr            = lsu_pkg_q.rd_addr;
    load_en            = lsu_pkg_q.load_en;
    store_en           = lsu_pkg_q.store_en;
    wren               = lsu_pkg_q.wren;
    valid              = lsu_pkg_q.valid & ~i_discard;
end


assign pre_valid = i_lsu_pkg.valid;

// i_fetch vs pre_valid
// LSU use ready valid to detect valid instruciton
// i_fetch is control by hazard detection to inform pipeline stall


// Enale Load new operations when IDLE or WRITEBACK is acknownledged
// IDLE:     Always ready to fetch new instruction
// ADDR:     Ready to fetch new instruction if current is being discarded
// REQUESR:
// -        Discard: Accept new instruction
// -        Store:   When DMEM inform valid
// -        Load:    When WB inform ack


assign buffer_en    = (IDLE_stage &  pre_valid);
assign buffer_clear = (IDLE_stage & ~pre_valid) | (i_discard);


// Effective address computation
prim_adder_32bit  address_adder   (
    .i_a    (base_addr     ),
    .i_b    (offset_addr   ),
    .i_sub  (1'b0          ),
    .o_sum  (effective_addr),
    .o_cout (              )
);

// Output: Dmem request
assign o_lsu_dmem_addr   =  effective_addr;
assign o_lsu_dmem_wdata  =  store_data;
assign o_lsu_dmem_bmsk   =  bytemask;
assign o_lsu_dmem_wren   =  store_en;
assign o_lsu_dmem_valid  = (ADDR_stage & valid);
assign o_lsu_dmem_ready  = (~valid) | (ADDR_stage) | (STORE_stage) | (LOAD_stage & i_wb_ack);

// State transition
always_ff @(posedge i_clk, negedge i_rstn)
    if (!i_rstn)     Pre_State <= IDLE;
    else             Pre_State <= Next_State;



assign LAOD_stage_fetch  = (STORE_stage) & (pre_valid);
assign STORE_stage_fetch = (STORE_stage) & (pre_valid);



always_comb begin
    case(Pre_State)
        IDLE:       if      (pre_valid)                              Next_State = ADDR;
                    else                                             Next_State = IDLE;

        ADDR:       if      (i_dmem_ready & load_en)                 Next_State = LOAD;
                    else if (i_dmem_ready & store_en)                Next_State = STORE;
                    else if (i_dmem_ready & ~valid)                  Next_State = IDLE;
                    else                                             Next_State = ADDR;

        LOAD:       if      (~valid)                                 Next_State = IDLE;
                    else if (i_wb_ack)                               Next_State = IDLE;
                    else                                             Next_State = LOAD;

        STORE:      if      (~valid)                                 Next_State = IDLE;
                    else if (i_dmem_valid)                           Next_State = IDLE;
                    else                                             Next_State = STORE;

        default:                                                     Next_State = IDLE;
    endcase
end



// ================================ WAIT_READ stage ==========================
// Select load data
logic [31:0] masked_rdata;       // LSU load data after applied bytemask

logic [1:0]  rdata_byte1_sel;    // Select data for byte 1
logic [1:0]  rdata_byte2_3_sel;  // Select data for byte 2 and 3
logic        load_byte;
logic        load_halfword;

always_comb begin : sign_extension_selection
    load_byte     = bytemask[0] & ~bytemask[1] & ~bytemask[2] & ~bytemask[3];
    load_halfword = bytemask[0] &  bytemask[1] & ~bytemask[2] & ~bytemask[3];

    rdata_byte1_sel[0]   =  (lsu_signed) & (load_byte);   // LB
    rdata_byte1_sel[1]   = ~(lsu_signed) & (load_byte);   // LBU

    rdata_byte2_3_sel[0] = (load_halfword) | (~lsu_signed & load_byte);
    rdata_byte2_3_sel[1] = (lsu_signed) & (load_byte | load_halfword);
end



assign masked_rdata[7:0] = i_dmem_rdata[7:0];

prim_mux_4x1 #(.WIDTH(8)) rdata_byte_1_sel(
        .i_sel( rdata_byte1_sel      ),
        .i_0  ( i_dmem_rdata[15:8]   ),  // [Default] --> Word & Halfword operations
        .i_1  ( {8{i_dmem_rdata[7]}} ),  // [LB ]     --> Sign Extended of byte 0
        .i_2  ( 8'h00                ),  // [LBU]     --> Not sign extended or Not Masked)
        .i_3  ( 8'h00                ),  //           --> Reserved
        .o_mux( masked_rdata[15:8]   )
);


prim_mux_4x1 #(.WIDTH(16))  rdata_byte_2_3_sel(
        .i_sel( rdata_byte2_3_sel     ),
        .i_0  ( i_dmem_rdata[31:16]   ),  // [Default]  --> For Word operation
        .i_1  ( 16'h0000              ),  // [LBU, LHU] --> Not sign extended when not Masked
        .i_2  ( {16{i_dmem_rdata[7]}} ),  // [LB]       --> Sign Extended of byte 0
        .i_3  ( {16{i_dmem_rdata[15]}}),  // [LH]       --> Sign Extended of byte 1
        .o_mux( masked_rdata[31:16]   )
);




// ===================================== WRITEBACK ==================================
// OUTPUT
assign o_lsu_pkg.rd_data    = masked_rdata;
assign o_lsu_pkg.rd_addr    = rd_addr;
assign o_lsu_pkg.wren       = wren;
assign o_lsu_pkg.valid      = (LOAD_stage & i_dmem_valid) & (valid & load_en);
assign o_lsu_pkg.rd_is_int  = 1'b1;

assign o_lsu_ready = (IDLE_stage);


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


assign db_instr         = lsu_pkg_q.debug_pkg.instr;
assign db_pc            = lsu_pkg_q.debug_pkg.pc;
assign db_imm           = lsu_pkg_q.debug_pkg.imm;
assign db_rs1_addr      = lsu_pkg_q.debug_pkg.rs1_addr;
assign db_rs2_addr      = lsu_pkg_q.debug_pkg.rs2_addr;
assign db_rd_addr       = lsu_pkg_q.debug_pkg.rd_addr;
assign db_alu_en        = lsu_pkg_q.debug_pkg.alu_en;
assign db_branch_en     = lsu_pkg_q.debug_pkg.branch_en;
assign db_load_en       = lsu_pkg_q.debug_pkg.load_en;
assign db_store_en      = lsu_pkg_q.debug_pkg.store_en;
assign db_mul_en        = lsu_pkg_q.debug_pkg.mul_en;
assign db_div_en        = lsu_pkg_q.debug_pkg.div_en;
assign db_fpu_en        = lsu_pkg_q.debug_pkg.fpu_en;
assign db_use_pc        = lsu_pkg_q.debug_pkg.use_pc;
assign db_use_imm       = lsu_pkg_q.debug_pkg.use_imm;
assign db_use_rs1       = lsu_pkg_q.debug_pkg.use_rs1;
assign db_use_rs2       = lsu_pkg_q.debug_pkg.use_rs2;
assign db_wren          = lsu_pkg_q.debug_pkg.wren;
assign db_valid         = lsu_pkg_q.debug_pkg.valid;
assign db_is_predicted  = lsu_pkg_q.debug_pkg.is_predicted;

assign o_lsu_pkg.debug_pkg = lsu_pkg_q.debug_pkg;


`endif







endmodule



