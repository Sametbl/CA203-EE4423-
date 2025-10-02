
// Primitice Cell: Convert BCD to common-anode (+) 7-segment LED

module prim_bcdtohex(
   input logic  [3:0] i_bcd,
   output logic [6:0] o_segment
);

always_comb begin
  unique case(i_bcd)
    4'd0: o_segment = 7'b1000000;
    4'd1: o_segment = 7'b1111001;
    4'd2: o_segment = 7'b0100100;
    4'd3: o_segment = 7'b0110000;
    4'd4: o_segment = 7'b0011001;
    4'd5: o_segment = 7'b0010010;
    4'd6: o_segment = 7'b0000010;
    4'd7: o_segment = 7'b1111000;
    4'd8: o_segment = 7'b0000000;
    4'd9: o_segment = 7'b0010000;
    4'hA: o_segment = 7'b0100000;
    4'hB: o_segment = 7'b0000011;
    4'hC: o_segment = 7'b1000110;
    4'hD: o_segment = 7'b0100001;
    4'hE: o_segment = 7'b0000110;
    4'hF: o_segment = 7'b0001110;
    default: o_segment = 7'b0111111;
  endcase
end

endmodule : prim_bcdtohex



