// 1.i_stop signal simply cancel the current operation
// And reserving the previousd Quotient and Remainder

// 2. o_done signal indicate a result is available in the next cycle

// 3. o_ready signal indicate the divider is idle and ready to accept new inputs


module prim_divider_32bit(
    input  logic          i_clk          ,
    input  logic          i_rstn         ,
    input  logic          i_start        ,
    input  logic          i_stop         ,   // HIGH to discard current operation and instruction
    input  logic          i_signed_en    ,   // HIGH to enable signed division
    input  logic [31:0]   i_a            ,   // Dividend
    input  logic [31:0]   i_b            ,   // Divisor
    output logic [31:0]   o_quotient     ,
    output logic [31:0]   o_remainder    ,
    output logic          o_ready        ,   // To inform if the module is IDLE
    output logic          o_done         ,   // To inform if the division process is complete
    output logic          o_error            // Divide by 0
);


// ========================== Finite State Machine ================================
typedef enum logic [2:0] {
    IDLE       ,    // Wait for START signal
    FETCH      ,    // Load operands and handle find absoluate value of operands
    PREPROCESS ,    // Pre-process to reduce number of cycle for the operation
    EXECUTE    ,    // Start calculating (shift and substract)
    WRITE           // Write results into output register (o_remainder, QUotient)
} states_t;

states_t PreStep;
states_t NextStep;

logic        IDLE_stage;
logic        FETCH_stage;
logic        PREPROCESS_stage;
logic        EXECUTE_stage;
logic        WRITE_stage;

logic [5:0]  count;
logic [7:0]  count_amount;
logic        cnt_done;
logic        divide_by_0;     // Indicate operand_b == 32'b0
logic        A_lt_B;          // Indicate the Dividend is less than the Divisor

assign IDLE_stage        = (PreStep == IDLE       );
assign FETCH_stage       = (PreStep == FETCH      );
assign PREPROCESS_stage  = (PreStep == PREPROCESS );
assign EXECUTE_stage     = (PreStep == EXECUTE    );
assign WRITE_stage       = (PreStep == WRITE      );


// FSM
always_ff @(posedge i_clk, negedge i_rstn)
    if (!i_rstn)   PreStep  <= IDLE;
    else           PreStep  <= NextStep;

// FSM control
always_comb begin
    case (PreStep)
        IDLE:       if (i_start & ~i_stop)      NextStep = FETCH;
                    else                        NextStep = IDLE;

        FETCH:      if(i_stop)                  NextStep = IDLE;
                    else                        NextStep = PREPROCESS;

        PREPROCESS: if(i_stop)                  NextStep = IDLE;
                    else if (divide_by_0)       NextStep = WRITE;
                    else if (A_lt_B)            NextStep = WRITE;
                    else                        NextStep = EXECUTE;

        EXECUTE:    if(i_stop)                  NextStep = IDLE;
                    else if (cnt_done)          NextStep = WRITE;
                    else                        NextStep = EXECUTE;

        WRITE:                                  NextStep = IDLE;
        default:                                NextStep = IDLE;
    endcase
end


// =================== IDLE to FETCH stage buffer ====================
logic [31:0] operand_a_fetch;      // Fetched Operand_A
logic [31:0] operand_b_fetch;      // Fetched Operand_B
logic        signed_en_fetch;

prim_register  Fetch_A (
    .i_clk (i_clk                ),
    .i_rstn(i_rstn               ),
    .i_en  (IDLE_stage & i_start ),
    .i_d   (i_a                  ),
    .o_q   (operand_a_fetch      )
);

prim_register  Fetch_B (
    .i_clk (i_clk                ),
    .i_rstn(i_rstn               ),
    .i_en  (IDLE_stage & i_start ),
    .i_d   (i_b                  ),
    .o_q   (operand_b_fetch      )
);


prim_d_flipflop  Sign_enable_fetch(
    .i_clk (i_clk                ),
    .i_rstn(i_rstn               ),
    .i_en  (IDLE_stage & i_start ),
    .i_d   (i_signed_en          ),
    .o_q   (signed_en_fetch      )
);


// ========================= FETCH STAGE ==========================
logic [31:0] operand_a_neg;  // Negated  value of operand A
logic [31:0] operand_b_neg;  // Negated  value of operand B
logic [31:0] operand_a_abs;  // Absolute value of operand A
logic [31:0] operand_b_abs;  // Absolute value of operand B

logic [31:0] operand_a_pre;  // Absolute value of operand A passed to PREPROCESS stage
logic [31:0] operand_b_pre;  // Absolute value of operand B passed to PREPROCESS stage

logic        different_sign;    // HIGH if 2 operand different in sign
logic        dividend_sign;     // Sign of operand A
logic        divisor_sign;      // Sign of opernad B

assign dividend_sign  = operand_a_fetch[31] & signed_en_fetch;
assign divisor_sign   = operand_b_fetch[31] & signed_en_fetch;
assign different_sign = dividend_sign ^ divisor_sign;

// Compute absolute value of operand A and operand B
prim_adder_32bit   Negate_operand_a (
    .i_a    (32'h0000_0000   ),
    .i_b    (operand_a_fetch ),
    .i_sub  (1'b1            ),
    .o_sum  (operand_a_neg   ),
    .o_cout ()
);

prim_adder_32bit   Negate_operand_b (
    .i_a    (32'h0000_0000   ),
    .i_b    (operand_b_fetch ),
    .i_sub  (1'b1            ),
    .o_sum  (operand_b_neg   ),
    .o_cout ()
);

prim_mux_2x1      Select_Absolute_A (
        .i_sel(dividend_sign    ),
        .i_0  (operand_a_fetch  ),
        .i_1  (operand_a_neg    ),
        .o_mux(operand_a_abs    )
);
prim_mux_2x1      Select_Absolute_B (
        .i_sel(divisor_sign     ),
        .i_0  (operand_b_fetch  ),
        .i_1  (operand_b_neg    ),
        .o_mux(operand_b_abs    )
);



// ---- Pipeline buffer to PREPROCESS stage ----
prim_register  Preprocess_buffer_A (
    .i_clk (i_clk         ),
    .i_rstn(i_rstn        ),
    .i_en  (FETCH_stage   ),
    .i_d   (operand_a_abs ),
    .o_q   (operand_a_pre )
);

prim_register  Preprocess_buffer_B (
    .i_clk (i_clk         ),
    .i_rstn(i_rstn        ),
    .i_en  (FETCH_stage   ),
    .i_d   (operand_b_abs ),
    .o_q   (operand_b_pre )
);

prim_cmp_eq #(.WIDTH(32))   op_b_check (
    .i_a        (operand_b_fetch ),
    .i_b        (32'h0000_0000   ),
    .o_eq       (divide_by_0     )
);


// ========================== PREPROCESS STAGE =========================
logic [31:0] reduced_operand_a;     // Operand A with removed leading zeros
logic [4:0]  nla_a;                 // Number of Leading Zero in |operand_a|


// Find the number of Leading Zero the reduce the Shift-and-Subtractor operations
prim_leading_zero_counter_32bit    Find_Reduced_A (
    .i_data    (operand_a_pre   ),
    .o_nlz     (nla_a           ),  // Number of Leading Zero
    .o_all_zero()
);


// Shift the operand_a so that the first bit 1's become the MSB
prim_logic_left_shifter_32bit  Operand_a_left_adjustment (
    .i_data  (operand_a_pre        ),
    .i_shamt ({{27{1'b0}}, nla_a}  ),  // Shift amount = Number of leading zero in A
    .o_data  (reduced_operand_a    )
);


// Pre-calculate number of shift and substract operation in term of cycles
prim_adder_8bit Reduced_count (
    .i_a    (8'd32           ),  // Originally Shift-and-Subtract takes 32 cycles
    .i_b    ({3'b000, nla_a} ),  // Reduced number of cycles based on NLZ of A
    .i_sub  (1'b1            ),
    .o_sum  (count_amount    ),
    .o_cout (                )
);


prim_down_counter #(.WIDTH(6))  iteration_counter  (
    .i_clk       (i_clk             ),
    .i_rstn      (i_rstn            ),
    .i_en        (EXECUTE_stage     ), // Enable down counter in EXECUTE stage
    .i_load      (PREPROCESS_stage  ),
    .i_load_data (count_amount[5:0] ), // Load number of shift and substract operation
    .o_count     (count             )
);


prim_cmp_eq #(.WIDTH(6)) Count_check (
    .i_a (count    ),
    .i_b (6'b000000),
    .o_eq(cnt_done )
);


// If A < B, Quotient is 32'b0 and Remainder = A  (Jump to WRITE stage)
prim_cmp_lt_32bit   Compare_operand (
    .i_a         (operand_a_pre ),
    .i_b         (operand_b_pre ),
    .i_signed_en (1'b0          ),
    .o_lt        (A_lt_B        )
);

// ======================== EXECUTE STAGES ============================
logic [31:0] dividend;
logic [31:0] divisor;
logic [31:0] shifted_a;  // Left shifting A to extract each bit via MSB
logic [31:0] adder_sum;  // 32-bit Substraction result from Adder
logic        adder_sign; // Sign-bit of Substraction

logic [31:0] partial_remainder;
logic [31:0] Pre_Remainder;
logic [31:0] Pre_Quotient;

logic [31:0] temp_quotient_q;  // Temporary Quotient
logic [31:0] temp_remainder_q; // Temporary Remainder
logic [31:0] temp_remainder_d; // Temporary Remainder (before registered)


assign divisor = operand_b_pre;


prim_left_shift_register shift_register_opreand_A(
    .i_clk       (i_clk                 ),
    .i_rstn      (i_rstn                ), // Active-Low asynchronous reset
    .i_en        (EXECUTE_stage         ),
    .i_shift_in  (1'b0                  ),
    .i_load      (PREPROCESS_stage      ), // Synchronous load
    .i_load_data (reduced_operand_a     ), // Load data
    .o_q         (shifted_a             )
);


prim_register_clr  Temp_dividend_register   (
    .i_clk  (i_clk                                    ),
    .i_rstn (i_rstn                                   ),
    .i_en   (EXECUTE_stage                            ),
    .i_clear(PREPROCESS_stage                         ),
    .i_d    ({partial_remainder[30:0], shifted_a[31]} ),
    .o_q    (dividend                                 )
);

// Extend adder to 33-bit to extrat sign bit
logic adder_connection;

prim_adder_32bit Subtract (
    .i_a   (dividend          ),
    .i_b   (divisor           ),
    .i_sub (1'b1              ),
    .o_sum (adder_sum         ),
    .o_cout(adder_connection  )
);

prim_full_adder Sign_bit(
    .i_a    (1'b0             ),
    .i_b    (1'b1             ),
    .i_cin  (adder_connection ),
    .o_sum  (adder_sign       ),
    .o_cout ()
);

// Partial Remainder = dividend if substract result in Negative
prim_mux_2x1  Partial_Remainder  (
    .i_sel(adder_sign         ),
    .i_0  (adder_sum          ),
    .i_1  (dividend           ),
    .o_mux(partial_remainder  )
);



// In PROPROCESS stage Reminder = Dividend if Dividend < Divisor
prim_mux_2x1   Init_Temp_remainder_register  (
    .i_sel(A_lt_B             ),
    .i_0  (partial_remainder  ), // Hold the parital Remainder
    .i_1  (operand_a_pre      ),
    .o_mux(temp_remainder_d   )
);

prim_register_clr  Temp_Remainder_register(
    .i_clk    ( i_clk                                         ),
    .i_rstn   ( i_rstn                                        ),
    .i_clear  ( PREPROCESS_stage  & ~A_lt_B                   ),
    .i_en     ( (PREPROCESS_stage &  A_lt_B) | EXECUTE_stage  ),
    .i_d      ( temp_remainder_d                              ),
    .o_q      ( temp_remainder_q                              )
);


prim_left_shift_register Temp_Quotient_register(
    .i_clk       (i_clk             ),
    .i_rstn      (i_rstn            ), // Active-Low asynchronous reset
    .i_en        (EXECUTE_stage     ),
    .i_shift_in  (~adder_sign       ), // Shift in 0 if Subatraction result in negative
    .i_load      (PREPROCESS_stage  ), // Clear
    .i_load_data (32'h0000_0000     ), // Clear
    .o_q         (temp_quotient_q   )
);




// ============================ WRITE STAGES =============================
logic [31:0] quotient_neg;   // Value of quotient  of handling sign
logic [31:0] remainder_neg;  // Value of remainder of handling sign
logic [31:0] signed_quotient;   // Value of quotient  of handling sign
logic [31:0] signed_remainder;  // Value of remainder of handling sign

// Negate and compute sign of result based on sign operands
prim_adder_32bit   Negate_quotient (
    .i_a    (32'h0000_0000   ),
    .i_b    (temp_quotient_q ),
    .i_sub  (1'b1            ),
    .o_sum  (quotient_neg    ),
    .o_cout ()
);
prim_adder_32bit   Negate_remainder (
    .i_a    (32'h0000_0000    ),
    .i_b    (temp_remainder_q ),
    .i_sub  (1'b1             ),
    .o_sum  (remainder_neg    ),
    .o_cout ()
);
prim_mux_2x1   Quotient_sign_assignment  (
    .i_sel(different_sign    ),
    .i_0  (temp_quotient_q   ),
    .i_1  (quotient_neg      ), // Negate when dividend and divisor are different in sign
    .o_mux(signed_quotient   )
);

prim_mux_2x1   Remainder_sign_assignment  (
    .i_sel(dividend_sign     ),
    .i_0  ( temp_remainder_q ),
    .i_1  ( remainder_neg    ), // Negate when dividend is negative
    .o_mux(signed_remainder  )
);





// Output
prim_register  Quotient_output_reg  (
    .i_clk  (i_clk           ),
    .i_rstn (i_rstn          ),
    .i_en   (WRITE_stage     ),
    .i_d    (signed_quotient ),
    .o_q    (o_quotient      )
);

prim_register  Remainder_output_reg (
    .i_clk  (i_clk            ),
    .i_rstn (i_rstn           ),
    .i_en   (WRITE_stage      ),
    .i_d    (signed_remainder ),
    .o_q    (o_remainder      )
);


assign o_error    = divide_by_0;
assign o_done     = WRITE_stage;
assign o_ready    = IDLE_stage;

endmodule: prim_divider_32bit





