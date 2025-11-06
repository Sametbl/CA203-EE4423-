// ============================================================
// Filename           : vending_machine_fsm.sv
// Module Name        : vending_machine_fsm
// Author             : 1. Trần Trọng Hiếu ()
//                      2. Luong Thanh Vy  (2151280)
// Created On         : 28-09-2025  (DD-MM-YYYY)
// Module Description : Vening Machine for receiving coins and returning change FSM
// Notes              : - Each Soda can cost 25¢
//                      - Changes are return immediately after input reached or exceeeded 25¢
// ============================================================


module vending_machine_fsm(
    input   logic         i_clk     ,
    input   logic         i_rstn    ,
    input   logic         i_nickle  ,   // Nickle  = 5¢
    input   logic         i_dime    ,   // dime    = 10¢
    input   logic         i_quarter ,   // quarter = 25¢
    output  logic         o_soda    ,
    output  logic [2:0]   o_change      // o_change = 3'b000: Return 0¢
                                        // o_change = 3'b001: Return 5¢
                                        // o_change = 3'b010: Return 10¢
                                        // o_change = 3'b011: Return 15¢
                                        // o_change = 3'b100: Return 20¢
                                        // o_change = 3'b101: Reserved
                                        // o_change = 3'b110: Reserved
                                        // o_change = 3'b111: Reserved
);

// Maximum input without dispensing a sode is 40¢ (1 Nicle, 1 Dime and then 1 Quarter)

typedef enum logic [3:0] {
    ZERO        = 4'b0000,  // Indicate 0¢  inserted
    FIVE        = 4'b0001,  // Indicate 5¢  inserted
    TEN         = 4'b0010,  // Indicate 10¢ inserted
    FIFTEEN     = 4'b0011,  // Indicate 15¢ inserted
    TWENTY      = 4'b0100,  // Indicate 20¢ inserted
    TWENTY_FIVE = 4'b0101,  // Indicate 25¢ inserted
    THIRTY      = 4'b0110,  // Indicate 30¢ inserted
    THIRTY_FIVE = 4'b0111,  // Indicate 35¢ inserted
    FORTY       = 4'b1000   // Indicate 40¢ inserted
} state_t;

state_t current_state;
state_t next_state;


// State memory
always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn)  current_state   <=   ZERO;
    else          current_state   <=   next_state;
end


// Next-state logic
always_comb begin : VENDING_FSM
    case (current_state)
        ZERO:       if      (i_quarter)    next_state = TWENTY_FIVE;
                    else if (i_dime   )    next_state = TEN;
                    else if (i_nickle )    next_state = FIVE;
                    else                   next_state = ZERO;

        FIVE:       if      (i_quarter)    next_state = THIRTY;
                    else if (i_dime   )    next_state = FIFTEEN;
                    else if (i_nickle )    next_state = TEN;
                    else                   next_state = FIVE;


        TEN:        if      (i_quarter)    next_state = THIRTY_FIVE;
                    else if (i_dime   )    next_state = TWENTY;
                    else if (i_nickle )    next_state = FIFTEEN;
                    else                   next_state = TEN;

        FIFTEEN:    if      (i_quarter)    next_state = FORTY;
                    else if (i_dime   )    next_state = TWENTY_FIVE;
                    else if (i_nickle )    next_state = TWENTY;
                    else                   next_state = FIFTEEN;


        TWENTY:                            next_state = ZERO;
        TWENTY_FIVE:                       next_state = ZERO;
        THIRTY:                            next_state = ZERO;
        THIRTY_FIVE:                       next_state = ZERO;
        FORTY:                             next_state = ZERO;
        default:                           next_state = ZERO;
    endcase
end


// Output logic
always_comb begin : mux_8x1_1bit
    case (current_state)
        ZERO:          o_soda = 1'b0;
        FIVE:          o_soda = 1'b0;
        TEN:           o_soda = 1'b0;
        FIFTEEN:       o_soda = 1'b0;
        TWENTY:        o_soda = 1'b1;
        TWENTY_FIVE:   o_soda = 1'b1;
        THIRTY:        o_soda = 1'b1;
        THIRTY_FIVE:   o_soda = 1'b1;
        FORTY:         o_soda = 1'b1;
        default:       o_soda = 1'b0;
    endcase
end


always_comb begin : mux_8x1_3bit
    case (current_state)
        ZERO:         o_change = 3'b000;  // Return 0¢  (Not enough ¢)
        FIVE:         o_change = 3'b000;  // Return 0¢  (Not enough ¢)
        TEN:          o_change = 3'b000;  // Return 0¢  (Not enough ¢)
        FIFTEEN:      o_change = 3'b000;  // Return 0¢  (Not enough ¢)
        TWENTY:       o_change = 3'b000;  // Return 0¢  (20¢ - 20¢)
        TWENTY_FIVE:  o_change = 3'b001;  // Return 5¢  (25¢ - 20¢)
        THIRTY:       o_change = 3'b010;  // Return 10¢ (30¢ - 20¢)
        THIRTY_FIVE:  o_change = 3'b011;  // Return 15¢ (35¢ - 20¢)
        FORTY:        o_change = 3'b100;  // Return 20¢ (40¢ - 20¢)
        default:      o_change = 3'b000;
    endcase
end

endmodule




















