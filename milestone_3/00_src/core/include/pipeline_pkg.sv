package pipeline_pkg;


// ==================================================================================
// ================================= DEBUG ==========================================

`define DEBUG

`ifdef LINT
        // Remove debugging features when check LINT
        `undef DEBUG
`elsif SYNTH
        // Remove debugging features when Synthesis
        `undef DEBUG
`endif


`ifdef  DEBUG
        typedef enum logic [6:0] {
        NOP             = 7'd0,
        LUI             = 7'd1,
        AUIPC           = 7'd2,  //-

        JAL             = 7'd3,
        JALR            = 7'd4,  // -

        BEQ             = 7'd5,
        BNE             = 7'd6,
        BLT             = 7'd7,
        BGE             = 7'd8,
        BLTU            = 7'd9,
        BGEU            = 7'd10, // -

        LB              = 7'd11,
        LH              = 7'd12,
        LW              = 7'd13,
        LBU             = 7'd14,
        LHU             = 7'd15, // -

        SB              = 7'd16,
        SH              = 7'd17,
        SW              = 7'd18, // -

        ADDI            = 7'd19,
        SLTI            = 7'd20,
        SLTIU           = 7'd21,
        XORI            = 7'd22,
        ORI             = 7'd23,
        ANDI            = 7'd24,
        SLLI            = 7'd25,
        SRLI            = 7'd26,
        SRAI            = 7'd27, // -

        ADD             = 7'd28,
        SUB             = 7'd29,
        SLT             = 7'd30,
        SLTU            = 7'd31,
        XOR             = 7'd32,
        OR              = 7'd33,
        AND             = 7'd34,
        SLL             = 7'd35,
        SRL             = 7'd36,
        SRA             = 7'd37, // -

        ECALL           = 7'd38,
        EBREAK          = 7'd39,
        PAUSE           = 7'd40,

        MUL             = 7'd41,   // M extension: rd = (rs1 * rs2) [31:0]  (signed   x signed)
        MULH            = 7'd42,   // M extension: rd = (rs1 * rs2) [63:0]  (signed   x signed)
        MULSU           = 7'd43,   // M extension: rd = (rs1 * rs2) [63:0]  (signed   x unsigned)
        MULU            = 7'd44,   // M extension: rd = (rs1 * rs2) [63:0]  (unsigned x unsigned)
        DIV             = 7'd45,   // M extension: rd = (rs1 / rs2)         (signed)
        DIVU            = 7'd46,   // M extension: rd = (rs1 / rs2)         (unsigned)
        REM             = 7'd47,   // M extension: rd = (rs1 % rs2)         (signed)
        REMU            = 7'd48,   // M extension: rd = (rs1 % rs2)         (unsigned)

        FLW             = 7'd49,   // F extension: Load float word
        FSW             = 7'd50,   // F extension: Store float word

        FMADD_S         = 7'd51,   // F extension: rd = rs1 * rs2 + rs3    (fused)
        FMSUB_S         = 7'd52,   // F extension: rd = rs1 * rs2 - rs3    (fused)
        FNMADD_S        = 7'd53,   // F extension: rd = -(rs1 * rs2 + rs3) (fused)
        FNMSUB_S        = 7'd54,   // F extension: rd = -(rs1 * rs2 - rs3) (fused)

        FADD_S           = 7'd55,  // F extension: rd = rs1 + rs2
        FSUB_S           = 7'd56,  // F extension: rd = rs1 - rs2
        FMUL_S           = 7'd57,  // F extension: rd = rs1 * rs2
        FDIV_S           = 7'd58,  // F extension: rd = rs1 / rs2
        FSQRT_S          = 7'd59,  // F extension: rd = sqrt(rs1)

        FSGNJ_S          = 7'd60,  // F extension: rd = sign(rs2) | mag(rs1)
        FSGNJN_S         = 7'd61,  // F extension: rd = ~sign(rs2) | mag(rs1)
        FSGNJX_S         = 7'd62,  // F extension: rd = sign(rs1)^sign(rs2) | mag(rs1)

        FMIN_S           = 7'd63,  // F extension: rd = min(rs1, rs2)
        FMAX_S           = 7'd64,  // F extension: rd = max(rs1, rs2)

        FCVT_W_S         = 7'd65,  // F extension: Convert float to int (signed)
        FCVT_WU_S        = 7'd66,  // F extension: Convert float to int (unsigned)
        FCVT_S_W         = 7'd67,  // F extension: Convert int (signed) to float
        FCVT_S_WU        = 7'd68,  // F extension: Convert int (unsigned) to float

        FMV_X_W          = 7'd69,  // F extension: Move float bits to int register
        FMV_W_X          = 7'd70,  // F extension: Move int bits to float register

        FEQ_S            = 7'd71,  // F extension: float compare equal
        FLT_S            = 7'd72,  // F extension: float compare less than
        FLE_S            = 7'd73,  // F extension: float compare less or equal

        FCLASS_S         = 7'd74   // F extension: classify float value
        } instr_e;

        typedef enum logic [4:0] {
                r0  = 5'd0,
                r1  = 5'd1,
                r2  = 5'd2,
                r3  = 5'd3,
                r4  = 5'd4,
                r5  = 5'd5,
                r6  = 5'd6,
                r7  = 5'd7,
                r8  = 5'd8,
                r9  = 5'd9,
                r10 = 5'd10,
                r11 = 5'd11,
                r12 = 5'd12,
                r13 = 5'd13,
                r14 = 5'd14,
                r15 = 5'd15,
                r16 = 5'd16,
                r17 = 5'd17,
                r18 = 5'd18,
                r19 = 5'd19,
                r20 = 5'd20,
                r21 = 5'd21,
                r22 = 5'd22,
                r23 = 5'd23,
                r24 = 5'd24,
                r25 = 5'd25,
                r26 = 5'd26,
                r27 = 5'd27,
                r28 = 5'd28,
                r29 = 5'd29,
                r30 = 5'd30,
                r31 = 5'd31
        } register_idx_t;


        typedef struct packed{
                instr_e                 instr;
                logic [31:0]            pc;
                logic [31:0]            imm;
                register_idx_t          rs1_addr;
                register_idx_t          rs2_addr;
                register_idx_t          rd_addr;
                logic                   alu_en;
                logic                   branch_en;
                logic                   load_en;
                logic                   store_en;
                logic                   mul_en;
                logic                   div_en;
                logic                   fpu_en;
                logic                   use_pc;
                logic                   use_imm;
                logic                   use_rs1;
                logic                   use_rs2;
                logic                   wren;
                logic                   valid;
                logic                   is_predicted;
        } debug_t;
`endif

// ==================================================================================
// ==================================================================================

// Instruction bitmap for decoder
typedef struct packed {
    logic [52:0] padding;     // [127:75] — unused, zero-padded or reserved
    logic        fclass_s;     // [74]
    logic        fle_s;        // [73]
    logic        flt_s;        // [72]
    logic        feq_s;        // [71]
    logic        fmv_w_x;      // [70]
    logic        fmv_x_w;      // [69]
    logic        fcvt_s_wu;    // [68]
    logic        fcvt_s_w;     // [67]
    logic        fcvt_wu_s;    // [66]
    logic        fcvt_w_s;     // [65]
    logic        fmax_s;       // [64]
    logic        fmin_s;       // [63]
    logic        fsgnjx_s;     // [62]
    logic        fsgnjn_s;     // [61]
    logic        fsgnj_s;      // [60]
    logic        fsqrt_s;      // [59]
    logic        fdiv_s;       // [58]
    logic        fmul_s;       // [57]
    logic        fsub_s;       // [56]
    logic        fadd_s;       // [55]
    logic        fnmsub_s;     // [54]
    logic        fnmadd_s;     // [53]
    logic        fmsub_s;      // [52]
    logic        fmadd_s;      // [51]
    logic        fsw;          // [50]
    logic        flw;          // [49]
    logic        remu;         // [48]
    logic        rem;          // [47]
    logic        divu;         // [46]
    logic        div;          // [45]
    logic        mulu;         // [44]
    logic        mulsu;        // [43]
    logic        mulh;         // [42]
    logic        mul;          // [41]
    logic        pause;        // [40]
    logic        ebreak;       // [39]
    logic        ecall;        // [38]
    logic        sra;          // [37]
    logic        srl;          // [36]
    logic        sll;          // [35]
    logic        and_;         // [34]
    logic        or_;          // [33]
    logic        xor_;         // [32]
    logic        sltu;         // [31]
    logic        slt;          // [30]
    logic        sub;          // [29]
    logic        add;          // [28]
    logic        srai;         // [27]
    logic        srli;         // [26]
    logic        slli;         // [25]
    logic        andi;         // [24]
    logic        ori;          // [23]
    logic        xori;         // [22]
    logic        sltiu;        // [21]
    logic        slti;         // [20]
    logic        addi;         // [19]
    logic        sw;           // [18]
    logic        sh;           // [17]
    logic        sb;           // [16]
    logic        lhu;          // [15]
    logic        lbu;          // [14]
    logic        lw;           // [13]
    logic        lh;           // [12]
    logic        lb;           // [11]
    logic        bgeu;         // [10]
    logic        bltu;         // [9]
    logic        bge;          // [8]
    logic        blt;          // [7]
    logic        bne;          // [6]
    logic        beq;          // [5]
    logic        jalr;         // [4]
    logic        jal;          // [3]
    logic        auipc;        // [2]
    logic        lui;          // [1]
    logic        nop;          // [0]
} instr_bitmap_t;


//---------------- Fetch ----------------------
typedef struct packed {
        logic [31:0] pc               ; // PC
        logic [31:0] instr            ; // Instruction
        logic        valid            ;
        logic        is_predicted     ; // Indicate this instruction is predicted
        logic [31:0] predicted_target ; // Predicted Target
} fetch_t ;


typedef struct packed {
        logic [31:0] br_update_pc        ; // PC     of the executed Branch instruction
        logic [31:0] br_pc_plus4         ; // PC + 4 of the executed Branch instruction
        logic [31:0] br_target           ; // Target of the executed Branch instruction
        logic        br_taken            ; // Result of the executed Brnach instriction is Taken
        logic        br_valid            ; // The executed Branch instruction is Valid
} branch_t ;




typedef struct packed {
        logic   [4:0]  rs1_addr          ;
        logic   [4:0]  rs2_addr          ;
        logic   [4:0]  rd_addr           ;
        logic   [31:0] imm               ;
        logic   [31:0] pc                ;
        logic          use_pc            ;  // Indicate operand A uses PC
        logic          use_imm           ;  // Indicate operand B uses Immediate
        logic          use_rs1           ;  // Indicate rs1 field actually used to Address Regfile
        logic          use_rs2           ;  // Indicate rs2 field actually used to Address Regfile
        logic          wren              ;  // Writeback enable

        logic          alu_en            ;
        logic          alu_sub_en        ;
        logic          alu_signed_cmp    ;
        logic   [1:0]  alu_shift_ctrl    ;
        logic   [2:0]  alu_op            ;   // 3'b000: ADDER (ADD - SUB) (default)
                                             // 3'b001: Comparator (SLT - SLTI - SLTU - SLTIU)
                                             // 3'b010: Shifter (SRLI - SRAI - SLLI - SRL - SRA - SLL)
                                             // 3'b011: XOR operation (XOR - XORI)
                                             // 3'b100: AND operation (AND - ANDI)
                                             // 3'b101: OR  operation (OR  - ORI )
                                             // 3'b110: PC + 4        (JAL - JALR)
                                             // 3'b111: Reserved (ALU = 32'b0)

        logic          branch_en         ;   // Enable updating Brnach Prediction BTB
        logic          is_predicted      ;   // Indicate the instruction is predidcted by BTB
        logic   [31:0] predicted_target  ;
        logic   [7:0]  branch_op         ;   // 8'b0000_0001: BEQ
                                             // 8'b0000_0010: BNE
                                             // 8'b0000_0100: BLT
                                             // 8'b0000_1000: BGE
                                             // 8'b0001_0000: BLTU
                                             // 8'b0010_0000: BGEU
                                             // 8'b0100_0000: JAL
                                             // 8'b1000_0000: JALR

        logic         load_en           ;    // Indicate a Loadf Instruction
        logic         store_en          ;    // Indicate a Store operation
        logic  [3:0]  lsu_bytemask      ;
        logic         lsu_signed        ;    // Indicate a Load operation is sign-extended

        logic         mul_en            ;
        logic         div_en            ;
        logic  [1:0]  mul_op            ;
        logic  [1:0]  div_op            ;

        logic         valid             ;    // Indicate the instruction is valid to be executed

        `ifdef DEBUG
               debug_t   debug_pkg;
        `endif
} decode_t ;



// Data package contain signal required for Hazard detection
typedef struct packed{
        logic [4:0] rs1_addr;
        logic [4:0] rs2_addr;
        logic [4:0] rd_addr;
        logic       use_rs1;
        logic       use_rs2;
        logic       load_en;
        logic       store_en;
        logic       mul_en;
        logic       div_en;
        logic       wren;
        logic       valid;
} hazard_t ;



typedef struct packed {
        logic [2:0]   alu_op;
        logic [31:0]  operand_a;
        logic [31:0]  operand_b;
        logic         is_signed_cmp;
        logic [1:0]   shifter_ctrl;
        logic         sub_en;
        logic [4:0]   rd_addr;
        logic         wren;               // Enable forwarding (avoid operand == imm or PC)
        logic         valid;
`ifdef DEBUG
        debug_t       debug_pkg;
`endif
} alu_t;



typedef struct packed {
        logic [7:0]   branch_op;
        logic [31:0]  pc;
        logic [31:0]  offset;             // Offset address to calculate Branch Target (immedicate)
        logic [31:0]  rs1_data;           // Source registe 1 for Branch condition comparison
        logic [31:0]  rs2_data;           // Source registe 2 for Branch condition comparison
        logic [4:0]   rd_addr;
        logic         wren;               // Writeback return address to regfile for JAL and JALR
        logic         valid;
        logic         is_predicted;        // Indicate the instruction is predidcted by BTB
        logic [31:0]  predicted_target;    // Indicate the instruction is predidcted by BTB
`ifdef DEBUG
        debug_t       debug_pkg;
`endif
} bru_t;



typedef struct packed {
        logic        load_en;
        logic        store_en;
        logic [31:0] base_addr;
        logic [31:0] offset_addr;
        logic [31:0] store_data;
        logic [4:0]  rd_addr;
        logic [3:0]  lsu_bytemask;
        logic        lsu_signed;
        logic        wren;
        logic        valid;

`ifdef DEBUG
        debug_t       debug_pkg;
`endif
} lsu_t;







typedef struct packed {
        logic [31:0]  multiplicand;
        logic [31:0]  multiplier;
        logic [4:0]   rd_addr;
        logic [1:0]   mul_op;
        logic         wren;               // Enable forwarding (avoid operand == imm or PC)
        logic         valid;

`ifdef DEBUG
        debug_t       debug_pkg;
`endif
} mul_t;


typedef struct packed {
        logic [31:0]  dividend;     // Operand A
        logic [31:0]  divisor;      // Operand B
        logic [4:0]   rd_addr;
        logic [1:0]   div_op;
        logic         wren;         // Enable forwarding (avoid operand == imm or PC)
        logic         valid;

`ifdef DEBUG
        debug_t       debug_pkg;
`endif
} div_t;



typedef struct packed {
        logic [31:0]  rd_data;
        logic [4:0]   rd_addr;
        logic         wren;       // Enable forwarding (avoid operand == imm or PC)
        logic         valid;
        logic         rd_is_int;
`ifdef DEBUG
        debug_t       debug_pkg;
`endif
} pipe_t;



endpackage
