module prim_mux_2x1   #(parameter int WIDTH = 32)(
    input  logic             i_sel ,
    input  logic [WIDTH-1:0] i_0   ,
    input  logic [WIDTH-1:0] i_1   ,
    output logic [WIDTH-1:0] o_mux
);

always_comb begin
    case (i_sel)
        1'b0: o_mux = i_0;
        1'b1: o_mux = i_1;
        default: o_mux = {(WIDTH){1'b0}};
    endcase
end

endmodule : prim_mux_2x1

