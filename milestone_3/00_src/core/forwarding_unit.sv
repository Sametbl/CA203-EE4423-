// Forwarding_cell module is defined at the end of file


module forwarding_unit import pipeline_pkg::pipe_t;(
    input   logic [4:0]  i_rs1_addr     ,  // Address of Source Register 1
    input   logic [4:0]  i_rs2_addr     ,  // Address of Source Register 2
    input   logic [31:0] i_rs1_data     ,  // Data of Source Register 1 from Regfile
    input   logic [31:0] i_rs2_data     ,  // Data of Source Register 2 from Regfile
    input   logic        i_valid        ,  // The current instruction in ID stage is valid
    input   logic        i_use_rs1      ,  // The current instruction in ID stage uses RS1
    input   logic        i_use_rs2      ,  // The current instruction in ID stage uses RS2

    input   pipe_t       i_alu_fwd_pkg  ,
    input   pipe_t       i_bru_pwd_pkg  ,  // Forwarding from BRU only useful if Branch Predcition
    input   pipe_t       i_wb_fwd_pkg   ,  // Include LSU, DIV, MUL
    output  logic [31:0] o_rs1_forwarded,
    output  logic [31:0] o_rs2_forwarded
);


logic [31:0] alu_fwd_data;
logic [4:0]  alu_rd_addr;
logic        alu_fwd_valid;

logic [31:0] bru_fwd_data;
logic [4:0]  bru_rd_addr;
logic        bru_fwd_valid;

logic [31:0] wb_fwd_data;
logic [4:0]  wb_rd_addr;
logic        wb_fwd_valid;


always_comb begin : signal_alias_and_extract
       alu_rd_addr   = i_alu_fwd_pkg.rd_addr;
       alu_fwd_data  = i_alu_fwd_pkg.rd_data;
       alu_fwd_valid = i_alu_fwd_pkg.valid & i_alu_fwd_pkg.wren & i_alu_fwd_pkg.rd_is_int;

       bru_rd_addr   = i_bru_pwd_pkg.rd_addr;
       bru_fwd_data  = i_bru_pwd_pkg.rd_data;
       bru_fwd_valid = i_bru_pwd_pkg.valid & i_bru_pwd_pkg.wren & i_bru_pwd_pkg.rd_is_int;

       wb_rd_addr    = i_wb_fwd_pkg.rd_addr;
       wb_fwd_data   = i_wb_fwd_pkg.rd_data;
       wb_fwd_valid  = i_wb_fwd_pkg.valid & i_wb_fwd_pkg.wren & i_wb_fwd_pkg.rd_is_int;
end


// ----------------------------------------------------
// *_fwd_flag == 3'b001: Forward valid from Execute stage
// *_fwd_flag == 3'b010: Forward valid from Memory Access stage
// *_fwd_flag == 3'b100: Forward valid from Writeback stage

logic [2:0] rs1_fwd_flags; // RS1 fowarding flags, each bit correspond to a fowarding Location
logic [2:0] rs2_fwd_flags; // RS2 fowarding flags, each bit correspond to a fowarding Location

logic       rs1_alu_matched;
logic       rs2_alu_matched;

logic       rs1_bru_matched;
logic       rs2_bru_matched;

logic       rs1_wb_matched;
logic       rs2_wb_matched;

//---------------------------- Forwarding Check ---------------------------------
forwarding_cell    fwd_check_alu_stage  (
        .i_rs1_addr       (i_rs1_addr     ),
        .i_rs2_addr       (i_rs2_addr     ),
        .i_fwd_rd_adder   (alu_rd_addr    ),
        .i_fwd_valid      (alu_fwd_valid  ),
        .o_fwd_rs1_matched(rs1_alu_matched),
        .o_fwd_rs2_matched(rs2_alu_matched)
);

forwarding_cell    fwd_check_bru_stage  (
        .i_rs1_addr       (i_rs1_addr     ),
        .i_rs2_addr       (i_rs2_addr     ),
        .i_fwd_rd_adder   (bru_rd_addr    ),
        .i_fwd_valid      (bru_fwd_valid  ),
        .o_fwd_rs1_matched(rs1_bru_matched),
        .o_fwd_rs2_matched(rs2_bru_matched)
);

forwarding_cell    fwd_check_wb_stage   (
        .i_rs1_addr       (i_rs1_addr     ),
        .i_rs2_addr       (i_rs2_addr     ),
        .i_fwd_rd_adder   (wb_rd_addr     ),
        .i_fwd_valid      (wb_fwd_valid   ),
        .o_fwd_rs1_matched(rs1_wb_matched ),
        .o_fwd_rs2_matched(rs2_wb_matched )
);


// One-hot encoded
// Prioritize the close Forwarding location to the EX stage
assign rs1_fwd_flags[0] = (i_valid & i_use_rs1) &  (rs1_alu_matched);
assign rs1_fwd_flags[1] = (i_valid & i_use_rs1) & ~(rs1_alu_matched) & rs1_bru_matched;
assign rs1_fwd_flags[2] = (i_valid & i_use_rs1) & ~(rs1_alu_matched  | rs1_bru_matched) & rs1_wb_matched;

assign rs2_fwd_flags[0] = (i_valid & i_use_rs2) &  (rs2_alu_matched);
assign rs2_fwd_flags[1] = (i_valid & i_use_rs2) & ~(rs2_alu_matched) &  rs2_bru_matched;
assign rs2_fwd_flags[2] = (i_valid & i_use_rs2) & ~(rs2_alu_matched  |  rs2_bru_matched) & rs2_wb_matched;


// ----------------------- Source Register Forwarding ---------------------------------
logic [1:0] rs1_data_sel;
logic [1:0] rs2_data_sel;

assign rs1_data_sel[0] = rs1_fwd_flags[2] | rs1_fwd_flags[0];
assign rs1_data_sel[1] = rs1_fwd_flags[2] | rs1_fwd_flags[1];

assign rs2_data_sel[0] = rs2_fwd_flags[2] | rs2_fwd_flags[0];
assign rs2_data_sel[1] = rs2_fwd_flags[2] | rs2_fwd_flags[1];



prim_mux_4x1   RS1_Select  (
        .i_sel(rs1_data_sel    ),
        .i_0  (i_rs1_data        ),   // 2'b00: Regfile (default)
        .i_1  (alu_fwd_data      ),   // 2'b11: EX   stage
        .i_2  (bru_fwd_data      ),   // 2'b01: MEM  stage
        .i_3  (wb_fwd_data       ),   // 2'b10: WB   stage
        .o_mux(o_rs1_forwarded   )
);

prim_mux_4x1   RS2_Select  (
        .i_sel(rs2_data_sel      ),
        .i_0  (i_rs2_data        ),   // 2'b00: Regfile (default)
        .i_1  (alu_fwd_data      ),   // 2'b11: EX   stage
        .i_2  (bru_fwd_data      ),   // 2'b01: MEM  stage
        .i_3  (wb_fwd_data       ),   // 2'b10: WB   stage
        .o_mux(o_rs2_forwarded   )
);


endmodule




