
module prim_d_flipflop #(parameter logic RESET_VAL = 1'b0)(
    input  logic i_clk,
    input  logic i_rstn,      // Active-Low asynchronous reset
    input  logic i_en,
    input  logic i_d,
    output logic o_q
);

always_ff @(posedge i_clk, negedge i_rstn) begin
    if (!i_rstn)       o_q  <=  RESET_VAL;
    else if (i_en)     o_q  <=  i_d;
    else               o_q  <=  o_q;  // Prevent latch
end


endmodule : prim_d_flipflop
