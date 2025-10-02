module prim_multiplier_32x32_pipelined (
    input  logic         i_clk           ,
    input  logic         i_rstn          ,
    input  logic         i_start         ,
    input  logic         i_stop          ,   // HIGH to discard the current operation
    input  logic         i_op_a_signed_en,   // HIGH to signed enable operand A
    input  logic         i_op_b_signed_en,   // HIGH to signed enable operand B
    input  logic [31:0]  i_a             ,   // Multiplicand
    input  logic [31:0]  i_b             ,   // Multiplier
    output logic [63:0]  o_product       ,
    output logic         o_done          ,   // HIGH to indicate an operation just completed
    output logic         o_ready             // HIGH to indicate Multiplier is IDLE
);


typedef enum logic [2:0]{
    IDLE        ,  // Wait for start signal and Latch inputs
    PREPROCESS  ,  // Check for sign of operand and compute absolute value
    EXE_1       ,  // Compte 16x16 parital product (p1, p2 ,p3, p4)
    EXE_2       ,  // Add partial product: (p1 + p2) and (p3 + p4)
    EXE_3       ,  // Finalize result: (p1 + p2) + (p3 + p4)
    WRITE          // Write to output register
} state_t;

state_t  Pre_state;
state_t  Next_state;

logic IDLE_stage;
logic PREPROCESS_stage;
logic EXE_1_stage;
logic EXE_2_stage;
logic EXE_3_stage;
logic WRITE_stage;
logic zero_operand;

assign IDLE_stage       =    (Pre_state == IDLE       );
assign PREPROCESS_stage =    (Pre_state == PREPROCESS );
assign EXE_1_stage      =    (Pre_state == EXE_1      );
assign EXE_2_stage      =    (Pre_state == EXE_2      );
assign EXE_3_stage      =    (Pre_state == EXE_3      );
assign WRITE_stage      =    (Pre_state == WRITE      );



// State transition
always_ff @(posedge i_clk, negedge i_rstn)
    if (!i_rstn)        Pre_state <= IDLE;
    else                Pre_state <= Next_state;


always_comb begin
    case (Pre_state)
        IDLE:       if (i_start & ~i_stop)  Next_state = PREPROCESS;
                    else                    Next_state = IDLE;

        PREPROCESS: if (i_stop)             Next_state = IDLE;
                    else if (zero_operand)  Next_state = IDLE;
                    else                    Next_state = EXE_1;

        EXE_1:      if (i_stop)             Next_state = IDLE;
                    else                    Next_state = EXE_2;

        EXE_2:      if (i_stop)             Next_state = IDLE;
                    else                    Next_state = EXE_3;

        EXE_3:      if (i_stop)             Next_state = IDLE;
                    else                    Next_state = WRITE;

        WRITE:                              Next_state = IDLE;
        default:                            Next_state = IDLE;
    endcase
end


// =========================== IDLE ===========================
logic [31:0] op_a_fetch;      // Fetched Operand_A
logic [31:0] op_b_fetch;      // Fetched Operand_B
logic        op_a_signed_en_fetch;
logic        op_b_signed_en_fetch;

prim_register  Fetch_A (
    .i_clk (i_clk                ),
    .i_rstn(i_rstn               ),
    .i_en  (IDLE_stage & i_start ),
    .i_d   (i_a                  ),
    .o_q   (op_a_fetch           )
);
prim_register  Fetch_B (
    .i_clk (i_clk                ),
    .i_rstn(i_rstn               ),
    .i_en  (IDLE_stage & i_start ),
    .i_d   (i_b                  ),
    .o_q   (op_b_fetch           )
);


prim_d_flipflop  Sign_a_enable_fetch(
    .i_clk (i_clk                  ),
    .i_rstn(i_rstn                 ),
    .i_en  (IDLE_stage & i_start   ),
    .i_d   (i_op_a_signed_en       ),
    .o_q   (op_a_signed_en_fetch   )
);
prim_d_flipflop  Sign_b_enable_fetch(
    .i_clk (i_clk                  ),
    .i_rstn(i_rstn                 ),
    .i_en  (IDLE_stage & i_start   ),
    .i_d   (i_op_b_signed_en       ),
    .o_q   (op_b_signed_en_fetch   )
);





// =========================== PREPROCESS ===========================
logic [31:0] op_a_neg;  // Negated  value of operand A
logic [31:0] op_b_neg;  // Negated  value of operand B
logic [31:0] op_a_abs;  // Absolute value of operand A
logic [31:0] op_b_abs;  // Absolute value of operand B

logic [31:0] op_a_pre;  // Absolute value of operand A passed to PREPROCESS stage
logic [31:0] op_b_pre;  // Absolute value of operand B passed to PREPROCESS stage

logic        op_a_sign;         // Sign of operand A
logic        op_b_sign;         // Sign of opernad B
logic        different_sign;    // HIGH if 2 operand different in sign

logic        op_a_zero;
logic        op_b_zero;

assign op_a_sign      = op_a_fetch[31] & op_a_signed_en_fetch;
assign op_b_sign      = op_b_fetch[31] & op_b_signed_en_fetch;
assign zero_operand   = op_a_zero | op_b_zero;
assign different_sign = op_a_sign ^ op_b_sign;

// Compute absolute value of operand A and operand B
prim_adder_32bit   Negate_opreand_a (
    .i_a    ({32{1'b0}} ),
    .i_b    (op_a_fetch ),
    .i_sub  (1'b1       ),
    .o_sum  (op_a_neg   ),
    .o_cout ()
);

prim_adder_32bit   Negate_opreand_b (
    .i_a    ({32{1'b0}} ),
    .i_b    (op_b_fetch ),
    .i_sub  (1'b1       ),
    .o_sum  (op_b_neg   ),
    .o_cout ()
);

prim_mux_2x1      Select_Absolute_A (
        .i_sel(op_a_sign  ),
        .i_0  (op_a_fetch ),
        .i_1  (op_a_neg   ),
        .o_mux(op_a_abs   )
);
prim_mux_2x1      Select_Absolute_B (
        .i_sel(op_b_sign       ),
        .i_0  (op_b_fetch      ),
        .i_1  (op_b_neg        ),
        .o_mux(op_b_abs        )
);



// ---- Pipeline buffer to EXE_1 stage ----
prim_register  Preprocess_buffer_A (
    .i_clk (i_clk              ),
    .i_rstn(i_rstn             ),
    .i_en  (PREPROCESS_stage   ),
    .i_d   (op_a_abs           ),
    .o_q   (op_a_pre           )
);
prim_register  Preprocess_buffer_B (
    .i_clk (i_clk              ),
    .i_rstn(i_rstn             ),
    .i_en  (PREPROCESS_stage   ),
    .i_d   (op_b_abs           ),
    .o_q   (op_b_pre           )
);


prim_cmp_eq #(.WIDTH(32))  zero_op_a_check (.i_a(op_a_fetch), .i_b(32'b0), .o_eq(op_a_zero) );
prim_cmp_eq #(.WIDTH(32))  zero_op_b_check (.i_a(op_b_fetch), .i_b(32'b0), .o_eq(op_b_zero) );




// =========================== EXECUTE 1 ===========================
// Partial Products
logic [31:0] p0, p0_buff;    // A[15:0]  × B[15:0]
logic [31:0] p1, p1_buff;    // A[31:16] × B[15:0]
logic [31:0] p2, p2_buff;    // A[15:0]  × B[31:16]
logic [31:0] p3, p3_buff;    // A[31:16] × B[31:16]

prim_multiplier_16x16  P1_calc (.i_a(op_a_pre[15:0] ), .i_b(op_b_pre[15:0] ), .o_product(p0) );
prim_multiplier_16x16  P2_calc (.i_a(op_a_pre[31:16]), .i_b(op_b_pre[15:0] ), .o_product(p1) );
prim_multiplier_16x16  P3_calc (.i_a(op_a_pre[15:0] ), .i_b(op_b_pre[31:16]), .o_product(p2) );
prim_multiplier_16x16  P4_calc (.i_a(op_a_pre[31:16]), .i_b(op_b_pre[31:16]), .o_product(p3) );


// ---- Pipeline buffer to EXE_1 stage ----
prim_register  P0_reg (
    .i_clk (i_clk       ),
    .i_rstn(i_rstn      ),
    .i_en  (EXE_1_stage ),
    .i_d   (p0          ),
    .o_q   (p0_buff     )
);

prim_register  P1_reg (
    .i_clk (i_clk       ),
    .i_rstn(i_rstn      ),
    .i_en  (EXE_1_stage ),
    .i_d   (p1          ),
    .o_q   (p1_buff     )
);

prim_register  P2_reg (
    .i_clk (i_clk       ),
    .i_rstn(i_rstn      ),
    .i_en  (EXE_1_stage ),
    .i_d   (p2          ),
    .o_q   (p2_buff     )
);

prim_register  P3_reg (
    .i_clk (i_clk       ),
    .i_rstn(i_rstn      ),
    .i_en  (EXE_1_stage ),
    .i_d   (p3          ),
    .o_q   (p3_buff     )
);




// =========================== EXECUTE 2 ===========================
logic [63:0] s1, s1_buff;    // Sum of shifted p0[31:16] and p1
logic [63:0] s2, s2_buff;    // Sum of shifted p2 and p3


prim_adder_64bit       Add_low (
    .i_a    ({16'h0000, p1_buff, 16'h0000}  ),
    .i_b    ({32'h0000_0000, p0_buff}       ),
    .i_sub  (1'b0                           ),
    .o_sum  (s1                             ),
    .o_cout ()
);

prim_adder_64bit       Add_high (
    .i_a    ({p3_buff, 32'h000_0000}        ),
    .i_b    ({16'h0000, p2_buff, 16'h0000}  ),
    .i_sub  (1'b0                           ),
    .o_sum  (s2                             ),
    .o_cout ()
);


prim_register #(.WIDTH(64))  S1_reg (
    .i_clk (i_clk       ),
    .i_rstn(i_rstn      ),
    .i_en  (EXE_2_stage ),
    .i_d   (s1          ),
    .o_q   (s1_buff     )
);

prim_register #(.WIDTH(64)) S2_reg (
    .i_clk (i_clk       ),
    .i_rstn(i_rstn      ),
    .i_en  (EXE_2_stage ),
    .i_d   (s2          ),
    .o_q   (s2_buff     )
);




// =========================== EXECUTE 2 ===========================
logic [63:0] s3, s3_buff;     // Final product high bits
logic [63:0] tmp_product;

prim_adder_64bit   Add_partial_sum (
    .i_a    (s1_buff  ),
    .i_b    (s2_buff  ),
    .i_sub  (1'b0     ),
    .o_sum  (s3       ),
    .o_cout ()
);

prim_register #(.WIDTH(64)) S3_reg (
    .i_clk (i_clk       ),
    .i_rstn(i_rstn      ),
    .i_en  (EXE_3_stage ),
    .i_d   (s3          ),
    .o_q   (s3_buff     )
);

assign tmp_product = s3_buff;


// =========================== WRITE ===========================
logic [63:0] product_neg;   // Value of quotient  of handling sign
logic [63:0] product_d;
logic [63:0] product_q;

logic zero_product;

assign zero_product = PREPROCESS_stage & zero_operand;


// Negate and compute sign of result based on sign operands
prim_adder_64bit   Negate_quotient (
    .i_a    ({64{1'b0}}    ),
    .i_b    (tmp_product   ),
    .i_sub  (1'b1          ),
    .o_sum  (product_neg   ),
    .o_cout ()
);

prim_mux_2x1 #(.WIDTH(64))   Quotient_sign_assignment  (
    .i_sel(different_sign ),
    .i_0  (tmp_product    ),
    .i_1  (product_neg    ),
    .o_mux(product_d      )
);

prim_register_clr #(.WIDTH(64)) Quotient_output_reg  (
    .i_clk  (i_clk        ),
    .i_rstn (i_rstn       ),
    .i_en   (WRITE_stage  ),
    .i_clear(zero_product ),
    .i_d    (product_d    ),
    .o_q    (product_q    )
);


// Output assignment
assign o_product        = product_q;
assign o_ready          = IDLE_stage;
assign o_done           = WRITE_stage | (zero_product);


endmodule : prim_multiplier_32x32_pipelined


