module prim_mux_4x1   #(parameter int WIDTH = 32)(
    input  logic [1:0]       i_sel,
    input  logic [WIDTH-1:0] i_0  ,
    input  logic [WIDTH-1:0] i_1  ,
    input  logic [WIDTH-1:0] i_2  ,
    input  logic [WIDTH-1:0] i_3  ,
    output logic [WIDTH-1:0] o_mux
);

always_comb begin
    case (i_sel)
        2'b00: o_mux = i_0;
        2'b01: o_mux = i_1;
        2'b10: o_mux = i_2;
        2'b11: o_mux = i_3;
        default: o_mux = {(WIDTH){1'b0}};
    endcase
end
endmodule : prim_mux_4x1


