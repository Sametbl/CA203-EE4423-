package data_pkg;


typedef struct packed {
    logic [86:0] padding;      // [127:41] — unused, zero-padded or reserved
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








endpackage











