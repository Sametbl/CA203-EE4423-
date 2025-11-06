module prim_mux_32x1   #(parameter int WIDTH = 32)(
    input  logic [4:0]       i_sel,
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
    input  logic [WIDTH-1:0] i_16 ,
    input  logic [WIDTH-1:0] i_17 ,
    input  logic [WIDTH-1:0] i_18 ,
    input  logic [WIDTH-1:0] i_19 ,
    input  logic [WIDTH-1:0] i_20 ,
    input  logic [WIDTH-1:0] i_21 ,
    input  logic [WIDTH-1:0] i_22 ,
    input  logic [WIDTH-1:0] i_23 ,
    input  logic [WIDTH-1:0] i_24 ,
    input  logic [WIDTH-1:0] i_25 ,
    input  logic [WIDTH-1:0] i_26 ,
    input  logic [WIDTH-1:0] i_27 ,
    input  logic [WIDTH-1:0] i_28 ,
    input  logic [WIDTH-1:0] i_29 ,
    input  logic [WIDTH-1:0] i_30 ,
    input  logic [WIDTH-1:0] i_31 ,
    output logic [WIDTH-1:0] o_mux);

always_comb begin
    case (i_sel)
        5'b00000:  o_mux = i_0;
        5'b00001:  o_mux = i_1;
        5'b00010:  o_mux = i_2;
        5'b00011:  o_mux = i_3;
        5'b00100:  o_mux = i_4;
        5'b00101:  o_mux = i_5;
        5'b00110:  o_mux = i_6;
        5'b00111:  o_mux = i_7;
        5'b01000:  o_mux = i_8;
        5'b01001:  o_mux = i_9;
        5'b01010:  o_mux = i_10;
        5'b01011:  o_mux = i_11;
        5'b01100:  o_mux = i_12;
        5'b01101:  o_mux = i_13;
        5'b01110:  o_mux = i_14;
        5'b01111:  o_mux = i_15;
        5'b10000:  o_mux = i_16;
        5'b10001:  o_mux = i_17;
        5'b10010:  o_mux = i_18;
        5'b10011:  o_mux = i_19;
        5'b10100:  o_mux = i_20;
        5'b10101:  o_mux = i_21;
        5'b10110:  o_mux = i_22;
        5'b10111:  o_mux = i_23;
        5'b11000:  o_mux = i_24;
        5'b11001:  o_mux = i_25;
        5'b11010:  o_mux = i_26;
        5'b11011:  o_mux = i_27;
        5'b11100:  o_mux = i_28;
        5'b11101:  o_mux = i_29;
        5'b11110:  o_mux = i_30;
        5'b11111:  o_mux = i_31;
        default: o_mux = {(WIDTH){1'b0}};
    endcase
end
endmodule : prim_mux_32x1


