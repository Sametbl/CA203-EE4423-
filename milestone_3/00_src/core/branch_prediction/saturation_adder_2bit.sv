// ============================================================
// Filename           : saturation_adder_2bit.sv
// Module Name        : saturation_adder_2bit
// Author             : Luong Thanh Vy (CA203 - K22)
// Created On         : 15-08-2025  (DD-MM-YYYY)
// Module Description : Used to control 2-bit predictor for BTB
// Module Purpose     : Used to integrate into BTB
// Notes              : Circuit Achieved by using Karnaugh map
// Version            : 1.0.0
// ============================================================

// module saturation_adder_2bit(
//     input        i_carry_in ,  // Carry in for adding to the data (also acts as enable pin)
//     input        i_sub_mode ,  // HIGH to enter saturation subtraction
//     input  [1:0] i_data_in  ,
//     output [1:0] o_data_out
// );
// // Alias (with shorter name)
// logic [1:0] a;
// logic       b;
// logic       sub;

// assign a   = i_data_in;
// assign b   = i_carry_in;
// assign sub = i_sub_mode;

// assign o_data_out[0] = (i_carry_in & i_sub_mode) ?



// assign o_data_out[1] = 


// assign o_data_out[0] = (a[0] & ~b) | (a[1] & ~a[0] & b) | sub & b & (~a[0] | a[1]);
// assign o_data_out[1] = (a[1] & ~b) | (a[1] &  a[0])     | sub & b & ( a[0] | a[1]);

// endmodule





module saturation_adder_2bit(
    input        i_carry_in ,  // Carry in for adding to the data (also acts as enable pin)
    input        i_sub_mode ,  // HIGH to enter saturation subtraction
    input  [1:0] i_data_in  ,
    output [1:0] o_data_out
);


// Internal signal to hold the result
logic [1:0] result;

always_comb begin
    result = i_data_in;

    if (i_carry_in) begin
        if (i_sub_mode) begin
            // Saturating decrement
            if (result != 2'b00)
                result = result - 2'b01;
        end
        else begin
            // Saturating increment
            if (result != 2'b11)
                result = result + 2'b01;
        end
    end
end

assign o_data_out = result;

endmodule

