// ============================================================
// Filename           : arbitrator.sv
// Module Name        : arbitrator
// Author             : Luong Thanh Vy (CA203 - K22)
// Created On         : DD-MM-2025  (DD-MM-YYYY)
// Version            : 1.0.0
// ============================================================


module arbitrator import pipeline_pkg::*;(
    input  logic           i_invalidate ,  // HIGH to Invalidate instruction
    input  decode_t        i_decode_pkg ,  // Decode data package in EX stage
    input  logic    [31:0] i_rs1_data   ,  // RS1 data from Regfile
    input  logic    [31:0] i_rs2_data   ,  // RS2 data from Regfile

    output alu_t           o_alu_pkg    ,
    output bru_t           o_bru_pkg    ,
    output lsu_t           o_lsu_pkg    ,  // Output data Package to LSU
    output mul_t           o_mul_pkg    ,
    output div_t           o_div_pkg
);

logic      [31:0] pc                ;
logic      [31:0] imm               ;

logic      [4:0]  rd_addr           ;
logic             wren              ;    // Writeback enable
logic             valid             ;    // Indicate the instruction is valid to be executed

// ALU operand helper signals
logic             use_rs1           ;    // Indicate rs1 field used to Address Regfile
logic             use_rs2           ;    // Indicate rs2 field used to Address Regfile
logic             use_imm           ;    // Indicate operand B uses Immediate
logic             use_pc            ;    // Indicate operand A uses PC

// Categorization
logic             alu_en            ;
logic             branch_en         ;
logic             load_en           ;
logic             store_en          ;
logic             mul_en            ;
logic             div_en            ;

// ALU control signals
logic      [2:0]  alu_op            ;
logic             alu_sub_en        ;
logic             alu_signed_cmp    ;
logic      [1:0]  alu_shift_ctrl    ;

// BRU control signal
logic      [7:0]  branch_op         ;    // 8'b0000_0001: BEQ
logic             is_predicted      ;    // Indicate the instruction is predidcted by BTB
logic      [31:0] predicted_target  ;    // 8'b0000_0001: BEQ

// LSU control signals
logic      [3:0]  lsu_bytemask      ;    // Indicate a Load/Store   Byte  operation
logic             lsu_signed        ;    // Indicate a Load operation is sign-extended

// MUL and DIV control signals
logic      [1:0]  mul_op            ;
logic      [1:0]  div_op            ;


always_comb begin : signal_aliass_and_extraction
        pc               = i_decode_pkg.pc;
        imm              = i_decode_pkg.imm;

        rd_addr          = i_decode_pkg.rd_addr;
        wren             = i_decode_pkg.wren;
        valid            = i_decode_pkg.valid & ~i_invalidate;

        use_rs1          = i_decode_pkg.use_rs1;
        use_rs2          = i_decode_pkg.use_rs2;
        use_imm          = i_decode_pkg.use_imm;
        use_pc           = i_decode_pkg.use_pc;

        alu_en           = i_decode_pkg.alu_en;
        branch_en        = i_decode_pkg.branch_en;
        load_en          = i_decode_pkg.load_en;
        store_en         = i_decode_pkg.store_en;
        mul_en           = i_decode_pkg.mul_en;
        div_en           = i_decode_pkg.div_en;

        alu_op           = i_decode_pkg.alu_op;
        alu_sub_en       = i_decode_pkg.alu_sub_en;
        alu_signed_cmp   = i_decode_pkg.alu_signed_cmp;
        alu_shift_ctrl   = i_decode_pkg.alu_shift_ctrl;

        branch_op        = i_decode_pkg.branch_op;
        is_predicted     = i_decode_pkg.is_predicted;
        predicted_target = i_decode_pkg.predicted_target;

        lsu_bytemask     = i_decode_pkg.lsu_bytemask;
        lsu_signed       = i_decode_pkg.lsu_signed;

        mul_op           = i_decode_pkg.mul_op;
        div_op           = i_decode_pkg.div_op;
end

// -------------------------------------------------
logic alu_request;
logic bru_request;
logic lsu_request;
logic mul_request;
logic div_request;

assign alu_request = (valid) & (alu_en            );
assign bru_request = (valid) & (branch_en         );
assign lsu_request = (valid) & (load_en | store_en);
assign mul_request = (valid) & (mul_en            );
assign div_request = (valid) & (div_en            );




// -------------------------------- ALU OPERANDS SELECTION -----------------------------
logic [31:0] alu_operand_a_selected;
logic [31:0] alu_operand_b_selected;
logic [1:0]  alu_operand_a_sel;
logic [1:0]  alu_operand_b_sel;

// NOTE: LUI and AUIPC only require Immediate and Zero as operand B

assign alu_operand_a_sel[0] =  (use_pc);
assign alu_operand_a_sel[1] = ~(use_rs1 | use_pc);    // LUI and AUIPC

assign alu_operand_b_sel[0] =  (use_imm);
assign alu_operand_b_sel[1] = ~(use_rs2 | use_imm);


prim_mux_4x1   Operand_A_Select  (
        .i_sel(alu_operand_a_sel     ),
        .i_0  (i_rs1_data            ),  // 2'b00: Regfile or forwarded RS1 (default)
        .i_1  (pc                    ),  // 2'b01: PC (for Branch instruction)
        .i_2  (32'h0000_0000         ),  // 2'b10: Operand A = 0 (LUI and AUIPC)
        .i_3  (32'h0000_0000         ),  // 2'b11: Reserved
        .o_mux(alu_operand_a_selected)
);


prim_mux_4x1   Operand_B_Select  (
        .i_sel(alu_operand_b_sel     ),
        .i_0  (i_rs2_data            ),  // 2'b00: Regfile or forwarded RS2 (default)
        .i_1  (imm                   ),  // 2'b01: immediate
        .i_2  (32'h0000_0000         ),  // 2'b10: Reserved or Operand B = 0
        .i_3  (32'h0000_0000         ),  // 2'b11: Reserved or Operand B = 0
        .o_mux(alu_operand_b_selected)
);




// OUTPUT
// ================================= 1. TO ALU ===========================================
always_comb begin : input_pkg_alu
        o_alu_pkg.alu_op        = alu_op;
        o_alu_pkg.operand_a     = alu_operand_a_selected;
        o_alu_pkg.operand_b     = alu_operand_b_selected;
        o_alu_pkg.is_signed_cmp = alu_signed_cmp;
        o_alu_pkg.shifter_ctrl  = alu_shift_ctrl;
        o_alu_pkg.sub_en        = alu_sub_en;
        o_alu_pkg.rd_addr       = rd_addr;
        o_alu_pkg.wren          = wren;
        o_alu_pkg.valid         = alu_request;
end

// ================================= 2. TO BRU ===========================================
always_comb begin : input_pkg_bru
        o_bru_pkg.branch_op        = branch_op;
        o_bru_pkg.pc               = pc;
        o_bru_pkg.offset           = imm;              // Offset to calculate Target (immedicate)
        o_bru_pkg.rs1_data         = i_rs1_data;       // RS1 for Branch condition comparison
        o_bru_pkg.rs2_data         = i_rs2_data;       // RS2 for Branch condition comparison
        o_bru_pkg.rd_addr          = rd_addr;
        o_bru_pkg.wren             = wren;             // Writeback return address (JAL and JALR)
        o_bru_pkg.valid            = bru_request;
        o_bru_pkg.is_predicted     = is_predicted;     // Indicate instruction is predidcted by BTB
        o_bru_pkg.predicted_target = predicted_target; // Indicate instruction is predidcted by BTB
end



// ================================= 3. TO LSU ===========================================
always_comb begin : input_pkg_lsu
        o_lsu_pkg.load_en      = load_en;
        o_lsu_pkg.store_en     = store_en;
        o_lsu_pkg.store_data   = i_rs2_data;
        o_lsu_pkg.base_addr    = i_rs1_data;
        o_lsu_pkg.offset_addr  = imm;
        o_lsu_pkg.rd_addr      = rd_addr;
        o_lsu_pkg.lsu_bytemask = lsu_bytemask;
        o_lsu_pkg.lsu_signed   = lsu_signed;
        o_lsu_pkg.wren         = wren;
        o_lsu_pkg.valid        = lsu_request;
end


// ================================= 4. TO MUL ===========================================
always_comb begin : input_pkg_mul
        o_mul_pkg.multiplicand = i_rs1_data; // Operand A
        o_mul_pkg.multiplier   = i_rs2_data; // Operand B
        o_mul_pkg.rd_addr      = rd_addr;
        o_mul_pkg.mul_op       = mul_op;
        o_mul_pkg.wren         = wren;
        o_mul_pkg.valid        = mul_request;
end


// ================================= 5. TO DIV ===========================================
always_comb begin : input_pkg_div
        o_div_pkg.dividend = i_rs1_data;   // Operand A
        o_div_pkg.divisor  = i_rs2_data;   // Operand B
        o_div_pkg.rd_addr  = rd_addr;
        o_div_pkg.div_op   = div_op;
        o_div_pkg.wren     = wren;
        o_div_pkg.valid    = div_request;
end



// DEBUG
`ifdef DEBUG
        assign o_alu_pkg.debug_pkg = i_decode_pkg.debug_pkg;
        assign o_bru_pkg.debug_pkg = i_decode_pkg.debug_pkg;
        assign o_lsu_pkg.debug_pkg = i_decode_pkg.debug_pkg;
        assign o_mul_pkg.debug_pkg = i_decode_pkg.debug_pkg;
        assign o_div_pkg.debug_pkg = i_decode_pkg.debug_pkg;
`endif




endmodule

