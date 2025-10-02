# Register usage:
# x1  = GPI address       (0x410)
# x2  = PORTA address     (0x500)
# x3  = input temp
# x4  = pulse count (0 to 20)
# x5  = delay loop
# x6  = pulse_high counter (x6 * 500 us = HIGH time)
# x7  = debounce counter (0 to 25, 20 ms steps)
# x8  = constant 25 (for 500ms)
# x9  = bit mask for bit 2 (0x4)
# x10 = bit mask for bit 3 (0x8)
# x11 = address for return from subroutine (link reg)

                        LUI   x1, 0x00000                 # 0                                                                                                                                                                                                                                                                                                      
                        ADDI  x1, x1, 0x400               # 4        # GPI input                                                                                                                                                          
                        LUI   x2, 0x00000                 # 8                                                                                                                                                             
                        ADDI  x2, x2, 0x500               # 12       # PORTA output                                                                                                                                                               
                        ADDI  x6, x0, 10                  # 16       # Initial angle = 10 * 50 us = 0.5 ms (middle)                                                                                                                                                               
                        ADDI  x7, x0, 0                   # 20       # debounce counter                                                                                                                                                           
                        ADDI  x8, x0, 25                  # 24       # debounce threshold = 20 * 25 ms = 500 ms                                                                                                                                                           
                        ADDI  x9, x0,  0x1                # 28       # mask bit 0 for GPI bit read                                                                                                                                                         
                        ADDI  x10, x0, 0x2                # 32       # mask bit 1 for GPI bit read                                                                                                                                                         
MAIN_LOOP:              BEQ   x7, x8, READ_INPUT          # 36       # If debounce counter == 25, read GPI                                                                                                                                                                
                        JAL   x0,     SEND_PULSE          # 40       # Else Senc Servo control                                                                                                                                                            
READ_INPUT:             LW    x3, 0(x1)                   # 44       # Read GPI                                                                                                                                                           
                        AND   x3, x3, x9                  # 48       # check bit 2                                                                                                                                                                
                        BEQ   x3, x0, CHECK_INC           # 52       # If LOW than check if bit 3 is HIGH                                                                                                                                                         
                        ADDI  x6, x6, -1                  # 56       # Else it is HIGH and decrease the iteration of 50 us delay by one                                                                                                                                                           
                        BLT   x6, x0, CLAMP_MIN           # 60       # If the amount of 500us delay less than 0, then keep it at 0                                                                                                                                                                
CHECK_INC:              LW    x3, 0(x1)                   # 64       # Read GPI                                                                                                                                                           
                        AND   x3, x3, x10                 # 68       # check bit 3                                                                                                                                                                
                        BEQ   x3, x0, RESET_DB            # 72       # If not HIGH then reset debounce counter and wait for next Read                                                                                                                                                             
                        ADDI  x6, x6, 1                   # 76       # Else it is HIGH and increase the iteration of 50 us delay by one                                                                                                                                                           
                        ADDI  x3, x0, 20                  # 80                                                                                                                                                                    
                        BGE   x6, x3, CLAMP_MAX           # 84       # Check if the amount of 50 us delay iteration is more than 20 (1ms)                                                                                                                                                                 
                        JAL   x0, RESET_DB                # 88       # If not reset the Debounce coutner                                                                                                                                                          
CLAMP_MIN:              ADDI  x6, x0, 0                   # 92                                                                                                                                                            
                        JAL   x0, RESET_DB                # 96                                                                                                                                                            
CLAMP_MAX:              ADDI  x6, x0, 20                  # 100                                                                                                                                                           
                        JAL   x0, RESET_DB                # 104                                                                                                                                                           
RESET_DB:               ADDI  x7, x0, 0                   # 108      # reset debounce counter                                                                                                                                                             
SEND_PULSE:             ADDI  x3, x0, 0x8                 # 112      # x3 = bit 3 mask                                                                                                                                                            
                        SW    x3, 0(x2)                   # 116      # set bit 3 HIGH of the GPO (start servo control signal)                                                                                                                                                             
                        ADDI  x4, x0, 0                   # 120      # x4 = counter for amount of 50 us delay                                                                                                                                                             
                        ADDI  x20, x0, 20                 # 124      # Base 1ms (20 * 50 us) delay for 0 degree turns                                                                                                                                                             
                        ADD   x20, x20, x6                # 128      # The amount of 5% degree increment (50 us)                                                                                                                                                          
DELAY_HIGH:             JAL   x11, DELAY_50US             # 132      # delay for 50 us (5% of the pulse) + 1 ms                                                                                                                                                           
                        ADDI  x4, x4, 1                   # 136                                                                                                                                                                   
                        BLT   x4, x20, DELAY_HIGH         # 140                                                                                                                                                                   
                        SW    x0, 0(x2)                   # 144      # set bit 3 LOW (stop the servo control signal)                                                                                                                                                              
                        ADDI  x4, x0, 0                   # 148      # Delay LOW for (380 - x6) * 50 us (19 ms - x6 * 50 us)                                                                                                                                                              
DELAY_LOW:              ADDI  x3, x0, 380                 # 152                                                                                                                                                           
                        SUB   x3, x3, x6                  # 156                                                                                                                                                           
                        BLT   x4, x3, LOW_LOOP            # 160                                                                                                                                                           
                        JAL   x0, NEXT                    # 164                                                                                                                                                   
LOW_LOOP:               JAL   x11, DELAY_50US             # 168      # Jump to 500us delay subroutine (x11 is return address)                                                                                                                                                             
                        ADDI  x4, x4, 1                   # 172                                                                                                                                                           
                        JAL   x0, DELAY_LOW               # 176                                                                                                                                                           
NEXT:                   ADDI  x7, x7, 1                   # 180      # increment debounce counter 
                        ADD   x20, x0, x6     # x20 = x6
                        SLLI  x20, x20, 3     # x20 = x6 * 8
                        ADD   x20, x20, x6    # x20 = x20 + x6 = 9 * x6
                        LUI   x21, 00000      # x21 = PORT_B address
                        ADDI  x21, x0, 0x510
                        SW    x20, 0(x21)                                                                                                                                                        
                        JAL   x0, MAIN_LOOP               # 184                                                                                                                                                           
DELAY_50US:             LI  x5, 625                       # 188      # outer loop (x2 = 2 cycle loop)                                                                                                                                                             
LOOP_50US:              ADDI  x5, x5, -1                  # 192                                                                                                                                                           
                        BNE   x5, x0, LOOP_50US           # 196                                                                                                                                                                   
                        JALR  x0, x11, 0                  # 200      # return (RET)                                                                                                                                                               
 




                         LUI   x1, 0x00000                 
                        ADDI  x1, x1, 0x410               
                        LUI   x2, 0x00000                 
                        ADDI  x2, x2, 0x500               
                        ADDI  x6, x0, 10                  
                        ADDI  x7, x0, 0                   
                        ADDI  x8, x0, 1                  
                        ADDI  x9, x0,  0x1                
                        ADDI  x10, x0, 0x2                
MAIN_LOOP:              BEQ   x7, x8, READ_INPUT          
                        JAL   x0,     SEND_PULSE          
READ_INPUT:             LW    x3, 0(x1)                   
                        AND   x3, x3, x9                  
                        BEQ   x3, x0, CHECK_INC           
                        ADDI  x6, x6, -1                  
                        BLT   x6, x0, CLAMP_MIN           
CHECK_INC:              LW    x3, 0(x1)                   
                        AND   x3, x3, x10                 
                        BEQ   x3, x0, RESET_DB            
                        ADDI  x6, x6, 1                   
                        ADDI  x3, x0, 40                  
                        BGE   x6, x3, CLAMP_MAX           
                        JAL   x0, RESET_DB                
CLAMP_MIN:              ADDI  x6, x0, 0                   
                        JAL   x0, RESET_DB                
CLAMP_MAX:              ADDI  x6, x0, 40                  
                        JAL   x0, RESET_DB                
RESET_DB:               ADDI  x7, x0, 0                   
SEND_PULSE:             ADDI  x3, x0, 0x8                 
                        SW    x3, 0(x2)                   
                        ADDI  x4, x0, 0                   
                        ADDI  x20, x0, 10                 
                        ADD   x20, x20, x6                
DELAY_HIGH:             JAL   x11, DELAY_50US             
                        ADDI  x4, x4, 1                   
                        BLT   x4, x20, DELAY_HIGH         
                        SW    x0, 0(x2)                   
                        ADDI  x4, x0, 0                   
DELAY_LOW:              ADDI  x3, x0, 380                 
                        SUB   x3, x3, x6                  
                        BLT   x4, x3, LOW_LOOP            
                        JAL   x0, NEXT                    
LOW_LOOP:               JAL   x11, DELAY_50US             
                        ADDI  x4, x4, 1                   
                        JAL   x0, DELAY_LOW               
NEXT:                   ADDI  x7, x7, 1 
                        ADD   x30, x0, x6     # x20 = x6
                        ADD   x30, x30, x6
                        ADD   x30, x30, x6
                        ADD   x30, x30, x6
                        ADD   x30, x30, x6
                        ADD   x31, x0,  x6
                        SRLI  x31, x31, 1
                        SUB   x30, x30, x31
                        LUI   x31, 0x00000
                        ADDI  x31, x31, 0x510
                        SW    x30, 0(x31)         
                        JAL   x0, MAIN_LOOP               
DELAY_50US:             LI  x5, 625                       
LOOP_50US:              ADDI  x5, x5, -1                  
                        BNE   x5, x0, LOOP_50US           
                        JALR  x0, x11, 0                  