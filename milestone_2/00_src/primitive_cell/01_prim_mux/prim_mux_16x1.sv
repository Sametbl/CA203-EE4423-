module prim_mux_16x1   #(parameter int WIDTH = 32)(
    input  logic [3:0]       i_sel,
    input  logic [WIDTH-1:0] i_0  ,
    input  logic [WIDTH-1:0] i_1  ,
    input  logic [WIDTH-1:0] i_2  ,
    input  logic [WIDTH-1:0] i_3  ,
    input  logic [WIDTH-1:0] i_4  ,
    input  logic [WIDTH-1:0] i_5  ,
    input  logic [WIDTH-1:0] i_6  ,
    input  logic [WIDTH-1:0] i_7  ,
    input  logic [WIDTH-1:0] i_8  ,
    input  logic [WIDTH-1:0] i_9  ,
    input  logic [WIDTH-1:0] i_10 ,
    input  logic [WIDTH-1:0] i_11 ,
    input  logic [WIDTH-1:0] i_12 ,
    input  logic [WIDTH-1:0] i_13 ,
    input  logic [WIDTH-1:0] i_14 ,
    input  logic [WIDTH-1:0] i_15 ,
    output logic [WIDTH-1:0] o_mux
);

always_comb begin
    case (i_sel)
        4'b0000:  o_mux = i_0;
        4'b0001:  o_mux = i_1;
        4'b0010:  o_mux = i_2;
        4'b0011:  o_mux = i_3;
        4'b0100:  o_mux = i_4;
        4'b0101:  o_mux = i_5;
        4'b0110:  o_mux = i_6;
        4'b0111:  o_mux = i_7;
        4'b1000:  o_mux = i_8;
        4'b1001:  o_mux = i_9;
        4'b1010: o_mux = i_10;
        4'b1011: o_mux = i_11;
        4'b1100: o_mux = i_12;
        4'b1101: o_mux = i_13;
        4'b1110: o_mux = i_14;
        4'b1111: o_mux = i_15;
        default: o_mux = {(WIDTH){1'b0}};
    endcase
end
endmodule : prim_mux_16x1


