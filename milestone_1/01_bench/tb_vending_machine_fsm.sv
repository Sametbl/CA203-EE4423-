`define CLK_DUR 2
`define RST_DUR 10
`define RUNTIME (`CLK_DUR * 1_000)
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





task tsk_insert_nickle();
    begin
        tb_nickle = 1'b1;
        @(posedge clk);
        tb_nickle = 1'b0;
    end
endtask


task tsk_insert_dime();
    begin
        tb_dime = 1'b1;
        @(posedge clk);
        tb_dime = 1'b0;
    end
endtask


task tsk_insert_quarter();
    begin
        tb_quarter = 1'b1;
        @(posedge clk);
        tb_quarter = 1'b0;
    end
endtask



task tsk_insert_all(
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
task test_1();
    begin
        for (int i = 0; i < 10; i++) begin
            tsk_insert_nickle();
        end
    end
endtask


// Test 2: Insert multiple Dime
task test_2();
    begin
        for (int i = 0; i < 10; i++) begin
            tsk_insert_dime();
        end
    end
endtask



// Test 3: Insert multiple Quarter
task test_3();
    begin
        for (int i = 0; i < 5; i++) begin
            tsk_insert_quarter();
        end
    end
endtask





// Test 4: 15¢ in Nickle + 10¢ in Dime
task test_4();
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
task test_5();
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
task test_6();
    begin
        // Insert 15¢ (Nickle, then Dime)
        tsk_insert_nickle();
        tsk_insert_dime();
        // Insert Nickle
        tsk_insert_nickle();
    end
endtask


// Test 7: 15¢ in Nickle and Dime + 10¢ in Dime
task test_7();
    begin
        // Insert 15¢ (Nickle, then Dime)
        tsk_insert_nickle();
        tsk_insert_dime();
        // Insert Dime
        tsk_insert_dime();
    end
endtask


// Test 8: 15¢ in Nickle and Dime + 25¢ in Quarter
task test_8();
    begin
        // Insert 15¢ (Nickle, then Dime)
        tsk_insert_nickle();
        tsk_insert_dime();
        // Insert Nickle
        tsk_insert_quarter();
    end
endtask





// Test 9: 15¢ in Dime and Nickle + 5¢ in Nickle
task test_9();
    begin
        // Insert 15¢ (Dime, then Nickle)
        tsk_insert_dime();
        tsk_insert_nickle();
        // Insert Nickle
        tsk_insert_nickle();
    end
endtask


// Test 10: 15¢ in Dime and Nickle  + 10¢ in Dime
task test_10();
    begin
        // Insert 15¢ (Dime, then Nickle)
        tsk_insert_dime();
        tsk_insert_nickle();
        // Insert Dime
        tsk_insert_dime();
    end
endtask


// Test 11: 15¢ in Dime and Nickle  + 25¢ in Quarter
task test_11();
    begin
        // Insert 15¢ (Dime, then Nickle)
        tsk_insert_dime();
        tsk_insert_nickle();
        // Insert Nickle
        tsk_insert_quarter();
    end
endtask




// Test 12: ALl coin insert
task test_12();
    begin
        for(int i = 0; i < 5; i++) begin
            tsk_insert_all(1'b1, 1'b1, 1'b1); // Insert all coin
        end
    end
endtask


// Test 13: Insert both Nickle and Dime
task test_13();
    begin
        for(int i = 0; i < 5; i++) begin
            tsk_insert_all(1'b1, 1'b1, 1'b0); // Insert both Nickle and Dime
        end
    end
endtask

// Test 14:  // Insert both Nickle and Quarter
task test_14();
    begin
        for(int i = 0; i < 5; i++) begin
            tsk_insert_all(1'b1, 1'b0, 1'b1); // Insert both Nickle and Quarter
        end
    end
endtask


// Test 15: // Insert both Dime and Quarter
task test_15();
    begin
        for(int i = 0; i < 5; i++) begin
            tsk_insert_all(1'b0, 1'b1, 1'b1); // Insert both Dime and Quarter
        end
    end
endtask

















endmodule








