#       
#   DATA_SEGMENT:   ADDI    x1, x0, 0x300        # 7-segment display datas are store at 0x300
#                   ADDI    x2, x0, 0b11000000   # 7-segment data to display 0
#                   SB      x2, 0(x1)
#                   ADDI    x2, x0, 0b11111001   # 7-segment data to display 1
#                   SB      x2, 1(x1)
#                   ADDI    x2, x0, 0b10100100   # 7-segment data to display 2
#                   SB      x2, 2(x1)
#                   ADDI    x2, x0, 0b10110000   # 7-segment data to display 3
#                   SB      x2, 3(x1)
#                   ADDI    x2, x0, 0b10011001   # 7-segment data to display 4
#                   SB      x2, 4(x1)
#                   ADDI    x2, x0, 0b10010010   # 7-segment data to display 5
#                   SB      x2, 5(x1)
#                   ADDI    x2, x0, 0b10000010   # 7-segment data to display 6
#                   SB      x2, 6(x1)
#                   ADDI    x2, x0, 0b11111000   # 7-segment data to display 7
#                   SB      x2, 7(x1)
#                   ADDI    x2, x0, 0b10000000   # 7-segment data to display 8
#                   SB      x2, 8(x1)
#                   ADDI    x2, x0, 0b10010000   # 7-segment data to display 9
#                   SB      x2, 9(x1)
#                   ADDI    x2, x0, 0b10111111   # 7-segment data to display '-'
#                   SB      x2, 10(x1)
#   
#                  ADDI    x1,  x0, 0x200            # Address to store LED_index = 1
#                  ADDI    x2,  x0, 1                # Init: LED_index = 1           
#                  SW      x2,  0(x1)                                                
#                  ADDI    x4,  x0, 0x100            # A at 0x100, B at 0x104        
#                  ADDI    x20, x0, 0                # Result initally = 0           
#                  SW      x20, 8(x4)                                                
#                                                                                    
#   MAIN_LOOP:     ADDI    x4, x0, 0x100       # A at 0x100, B at 0x104              
#                  ADDI    x1, x0, 0x400                                             
#                  LW      x7, 0x10(x1)        # x7 = GPI (0x410)                    
#                                                                                    
#   READ_OP_A:     ANDI    x8, x7, 0x1         # if GPI[0] == 1 → store A            
#                  BEQ     x8, x0, CALC                                              
#                  LW      x6, 0(x1)           # x6 = SWITCH input (0x400)           
#                  SW      x6, 0(x4)           # store A to 0x100                    
#                                                                                    
#   CALC:          ANDI    x8, x7, 0x4         # if GPI[2] == 1 → Perfrom calculation
#                  BNE     x8, x0, DO_SQRT_1                                         
#                  LW      x20, 8(x4)          # Store Result to 0x108               
#                  ADDI    x19, x0, 0          # Signed enable                       
#                  JAL     x0, BCD_CONV_R20                                          
#                                                                                    
#   DO_SQRT_1:     LW      x9,  0(x4)          # x9  = operand A                     
#                  SLT     x11, x9,  x0                                              
#                  BEQ     x11, x0, DO_SQRT_2                                        
#                  LW      x20, 8(x4)          # Store Result to 0x108               
#                  ADDI    x19, x0, 0          # Signed enable                       
#                  JAL     x0, BCD_CONV_R20                                          
#                                                                                    
#   DO_SQRT_2:     LI      x8,  1000000        # Scale = 1_000_000                   
#                  MUL     x15, x9 x8          # 1000000*(A)                         
#                                                                                    
#                                                                                    
#                  ADDI x11, x0, 0       # low = 0                                   
#                  ADD  x12, x0, x15     # high = num                                
#                  ADDI x13, x0, 0       # ans = 0                                   
#                                                                                    
#   CHECK_LOOP:    SUB  x14, x12, x11    # mid = high - low                          
#                  ADDI x17, x0 , 2                                                  
#                  DIVU x14, x14, x17    # mid = mid / 2                             
#                  ADD  x14, x14, x11    # mid = mid + low                           
#                  MUL  x16, x14, x14    # sq = mid * mid                            
#                                                                                    
#                  BNE  x16, x15, CHECK_2 # if (sq == num) x20 = num                 
#                  ADD  x20, x16, x0                                                 
#                  JAL  x0, SHOW_RESULT                                              
#                                                                                    
#   CHECK_2:       MULH x17, x14, x14    # x17 = mid * mid [63:32]                   
#                  BLTU x0,  x17, CHECK_3                                            
#                  BGEU x16, x15, CHECK_3                                            
#                  ADD  x13, x14, x0      # ans = mid                                
#                  ADDI x11, x14, 1       # low = mid + 1                            
#                  BEQ  x11, x12, CHECK_LOOP                                         
#                  BLT  x11, x12, CHECK_LOOP                                         
#                  ADD  x20, x13, x0                                                 
#                  JAL  x0, SHOW_RESULT                                              
#                                                                                    
#   CHECK_3:       ADDI x12, x14, -1      # high = mid - 1                           
#                  BEQ  x11, x12, CHECK_LOOP                                         
#                  BLT  x11, x12, CHECK_LOOP                                         
#                  ADD  x20, x13, x0                                                 
#                  JAL  x0, SHOW_RESULT                                              
#                                                                                    
#                                                                                    
#   SHOW_RESULT:   ADDI    x4,  x0, 0x100  
#                  LW      x28, 0(x4) 
#                  ADD     x29, x0 , x20
#                  SW      x20, 8(x4)          # Store Result to 0x108               
#                  ADDI    x19, x0, 0          # Signed enable                       
#                  JAL     x0, BCD_CONV_R20                                          
#                                                                                                                  
#   
#   
#   
#   
#   
#   
#   
#   BCD_CONV_R20:   ADD     x21, x0,  x20                       # Copy x20 to x21   
#                   ADDI    x22, x0,  0 
#                   BEQ     x19, x0,  POSITIVE_EX               # Check for signed enable                       
#                   SLT     x22, x20, x0              #188      # x22 = 1 (if x20 < 0)                          
#                   BEQ     x22, x0,  POSITIVE_EX     #192                                                      
#                   SUB     x21, x0,  x20             #196      # x21 = abs(x20)                                
#                                                                                                               
#   POSITIVE_EX:    ADD     x19, x0,  x21             #200      # x19 = x21 (copy of abs(x20))                  
#                   ADDI    x18, x0,  10              #204      # x18 = divisor (10)                            
#                   ADDI    x21, x0,  0x200           #212      # Base address for digit storage                
#                   ADDI    x21, x21, 4               #216                                                      
#                   ADDI    x23, x0,  1               #220      # Digit counter = 1 (From 1 to 11)              
#   DIGIT_EX_LOOP:  REMU    x24, x19, x18             #224      # x24 = digit                                   
#                   DIVU    x19, x19, x18             #228                                                      
#                   SW      x24, 0(x21)               #232      # store digit                                   
#                                                                                                               
#                   ADDI    x21, x21, 4               #236      # next digit address                            
#                   ADDI    x23, x23, 1               #240      # Digit counter ++                              
#                   ADDI    x25, x0,  11              #244      # Check if LED_inex = 11 (If true then continue)
#                   BNE     x23, x25, DIGIT_EX_LOOP   #248                                                      
#                   ADDI    x21, x0,  0x200           #252      # base address for digit storage                
#                   ADDI    x21, x21, 0x30            #260      # Address for sign flag (0x200 + 44)            
#                   ADDI    x25, x0,  10                        #                                               
#                   MUL     x22, x25, x22                       # x22 = (x22 == 1) ? 10 : 0                     
#                   SW      x22, 0(x21)               #264      # MEM[x230] = x22 = (x20 < 0) ? 1: 0            
#                   JAL     x0,  DISPLAY_DIGIT        #268      # Display Digit                                                                                                
#   
#   
#   
#   DISPLAY_DIGIT:  ADDI    x2,  x0, 0x500            # GPO base address                                      
#                   ADDI    x21, x0, 0x200            # x21 = Base address for digit                          
#                   LW      x22, 0(x21)               # x22 = LED_index (From 1 to 12)                        
#                   SLLI    x23, x22, 2               # x23 = offset = LED_index * 4                          
#                   ADD     x21, x21, x23             # x21 = Address of the Digit to be displayed            
#                   LW      x24, 0(x21)               # x24 = digit value                                     
#                                                                                                             
#                   ADDI    x21, x22, -1              # x21 = Bit mask to select LED                          
#                   ADDI    x25, x0,   1              #                                                       
#                   SLL     x25, x25, x21             # x25 = 0x1 << x21 (GPO_A bit for current LED)          
#                   ADDI    x26, x0,  0x0F            # x26 = Bit mask for digit value                        
#                   AND     x26, x26, x24             #                                                       
#                                                                                                             
#                   ADDI    x21, x0, 0x300            # Base address to load 7-segment data                   
#                   ADD     x21, x21, x26                                                                     
#                   LBU     x26, 0(x21)                                                                       
#                   ANDI    x26, x26, 0xFF                                                                    
#                                                                                                             
#                   ADDI    x27, x0, 0b000001000000                                                                        
#                   BNE     x27, x25, SKIP                                                                    
#                   ADDI    x27, x0, 0x7F             # Display decimal point                                 
#                   AND     x26, x26, x27                                                                     
#   SKIP:           SW      x0 , 0x0(x2)              # Turn off                                              
#                   SW      x26, 0x10(x2)             # GPO_B = digit bits (MEM[x510] = Digit value in 4-bit) 
#                   NOP                               # 100ns delay                                           
#                   NOP                                                                                       
#                   NOP                                                                                       
#                   NOP                                                                                       
#                   NOP                                                                                       
#                   NOP                                                                                       
#                   NOP                                                                                       
#                   NOP                                                                                       
#                   SW      x25, 0(x2)                # GPO_A = LED_index bit                                 
#                                                                                                             
#                   ADDI    x21, x0,  12                                                                      
#                   BEQ     x22, x21, CLEAR_INDEX                                                             
#                   ADDI    x22, x22, 1               # LED_index++                                           
#                   JAL     x0,  STORE_INDEX                                                                  
#                                                                                                             
#   CLEAR_INDEX:    ADDI    x22, x0, 1                # LED_index = 1                                         
#                   JAL     x0,  STORE_INDEX                                                                  
#                                                                                                             
#   STORE_INDEX:    ADDI    x21, x0,  0x200           # Address to hold LED_index                             
#                   ANDI    x22, x22, 0x0F            # wrap around 0–15                                      
#                   SW      x22, 0(x21)               # Store bit index                                       
#                   JAL     x0, MAIN_LOOP             # RET                                                   











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
00 43 F4 13
00 04 18 63
00 82 2A 03
00 00 09 93
0A 40 00 6F
00 02 24 83
00 04 A5 B3
00 05 88 63
00 82 2A 03
00 00 09 93
08 C0 00 6F
00 0F 44 37
24 04 04 13
02 84 87 B3
00 00 05 93
00 F0 06 33
00 00 06 93
40 B6 07 33
00 20 08 93
03 17 57 33
00 B7 07 33
02 E7 08 33
00 F8 16 63
00 07 0A 33
03 C0 00 6F
02 E7 18 B3
03 10 60 63
00 F8 7E 63
00 07 06 B3
00 17 05 93
FC C5 86 E3
FC C5 C4 E3
00 06 8A 33
01 80 00 6F
FF F7 06 13
FA C5 8C E3
FA C5 CA E3
00 06 8A 33
00 40 00 6F
10 00 02 13
00 02 2E 03
01 40 0E B3
01 42 24 23
00 00 09 93
00 40 00 6F
01 40 0A B3
00 00 0B 13
00 09 88 63
00 0A 2B 33
00 0B 04 63
41 40 0A B3
01 50 09 B3
00 A0 09 13
20 00 0A 93
00 4A 8A 93
00 10 0B 93
03 29 FC 33
03 29 D9 B3
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
00 80 0D 93
01 9D 96 63
07 F0 0D 93
01 BD 7D 33
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
E3 5F F0 F





























































































































































































