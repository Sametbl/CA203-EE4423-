
module lsu #(parameter int    MEM_DEPTH = 10,
             parameter string DMEM_INIT_FILE)(
    input  logic            i_clk               ,
    input  logic            i_rstn              ,
    // LSU control
    input  logic            i_instr_valid       , // Indicate a valid instruction is executing
    input  logic [31:0]     i_lsu_addr          , // Address from ALU
    input  logic [31:0]     i_lsu_st_data       , // Store dat
    input  logic [3:0]      i_lsu_bytemask      , // Bytemask for store operation
    input  logic            i_lsu_st_en         , // Store enable
    input  logic            i_lsu_ld_unsigned   ,
    // Input peripheral
    input  logic [31:0]     i_io_sw             ,
    // Ouptut peripheral
    output logic [31:0]     o_io_lcd            ,
    output logic [31:0]     o_io_ledg           ,
    output logic [31:0]     o_io_ledr           ,
    output logic [6:0]      o_io_hex0           ,
    output logic [6:0]      o_io_hex1           ,
    output logic [6:0]      o_io_hex2           ,
    output logic [6:0]      o_io_hex3           ,
    output logic [6:0]      o_io_hex4           ,
    output logic [6:0]      o_io_hex5           ,
    output logic [6:0]      o_io_hex6           ,
    output logic [6:0]      o_io_hex7           ,
    // Load data
    output logic [31:0]     o_lsu_ld_data           // Load data
);


// ======================================= PRE-PROCESSING ==========================================

logic         io_sw_sel;    // Indicate memory region of SW   is selected
logic         io_ledr_sel;  // Indicate memory region of LEDR is selected
logic         io_ledg_sel;  // Indicate memory region of LEDG is selected
logic         io_lcd_sel;   // Indicate memory region of LCD  is selected
logic         io_hex0_sel;  // Indicate memory region of HEX0 is selected
logic         io_hex1_sel;  // Indicate memory region of HEX1 is selected
logic         io_hex2_sel;  // Indicate memory region of HEX2 is selected
logic         io_hex3_sel;  // Indicate memory region of HEX3 is selected
logic         io_hex4_sel;  // Indicate memory region of HEX4 is selected
logic         io_hex5_sel;  // Indicate memory region of HEX5 is selected
logic         io_hex6_sel;  // Indicate memory region of HEX6 is selected
logic         io_hex7_sel;  // Indicate memory region of HEX7 is selected
logic         dmem_sel;     // Indicate Data memory region is selected

always_comb begin
    dmem_sel    = ~(| i_lsu_addr[31:MEM_DEPTH]);       // Address < (2**DMEM_SIZE)
    io_sw_sel   = (i_lsu_addr[31:12] == 20'h1001_0);   // Address =  0x1001_0000 -> 0x1001_0FFF
    io_ledr_sel = (i_lsu_addr[31:12] == 20'h1000_0);   // Address =  0x1000_0000 -> 0x1000_0FFF
    io_ledg_sel = (i_lsu_addr[31:12] == 20'h1000_1);   // Address =  0x1001_1000 -> 0x1001_1FFF
    io_lcd_sel  = (i_lsu_addr[31:12] == 20'h1000_4);   // Address =  0x1004_0000 -> 0x1004_0FFF
    io_hex0_sel = (i_lsu_addr[31:8]  == 24'h1000_20);  // Address =  0x1000_2000 -> 0x1001_23FF
    io_hex1_sel = (i_lsu_addr[31:8]  == 24'h1000_24);  // Address =  0x1000_2400 -> 0x1001_27FF
    io_hex2_sel = (i_lsu_addr[31:8]  == 24'h1000_28);  // Address =  0x1000_2800 -> 0x1001_2BFF
    io_hex3_sel = (i_lsu_addr[31:8]  == 24'h1000_2C);  // Address =  0x1000_2C00 -> 0x1001_2FFF
    io_hex4_sel = (i_lsu_addr[31:8]  == 24'h1000_30);  // Address =  0x1000_3000 -> 0x1000_33FF
    io_hex5_sel = (i_lsu_addr[31:8]  == 24'h1000_34);  // Address =  0x1000_3400 -> 0x1000_37FF
    io_hex6_sel = (i_lsu_addr[31:8]  == 24'h1000_38);  // Address =  0x1000_3800 -> 0x1000_3BFF
    io_hex7_sel = (i_lsu_addr[31:8]  == 24'h1000_3C);  // Address =  0x1000_3C00 -> 0x1000_3FFF
end



logic  [31:0] sw_reg_data;  // Registered input switch value
logic  [31:0] dmem_ld_data;  // Load data from DMEM


// ======================================= MEMORIES ==========================================
// Data memory (async read)
dmem_model #(.MEM_DEPTH(MEM_DEPTH), .DMEM_INIT_FILE(DMEM_INIT_FILE) ) DMEM(
    .i_clk   (i_clk                                 ), // Clock
    .i_addr  (i_lsu_addr                            ), // Word address
    .i_wren  (dmem_sel & i_lsu_st_en & i_instr_valid), // Write enable
    .i_bmask (i_lsu_bytemask                        ), // Write enable
    .i_wdata (i_lsu_st_data                         ), // Write data
    .o_rdata (dmem_ld_data                          )  // Read data
);


// Input Peripheral
prim_register #(.WIDTH(32)) reg_i_io_sw (.i_clk(i_clk), .i_rstn(i_rstn), .i_en(1'b1), .i_d(i_io_sw), .o_q(sw_reg_data) );


// Output Periperal
prim_register #(.WIDTH(32)) reg_io_ledr (.i_clk(i_clk), .i_rstn(i_rstn), .i_en(io_ledr_sel & i_lsu_st_en & i_instr_valid), .i_d(i_lsu_st_data),      .o_q(o_io_ledr) );
prim_register #(.WIDTH(32)) reg_io_ledg (.i_clk(i_clk), .i_rstn(i_rstn), .i_en(io_ledg_sel & i_lsu_st_en & i_instr_valid), .i_d(i_lsu_st_data),      .o_q(o_io_ledg) );
prim_register #(.WIDTH(32)) reg_io_lcd  (.i_clk(i_clk), .i_rstn(i_rstn), .i_en(io_lcd_sel  & i_lsu_st_en & i_instr_valid), .i_d(i_lsu_st_data),      .o_q(o_io_lcd ) );
prim_register #(.WIDTH(7) ) reg_io_hex0 (.i_clk(i_clk), .i_rstn(i_rstn), .i_en(io_hex0_sel & i_lsu_st_en & i_instr_valid), .i_d(i_lsu_st_data[6:0]), .o_q(o_io_hex0) );
prim_register #(.WIDTH(7) ) reg_io_hex1 (.i_clk(i_clk), .i_rstn(i_rstn), .i_en(io_hex1_sel & i_lsu_st_en & i_instr_valid), .i_d(i_lsu_st_data[6:0]), .o_q(o_io_hex1) );
prim_register #(.WIDTH(7) ) reg_io_hex2 (.i_clk(i_clk), .i_rstn(i_rstn), .i_en(io_hex2_sel & i_lsu_st_en & i_instr_valid), .i_d(i_lsu_st_data[6:0]), .o_q(o_io_hex2) );
prim_register #(.WIDTH(7) ) reg_io_hex3 (.i_clk(i_clk), .i_rstn(i_rstn), .i_en(io_hex3_sel & i_lsu_st_en & i_instr_valid), .i_d(i_lsu_st_data[6:0]), .o_q(o_io_hex3) );
prim_register #(.WIDTH(7) ) reg_io_hex4 (.i_clk(i_clk), .i_rstn(i_rstn), .i_en(io_hex4_sel & i_lsu_st_en & i_instr_valid), .i_d(i_lsu_st_data[6:0]), .o_q(o_io_hex4) );
prim_register #(.WIDTH(7) ) reg_io_hex5 (.i_clk(i_clk), .i_rstn(i_rstn), .i_en(io_hex5_sel & i_lsu_st_en & i_instr_valid), .i_d(i_lsu_st_data[6:0]), .o_q(o_io_hex5) );
prim_register #(.WIDTH(7) ) reg_io_hex6 (.i_clk(i_clk), .i_rstn(i_rstn), .i_en(io_hex6_sel & i_lsu_st_en & i_instr_valid), .i_d(i_lsu_st_data[6:0]), .o_q(o_io_hex6) );
prim_register #(.WIDTH(7) ) reg_io_hex7 (.i_clk(i_clk), .i_rstn(i_rstn), .i_en(io_hex7_sel & i_lsu_st_en & i_instr_valid), .i_d(i_lsu_st_data[6:0]), .o_q(o_io_hex7) );




// ======================================= LOAD DATA SELECTION ==========================================
logic [31:0] selected_ld_data;
logic [3:0]  mux_sel_ld_data;


assign mux_sel_ld_data[0] = io_hex0_sel | io_hex2_sel | io_hex4_sel | io_hex6_sel | io_ledr_sel | io_lcd_sel;
assign mux_sel_ld_data[1] = io_hex1_sel | io_hex2_sel | io_hex5_sel | io_hex6_sel | io_ledg_sel | io_lcd_sel;
assign mux_sel_ld_data[2] = io_hex3_sel | io_hex4_sel | io_hex5_sel | io_hex6_sel | io_sw_sel;
assign mux_sel_ld_data[3] = io_hex7_sel | io_ledr_sel | io_ledg_sel | io_lcd_sel  | io_sw_sel;

prim_mux_16x1 #(.WIDTH(32)) load_data_mux (
    .i_sel  (mux_sel_ld_data            ),
    .i_0    (dmem_ld_data               ),
    .i_1    ({25'h000_0000, o_io_hex0}  ),
    .i_2    ({25'h000_0000, o_io_hex1}  ),
    .i_3    ({25'h000_0000, o_io_hex2}  ),
    .i_4    ({25'h000_0000, o_io_hex3}  ),
    .i_5    ({25'h000_0000, o_io_hex4}  ),
    .i_6    ({25'h000_0000, o_io_hex5}  ),
    .i_7    ({25'h000_0000, o_io_hex6}  ),
    .i_8    ({25'h000_0000, o_io_hex7}  ),
    .i_9    (o_io_ledr                  ),
    .i_10   (o_io_ledg                  ),
    .i_11   (o_io_lcd                   ),
    .i_12   (sw_reg_data                ),
    .i_13   (32'h0000_0000              ),
    .i_14   (32'h0000_0000              ),
    .i_15   (32'h0000_0000              ),
    .o_mux  (selected_ld_data           )
);


// ============================== Apply i_lsu_bytemask for Loaded Data ==========================
logic [31:0] masked_selected_ld_data;       // LSU load data after applied i_lsu_bytemask

logic [1:0]  rdata_byte1_sel;    // Select data for byte 1
logic [1:0]  rdata_byte2_3_sel;  // Select data for byte 2 and 3
logic        load_byte;
logic        load_halfword;

always_comb begin : sign_extension_selection
    load_byte     = i_lsu_bytemask[0] & ~i_lsu_bytemask[1] & ~i_lsu_bytemask[2] & ~i_lsu_bytemask[3];
    load_halfword = i_lsu_bytemask[0] &  i_lsu_bytemask[1] & ~i_lsu_bytemask[2] & ~i_lsu_bytemask[3];

    rdata_byte1_sel[0]   = ~(i_lsu_ld_unsigned) & (load_byte);   // LB
    rdata_byte1_sel[1]   =  (i_lsu_ld_unsigned) & (load_byte);   // LBU

    rdata_byte2_3_sel[0] =  (load_halfword) | (i_lsu_ld_unsigned & load_byte);
    rdata_byte2_3_sel[1] = ~(i_lsu_ld_unsigned) & (load_byte | load_halfword);
end


assign masked_selected_ld_data[7:0] = selected_ld_data[7:0];

prim_mux_4x1 #(.WIDTH(8)) rdata_byte_1_sel(
        .i_sel( rdata_byte1_sel               ),
        .i_0  ( selected_ld_data[15:8]        ),  // [Default] --> Word & Halfword operations
        .i_1  ( {8{selected_ld_data[7]}}      ),  // [LB ]     --> Sign Extended of byte 0
        .i_2  ( 8'h00                         ),  // [LBU]     --> Not sign extended or Not Masked)
        .i_3  ( 8'h00                         ),  //           --> Reserved
        .o_mux( masked_selected_ld_data[15:8] )
);


prim_mux_4x1 #(.WIDTH(16))  rdata_byte_2_3_sel(
        .i_sel( rdata_byte2_3_sel              ),
        .i_0  ( selected_ld_data[31:16]        ),  // [Default]  --> For Word operation
        .i_1  ( 16'h0000                       ),  // [LBU, LHU] --> Not sign extended
        .i_2  ( {16{selected_ld_data[7]}}      ),  // [LB]       --> Sign Extended of byte 0
        .i_3  ( {16{selected_ld_data[15]}}     ),  // [LH]       --> Sign Extended of byte 1
        .o_mux( masked_selected_ld_data[31:16] )
);




// Output
assign o_lsu_ld_data = masked_selected_ld_data;




endmodule



