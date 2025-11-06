// ============================================================
// Filename           : instruction_decoder.sv
// Module Name        : instruction_decoder
// Author             : Luong Thanh Vy (CA203 - K22)
// Created On         : 03-09-2025  (DD-MM-YYYY)
// ============================================================


module control_unit import data_pkg::*; (
    input  logic  [31:0] i_instr        , // Input  data package from Fetch Stage

    // Fetch control
    input  logic         i_br_equal            ,
    input  logic         i_br_less             ,
    output logic         o_pc_sel              ,
    output logic         o_branch_cmp_unsigned ,

    // Immediate generation
    output logic [31:0]  o_immediate           ,

    // ALU control
    output logic [2:0]   o_alu_op              ,
    output logic [1:0]   o_alu_opa_sel         ,
    output logic         o_alu_opb_sel         ,
    output logic [1:0]   o_alu_shifter_ctrl    ,
    output logic         o_alu_signed_cmp_en   ,
    output logic         o_alu_sub_en          ,

    // LSU control
    output logic         o_lsu_st_en           , // Store enable
    output logic         o_lsu_unsigned        , // Unsigned extension for non-word load
    output logic [3:0]   o_lsu_bytemask        , // Bytemask for Store operation

    // Writeback control
    output logic         o_rd_wren             ,
    output logic [1:0]   o_wb_sel              ,
    output logic [4:0]   o_rs1_addr            ,
    output logic [4:0]   o_rs2_addr            ,
    output logic [4:0]   o_rd_addr             ,

    // General signal
    output logic         o_instr_valid         , // Instruction Valid
    output logic         o_ecall               , // Reserved
    output logic         o_ebreak              , // Reserved
    output logic         o_pause                 // Reserved

);


// ======================== Field Extractor ========================
logic [4:0]    rs1_addr;     // Address of Source Register 1
logic [4:0]    rs2_addr;     // Address of Source Register 2
logic [4:0]    rd_addr;      // Address of Destination Register
logic [6:0]    opcode;       // Opcode of instruction

logic [2:0]    funct3_field; // Field of funct3 in instruction binary format
logic [4:0]    funct5_field; // Field of funct3 in instruction binary format
logic [6:0]    funct7_field; // Field of funct7 in instruction binary format

logic [7:0]    funct3;       // One-hot signal represent each funct3 value
logic [31:0]   funct5;       // One-hot signal represent each funct5 value (For F extension)
logic [127:0]  funct7;       // One-hot signal represent each funct7 value

always_comb begin : field_extraction
    rs1_addr     = i_instr[19:15];
    rs2_addr     = i_instr[24:20];
    rd_addr      = i_instr[11:7];
    opcode       = i_instr[6:0];

    funct3_field = i_instr[14:12];
    funct5_field = i_instr[31:27];
    funct7_field = i_instr[31:25];
end

// Binary decoder
prim_decoder_3to8    funct3_dec (.i_bin(funct3_field), .o_dec(funct3) );
prim_decoder_5to32   funct5_dec (.i_bin(funct5_field), .o_dec(funct5) );
prim_decoder_7to128  funct7_dec (.i_bin(funct7_field), .o_dec(funct7) );


// ======================== Instruction Classifier ========================
// This type classification is NOT Based on ISA

logic R_type;    // Register  & Register type
logic I_type;    // Immediate & Register type (Not including JALR)
logic L_type;    // Loads                type
logic S_type;    // Stores               type
logic B_type;    // Branches             type
logic E_type;    // Environment          type (ECALL and EBREAK)
logic SYS_type;  // System               type (Reserved)

// Special instruction with unique opcode
logic LUI_op;
logic AUIPC_op;
logic JAL_op;
logic JALR_op;


// System operation (RESERVED)
// logic FENCE_type
// logic FENSE_TSO_type;
// logic PAUSE_type;

prim_cmp_eq #(.WIDTH(7)) R_type_cmp    (.i_a(opcode), .i_b(7'b011_0011), .o_eq(R_type  ));
prim_cmp_eq #(.WIDTH(7)) I_type_cmp    (.i_a(opcode), .i_b(7'b001_0011), .o_eq(I_type  ));
prim_cmp_eq #(.WIDTH(7)) L_type_cmp    (.i_a(opcode), .i_b(7'b000_0011), .o_eq(L_type  ));
prim_cmp_eq #(.WIDTH(7)) S_type_cmp    (.i_a(opcode), .i_b(7'b010_0011), .o_eq(S_type  ));
prim_cmp_eq #(.WIDTH(7)) B_type_cmp    (.i_a(opcode), .i_b(7'b110_0011), .o_eq(B_type  ));
prim_cmp_eq #(.WIDTH(7)) E_type_cmp    (.i_a(opcode), .i_b(7'b111_0011), .o_eq(E_type  ));
prim_cmp_eq #(.WIDTH(7)) Y_type_cmp    (.i_a(opcode), .i_b(7'b000_1111), .o_eq(SYS_type));

prim_cmp_eq #(.WIDTH(7)) LUI_op_cmp    (.i_a(opcode), .i_b(7'b011_0111), .o_eq(LUI_op  ));
prim_cmp_eq #(.WIDTH(7)) JAL_op_cmp    (.i_a(opcode), .i_b(7'b110_1111), .o_eq(JAL_op  ));
prim_cmp_eq #(.WIDTH(7)) JALR_op_cmp   (.i_a(opcode), .i_b(7'b110_0111), .o_eq(JALR_op ));
prim_cmp_eq #(.WIDTH(7)) AUIPC_op_cmp  (.i_a(opcode), .i_b(7'b001_0111), .o_eq(AUIPC_op));


// =========================== Instruction indication signals ===================
instr_bitmap_t isa;        // Bitmap signal represent each instruction

always_comb begin : instruction_bitmap_assignment
    isa.nop   = ~(opcode == 7'b000_0000);

    isa.lui   = LUI_op;
    isa.auipc = AUIPC_op;
    isa.jal   = JAL_op;
    isa.jalr  = JALR_op;

    isa.beq    = B_type & funct3[0];
    isa.bne    = B_type & funct3[1];
    isa.blt    = B_type & funct3[4];
    isa.bge    = B_type & funct3[5];
    isa.bltu   = B_type & funct3[6];
    isa.bgeu   = B_type & funct3[7];

    isa.lb     = L_type & funct3[0];
    isa.lh     = L_type & funct3[1];
    isa.lw     = L_type & funct3[2];
    isa.lbu    = L_type & funct3[4];
    isa.lhu    = L_type & funct3[5];

    isa.sb     = S_type & funct3[0];
    isa.sh     = S_type & funct3[1];
    isa.sw     = S_type & funct3[2];

    isa.addi   = I_type & funct3[0];
    isa.slti   = I_type & funct3[2];
    isa.sltiu  = I_type & funct3[3];
    isa.xori   = I_type & funct3[4];
    isa.ori    = I_type & funct3[6];
    isa.andi   = I_type & funct3[7];
    isa.slli   = I_type & funct3[1] & funct7[0];
    isa.srli   = I_type & funct3[5] & funct7[0];
    isa.srai   = I_type & funct3[5] & funct7[32];

    isa.add    = R_type & funct3[0] & funct7[0];
    isa.sub    = R_type & funct3[0] & funct7[32];
    isa.slt    = R_type & funct3[2] & funct7[0];
    isa.sltu   = R_type & funct3[3] & funct7[0];
    isa.xor_   = R_type & funct3[4] & funct7[0];
    isa.or_    = R_type & funct3[6] & funct7[0];
    isa.and_   = R_type & funct3[7] & funct7[0];
    isa.sll    = R_type & funct3[1] & funct7[0];
    isa.srl    = R_type & funct3[5] & funct7[0];
    isa.sra    = R_type & funct3[5] & funct7[32];

    isa.ecall  = E_type   & funct7[0] & (i_instr[19:7] == 13'b0) & (i_instr[24:20] == 5'b00000);
    isa.ebreak = E_type   & funct7[0] & (i_instr[19:7] == 13'b0) & (i_instr[24:20] == 5'b00001);
    isa.pause  = SYS_type & funct7[0] & (i_instr[19:7] == 13'b0) & (i_instr[24:20] == 5'b10000);

    isa.padding = {($bits(isa.padding)){1'b0}};
end



// ======================== Immediate Generator ========================
logic [31:0]   imm_i_type;     // Immediate value for I_TYPE instructions (Including L_type)
logic [31:0]   imm_b_type;     // Immediate value for B_TYPE instructions
logic [31:0]   imm_s_type;     // Immediate value for S_TYPE and L_TYPE instructions
logic [31:0]   imm_shift;      // Immedate shift amount (5-bit) for Shift Instructions
logic [31:0]   imm_jal;        // Immediate value for JAL and JALR instructions
logic [31:0]   imm_ui;         // Immediate value for Upper Immediate instructions (LUI, AUIPC)
logic [31:0]   immediate;      // Selected immediate

logic [2:0]    instr_imm_sel;
logic          imm_i_type_sel;
logic          imm_b_type_sel;
logic          imm_s_type_sel;
logic          imm_shift_sel;
logic          imm_jal_sel;
logic          imm_ui_sel;


always_comb begin : immediate_extraction
    imm_i_type = {{20{i_instr[31]}}, i_instr[31:20]};
    imm_s_type = {{20{i_instr[31]}}, i_instr[31:25], i_instr[11:7]};
    imm_b_type = {{19{i_instr[31]}}, i_instr[31], i_instr[7], i_instr[30:25],  i_instr[11:8],  1'b0};
    imm_shift  = {27'h000_0000, i_instr[24:20]};     // For shift immediate
    imm_jal    = {{11{i_instr[31]}}, i_instr[31], i_instr[19:12], i_instr[20], i_instr[30:21], 1'b0};
    imm_ui     = {i_instr[31:12], 12'h000};
end


always_comb begin : immediate_select_signal
    imm_shift_sel  = (isa.slli | isa.srli | isa.srai);            // 3'b100 (4)
    imm_i_type_sel = (I_type | L_type | isa.jalr) & ~(imm_shift_sel); // 3'b001 (1)
    imm_s_type_sel = (S_type);                                    // 3'b010 (2)
    imm_b_type_sel = (B_type);                                    // 3'b011 (3)
    imm_jal_sel    = (isa.jal);                                   // 3'b101 (5)
    imm_ui_sel     = (isa.lui | isa.auipc);                       // 3'b110 (6)

    // Select signal logic for immediate MUX
    instr_imm_sel[0] = (imm_i_type_sel) | (imm_b_type_sel) | (imm_jal_sel);
    instr_imm_sel[1] = (imm_s_type_sel) | (imm_b_type_sel) | (imm_ui_sel );
    instr_imm_sel[2] = (imm_shift_sel ) | (imm_jal_sel   ) | (imm_ui_sel );
end


prim_mux_8x1   immediate_value_selection (
        .i_sel(instr_imm_sel),
        .i_0  (32'h0000_0000),  // Default value = 0
        .i_1  (imm_i_type   ),  // 3'b001: I_type, L_type, JALR and not SLLI, SRLI, SRAI
        .i_2  (imm_s_type   ),  // 3'b010: S_type
        .i_3  (imm_b_type   ),  // 3'b011: B_type
        .i_4  (imm_shift    ),  // 3'b100: SLLI, SRLI, SRAI
        .i_5  (imm_jal      ),  // 3'b101: JAL (not JALR)
        .i_6  (imm_ui       ),  // 3'b110: LUI and AUIPC
        .i_7  (32'h0000_0000),  // Reserved
        .o_mux(immediate    )
);





// =============================  Control signal ============================
logic alu_en;    // Indicate ALU    instructions
logic branch_en; // Indicate BRANCH instructions
logic load_en;   // Indicate LOAD   instructions
logic store_en;  // Indicate STIRE  instructions

assign alu_en       = (R_type & ~funct7[1]) | (I_type) | (isa.lui) | (isa.auipc);
assign branch_en    = (B_type) | (isa.jal | isa.jalr);
assign load_en      = (L_type);
assign store_en     = (S_type);



// ---------- Fetch control ----------
logic br_unsigned_cmp; // Indicate unsigned branch comparasion
logic br_taken;        // Branch result in taken
assign br_unsigned_cmp = (isa.bgeu | isa.bltu);
assign br_taken = (isa.beq  &  i_br_equal ) |
                  (isa.bne  & ~i_br_equal ) |
                  (isa.blt  &  i_br_less  ) |
                  (isa.bltu &  i_br_less  ) |
                  (isa.bge  &  i_br_equal ) |
                  (isa.bge  & ~i_br_less  ) |
                  (isa.bgeu &  i_br_equal ) |
                  (isa.bgeu & ~i_br_less  ) |
                  (isa.jal                ) |
                  (isa.jalr               );




// --------------- ALU control signals -----------------
logic [2:0] alu_op;         // 3'b000: ADDER (ADD - SUB) (default)
                            // 3'b001: Comparator (SLT - SLTI - SLTU - SLTIU)
                            // 3'b010: Shifter (SRLI - SRAI - SLLI - SRL - SRA - SLL)
                            // 3'b011: XOR operation (XOR - XORI)
                            // 3'b100: AND operation (AND - ANDI)
                            // 3'b101: OR  operation (OR  - ORI )
                            // 3'b110: PC + 4 (ALU = 32'b0)
                            // 3'b111: Reserved (ALU = 32'b0)logic       alu_opa_sel;
logic       alu_sub_en;
logic       use_pc;
logic       use_imm;
logic       alu_signed_cmp_en;
logic [1:0] alu_shifter_ctrl;   // alu_shifter_ctrl = 2'b00 : shift Right logical (default)
                                // alu_shifter_ctrl = 2;b01 : shift Left  logical
                                // alu_shifter_ctrl = 2'b10 : shift Right Arithmetic
                                // alu_shifter_ctrl = 2'b11 : Reserved


assign alu_op[0] =  (isa.slt  | isa.slti  | isa.sltu | isa.sltiu) |
                    (isa.xor_ | isa.xori) | (isa.or_ | isa.ori  );

assign alu_op[1] =  (isa.srli | isa.srai  | isa.slli) | (isa.srl | isa.sra | isa.sll) |
                    (isa.xor_ | isa.xori);

assign alu_op[2] =  (isa.and_ | isa.andi) |
                    (isa.or_  | isa.ori );

assign alu_sub_en          = (isa.sub);
assign alu_signed_cmp_en   = (isa.slt | isa.slti);
assign alu_shifter_ctrl[0] = (isa.sll | isa.slli);
assign alu_shifter_ctrl[1] = (isa.sra | isa.srai);

assign use_pc       =  (B_type) | (isa.auipc  | isa.jal);
assign use_imm      =  (L_type | I_type | S_type | B_type) |
                       (isa.auipc | isa.jal | isa.jalr | isa.lui);



// ---------------- LSU control
logic [3:0] lsu_bytemask;
logic       lsu_unsigned;     // Indicate a Load operation is sign-extended

assign lsu_bytemask[0] = 1'b1;
assign lsu_bytemask[1] = ~(isa.sb | isa.lb | isa.lbu);
assign lsu_bytemask[2] = ~(isa.sb | isa.lb | isa.lbu | isa.sh | isa.lh | isa.lhu);
assign lsu_bytemask[3] = ~(isa.sb | isa.lb | isa.lbu | isa.sh | isa.lh | isa.lhu);
assign lsu_unsigned    =  (isa.lbu | isa.lhu);




// ------------------- Writeback control ---------------------
logic [1:0] wb_sel; // Writeback data selection
logic       rd_wren;     // Write enable for Register Writeback operations

assign rd_wren  = (alu_en | load_en | isa.jal | isa.jalr);

assign wb_sel[0] = (isa.jal | isa.jalr);
assign wb_sel[1] = (load_en);




// ====================== Output package ========================

// Fetch control
assign o_pc_sel              = br_taken;
assign o_branch_cmp_unsigned = br_unsigned_cmp;

// Immediate generation
assign o_immediate                  = immediate;

// ALU control
assign o_alu_op            = alu_op;
assign o_alu_sub_en        = alu_sub_en;
assign o_alu_opa_sel[0]    =  (use_pc) ;
assign o_alu_opa_sel[1]    = ~(use_pc) & (LUI_op | AUIPC_op);
assign o_alu_opb_sel       = use_imm;
assign o_alu_shifter_ctrl  = alu_shifter_ctrl;
assign o_alu_signed_cmp_en = alu_signed_cmp_en;


// LSU control
assign o_lsu_bytemask = lsu_bytemask;
assign o_lsu_st_en    = store_en;
assign o_lsu_unsigned = lsu_unsigned;


// Writeback control
assign o_rd_wren  = rd_wren;
assign o_wb_sel   = wb_sel;
assign o_rs1_addr = rs1_addr;
assign o_rs2_addr = rs2_addr;
assign o_rd_addr  = rd_addr;


// General
assign o_ecall       = isa.ecall;      // FIXME: Not-used
assign o_ebreak      = isa.ebreak;     // FIXME: Not-used
assign o_pause       = isa.pause;      // FIXME: Not-used

assign o_instr_valid = (alu_en | branch_en | load_en | store_en) |
                       (o_ecall | o_ebreak | o_pause);





endmodule






