


module dmem_model #(parameter int    MEM_DEPTH = 10,
                    parameter string DMEM_INIT_FILE = "")(
    input  logic                  i_clk,      // Clock
    input  logic [31:0]           i_addr,     // Word address
    input  logic [3:0]            i_bmask,    // Bytemask
    input  logic                  i_wren,     // Write enable
    input  logic [31:0]           i_wdata,    // Write data
    output logic [31:0]           o_rdata     // Read data
);



// Data memory array
logic [ 7:0] dmem [2**MEM_DEPTH];
logic [31:0] read_data;
logic        out_of_range;


assign out_of_range = |(i_addr[31:MEM_DEPTH]);





// Optional: preload or dump memory for simulation
initial begin
    $readmemh(DMEM_INIT_FILE, dmem);
end


// Synchronous write
always_ff @(posedge i_clk) begin
    if (i_wren) begin
        if (i_bmask[0])     dmem[i_addr    ]   <=  i_wdata[7:0];
        if (i_bmask[1])     dmem[i_addr + 1]   <=  i_wdata[15:8];
        if (i_bmask[2])     dmem[i_addr + 2]   <=  i_wdata[23:16];
        if (i_bmask[3])     dmem[i_addr + 3]   <=  i_wdata[31:24];
    end
    else begin
        dmem[i_addr]   <=  dmem[i_addr]; // Prevent Latch
    end
end


// Asynchronous (combinational) read
always_comb begin
    read_data[7:0]   = dmem[i_addr    ];
    read_data[15:8]  = dmem[i_addr + 1];
    read_data[23:16] = dmem[i_addr + 2];
    read_data[31:24] = dmem[i_addr + 3];
end


// Output
prim_mux_2x1 #(.WIDTH(32)) out_of_range_mux (
    .i_sel  (out_of_range  ),
    .i_0    (read_data     ),
    .i_1    (32'h0000_0000 ),
    .o_mux  (o_rdata       )
);


endmodule
