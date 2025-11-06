module prim_up_counter #(
    parameter int WIDTH = 32,
    parameter logic [WIDTH-1 :0] RESET_VAL = {(WIDTH){1'b0}}
)(
    input  logic             i_clk          ,
    input  logic             i_rstn         ,     // Active-Low  asynchronous reset
    input  logic             i_en           ,       // Count enable
    input  logic             i_load         ,     // Active-High synchronous load
    input  logic [WIDTH-1:0] i_load_data    ,
    output logic [WIDTH-1:0] o_count
);

localparam logic [WIDTH-1:0] ONE = {{(WIDTH-1){1'b0}}, 1'b1};

logic [WIDTH-1 :0]  count_inc;
logic [WIDTH-1 :0]  write_data;

assign count_inc = o_count + ONE;

prim_mux_2x1 #(.WIDTH(WIDTH)) load_mux(
    .i_sel(i_load       ),
    .i_0  (count_inc    ),
    .i_1  (i_load_data  ),
    .o_mux(write_data   )
);

always_ff @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn)                 o_count <= RESET_VAL;
        else if (i_en | i_load)      o_count <= write_data;
        else                         o_count <= o_count;        // Prevent Latch
end


endmodule : prim_up_counter

