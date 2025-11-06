
module regfile (
    input  logic         i_clk,
    input  logic         i_rstn,

    input  logic [31:0]  i_rd_data,
    input  logic [4:0]   i_rd_addr,
    input  logic         i_rd_wren,

    input  logic [4:0]   i_rs1_addr,
    input  logic [4:0]   i_rs2_addr,

    output logic [31:0]  o_rs1_data,  // Combinational read
    output logic [31:0]  o_rs2_data   // Combinational read
);


// Renme signals to enhance readability
logic [31:0] rd_data;    // Sync Write destination data
logic [4:0]  rd_addr;    // Sync Write destination addr
logic        rd_wren;    // Sync Write write enable


// WRITE
always_comb begin : sync_write_signals
    rd_data  = i_rd_data;  // Destination registers (2)
    rd_addr  = i_rd_addr;  // Data of destination registers (2)
    rd_wren  = i_rd_wren;  // Write enable signal (2)
end



//----------------------- WRITE DATA TO REGFILE ------------------------------
logic [31:0] regfile_reg      [32];
logic [31:0] wren_onehot;
logic [31:0] wren_onehot_enabled;

// Decode
prim_decoder_5to32 decode_wr_sel(
    .i_bin(rd_addr    ),
    .o_dec(wren_onehot)
);

assign wren_onehot_enabled = (wren_onehot & {32{rd_wren}});


genvar write_index;
generate
    for(write_index = 0; write_index < 32; write_index++) begin : gen_reg
        // Storing/Writing data to registers
        if(write_index == 0) begin : gen_R0
            prim_register #(.WIDTH(32)) register (
                .i_clk   (i_clk                          ),
                .i_rstn  (i_rstn                         ),
                .i_en    (1'b1                           ),
                .i_d     (32'h0000_0000                  ),
                .o_q     (regfile_reg[write_index]       )
            );
        end
        else begin : gen_R1_to_R31
            prim_register #(.WIDTH(32)) register (
                .i_clk   (i_clk                            ),
                .i_rstn  (i_rstn                           ),
                .i_en    (wren_onehot_enabled[write_index] ),
                .i_d     (rd_data                          ),
                .o_q     (regfile_reg[write_index]         )
            );
        end
    end
endgenerate



//---------------------- READ REGFILE --------------------------------
// 4 async read ports
logic [31:0] rs1_data;
logic [31:0] rs2_data;
logic [4:0]  rs1_addr;
logic [4:0]  rs2_addr;


always_comb begin : async_read
    rs1_addr = i_rs1_addr;
    rs2_addr = i_rs2_addr;

end


prim_mux_32x1 #(.WIDTH(32)) rs1_read_mux (
    .i_sel  (rs1_addr        ),
    .i_0    (regfile_reg[0]  ),
    .i_1    (regfile_reg[1]  ),
    .i_2    (regfile_reg[2]  ),
    .i_3    (regfile_reg[3]  ),
    .i_4    (regfile_reg[4]  ),
    .i_5    (regfile_reg[5]  ),
    .i_6    (regfile_reg[6]  ),
    .i_7    (regfile_reg[7]  ),
    .i_8    (regfile_reg[8]  ),
    .i_9    (regfile_reg[9]  ),
    .i_10   (regfile_reg[10] ),
    .i_11   (regfile_reg[11] ),
    .i_12   (regfile_reg[12] ),
    .i_13   (regfile_reg[13] ),
    .i_14   (regfile_reg[14] ),
    .i_15   (regfile_reg[15] ),
    .i_16   (regfile_reg[16] ),
    .i_17   (regfile_reg[17] ),
    .i_18   (regfile_reg[18] ),
    .i_19   (regfile_reg[19] ),
    .i_20   (regfile_reg[20] ),
    .i_21   (regfile_reg[21] ),
    .i_22   (regfile_reg[22] ),
    .i_23   (regfile_reg[23] ),
    .i_24   (regfile_reg[24] ),
    .i_25   (regfile_reg[25] ),
    .i_26   (regfile_reg[26] ),
    .i_27   (regfile_reg[27] ),
    .i_28   (regfile_reg[28] ),
    .i_29   (regfile_reg[29] ),
    .i_30   (regfile_reg[30] ),
    .i_31   (regfile_reg[31] ),
    .o_mux  (rs1_data        )
);



prim_mux_32x1 #(.WIDTH(32)) rs2_read_mux (
    .i_sel  (rs2_addr        ),
    .i_0    (regfile_reg[0]  ),
    .i_1    (regfile_reg[1]  ),
    .i_2    (regfile_reg[2]  ),
    .i_3    (regfile_reg[3]  ),
    .i_4    (regfile_reg[4]  ),
    .i_5    (regfile_reg[5]  ),
    .i_6    (regfile_reg[6]  ),
    .i_7    (regfile_reg[7]  ),
    .i_8    (regfile_reg[8]  ),
    .i_9    (regfile_reg[9]  ),
    .i_10   (regfile_reg[10] ),
    .i_11   (regfile_reg[11] ),
    .i_12   (regfile_reg[12] ),
    .i_13   (regfile_reg[13] ),
    .i_14   (regfile_reg[14] ),
    .i_15   (regfile_reg[15] ),
    .i_16   (regfile_reg[16] ),
    .i_17   (regfile_reg[17] ),
    .i_18   (regfile_reg[18] ),
    .i_19   (regfile_reg[19] ),
    .i_20   (regfile_reg[20] ),
    .i_21   (regfile_reg[21] ),
    .i_22   (regfile_reg[22] ),
    .i_23   (regfile_reg[23] ),
    .i_24   (regfile_reg[24] ),
    .i_25   (regfile_reg[25] ),
    .i_26   (regfile_reg[26] ),
    .i_27   (regfile_reg[27] ),
    .i_28   (regfile_reg[28] ),
    .i_29   (regfile_reg[29] ),
    .i_30   (regfile_reg[30] ),
    .i_31   (regfile_reg[31] ),
    .o_mux  (rs2_data        )
);




// Output data for Source Reigsters
assign o_rs1_data = rs1_data;
assign o_rs2_data = rs2_data;





`ifdef DEBUG
    // Aliases for Debugging
    logic [31:0] R0, R8,  R16, R24;
    logic [31:0] R1, R9,  R17, R25;
    logic [31:0] R2, R10, R18, R26;
    logic [31:0] R3, R11, R19, R27;
    logic [31:0] R4, R12, R20, R28;
    logic [31:0] R5, R13, R21, R29;
    logic [31:0] R6, R14, R22, R30;
    logic [31:0] R7, R15, R23, R31;

    assign R0  = regfile_reg[0] ;
    assign R1  = regfile_reg[1] ;
    assign R2  = regfile_reg[2] ;
    assign R3  = regfile_reg[3] ;
    assign R4  = regfile_reg[4] ;
    assign R5  = regfile_reg[5] ;
    assign R6  = regfile_reg[6] ;
    assign R7  = regfile_reg[7] ;
    assign R8  = regfile_reg[8] ;
    assign R9  = regfile_reg[9] ;
    assign R10 = regfile_reg[10];
    assign R11 = regfile_reg[11];
    assign R12 = regfile_reg[12];
    assign R13 = regfile_reg[13];
    assign R14 = regfile_reg[14];
    assign R15 = regfile_reg[15];
    assign R16 = regfile_reg[16];
    assign R17 = regfile_reg[17];
    assign R18 = regfile_reg[18];
    assign R19 = regfile_reg[19];
    assign R20 = regfile_reg[20];
    assign R21 = regfile_reg[21];
    assign R22 = regfile_reg[22];
    assign R23 = regfile_reg[23];
    assign R24 = regfile_reg[24];
    assign R25 = regfile_reg[25];
    assign R26 = regfile_reg[26];
    assign R27 = regfile_reg[27];
    assign R28 = regfile_reg[28];
    assign R29 = regfile_reg[29];
    assign R30 = regfile_reg[30];
    assign R31 = regfile_reg[31];

`endif


















endmodule
