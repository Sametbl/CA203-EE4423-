module prim_encoder_8to3(
  input  logic [7:0] i_bin,
  output logic [2:0] o_enc
);

// Priority encoder: highest bit has highest priority
always_comb begin
casez (i_bin)
    8'b1???_????:    o_enc = 3'b111;
    8'b01??_????:    o_enc = 3'b110;
    8'b001?_????:    o_enc = 3'b101;
    8'b0001_????:    o_enc = 3'b100;
    8'b0000_1???:    o_enc = 3'b011;
    8'b0000_01??:    o_enc = 3'b010;
    8'b0000_001?:    o_enc = 3'b001;
    8'b0000_0001:    o_enc = 3'b000;
    default:         o_enc = 3'b000;
endcase
end

endmodule : prim_encoder_8to3
