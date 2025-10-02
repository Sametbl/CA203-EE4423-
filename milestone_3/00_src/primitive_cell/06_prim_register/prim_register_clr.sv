
// Primitive Cell: Register with Synchronous Active-High Clear pin
// "Clear" means clear all bits to logic 0's
// "Reset" means reset register to pre-defined value

module prim_register_clr #(
    parameter int WIDTH = 32,
    parameter logic [WIDTH-1 :0] RESET_VAL = {(WIDTH){1'b0}}
)(
    input  logic                i_clk,
    input  logic                i_rstn,      // Active-Low asynchronous reset
    input  logic                i_clear,     // Synchronous clear
    input  logic                i_en,
    input  logic [WIDTH- 1 : 0] i_d,
    output logic [WIDTH- 1 : 0] o_q
);

logic [WIDTH-1: 0] write_data;

prim_mux_2x1 #(.WIDTH(WIDTH)) Clear_mux(
    .i_sel(i_clear          ),
    .i_0  (i_d              ),
    .i_1  ({(WIDTH){1'b0}}  ),
    .o_mux(write_data       )
);

always_ff @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn)                o_q  <=  RESET_VAL;
        else if (i_en | i_clear)    o_q  <=  write_data;
        else                        o_q  <=  o_q;
end


endmodule : prim_register_clr
