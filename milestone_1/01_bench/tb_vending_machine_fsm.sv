`define CLK_DUR 2
`define RST_DUR 10
`define RUNTIME (`CLK_DUR * 100_000)
`define TIMEOUT (`RST_DUR + `RUNTIME)


`define FSDB 1


module tb_vending_machine_fsm();

logic clk;
logic rstn;


logic       tb_nickle;
logic       tb_dime;
logic       tb_quarter;
logic       dut_soda;
logic [2:0] dut_change;


logic [31:0] coin_value;
logic [31:0] change_value;


// o_change = 3'b000: Return 0¢
// o_change = 3'b001: Return 5¢
// o_change = 3'b010: Return 10¢
// o_change = 3'b011: Return 15¢
// o_change = 3'b100: Return 20¢
// o_change = 3'b101: Reserved
// o_change = 3'b110: Reserved
// o_change = 3'b111: Reserved

vending_machine_fsm   dut(
    .i_clk     (clk         ),
    .i_rstn    (rstn        ),
    .i_nickle  (tb_nickle   ),  // Nickle  = 5¢
    .i_dime    (tb_dime     ),  // dime    = 10¢
    .i_quarter (tb_quarter  ),  // quarter = 25¢
    .o_soda    (dut_soda    ),
    .o_change  (dut_change  )
);


`ifdef FSDB
    initial begin : dumpfile
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, tb_vending_machine_fsm);
    end
`else
    initial begin : dumpfile
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_vending_machine_fsm);
    end
`endif



initial tsk_clk_gen (clk,  `CLK_DUR);
initial tsk_rstn_gen(rstn, `RST_DUR);
initial tsk_timeout(`TIMEOUT);




`define REST_TIME 10
initial begin
    tb_nickle  = 1'b0;
    tb_dime    = 1'b0;
    tb_quarter = 1'b0;
    #(`RST_DUR);
    #(`RST_DUR);

    test_1();
    tsk_latency(clk, `REST_TIME);

    test_2();
    tsk_latency(clk, `REST_TIME);

    test_3();
    tsk_latency(clk, `REST_TIME);

    test_4();
    tsk_latency(clk, `REST_TIME);

    test_5();
    tsk_latency(clk, `REST_TIME);

    test_6();
    tsk_latency(clk, `REST_TIME);

    test_7();
    tsk_latency(clk, `REST_TIME);

    test_8();
    tsk_latency(clk, `REST_TIME);

    test_9();
    tsk_latency(clk, `REST_TIME);

    test_10();
    tsk_latency(clk, `REST_TIME);

    test_11();
    tsk_latency(clk, `REST_TIME);

    test_12();
    tsk_latency(clk, `REST_TIME);

    test_13();
    tsk_latency(clk, `REST_TIME);

    test_14();
    tsk_latency(clk, `REST_TIME);

    test_15();
    tsk_latency(clk, `REST_TIME);

    $finish;
end


always_comb begin
        case(dut.current_state)
            4'b0000:        coin_value = 0;
            4'b0001:        coin_value = 5;
            4'b0010:        coin_value = 10;
            4'b0011:        coin_value = 15;
            4'b0100:        coin_value = 20;
            4'b0101:        coin_value = 25;
            4'b0110:        coin_value = 30;
            4'b0111:        coin_value = 35;
            4'b1000:        coin_value = 40;
            default:        coin_value = 0;
        endcase

        case(dut_change)
            3'b000:        change_value = 0;  // Return 0¢  (20¢ - 20¢)
            3'b001:        change_value = 5;  // Return 5¢  (25¢ - 20¢)
            3'b010:        change_value = 10; // Return 10¢ (30¢ - 20¢)
            3'b011:        change_value = 15; // Return 15¢ (35¢ - 20¢)
            3'b100:        change_value = 20; // Return 20¢ (20¢ - 20¢)
            default:       change_value = 0;
        endcase
end










task static tsk_insert_nickle();
    begin
        tb_nickle = 1'b1;
        @(posedge clk);
        tb_nickle = 1'b0;
    end
endtask


task static tsk_insert_dime();
    begin
        tb_dime = 1'b1;
        @(posedge clk);
        tb_dime = 1'b0;
    end
endtask


task static tsk_insert_quarter();
    begin
        tb_quarter = 1'b1;
        @(posedge clk);
        tb_quarter = 1'b0;
    end
endtask



task static tsk_insert_all(
    input  logic insert_nickle      ,
    input  logic insert_dime        ,
    input  logic insert_quarter
);
    begin
        tb_nickle  = insert_nickle;
        tb_dime    = insert_dime;
        tb_quarter = insert_quarter;

        @(posedge clk);

        tb_nickle  = 1'b0;
        tb_dime    = 1'b0;
        tb_quarter = 1'b0;
    end
endtask














// Test 1: Insert multiple Nickle
task static test_1();
    begin
        for (int i = 0; i < 10; i++) begin
            tsk_insert_nickle();
        end
    end
endtask


// Test 2: Insert multiple Dime
task static test_2();
    begin
        for (int i = 0; i < 10; i++) begin
            tsk_insert_dime();
        end
    end
endtask



// Test 3: Insert multiple Quarter
task static test_3();
    begin
        for (int i = 0; i < 5; i++) begin
            tsk_insert_quarter();
        end
    end
endtask





// Test 4: 15¢ in Nickle + 10¢ in Dime
task static test_4();
    begin
        // Insert 15¢ (3 Nickles)
        tsk_insert_nickle();
        tsk_insert_nickle();
        tsk_insert_nickle();
        // Insert Dime
        tsk_insert_dime();
    end
endtask



// Test 5: 15¢ in Nickle + 25¢ in Quarter
task static test_5();
    begin
        // Insert 15¢ (3 Nickles)
        tsk_insert_nickle();
        tsk_insert_nickle();
        tsk_insert_nickle();
        // Insert Quarter
        tsk_insert_quarter();
    end
endtask







// Test 6: 15¢ in Nickle and Dime + 5¢ in Nickle
task static test_6();
    begin
        // Insert 15¢ (Nickle, then Dime)
        tsk_insert_nickle();
        tsk_insert_dime();
        // Insert Nickle
        tsk_insert_nickle();
    end
endtask


// Test 7: 15¢ in Nickle and Dime + 10¢ in Dime
task static test_7();
    begin
        // Insert 15¢ (Nickle, then Dime)
        tsk_insert_nickle();
        tsk_insert_dime();
        // Insert Dime
        tsk_insert_dime();
    end
endtask


// Test 8: 15¢ in Nickle and Dime + 25¢ in Quarter
task static test_8();
    begin
        // Insert 15¢ (Nickle, then Dime)
        tsk_insert_nickle();
        tsk_insert_dime();
        // Insert Nickle
        tsk_insert_quarter();
    end
endtask





// Test 9: 15¢ in Dime and Nickle + 5¢ in Nickle
task static test_9();
    begin
        // Insert 15¢ (Dime, then Nickle)
        tsk_insert_dime();
        tsk_insert_nickle();
        // Insert Nickle
        tsk_insert_nickle();
    end
endtask


// Test 10: 15¢ in Dime and Nickle  + 10¢ in Dime
task static test_10();
    begin
        // Insert 15¢ (Dime, then Nickle)
        tsk_insert_dime();
        tsk_insert_nickle();
        // Insert Dime
        tsk_insert_dime();
    end
endtask


// Test 11: 15¢ in Dime and Nickle  + 25¢ in Quarter
task static test_11();
    begin
        // Insert 15¢ (Dime, then Nickle)
        tsk_insert_dime();
        tsk_insert_nickle();
        // Insert Nickle
        tsk_insert_quarter();
    end
endtask




// Test 12: ALl coin insert
task static test_12();
    begin
        for(int i = 0; i < 5; i++) begin
            tsk_insert_all(1'b1, 1'b1, 1'b1); // Insert all coin
        end
    end
endtask


// Test 13: Insert both Nickle and Dime
task static test_13();
    begin
        for(int i = 0; i < 5; i++) begin
            tsk_insert_all(1'b1, 1'b1, 1'b0); // Insert both Nickle and Dime
        end
    end
endtask

// Test 14:  // Insert both Nickle and Quarter
task static test_14();
    begin
        for(int i = 0; i < 5; i++) begin
            tsk_insert_all(1'b1, 1'b0, 1'b1); // Insert both Nickle and Quarter
        end
    end
endtask


// Test 15: // Insert both Dime and Quarter
task static test_15();
    begin
        for(int i = 0; i < 5; i++) begin
            tsk_insert_all(1'b0, 1'b1, 1'b1); // Insert both Dime and Quarter
        end
    end
endtask

















endmodule








