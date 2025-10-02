// The NLC counts the number of zero of the 4 bit number: Zero[1:0] (From 0 to 3)
// If all bits are zero (4 zeros) then singal "all_zero" will represent this case.

module nlc_4bit (
    input  logic [3:0] i_X,
    output logic [1:0] o_zero,     // Number of zero
    output logic       o_all_zero  // Indicate the 4-bit number if all zeros
);

logic A, B, C, D;

assign A = i_X[3];
assign B = i_X[2];
assign C = i_X[1];
assign D = i_X[0];

assign o_all_zero = ~(A | B | C | D);
assign o_zero[1]  = ~(A | B);           // High when two first MSB is LOW
assign o_zero[0]  = ~( (~B & C) | A );  // High when {ABC} = 3'b01X , or {ABC} = 3'b000


endmodule : nlc_4bit






