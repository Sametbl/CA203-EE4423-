module prim_register #(
    parameter int WIDTH = 32,
    parameter logic [WIDTH-1 :0] RESET_VAL = {(WIDTH){1'b0}}
)(
    input  logic                i_clk,
    input  logic                i_rstn,      // Active-Low asynchronous reset
    input  logic                i_en,
    input  logic [WIDTH- 1 : 0] i_d,
    output logic [WIDTH- 1 : 0] o_q
);

always_ff @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn)      o_q  <=  RESET_VAL;
        else if (i_en)    o_q  <=  i_d;
        else              o_q  <=  o_q;   // To prevent latch
end

endmodule : prim_register


