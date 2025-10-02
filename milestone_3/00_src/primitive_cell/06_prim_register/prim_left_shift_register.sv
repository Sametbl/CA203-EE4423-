
// Primitive Cell: Register with Synchronous Active-High Clear pin
// "Clear" means clear all bits to logic 0's
// "Reset" means reset register to pre-defined value

module prim_left_shift_register #(parameter int WIDTH = 32,
                                  parameter logic [WIDTH-1 :0] RESET_VAL = {(WIDTH){1'b0}} )(
    input  logic                i_clk       ,
    input  logic                i_rstn      , // Active-Low asynchronous reset
    input  logic                i_en        ,
    input  logic                i_shift_in  ,
    input  logic                i_load      , // Synchronous load
    input  logic [WIDTH- 1 : 0] i_load_data , // Load data
    output logic [WIDTH- 1 : 0] o_q
);

logic [WIDTH-1: 0] write_data;
logic [WIDTH-1: 0] q;


prim_mux_2x1  #(.WIDTH(WIDTH))  Load_mux (
    .i_sel(i_load                     ),
    .i_0  ({q[WIDTH-2:0], i_shift_in} ),
    .i_1  (i_load_data                ),
    .o_mux(write_data                 )
);


always_ff @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn)                q  <=  RESET_VAL;
        else if (i_en | i_load)     q  <=  write_data;
        else                        q  <=  q;
end

// Ouptut
assign o_q = q;


endmodule : prim_left_shift_register
