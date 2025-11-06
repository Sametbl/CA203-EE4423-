module prim_mux_8x1   #(parameter int WIDTH = 32)(
    input  logic [2:0]       i_sel,
    input  logic [WIDTH-1:0] i_0  ,
    input  logic [WIDTH-1:0] i_1  ,
    input  logic [WIDTH-1:0] i_2  ,
    input  logic [WIDTH-1:0] i_3  ,
    input  logic [WIDTH-1:0] i_4  ,
    input  logic [WIDTH-1:0] i_5  ,
    input  logic [WIDTH-1:0] i_6  ,
    input  logic [WIDTH-1:0] i_7  ,
    output logic [WIDTH-1:0] o_mux
);

always_comb begin
    case (i_sel)
        3'b000: o_mux = i_0;
        3'b001: o_mux = i_1;
        3'b010: o_mux = i_2;
        3'b011: o_mux = i_3;
        3'b100: o_mux = i_4;
        3'b101: o_mux = i_5;
        3'b110: o_mux = i_6;
        3'b111: o_mux = i_7;
        default: o_mux = {(WIDTH){1'b0}};
    endcase
end

endmodule : prim_mux_8x1
