
// Primitive Cell: Counter with both directions
module prim_counter  #(
    parameter int WIDTH = 32,
    parameter logic [WIDTH-1 :0] RESET_VAL = {(WIDTH){1'b0}}
)(
    input  logic             i_clr,
    input  logic             i_rstn,       // Active-Low asynchronous reset
    input  logic             i_en,         // Count enable
    input  logic             i_up,         // 1 = i_up, 0 = down
    input  logic             i_load,       // Active-High synchronous load
    input  logic [WIDTH-1:0] i_load_data,  // Load Value
    output logic [WIDTH-1:0] o_count
);

localparam logic [WIDTH-1:0] ONE = {{(WIDTH-1){1'b0}}, 1'b1};

logic [WIDTH-1 :0]  next_count;
logic [WIDTH-1 :0]  write_data;


assign next_count = (i_up) ? (o_count + ONE) : (o_count - ONE);

prim_mux_2x1 #(.WIDTH(WIDTH)) load_mux(
    .i_sel(i_load       ),
    .i_0  (next_count   ),
    .i_1  (i_load_data  ),
    .o_mux(write_data   )
);

always_ff @(posedge i_clr, negedge i_rstn) begin
        if (!i_rstn)                o_count <= RESET_VAL;
        else if (i_en | i_load)     o_count <= write_data;
        else                        o_count <= o_count;        // Prevent Latch
end


endmodule : prim_counter

