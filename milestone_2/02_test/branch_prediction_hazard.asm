            ADDI     x10, x0,  1        # PC = 0  | R10 = 1
            ADDI     x5, x0,   10       # PC = 4  | R5  = 10 
            ADDI     x6, x0,   0        # PC = 8  | R6  = 0  
LOOP1:      ADDI     x6, x6,   1        # PC = 12 | R6  = R6 + 1
            BNE      x6, x5,   LOOP1    # PC = 16 |  
            ADDI     x10, x10, 1        # PC = 20 | R10 = R10 + 1 = 2
            
            ADDI     x11, x0,  20       # PC = 24 | R11 = 20
            ADDI     x12, x0,  0        # PC = 28 | R12 = 0
LOOP2:      ADDI     x12, x12, 1        # PC = 32 | R12 = R12  + 1 
            BNE      x12, x11, LOOP2    # PC = 36 |   

            ADDI     x10, x10, 1        # PC = 40 | 
            ADDI     x13, x0,  20       # PC = 44 | 
            ADDI     x14, x0,  0        # PC = 48 | 
LOOP3:      ADDI     x14, x14, 1        # PC = 52 | 
            BNE      x14, x13, LOOP3    # PC = 56 |
            JAL      x1, LOOP4          # PC = 60 |
            LUI      x1,  0xDEAD        # PC = 64 
            LUI      x2,  0xDEAD        # PC = 68 
            LUI      x3,  0xDEAD        # PC = 72 
            LUI      x4,  0xDEAD        # PC = 76 
            LUI      x5,  0xDEAD        # PC = 80 
            LUI      x6,  0xDEAD        # PC = 84 
            LUI      x7,  0xDEAD        # PC = 88 
            LUI      x8,  0xDEAD        # PC = 92 
            LUI      x9,  0xDEAD        # PC = 96         
LOOP4:      BEQ      x0, x14,  END      # PC = 100
            ADDI     x14, x14, -1       # PC = 104 | R14 = R14 - 1 
            JAL      x1, LOOP4          # PC = 108
END:        LUI      x8, 0x90000        # PC = 112 | R8 = 0x9000_0000
            ADDI     x8, x8, -0x10
            ADDI     x9, x0, 0xAA
            SW       x9, 0(x8)
HALT:       JAL      x0, HALT
            
            
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
