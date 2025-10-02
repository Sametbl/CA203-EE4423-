// ============================================================
// Filename           : instruction_decoder.sv
// Module Name        : instruction_decoder
// Author             : Luong Thanh Vy (CA203 - K22)
// Created On         : 03-09-2025  (DD-MM-YYYY)
// ============================================================

import pipeline_pkg::*;

module instruction_decoder(
    input  logic         i_flush            ,  // Invalidate instruction if Flushed
    input  fetch_t       i_fetch_pkg        , // Input  data package from Fetch Stage
    output decode_t      o_decode_pkg       , // Output decoded data package
    output hazard_t      o_decode_hazard_pkg,

    // Reserved
    output logic         o_ecall            ,
    output logic         o_ebreak           ,
    output logic         o_pause
);


// Alias
logic [31:0] pc;
logic [31:0] instr;
logic        valid;
logic        is_predicted;
logic [31:0] predicted_target;

always_comb begin : input_signal_alias
    pc               = i_fetch_pkg.pc;
    instr            = i_fetch_pkg.instr;
    valid            = i_fetch_pkg.valid & ~i_flush;
    is_predicted     = i_fetch_pkg.is_predicted;
    predicted_target = i_fetch_pkg.predicted_target;
end


// ---------------------------- Field Extractor --------------------
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
    rs1_addr     = instr[19:15];
    rs2_addr     = instr[24:20];
    rd_addr      = instr[11:7];
    opcode       = instr[6:0];

    funct3_field = instr[14:12];
    funct5_field = instr[31:27];
    funct7_field = instr[31:25];
end

// Binary decoder
prim_decoder_3to8    funct3_dec (.i_bin(funct3_field), .o_dec(funct3) );
prim_decoder_5to32   funct5_dec (.i_bin(funct5_field), .o_dec(funct5) );
prim_decoder_7to128  funct7_dec (.i_bin(funct7_field), .o_dec(funct7) );


// ------------------------------ Instruction Classifier ---------------------------
// This type classification is NOT Based on ISA

logic R_type;    // Register  & Register type
logic I_type;    // Immediate & Register type (Not including JALR)
logic L_type;    // Loads                type
logic S_type;    // Stores               type
logic B_type;    // Branches             type
logic F_type;    // Register  & Register type (float)
logic E_type;    // Environment          type (ECALL and EBREAK)
logic SYS_type;  // System               type (Reserved)

// Special instruction with unique opcode
logic LUI_op;
logic AUIPC_op;
logic JAL_op;
logic JALR_op;

// Float Extension instructions with unique opcode
logic F_LOAD_op;
logic F_STORE_op;
logic F_FMA_op;
logic F_FMS_op;
logic F_NFMA_op;
logic F_NFMS_op;

// System operation (RESERVED)
// logic FENCE_type
// logic FENSE_TSO_type;
// logic PAUSE_type;

prim_cmp_eq #(.WIDTH(7)) R_type_cmp    (.i_a(opcode), .i_b(7'b011_0011), .o_eq(R_type  ));
prim_cmp_eq #(.WIDTH(7)) I_type_cmp    (.i_a(opcode), .i_b(7'b001_0011), .o_eq(I_type  ));
prim_cmp_eq #(.WIDTH(7)) L_type_cmp    (.i_a(opcode), .i_b(7'b000_0011), .o_eq(L_type  ));
prim_cmp_eq #(.WIDTH(7)) S_type_cmp    (.i_a(opcode), .i_b(7'b010_0011), .o_eq(S_type  ));
prim_cmp_eq #(.WIDTH(7)) B_type_cmp    (.i_a(opcode), .i_b(7'b110_0011), .o_eq(B_type  ));
prim_cmp_eq #(.WIDTH(7)) F_type_cmp    (.i_a(opcode), .i_b(7'b101_0011), .o_eq(F_type  ));
prim_cmp_eq #(.WIDTH(7)) E_type_cmp    (.i_a(opcode), .i_b(7'b111_0011), .o_eq(E_type  ));
prim_cmp_eq #(.WIDTH(7)) Y_type_cmp    (.i_a(opcode), .i_b(7'b000_1111), .o_eq(SYS_type));

prim_cmp_eq #(.WIDTH(7)) LUI_op_cmp    (.i_a(opcode), .i_b(7'b011_0111), .o_eq(LUI_op  ));
prim_cmp_eq #(.WIDTH(7)) JAL_op_cmp    (.i_a(opcode), .i_b(7'b110_1111), .o_eq(JAL_op  ));
prim_cmp_eq #(.WIDTH(7)) JALR_op_cmp   (.i_a(opcode), .i_b(7'b110_0111), .o_eq(JALR_op ));
prim_cmp_eq #(.WIDTH(7)) AUIPC_op_cmp  (.i_a(opcode), .i_b(7'b001_0111), .o_eq(AUIPC_op));

prim_cmp_eq #(.WIDTH(7)) FLOAD_op_cmp  (.i_a(opcode), .i_b(7'b000_0111), .o_eq(F_LOAD_op ));
prim_cmp_eq #(.WIDTH(7)) FSTORE_op_cmp (.i_a(opcode), .i_b(7'b010_0111), .o_eq(F_STORE_op));
prim_cmp_eq #(.WIDTH(7)) FMA_op_cmp    (.i_a(opcode), .i_b(7'b100_0011), .o_eq(F_FMA_op  ));
prim_cmp_eq #(.WIDTH(7)) FMS_op_cmp    (.i_a(opcode), .i_b(7'b100_0111), .o_eq(F_FMS_op  ));
prim_cmp_eq #(.WIDTH(7)) NFMA_op_cmp   (.i_a(opcode), .i_b(7'b100_1011), .o_eq(F_NFMA_op ));
prim_cmp_eq #(.WIDTH(7)) NFMS_op_cmp   (.i_a(opcode), .i_b(7'b100_1111), .o_eq(F_NFMS_op ));


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

    isa.ecall  = E_type   & funct7[0] & (instr[19:7] == 13'b0) & (instr[24:20] == 5'b00000);
    isa.ebreak = E_type   & funct7[0] & (instr[19:7] == 13'b0) & (instr[24:20] == 5'b00001);
    isa.pause  = SYS_type & funct7[0] & (instr[19:7] == 13'b0) & (instr[24:20] == 5'b10000);

    isa.mul    = R_type & funct7[1] & funct3[0]; // rd = (rs1 * rs2)[31:0] (signed   x signed)
    isa.mulh   = R_type & funct7[1] & funct3[1]; // rd = (rs1 * rs2)[63:0] (signed   x signed)
    isa.mulsu  = R_type & funct7[1] & funct3[2]; // rd = (rs1 * rs2)[63:0] (signed   x unsigned)
    isa.mulu   = R_type & funct7[1] & funct3[3]; // rd = (rs1 * rs2)[63:0] (unsigned x unsigned)
    isa.div    = R_type & funct7[1] & funct3[4]; // rd = (rs1 / rs2)       (signed  )
    isa.divu   = R_type & funct7[1] & funct3[5]; // rd = (rs1 / rs2)       (unsigned)
    isa.rem    = R_type & funct7[1] & funct3[6]; // rd = (rs1 % rs2)       (signed  )
    isa.remu   = R_type & funct7[1] & funct3[7]; // rd = (rs1 % rs2)       (unsigned)

    isa.flw       = F_LOAD_op  & funct3[2];
    isa.fsw       = F_STORE_op & funct3[2];
    isa.fmadd_s   = F_FMA_op;
    isa.fmsub_s   = F_FMS_op;
    isa.fnmadd_s  = F_NFMA_op;
    isa.fnmsub_s  = F_NFMS_op;
    isa.fadd_s    = F_type & funct5[0];
    isa.fsub_s    = F_type & funct5[1];
    isa.fmul_s    = F_type & funct5[2];
    isa.fdiv_s    = F_type & funct5[3];
    isa.fsqrt_s   = F_type & funct5[11];
    isa.fsgnj_s   = F_type & funct5[4]   & funct3[0];
    isa.fsgnjn_s  = F_type & funct5[4]   & funct3[1];
    isa.fsgnjx_s  = F_type & funct5[4]   & funct3[2];
    isa.fmin_s    = F_type & funct5[5]   & funct3[0];
    isa.fmax_s    = F_type & funct5[5]   & funct3[1];
    isa.fcvt_w_s  = F_type & funct7[96];                // funct7 = 110_0000
    isa.fcvt_wu_s = F_type & funct7[96];                // funct7 = 110_0000
    isa.fcvt_s_w  = F_type & funct7[104];               // funct7 = 110_1000
    isa.fcvt_s_wu = F_type & funct7[104];               // funct7 = 110_1000
    isa.fmv_x_w   = F_type & funct7[112] & funct3[0];   // funct7 = 111_0000
    isa.fmv_w_x   = F_type & funct7[120] & funct3[0];   // funct7 = 111_1000
    isa.feq_s     = F_type & funct5[20]  & funct3[2];   // funct5 = 1_0100
    isa.flt_s     = F_type & funct5[20]  & funct3[1];   // funct5 = 1_0100
    isa.fle_s     = F_type & funct5[20]  & funct3[0];   // funct5 = 1_0100
    isa.fclass_s  = F_type & funct5[28]  & funct3[1];   // funct5 = 1_1100

    isa.padding = {($bits(isa.padding)){1'b0}};

end


// ----------------------------- Immediate Generator ----------------------------
logic [31:0]   imm_i_type;     // Immediate value for I_TYPE instructions (Including L_type)
logic [31:0]   imm_b_type;     // Immediate value for B_TYPE instructions
logic [31:0]   imm_s_type;     // Immediate value for S_TYPE and L_TYPE instructions
logic [31:0]   imm_shift;      // Immedate shift amount (5-bit) for Shift Instructions
logic [31:0]   imm_jal;        // Immediate value for JAL and JALR instructions
logic [31:0]   imm_ui;         // Immediate value for Upper Immediate instructions (LUI, AUIPC)
logic [31:0]   immediate;      // Selected immediate

logic [2:0]    instr_imm_sel;
logic imm_i_type_sel;
logic imm_b_type_sel;
logic imm_s_type_sel;
logic imm_shift_sel;
logic imm_jal_sel;
logic imm_ui_sel;

always_comb begin : immediate_extraction
    imm_i_type = {{20{instr[31]}}, instr[31:20]};
    imm_s_type = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    imm_b_type = {{19{instr[31]}}, instr[31], instr[7], instr[30:25],  instr[11:8],  1'b0};
    imm_shift  = {27'h000_0000, instr[24:20]};     // For shift immediate
    imm_jal    = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
    imm_ui     = {instr[31:12], 12'h000};
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


// --------------------------------- Control signal ----------------------------------------
logic       alu_en;         // Indiacte a ALU íntruction
logic       branch_en;      // Indiacte a Branch íntruction
logic       load_en;        // Indicate a Load íntruction
logic       store_en;       // Indicate a Store operation
logic       mul_en;         // Indicate a Multiplication operation
logic       div_en;         // Indicate a Division operation
logic       fpu_en;         // Indicate a Floating point íntruction

logic       wren;           // Write enable for Register Writeback operations
logic       use_rs1;        // Indicate the instruction uses rs1
logic       use_rs2;        // Indicate the instruction uses rs2
logic       use_pc;         // Indicate the instruction use PC as operand
logic       use_imm;        // Indicate the instruction use immediate value

logic [1:0] mul_op;         // Multiplication operation selection
logic [1:0] div_op;         // Division       operation selection

logic [2:0] alu_op;         // 3'b000: ADDER (ADD - SUB) (default)
                            // 3'b001: Comparator (SLT - SLTI - SLTU - SLTIU)
                            // 3'b010: Shifter (SRLI - SRAI - SLLI - SRL - SRA - SLL)
                            // 3'b011: XOR operation (XOR - XORI)
                            // 3'b100: AND operation (AND - ANDI)
                            // 3'b101: OR  operation (OR  - ORI )
                            // 3'b110: Reserved (ALU = 32'b0)
                            // 3'b111: Reserved (ALU = 32'b0)

logic       alu_sub_en;
logic       alu_signed_cmp;
logic [1:0] alu_shift_ctrl; // shifter_crtl = 2'b00 : shift Right logical (default)
                            // shifter_crtl = 2;b01 : shift Left  logical
                            // shifter_crtl = 2'b10 : shift Right Arithmetic
                            // shifter_crtl = 2'b11 : Reserved

logic [7:0] branch_op;      // 8'b0000_0001: BEQ
                            // 8'b0000_0010: BNE
                            // 8'b0000_0100: BLT
                            // 8'b0000_1000: BGE
                            // 8'b0001_0000: BLTU
                            // 8'b0010_0000: BGEU
                            // 8'b0100_0000: JAL
                            // 8'b1000_0000: JALR


logic [3:0] lsu_bytemask;
logic       lsu_signed;     // Indicate a Load operation is sign-extended


// Pipeline categorization
assign alu_en       = (R_type & ~funct7[1]) | (I_type) | (isa.lui) | (isa.auipc);
assign branch_en    = (B_type) | (isa.jal | isa.jalr);
assign load_en      = (L_type);
assign store_en     = (S_type);
assign mul_en       = (isa.mul | isa.mulh | isa.mulsu | isa.mulu);
assign div_en       = (isa.div | isa.divu | isa.rem   | isa.remu);
assign fpu_en       = (F_type);

// Instruction operand informations
assign use_rs1      = ~(E_type | SYS_type) & ~(isa.lui | isa.auipc | isa.jal);
assign use_rs2      =  (B_type | S_type | R_type);
assign use_pc       =  (B_type) | (isa.auipc  | isa.jal);

assign use_imm      =  (L_type | I_type | S_type | B_type) |
                       (isa.auipc | isa.jal | isa.jalr | isa.lui);

assign wren         =  (L_type | I_type | R_type) |
                       (isa.auipc | isa.jal | isa.jalr | isa.lui);


// ALU control signals
assign alu_sub_en        = (isa.sub);
assign alu_signed_cmp    = (isa.slt | isa.slti);
assign alu_shift_ctrl[0] = (isa.sll | isa.slli);
assign alu_shift_ctrl[1] = (isa.sra | isa.srai);

assign alu_op[0] =  (isa.slt  | isa.slti  | isa.sltu | isa.sltiu) |
                    (isa.xor_ | isa.xori) | (isa.or_ | isa.ori  );

assign alu_op[1] =  (isa.srli | isa.srai  | isa.slli) | (isa.srl | isa.sra | isa.sll) |
                    (isa.xor_ | isa.xori) |
                    (isa.jal  | isa.jalr);

assign alu_op[2] =  (isa.and_ | isa.andi) |
                    (isa.or_  | isa.ori ) |
                    (isa.jal  | isa.jalr);

// BRU control signals
assign branch_op[0] = isa.beq;
assign branch_op[1] = isa.bne;
assign branch_op[2] = isa.blt;
assign branch_op[3] = isa.bge;
assign branch_op[4] = isa.bltu;
assign branch_op[5] = isa.bgeu;
assign branch_op[6] = isa.jal;
assign branch_op[7] = isa.jalr;

// LSU control signals
assign lsu_bytemask[0] = 1'b1;
assign lsu_bytemask[1] = ~(isa.sb | isa.lb | isa.lbu);
assign lsu_bytemask[2] = ~(isa.sb | isa.lb | isa.lbu | isa.sh | isa.lh | isa.lhu);
assign lsu_bytemask[3] = ~(isa.sb | isa.lb | isa.lbu | isa.sh | isa.lh | isa.lhu);
assign lsu_signed      =  (isa.lb | isa.lh);


// MUL control signals
assign mul_op[0] = (isa.mulu) | (isa.mulh );
assign mul_op[1] = (isa.mulu) | (isa.mulsu);


// DIV control signals
assign div_op[0] = (isa.remu) | (isa.divu);
assign div_op[1] = (isa.remu) | (isa.rem );



// ---------------------------------- Output package ------------------
always_comb begin : decode_pkg_assignemt
    // ALU
    o_decode_pkg.alu_en          = alu_en;
    o_decode_pkg.alu_op          = alu_op;
    o_decode_pkg.alu_sub_en      = alu_sub_en;
    o_decode_pkg.alu_signed_cmp  = alu_signed_cmp;
    o_decode_pkg.alu_shift_ctrl  = alu_shift_ctrl;

    o_decode_pkg.rs1_addr        = rs1_addr;
    o_decode_pkg.rs2_addr        = rs2_addr;
    o_decode_pkg.rd_addr         = rd_addr;
    o_decode_pkg.imm             = immediate;
    o_decode_pkg.pc              = pc;
    o_decode_pkg.use_pc          = use_pc;
    o_decode_pkg.use_imm         = use_imm;
    o_decode_pkg.use_rs1         = use_rs1;
    o_decode_pkg.use_rs2         = use_rs2;

    // BRU
    o_decode_pkg.branch_en        = branch_en;
    o_decode_pkg.is_predicted     = is_predicted;
    o_decode_pkg.predicted_target = predicted_target;
    o_decode_pkg.branch_op        = branch_op;

    // LSU
    o_decode_pkg.load_en         = load_en;
    o_decode_pkg.store_en        = store_en;
    o_decode_pkg.lsu_bytemask    = lsu_bytemask;
    o_decode_pkg.lsu_signed      = lsu_signed;

    // MUL/DIV
    o_decode_pkg.mul_en          = mul_en;
    o_decode_pkg.div_en          = div_en;
    o_decode_pkg.mul_op          = mul_op;
    o_decode_pkg.div_op          = div_op;

    // General
    o_decode_pkg.wren            = wren;
    o_decode_pkg.valid           = valid;
end


always_comb begin : hazard_helper_signal_assignment // To Hazard Detection
    o_decode_hazard_pkg.rs1_addr = rs1_addr;
    o_decode_hazard_pkg.rs2_addr = rs2_addr;
    o_decode_hazard_pkg.rd_addr  = rd_addr;
    o_decode_hazard_pkg.use_rs1  = use_rs1;
    o_decode_hazard_pkg.use_rs2  = use_rs2;
    o_decode_hazard_pkg.load_en  = load_en;
    o_decode_hazard_pkg.store_en = store_en;
    o_decode_hazard_pkg.mul_en   = mul_en;
    o_decode_hazard_pkg.div_en   = div_en;
    o_decode_hazard_pkg.wren     = wren;
    o_decode_hazard_pkg.valid    = valid;
end

assign o_ecall    = isa.ecall;      // FIXME: Not-used
assign o_ebreak   = isa.ebreak;     // FIXME: Not-used
assign o_pause    = isa.pause;      // FIXME: Not-used





// ======================================================================
// ============================= DEBUG ==================================
`ifdef DEBUG
    logic [6:0]   instr_encoded;
    instr_e       instr_op;
    register_idx_t  RS1;
    register_idx_t  RS2;
    register_idx_t  RD;

    prim_encoder_128to7   Encoding_instr_op (
        .i_bin(isa),
        .o_enc(instr_encoded)
    );

    assign RS1      = register_idx_t'(rs1_addr);
    assign RS2      = register_idx_t'(rs2_addr);
    assign RD       = register_idx_t'(rd_addr);
    assign instr_op = instr_e'(instr_encoded);

    assign o_decode_pkg.debug_pkg.instr         = instr_e'(instr_encoded);
    assign o_decode_pkg.debug_pkg.pc            = pc;
    assign o_decode_pkg.debug_pkg.imm           = immediate;
    assign o_decode_pkg.debug_pkg.rs1_addr      = register_idx_t'(rs1_addr);
    assign o_decode_pkg.debug_pkg.rs2_addr      = register_idx_t'(rs2_addr);
    assign o_decode_pkg.debug_pkg.rd_addr       = register_idx_t'(rd_addr );
    assign o_decode_pkg.debug_pkg.alu_en        = alu_en;
    assign o_decode_pkg.debug_pkg.branch_en     = branch_en;
    assign o_decode_pkg.debug_pkg.load_en       = load_en;
    assign o_decode_pkg.debug_pkg.store_en      = store_en;
    assign o_decode_pkg.debug_pkg.mul_en        = mul_en;
    assign o_decode_pkg.debug_pkg.div_en        = div_en;
    assign o_decode_pkg.debug_pkg.fpu_en        = fpu_en;
    assign o_decode_pkg.debug_pkg.use_pc        = use_pc;
    assign o_decode_pkg.debug_pkg.use_imm       = use_imm;
    assign o_decode_pkg.debug_pkg.use_rs1       = use_rs1;
    assign o_decode_pkg.debug_pkg.use_rs2       = use_rs2;
    assign o_decode_pkg.debug_pkg.wren          = wren;
    assign o_decode_pkg.debug_pkg.valid         = 1'b1;
    assign o_decode_pkg.debug_pkg.is_predicted  = is_predicted;
`endif


endmodule




