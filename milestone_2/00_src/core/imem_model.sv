


module imem_model #(parameter string PROGRAMFILE = "",
                    parameter int    MEM_DEPTH = 10 )              // Number of words
(
    input  logic [31:0] i_addr,    // Word address (PC)
    output logic [31:0] o_data     // Instruction word
);

// Instruction memory array
logic [7:0] imem [2**MEM_DEPTH];

initial begin
    $readmemh(PROGRAMFILE, imem);
end


logic [MEM_DEPTH-1:0] imem_addr;
logic [31:0]          imem_data;

// Asynchronous (combinational) read
assign imem_addr     = i_addr[MEM_DEPTH-1 :0];

always_comb begin
    imem_data[7:0]   = imem[imem_addr    ];
    imem_data[15:8]  = imem[imem_addr + 1];
    imem_data[23:16] = imem[imem_addr + 2];
    imem_data[31:24] = imem[imem_addr + 3];
end


// Ouptut
assign o_data = imem_data;

endmodule



