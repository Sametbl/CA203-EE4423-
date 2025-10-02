// ============================================================
// Filename           : forwarding_cell.sv
// Module Name        : forwarding_cell
// Author             : Luong Thanh Vy (CA203 - K22)
// Created On         : DD-MM-2025  (DD-MM-YYYY)
// Module Description : Perform forwarding check from a forwarding source
// Module Purpose     : Used to make a modular and scaleble Forwarding Unit
// Version            : 1.0.0
// ============================================================


module forwarding_cell(
    input  logic [4:0] i_rs1_addr       ,   // Current RS1 address to be compared
    input  logic [4:0] i_rs2_addr       ,   // Current RS2 address to be compared
    input  logic [4:0] i_fwd_rd_adder   ,   // RD address from buffer to be compared to
    input  logic       i_fwd_valid      ,
    output logic       o_fwd_rs1_matched,
    output logic       o_fwd_rs2_matched
);

logic rs1_matched;
logic rs2_matched;
logic rd_addr_R0;

prim_cmp_eq #(.WIDTH(5)) compare_rs1 (
    .i_a (i_rs1_addr     ),
    .i_b (i_fwd_rd_adder ),
    .o_eq(rs1_matched    )
);

prim_cmp_eq #(.WIDTH(5)) compare_rs2 (
    .i_a (i_rs2_addr     ),
    .i_b (i_fwd_rd_adder ),
    .o_eq(rs2_matched    )
);


assign rd_addr_R0  = ~(|i_fwd_rd_adder);

assign o_fwd_rs1_matched = (rs1_matched) & (i_fwd_valid) & ~rd_addr_R0;
assign o_fwd_rs2_matched = (rs2_matched) & (i_fwd_valid) & ~rd_addr_R0;

endmodule

