
module hazard_detection import pipeline_pkg::*;
(
    input  hazard_t      i_dcd_hazard_pkg, // Data from decode for Hazard Detection

    input  logic         i_lsu_ready     , // Indicate a AGU is currently idle
    input  logic         i_mul_ready     , // Indicate a MUL is currently idle
    input  logic         i_div_ready     , // Indicate a DIV is currently idle

    input  logic         i_lsu_wren      ,
    input  logic [4:0]   i_rd_addr_lsu   ,
    input  logic [4:0]   i_rd_addr_mul   ,
    input  logic [4:0]   i_rd_addr_div   ,

    output logic         o_discard_lsu   , // Cancel unnecessary LSU due to WAW hazard
    output logic         o_discard_mul   , // Cancel unnecessary MUL due to WAW hazard
    output logic         o_discard_div   , // Cancel unnecessary DIV due to WAW hazard
    output logic         o_stall           // Stall signal due to Hazard
);


// Alias
logic [4:0]   dec_rs1_addr;   // Address of RS1 in ID stage (from Deocder)
logic [4:0]   dec_rs2_addr;   // Address of RS2 in ID stage (from Deocder)
logic [4:0]   dec_rd_addr;
logic         dec_use_rs1;    // Indicate the current instr in ID stage uses RS1
logic         dec_use_rs2;    // Indicate the current instr in ID stage uses RS2
logic         dec_load_en;
logic         dec_store_en;
logic         dec_mul_en;     // Indicate the current instruction in ID stage is MUL
logic         dec_div_en;     // Indicate the current instruction in ID stage is DIV
logic         dec_wren;
logic         dec_valid;      // Indicate the current instruction in ID stage is valid

always_comb begin : signal_aliasing     // In decode stage
    dec_rs1_addr = i_dcd_hazard_pkg.rs1_addr;
    dec_rs2_addr = i_dcd_hazard_pkg.rs2_addr;
    dec_rd_addr  = i_dcd_hazard_pkg.rd_addr;
    dec_use_rs1  = i_dcd_hazard_pkg.use_rs1;
    dec_use_rs2  = i_dcd_hazard_pkg.use_rs2;
    dec_load_en  = i_dcd_hazard_pkg.load_en;
    dec_store_en = i_dcd_hazard_pkg.store_en;
    dec_mul_en   = i_dcd_hazard_pkg.mul_en;
    dec_div_en   = i_dcd_hazard_pkg.div_en;
    dec_wren     = i_dcd_hazard_pkg.wren;
    dec_valid    = i_dcd_hazard_pkg.valid;
end

// Decode instruction info
logic dec_rs1_valid;
logic dec_rs2_valid;
logic dec_rd_valid;

// RAW
logic rs1_eq_rd_lsu;
logic rs2_eq_rd_lsu;

logic rs1_eq_rd_mul;
logic rs2_eq_rd_mul;

logic rs1_eq_rd_div;
logic rs2_eq_rd_div;

// WAW
logic rd_eq_rd_lsu;
logic rd_eq_rd_mul;
logic rd_eq_rd_div;


assign dec_rs1_valid = (dec_valid) & (dec_use_rs1) & (|dec_rs1_addr);
assign dec_rs2_valid = (dec_valid) & (dec_use_rs2) & (|dec_rs2_addr);
assign dec_rd_valid  = (dec_valid) & (dec_wren)    & (|dec_rd_addr);

always_comb begin : source_address_comparison
    // LSU
    rs1_eq_rd_lsu = (dec_rs1_addr == i_rd_addr_lsu) & (dec_rs1_valid);
    rs2_eq_rd_lsu = (dec_rs2_addr == i_rd_addr_lsu) & (dec_rs2_valid);

    // MUL
    rs1_eq_rd_mul = (dec_rs1_addr == i_rd_addr_mul) & dec_rs1_valid;
    rs2_eq_rd_mul = (dec_rs2_addr == i_rd_addr_mul) & dec_rs2_valid;

    // DIV
    rs1_eq_rd_div = (dec_rs1_addr == i_rd_addr_div) & dec_rs1_valid;
    rs2_eq_rd_div = (dec_rs2_addr == i_rd_addr_div) & dec_rs2_valid;
end

always_comb begin : destination_address_comparison
    rd_eq_rd_lsu = (dec_rd_addr == i_rd_addr_lsu) & dec_rd_valid;
    rd_eq_rd_mul = (dec_rd_addr == i_rd_addr_mul) & dec_rd_valid;
    rd_eq_rd_div = (dec_rd_addr == i_rd_addr_div) & dec_rd_valid;
end


// ----------------------------- Hazard Detection ----------------------
logic wait_for_lsu;    // LSU is not available for the next Load/Store instruction
logic wait_for_mul;    // MUL is not available for the next MUL instruction
logic wait_for_div;    // DIV is not available for the next DIV instruction

logic raw_depend_lsu;  // RAW dependency on result from currently executing Load operation
logic raw_depend_mul;  // RAW dependency on result from currently executing MUL operation
logic raw_depend_div;  // RAW dependency on result from currently executing DIV operation

// LSU, MUL, DIV required many cycles to complete
// While executing there may some instruction with same Destination address complete first (WAW)

logic waw_lsu;
logic waw_mul;
logic waw_div;

// Structural hazard
always_comb begin : hazard_detection
    wait_for_lsu = (~i_lsu_ready) & (dec_load_en | dec_store_en);
    wait_for_mul = (~i_mul_ready) & (dec_mul_en);
    wait_for_div = (~i_div_ready) & (dec_div_en);
end

// RAW hazard
always_comb begin : raw_detection
    raw_depend_lsu = (rs1_eq_rd_lsu | rs2_eq_rd_lsu) & (i_lsu_wren);
    raw_depend_mul = (rs1_eq_rd_mul | rs2_eq_rd_mul);
    raw_depend_div = (rs1_eq_rd_div | rs2_eq_rd_div);
end


// WAW hazard
always_comb begin : waw_detection
    waw_lsu = (rd_eq_rd_lsu) & (~raw_depend_lsu) & (i_lsu_wren);
    waw_mul = (rd_eq_rd_mul) & (~raw_depend_mul);
    waw_div = (rd_eq_rd_div) & (~raw_depend_div);
end




// Output
assign o_stall  = (wait_for_lsu | wait_for_mul | wait_for_div) |
                  (raw_depend_lsu | raw_depend_mul | raw_depend_div);

assign o_discard_lsu = waw_lsu;
assign o_discard_mul = waw_mul;
assign o_discard_div = waw_div;

endmodule


