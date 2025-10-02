#       
#       DATA_SEGMENT:   ADDI    x1, x0, 0x300        # 7-segment display datas are store at 0x300                                                                                                                                                                                                                                                                                                                                   
#                       ADDI    x2, x0, 0b11000000   # 7-segment data to display 0                                                                                                                                                                                                                                                      
#                       SB      x2, 0(x1)                                                                                                                                                                                                                                                       
#                       ADDI    x2, x0, 0b11111001   # 7-segment data to display 1                                                                                                                                                                                                                                                      
#                       SB      x2, 1(x1)                                                                                                                                                                                                                                                       
#                       ADDI    x2, x0, 0b10100100   # 7-segment data to display 2                                                                                                                                                                                                                                                      
#                       SB      x2, 2(x1)                                                                                                                                                                                                                                                       
#                       ADDI    x2, x0, 0b10110000   # 7-segment data to display 3                                                                                                                                                                                                                                                      
#                       SB      x2, 3(x1)                                                                                                                                                                                                                                                       
#                       ADDI    x2, x0, 0b10011001   # 7-segment data to display 4                                                                                                                                                                                                                                                      
#                       SB      x2, 4(x1)                                                                                                                                                                                                                                                       
#                       ADDI    x2, x0, 0b10010010   # 7-segment data to display 5                                                                                                                                                                                                                                                      
#                       SB      x2, 5(x1)                                                                                                                                                                                                                                                       
#                       ADDI    x2, x0, 0b10000010   # 7-segment data to display 6                                                                                                                                                                                                                                                      
#                       SB      x2, 6(x1)                                                                                                                                                                                                                                                       
#                       ADDI    x2, x0, 0b11111000   # 7-segment data to display 7                                                                                                                                                                                                                                                      
#                       SB      x2, 7(x1)                                                                                                                                                                                                                                                       
#                       ADDI    x2, x0, 0b10000000   # 7-segment data to display 8                                                                                                                                                                                                                                                      
#                       SB      x2, 8(x1)                                                                                                                                                                                                                                                       
#                       ADDI    x2, x0, 0b10010000   # 7-segment data to display 9                                                                                                                                                                                                                                                      
#                       SB      x2, 9(x1)                                                                                                                                                                                                                                                       
#                       ADDI    x2, x0, 0b10111111   # 7-segment data to display '-'                                                                                                                                                                                                                                                        
#                       SB      x2, 10(x1)                                                                                                                                                                                                                                                      
#                                                                                                                                                                                                                                                               
#                       ADDI    x1,  x0, 0x200            # Address to store LED_index = 1                                                                                                                                                                                                                                                      
#                       ADDI    x2,  x0, 1                # Init: LED_index = 1                                                                                                                                                                                                                                                     
#                       SW      x2,  0(x1)                                                                                                                                                                                                                                                                  
#                       ADDI    x4,  x0, 0x100            # A at 0x100, B at 0x104                                                                                                                                                                                                                                                      
#                       ADDI    x20, x0, 0                # Result initally = 0                                                                                                                                                                                                                                                     
#                       SW      x20, 8(x4)                                                                                                                                                                                                                                                      
#                                                                                                                                                                                                                                                        
#        MAIN_LOOP:     ADDI    x4, x0, 0x100       # A at 0x100, B at 0x104                                                                                                                                                                                                                                                        
#                       ADDI    x1, x0, 0x400                                                                                                                                                                                                                                                       
#                       LW      x7, 0x10(x1)        # x7 = GPI (0x410)                                                                                                                                                                                                                                                      
#                                                                                                                                                                                                                                                       
#        READ_OP_A:     ANDI    x8, x7, 0x1         # if GPI[0] == 1 → store A                                                                                                                                                                                                                                                      
#                       BEQ     x8, x0, READ_OP_B                                                                                                                                                                                                                                                       
#                       LW      x6, 0(x1)           # x6 = SWITCH input (0x400)                                                                                                                                                                                                                                                     
#                       SW      x6, 0(x4)           # store A to 0x100                                                                                                                                                                                                                                                      
#        READ_OP_B:     ANDI    x8, x7, 0x2         # if GPI[1] == 1 → store B                                                                                                                                                                                                                                                      
#                       BNE     x8, x0, CALC                                                                                                                                                                                                                                                        
#                       LW      x6, 0(x1)           # x6 = SWITCH input (0x400)                                                                                                                                                                                                                                                     
#                       SW      x6, 4(x4)           # store B to 0x104                                                                                                                                                                                                                                                      
#                                                                                                                                                                                                                                                       
#        CALC:          ANDI    x8, x7, 0x4         # if GPI[2] == 1 → Perfrom calculation                                                                                                                                                                                                                                                      
#                       BNE     x8, x0, DO_MUL                                                                                                                                                                                                                                                      
#                       LW      x20, 8(x4)          # Store Result to 0x108  
#                       ADDI    x19, x0, 1          # Signed enable                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
#                       JAL     x0, BCD_CONV_R20                                                                                                                                                                                                                                                        
#                                                                                                                                                                                                                                                       
#        DO_MUL:        LW      x9,  0(x4)          # x9  = operand A                                                                                                                                                                                                                                                       
#                       LW      x10, 4(x4)          # x10 = operand B                                                                                                                                                                                                                                                       
#                       MUL     x20, x9, x10        # x16 = A * B (signed)                                                                                                                                                                                                                                                      
#                       SW      x20, 8(x4)          # Store Result to 0x108  
#                       ADDI    x19, x0, 1          # Signed enable                                                                                                                                                                                                                                            
#                       JAL     x0, BCD_CONV_R20                                                                                                                                                                                                                                                        
#         


# x19 = Signed enable      
# x20 = Number to display (signed)
# temp = x20
# For (int i = 1; i < 12; i++){
#       digit = temp % 10
#       MEM[x200 + i * 4] = digit
#       temp = temp / 10
# }
# ===> x19 = temp
# ===> x18 = 10
# ===> x21 = x200
# ===> x23 = i
# ===> x24 = digit

#       BCD_CONV_R20:   ADD     x21, x0,  x20                       # Copy x20 to x21     
                        ADDI    x22, x0,  0 
#                       BEQ     x19, x0,  POSITIVE_EX               # Check for signed enable                                                                                                                                                                                                                               
#                       SLT     x22, x20, x0              #188      # x22 = 1 (if x20 < 0)                                                                                                                                                                                                                                                                                                                                                                                                                     
#                       BEQ     x22, x0,  POSITIVE_EX     #192                                                                                                                                                                                                                                                                                                                                                                                                                                  
#                       SUB     x21, x0,  x20             #196      # x21 = abs(x20)                                                                                                                                                                                                                                                            
#                                                                                                                                                                                                                                                               
#       POSITIVE_EX:    ADD     x19, x0,  x21             #200      # x19 = x21 (copy of abs(x20))                                                                                                                                                                                                                                                                                                                                                                                                                         
#                       ADDI    x18, x0,  10              #204      # x18 = divisor (10)                                                                                                                                                                                                                                                                                                                                                                                                                            
#                       ADDI    x21, x0,  0x200           #212      # Base address for digit storage                                                                                                                                                                                                                                                                                                                                                                                                                         
#                       ADDI    x21, x21, 4               #216                                                                                                                                                                                                                                                                                                                                                                                                                             
#                       ADDI    x23, x0,  1               #220      # Digit counter = 1 (From 1 to 11)                                                                                                                                                                                                                                                                                                                                                                                                                       
#       DIGIT_EX_LOOP:  REMU    x24, x19, x18             #224      # x24 = digit                                                                                                                                                                                                                                                                                                                                                                                                                           
#                       DIVU    x19, x19, x18             #228                                                                                                                                                                                                                                                                                                                                                                                                                          
#                       SW      x24, 0(x21)               #232      # store digit                                                                                                                                                                                                                                                               
#                                                                                                                                                                                                                                                               
#                       ADDI    x21, x21, 4               #236      # next digit address                                                                                                                                                                                                                                                                                                                                                                                                                            
#                       ADDI    x23, x23, 1               #240      # Digit counter ++                                                                                                                                                                                                                                                                                                                                                                                                                
#                       ADDI    x25, x0,  11              #244      # Check if LED_inex = 11 (If true then continue)                                                                                                                                                                                                                                                                                                                                                                                                                            
#                       BNE     x23, x25, DIGIT_EX_LOOP   #248                                                                                                                                                                                                                                                                                                                                                                                                                               
#                       ADDI    x21, x0,  0x200           #252      # base address for digit storage                                                                                                                                                                                                                                                                                                                                                                                                                   
#                       ADDI    x21, x21, 0x30            #260      # Address for sign flag (0x200 + 44)                                                                                                                                                                                                                                                        
#                       ADDI    x25, x0,  10                        #                                                                                                                                                                                                                                                           
#                       MUL     x22, x25, x22                       # x22 = (x22 == 1) ? 10 : 0                                                                                                                                                                                                                                                                                                                                                                                                                        
#                       SW      x22, 0(x21)               #264      # MEM[x230] = x22 = (x20 < 0) ? 1: 0                                                                                                                                                                                                                                                                                                                                                                                                                  
#                       JAL     x0,  DISPLAY_DIGIT        #268      # Display Digit                                                                                                                                                                                                                                                                                                                         
#                                                                                                                                                                                                                                                               
#                                                                                                                                                                                                                                                               
# Address x200: Current Digit Index counter      
# Address x204: Digit 1
# Address x208: Digit 2
# Address x20C: Digit 3
# Address x210: Digit 4
# Address x214: Digit 5
# Address x218: Digit 6
# Address x21C: Digit 7
# Address x220: Digit 8
# Address x224: Digit 9
# Address x228: Digit 10
# Address x22C: Digit 11
# Address x230: Digit 12 (1 to display sign, 0 to turn OFF)
                                                                                                                                                                                                                                                          
#       DISPLAY_DIGIT:  ADDI    x2,  x0, 0x500            # GPO base address                                                                                                                                                                                                                                                        
#                       ADDI    x21, x0, 0x200            # x21 = Base address for digit                                                                                                                                                                                                                                                                
#                       LW      x22, 0(x21)               # x22 = LED_index (From 1 to 12)                                                                                                                                                                                                                                                              
#                       SLLI    x23, x22, 2               # x23 = offset = LED_index * 4                                                                                                                                                                                                                                                                                
#                       ADD     x21, x21, x23             # x21 = Address of the Digit to be displayed                                                                                                                                                                                                                                                                                                          
#                       LW      x24, 0(x21)               # x24 = digit value                                                                                                                                                                                                                                                           
#                                                                                                                                                                                                                                                               
#                       ADDI    x21, x22, -1              # x21 = Bit mask to select LED                                                                                                                                                                                                                                                                                                                
#                       ADDI    x25, x0,   1              #                                                                                                                                                                                                                                                                                                                 
#                       SLL     x25, x25, x21             # x25 = 0x1 << x21 (GPO_A bit for current LED)                                                                                                                                                                                                                                                                        
#                       ADDI    x26, x0,  0x0F            # x26 = Bit mask for digit value                                                                                                                                                                                                                                                      
#                       AND     x26, x26, x24             #                                                                                                                                                                                                                                                     
#                                                                                                                                                                                                                                                               
#                       ADDI    x21, x0, 0x300            # Base address to load 7-segment data                                                                                                                                                                                                                                                     
#                       ADD     x21, x21, x26                                                                                                                                                                                                                                                       
#                       LBU     x26, 0(x21)                                                                                                                                                                                                                                                     
#                       ANDI    x26, x26, 0xFF                                                                                                                                                                                                                                                      
#                                                                                                                                                                                                                                                               
#                       SW      x0 , 0x0(x2)              # Turn off                                                                                                                                                                                                                                                        
#                       SW      x26, 0x10(x2)             # GPO_B = digit bits (MEM[x510] = Digit value in 4-bit)                                                                                                                                                                                                                                                               
#                       NOP                               # 100ns delay                                                                                                                                                                                                                                                     
#                       NOP                                                                                                                                                                                                                                                     
#                       NOP                                                                                                                                                                                                                                                     
#                       NOP                                                                                                                                                                                                                                                     
#                       NOP                                                                                                                                                                                                                                                     
#                       NOP                                                                                                                                                                                                                                                     
#                       NOP                                                                                                                                                                                                                                                     
#                       NOP                                                                                                                                                                                                                                                                     
#                       SW      x25, 0(x2)                # GPO_A = LED_index bit                                                                                                                                                                                                                                                           
#                                                                                                                                                                                                                                                               
#                       ADDI    x21, x0,  12                                                                                                                                                                                                                                                        
#                       BEQ     x22, x21, CLEAR_INDEX                                                                                                                                                                                                                                                       
#                       ADDI    x22, x22, 1               # LED_index++                                                                                                                                                                                                                                                                 
#                       JAL     x0,  STORE_INDEX                                                                                                                                                                                                                                                        
#                                                                                                                                                                                                                                                               
#       CLEAR_INDEX:    ADDI    x22, x0, 1                # LED_index = 1                                                                                                                                                                                                                                                       
#                       JAL     x0,  STORE_INDEX                                                                                                                                                                                                                                                        
#                                                                                                                                                                                                                                                               
#       STORE_INDEX:    ADDI    x21, x0,  0x200           # Address to hold LED_index                                                                                                                                                                                                                                                       
#                       ANDI    x22, x22, 0x0F            # wrap around 0–15                                                                                                                                                                                                                                                            
#                       SW      x22, 0(x21)               # Store bit index                                                                                                                                                                                                                                                     
#                       JAL     x0, MAIN_LOOP             # RET                                                                                                                                                                                                                                                                                                             

30 00 00 93
0C 00 01 13
00 20 80 23
0F 90 01 13
00 20 80 A3
0A 40 01 13
00 20 81 23
0B 00 01 13
00 20 81 A3
09 90 01 13
00 20 82 23
09 20 01 13
00 20 82 A3
08 20 01 13
00 20 83 23
0F 80 01 13
00 20 83 A3
08 00 01 13
00 20 84 23
09 00 01 13
00 20 84 A3
0B F0 01 13
00 20 85 23
20 00 00 93
00 10 01 13
00 20 A0 23
10 00 02 13
00 00 0A 13
01 42 24 23
10 00 02 13
40 00 00 93
01 00 A3 83
00 13 F4 13
00 04 06 63
00 00 A3 03
00 62 20 23
00 23 F4 13
00 04 06 63
00 00 A3 03
00 62 22 23
00 43 F4 13
00 04 16 63
00 82 2A 03
01 80 00 6F
00 02 24 83
00 42 25 03
02 A4 8A 33
01 42 24 23
00 40 00 6F
01 40 0A B3
00 0A 2B 33
00 0B 04 63
41 40 0A B3
01 50 09 B3
00 A0 09 13
20 00 0A 93
00 4A 8A 93
00 10 0B 93
03 29 EC 33
03 29 C9 B3
01 8A A0 23
00 4A 8A 93
00 1B 8B 93
00 B0 0C 93
FF 9B 94 E3
20 00 0A 93
03 0A 8A 93
00 A0 0C 93
03 6C 8B 33
01 6A A0 23
00 40 00 6F
50 00 01 13
20 00 0A 93
00 0A AB 03
00 2B 1B 93
01 7A 8A B3
00 0A AC 03
FF FB 0A 93
00 10 0C 93
01 5C 9C B3
00 F0 0D 13
01 8D 7D 33
30 00 0A 93
01 AA 8A B3
00 0A CD 03
0F FD 7D 13
00 01 20 23
01 A1 28 23
00 00 00 13
00 00 00 13
00 00 00 13
00 00 00 13
00 00 00 13
00 00 00 13
00 00 00 13
00 00 00 13
01 91 20 23
00 C0 0A 93
01 5B 06 63
00 1B 0B 13
00 C0 00 6F
00 10 0B 13
00 40 00 6F
20 00 0A 93
00 FB 7B 13
01 6A A0 23
EC DF F0 6F








