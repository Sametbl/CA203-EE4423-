`define CLK_DUR 2
`define RST_DUR 10
`define RUNTIME (`CLK_DUR * 20_000)
`define TIMEOUT (`RST_DUR + `RUNTIME)

// `define WAVE
// `define REGFILE_LOG
// `define MEMORY_LOG
// `define DISPLAY_PROGRESS
`define ENABLE_TIMEOUT
`define ZERO_TIMER

// `define SET_DUMP
`define START_DUMP 30_000
`define END_DUMP   100_000

// `define NO_PREDICTION

module tb_core;

import ansi_pkg::*;
import pipeline_pkg::*;

/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHTRUNC  */

localparam int IMEM_SIZE = 18;
localparam int DMEM_SIZE = 18;


localparam int HALT_ADDR     = 32'h8FFF_FFF0;
localparam int HALT_DATA     = 32'h0000_00AA;
localparam int CYCLE_LO_ADDR = 32'h8000_0000;
localparam int CYCLE_HI_ADDR = 32'h8000_0004;
localparam int UART_TX_ADDR  = 32'h7000_0000;
localparam int TICK_CNT_ADDR = 32'h6000_0000;

reg clk;
reg rstn;

// Count
longint clk_cnt      = -(`RST_DUR);
longint timer        = 0;
int fd;

// Instruction
int alu_instr_cnt    = 0;
int bru_instr_cnt    = 0;
int lsu_instr_cnt    = 0;
int mul_instr_cnt    = 0;
int div_instr_cnt    = 0;




// Hazard
int br_miss_cnt  = 0;
int wb_stall_cnt = 0;
int hzdstall_cnt = 0;
int hzd_wait_lsu = 0;
int hzd_wait_mul = 0;
int hzd_wait_div = 0;
int hzd_raw_lsu  = 0;
int hzd_raw_mul  = 0;
int hzd_raw_div  = 0;
int hzd_waw_lsu  = 0;
int hzd_waw_mul  = 0;
int hzd_waw_div  = 0;
int target_mismatch = 0;

int   total_executed_instr = 0;
real  ipc                  = 0;
real  percent              = 0;


// Wiring
int dmem_fd; // File descriptor
reg [31:0] end_ptr_addr;

reg [63:0] imem_data;
reg [31:0] imem_addr;
reg [7:0]  imem_bytemask;
reg        imem_valid_input;
reg        imem_ready_input;
reg        imem_valid_output;
reg        imem_ready_output;

reg [31:0] dmem_rdata_mem; // Read data from Data memory
reg        dmem_valid_mem; // Data memory acknownledge
reg        dmem_ready_mem; // Data memory is ready to receive request

reg [31:0] lsu_addr;   // Address for Load/Store operation
reg [31:0] lsu_wdata;  // Data for Store address
reg [3:0]  lsu_bmsk;   // Bytemask for Load/Store operation
reg        lsu_wren;   // Write enable for Store operation
reg        lsu_valid;  // Request signal to Data memory
reg        lsu_ready;  // Indicate LSU is ready to receive data


// From testbench task
reg [31:0]  dmem_rdata; //
reg         dmem_valid; //
reg         dmem_ready; //

reg [31:0]  dmem_rdata_tsk;
reg         dmem_valid_tsk;
reg         dmem_ready_tsk;

reg [7:0]   uart_char[1024];
int         uart_char_index = 0;

logic       dmem_region_sel;
logic [2:0] dmem_tsk_sel;

logic [31:0]  lsu_masked_wdata;
logic [31:0]  lsu_masked_rdata;
logic [31:0]  reg_halt_data;
logic [31:0]  reg_clock_low_data;
logic [31:0]  reg_clock_high_data;
logic [31:0]  reg_uart_data;
logic [31:0]  reg_tick_cnt_data;



`ifdef FSDB  localparam string ProgrmaFile = "./../../../01_mars_core/01_bench/tb_program/mem.dump";
`else        localparam string ProgrmaFile = "./../../../01_mars_core/01_bench/tb_program/mem.dump";
`endif

// `ifdef FSDB  localparam string ProgrmaFile = "./../../01_bench/tb_program/C/build/coremark_1b.hex";
// `else        localparam string ProgrmaFile = "./../../01_bench/tb_program/C/build/coremark_1b.hex";
// `endif

// `ifdef FSDB  localparam string ProgrmaFile = "./../../01_bench/tb_program/branch/branch.hex";
// `else        localparam string ProgrmaFile = "./../../01_bench/tb_program/branch/branch.hex";
// `endif

assign imem_bytemask[7:4] = 4'b0000;


tb_icache_model #(.PROGRAMFILE(ProgrmaFile),
                  .SIZE(2**IMEM_SIZE)  )   imem  (
    .i_clk   (clk                ),
    .i_rstn  (rstn               ),
    .i_addr  (imem_addr          ),
    .i_bmsk  (imem_bytemask      ),
    .i_ready (imem_ready_input   ),
    .i_valid (imem_valid_input   ),
    .o_ready (imem_ready_output  ),
    .o_valid (imem_valid_output  ),
    .o_data  (imem_data          )
);


tb_dcache_model #(.PROGRAMFILE(ProgrmaFile),
                  .SIZE(2**DMEM_SIZE)) dmem
(
    .i_clk    (clk                         ),
    .i_rstn   (rstn                        ),
    .i_addr   (lsu_addr                    ),
    .i_bmsk   (lsu_bmsk                    ),
    .i_wren   (lsu_wren                    ),

    .i_data   (lsu_wdata                   ),
    .i_valid  (lsu_valid & ~dmem_region_sel),
    .i_ready  (lsu_ready                   ),
    .o_valid  (dmem_valid_mem              ),
    .o_ready  (dmem_ready_mem              ),
    .o_data   (dmem_rdata_mem              )
);

processor   dut(
    .i_clk            (clk                  ),
    .i_rstn           (rstn                 ),
    // Instruction memory interface
    .i_imem_data      (imem_data[31:0]      ),
    .i_imem_valid     (imem_valid_output    ), // High if instruction refill has completed
    .i_imem_ready     (imem_ready_output    ), // High if I-cahce is ready to accept new request
    .o_imem_addr      (imem_addr            ), // The PC value
    .o_imem_bytemask  (imem_bytemask[3:0]   ), // Hardwired to 4'b1111
    .o_imem_valid     (imem_valid_input     ), // Asserted to initiate a refill/fetch request
    .o_imem_ready     (imem_ready_input     ),
    // Data memory interface
    .i_dmem_rdata     (dmem_rdata           ), // Read data from Data memory
    .i_dmem_valid     (dmem_valid           ), // Data memory acknownledge
    .i_dmem_ready     (dmem_ready           ), // Data memory is ready to receive request
    .o_lsu_addr       (lsu_addr             ), // Address for Load/Store operation
    .o_lsu_wdata      (lsu_wdata            ), // Data for Store address
    .o_lsu_bmsk       (lsu_bmsk             ), // Bytemask for Load/Store operation
    .o_lsu_wren       (lsu_wren             ), // Write enable for Store operation
    .o_lsu_valid      (lsu_valid            ), // Request signal to Data memory
    .o_lsu_ready      (lsu_ready            )  // Indicate LSU is ready to receive data
);

`ifdef WAVE

    `ifdef FSDB
        initial begin : dumpfile
            $fsdbDumpfile("wave.fsdb");
            $fsdbDumpvars(0, tb_core);
            // $fsdbDumpvars(0, dut, "+all");
            // $fsdbDumpvars(0, dmem, "+mda+packedOnly");

            `ifdef SET_DUMP
                $fsdbDumpoff;   // Turn dump off immediately so file is small

                #(`START_DUMP);
                $fsdbDumpon;     // start recording

                #(`END_DUMP);
                $fsdbDumpoff;    // stop recording
                $display("Stopped ! Finish dumpfile");
                $finish;
            `endif

        end
    `else
        initial begin : dumpfile
            $dumpfile("wave.vcd");
            $dumpvars(0, tb_core);
            $dumpvars(1, dut);

            `ifdef SET_DUMP
                $dumpoff;   // Turn dump off immediately so file is small

                #(`START_DUMP);
                $dumpon;     // start recording

                #(`END_DUMP);
                $dumpoff;    // stop recording
            `endif

        end
    `endif

`endif


initial tsk_clk_gen       (clk, `CLK_DUR);
initial tsk_rstn_gen      (rstn, `RST_DUR);
initial tsk_halt_sim      ();
initial tsk_instr_count   ();
initial tsk_timer         ();
initial tsk_deadend_detect();
`ifdef ENABLE_TIMEOUT
    initial tsk_timeout(`RUNTIME);
`endif
// initial tsk_uart_terminal();

always @(posedge clk) begin
    total_executed_instr <= (alu_instr_cnt + bru_instr_cnt) + (lsu_instr_cnt + mul_instr_cnt + div_instr_cnt);
end


always_comb begin
    dmem_region_sel  = |(lsu_addr[31:DMEM_SIZE]);   //
    lsu_masked_wdata[7:0  ] = lsu_wdata[7:0  ] & {8{lsu_bmsk[0]}};
    lsu_masked_wdata[15:8 ] = lsu_wdata[15:8 ] & {8{lsu_bmsk[1]}};
    lsu_masked_wdata[23:16] = lsu_wdata[23:16] & {8{lsu_bmsk[2]}};
    lsu_masked_wdata[31:24] = lsu_wdata[31:24] & {8{lsu_bmsk[3]}};

    dmem_valid_tsk   = 1'b1;
    dmem_ready_tsk   = 1'b1;

    reg_clock_low_data  = timer[31:0 ];
    reg_clock_high_data = timer[63:32];

    if      (lsu_addr == HALT_ADDR    )   dmem_tsk_sel = 3'b001;
    else if (lsu_addr == CYCLE_LO_ADDR)   dmem_tsk_sel = 3'b010;
    else if (lsu_addr == CYCLE_HI_ADDR)   dmem_tsk_sel = 3'b011;
    else if (lsu_addr == UART_TX_ADDR )   dmem_tsk_sel = 3'b100;
    else                                  dmem_tsk_sel = 3'b000;

    case(dmem_tsk_sel)
        3'b000:     dmem_rdata_tsk = 32'h0000_0000;
        3'b001:     dmem_rdata_tsk = reg_halt_data;
    `ifdef ZERO_TIMER
        3'b010:     dmem_rdata_tsk = 32'h0000_0000;
        3'b011:     dmem_rdata_tsk = 32'h0000_0000;
    `else
        3'b010:     dmem_rdata_tsk = reg_clock_low_data;
        3'b011:     dmem_rdata_tsk = reg_clock_high_data;
    `endif
        3'b100:     dmem_rdata_tsk = reg_uart_data;
        default:    dmem_rdata_tsk = 32'h0000_0000;
    endcase

    dmem_rdata = (dmem_region_sel == 1'b1) ? dmem_rdata_tsk : dmem_rdata_mem;
    dmem_valid = (dmem_region_sel == 1'b1) ? dmem_valid_tsk : dmem_valid_mem;
    dmem_ready = (dmem_region_sel == 1'b1) ? dmem_ready_tsk : dmem_ready_mem;
end


reg [31:0] total_executed_instr_reg;
int        dead_time  = 0;
int        stall_time = 0;

task automatic tsk_deadend_detect(); begin
    forever @(posedge clk) begin
        if (total_executed_instr_reg == total_executed_instr) begin
            dead_time <= dead_time + 1;
            if (dead_time == 1000) begin
                $display("\n\nERROR: Simulation stopped, program STUCKED indefinitely !\n\n");
                $finish;
            end
        end
        else begin
            dead_time <= 0;
            total_executed_instr_reg <= total_executed_instr;
        end

        if(dut.hazard_detection_unit.o_stall) stall_time <= stall_time + 1;
        else                                  stall_time <= 0;

        if (stall_time == 1000) begin
            $display("\n\nERROR: Simulation stopped, program STALLED indefinitely !\n\n");
            $finish;
        end
    end
end
endtask



task automatic tsk_uart_terminal();
    $display("\n\n");
    forever @(posedge clk) begin
        if (lsu_wren && lsu_valid && (lsu_addr == UART_TX_ADDR  )) begin
            $write("%c", lsu_masked_wdata[7:0]);
        end
end
endtask


task automatic tsk_halt_sim (); begin
        forever @(posedge clk) begin
            if (reg_halt_data == HALT_DATA) begin
                $display("\n\n\n");
                $display("Return value         = %0d\n", reg_halt_data);
                $display("Execution time ticks = %0d\n", reg_tick_cnt_data);
                $write  ("Uart string sent:\n\n");
                for (int i = 0; i < 1024; i++) begin
                    $write("%c", uart_char[i]);
                end
                $display("\n\n\n");
                $finish();
            end
        end
    end
endtask: tsk_halt_sim



logic wait_for_lsu;    // LSU is not available for the next Load/Store instruction
logic wait_for_mul;    // MUL is not available for the next MUL instruction
logic wait_for_div;    // DIV is not available for the next DIV instruction

logic raw_depend_lsu;  // RAW dependency on result from currently executing Load operation
logic raw_depend_mul;  // RAW dependency on result from currently executing MUL operation
logic raw_depend_div;  // RAW dependency on result from currently executing DIV operation

// LSU, MUL, DIV required many cycles to complete
// While executing there may some instruction with same Destination address complete first (WAW)

logic waw_lsu;
logic waw_mul;
logic waw_div;


task automatic tsk_instr_count();
    begin
        forever @(posedge clk) begin
            clk_cnt <= (clk_cnt + 1);
            if (dut.branch_miss                         )   br_miss_cnt    <= br_miss_cnt  + 1;
            if (dut.stall_from_wb                       )   wb_stall_cnt   <= wb_stall_cnt + 1;
            if (dut.hazard_detection_unit.o_stall       )   hzdstall_cnt   <= hzdstall_cnt + 1;
            if (dut.hazard_detection_unit.wait_for_lsu  )   hzd_wait_lsu   <= hzd_wait_lsu + 1;
            if (dut.hazard_detection_unit.wait_for_mul  )   hzd_wait_mul   <= hzd_wait_mul + 1;
            if (dut.hazard_detection_unit.wait_for_div  )   hzd_wait_div   <= hzd_wait_div + 1;
            if (dut.hazard_detection_unit.raw_depend_lsu)   hzd_raw_lsu    <= hzd_raw_lsu  + 1;
            if (dut.hazard_detection_unit.raw_depend_mul)   hzd_raw_mul    <= hzd_raw_mul  + 1;
            if (dut.hazard_detection_unit.raw_depend_div)   hzd_raw_div    <= hzd_raw_div  + 1;
            if (dut.hazard_detection_unit.waw_lsu       )   hzd_waw_lsu    <= hzd_waw_lsu  + 1;
            if (dut.hazard_detection_unit.waw_mul       )   hzd_waw_mul    <= hzd_waw_mul  + 1;
            if (dut.hazard_detection_unit.waw_div       )   hzd_waw_div    <= hzd_waw_div  + 1;
            if (dut.execute_bru.br_mispredict_target    )   target_mismatch  <= target_mismatch + 1;

            if (dut.execute_alu.valid)                                      alu_instr_cnt <= alu_instr_cnt + 1;
            if (dut.execute_bru.valid)                                      bru_instr_cnt <= bru_instr_cnt + 1;
            if (dut.execute_lsu.i_dmem_valid)                               lsu_instr_cnt <= lsu_instr_cnt + 1;
            if (dut.execute_mul.REQUEST_stage && dut.execute_mul.i_wb_ack)  mul_instr_cnt <= mul_instr_cnt + 1;
            if (dut.execute_div.REQUEST_stage && dut.execute_div.i_wb_ack)  div_instr_cnt <= div_instr_cnt + 1;
        end
    end

endtask


`ifdef DISPLAY_PROGRESS

task automatic tsk_progress();
    begin
        $write("\033[?25l"); // hide cursor
        for (int i = 0; i <30; i++) $write("\n");

        forever @(posedge clk) begin

            ipc     = real'(total_executed_instr) / real'(clk_cnt);
            percent = (real'(clk_cnt*2) / real'(`RUNTIME)) * 100.0;

            $write("\033[23A");   // Jump cursor back 22 lines
            $write("Number of branch misprediction            = %0d\n", br_miss_cnt    );
            $write("Number of predicted target mismatch       = %0d\n", target_mismatch);
            $write("Number of stall from writeback            = %0d\n", wb_stall_cnt   );
            $write("Number of stall by Hazard Detection Unit  = %0d\n", hzdstall_cnt   );
            $write("Number of stall cycles waiting LSU        = %0d\n", hzd_wait_lsu   );
            $write("Number of stall cycles waiting MUL        = %0d\n", hzd_wait_mul   );
            $write("Number of stall cycles waiting DIV        = %0d\n", hzd_wait_div   );
            $write("Number of stall cycles resolve RAW by LSU = %0d\n", hzd_raw_lsu   );
            $write("Number of stall cycles resolve RAW by MUL = %0d\n", hzd_raw_mul   );
            $write("Number of stall cycles resolve RAW by DIV = %0d\n", hzd_raw_div   );
            $write("Number of WAW occurence in LSU            = %0d\n", hzd_waw_lsu   );
            $write("Number of WAW occurence in MUL            = %0d\n", hzd_waw_mul   );
            $write("Number of WAW occurence in DIV            = %0d\n", hzd_waw_div   );

            $write("Number of instructions use ALU            = %0d\n", alu_instr_cnt);
            $write("Number of instructions use BRU            = %0d\n", bru_instr_cnt);
            $write("Number of instructions use LSU            = %0d\n", lsu_instr_cnt);
            $write("Number of instructions use MUL            = %0d\n", mul_instr_cnt);
            $write("Number of instructions use DIV            = %0d\n", div_instr_cnt);

            $write("Total execution cycles                    = %0d\n", clk_cnt);
            $write("Total Instruction executed                = %0d\n", total_executed_instr);
            $write("The Instruction per Cycle (IPC)           = %f\n" , ipc);
            $write("Timeout Process: %0.1f%%\n\n", percent);

        end
    end
endtask


initial tsk_progress();

`endif


task automatic tsk_timer ();
    fd = $fopen("uart.txt", "w");
    $fwrite(fd, "");
    $fclose(fd);

    forever @(posedge clk) begin
        if(!rstn) begin
            reg_halt_data      <= 32'h0000_0000;
            reg_tick_cnt_data  <= 32'h0000_0000;
            reg_uart_data      <= 32'h0000_0000;
        end
        else begin
            if      (lsu_wren && lsu_valid && (lsu_addr == HALT_ADDR     )) reg_halt_data     <= lsu_masked_wdata;
            if      (lsu_wren && lsu_valid && (lsu_addr == TICK_CNT_ADDR )) reg_tick_cnt_data <= lsu_masked_wdata;
            else if (lsu_wren && lsu_valid && (lsu_addr == UART_TX_ADDR  )) begin
                reg_uart_data              <= lsu_masked_wdata;
                uart_char[uart_char_index] <= lsu_masked_wdata[7:0];
                uart_char_index            <= uart_char_index + 1;
                fd = $fopen("uart.txt", "a");
                $fwrite(fd, "%c", lsu_masked_wdata[7:0]);
                $fclose(fd);
            end

            timer      <= timer + {{63{1'b0}}, 1'b1};
        end
end
endtask






integer fd_regfile[32];
string  regfile_name;
// alias
logic        regfile_w_valid;
logic [31:0] regfile_rd_addr;
logic [31:0] regfile_rd_data;
logic [31:0] regfile_current_pc;
logic [31:0] regfile_prev_val[32];   // store previous values

assign regfile_rd_data = (dut.int_regfile.rd_data);
assign regfile_rd_addr = {27'h000_0000, dut.int_regfile.rd_addr};
assign regfile_w_valid = (dut.int_regfile.wren) | (dut.int_regfile.valid) | (dut.int_regfile.rd_is_int);
assign regfile_current_pc = dut.int_regfile.db_pc;

`ifdef REGFILE_LOG
    task automatic tsk_regfile_monitor(); begin
        // open DUT logs
        for (int i = 0; i < 32; i++) begin
            regfile_name   = $sformatf("regfile_log/reg%0d.log", i);
            fd_regfile[i]  = $fopen(regfile_name, "w");

            if (!fd_regfile[i])     $display("\nERROR: Cannot open %s",  regfile_name);
            // else                    $display("\nSucceeded open file %s", regfile_name);

            regfile_prev_val[i] = 32'hFFFF_FFFF; // init old values
            $fclose(fd_regfile[i]);
        end

        // monitor writes
        forever @(posedge clk) begin
            if (regfile_w_valid) begin
                int idx;
                idx = regfile_rd_addr[4:0];
                regfile_name = $sformatf("regfile_log/reg%0d.log", idx);

                if (!fd_regfile[idx]) begin
                    $display("ERROR: Cannot open %s", regfile_name);
                end
                // else if (regfile_prev_val[idx] != regfile_rd_data)   begin
                else begin
                    fd_regfile[idx]  = $fopen(regfile_name, "a");
                    $fwrite(fd_regfile[idx], "%0t %08h %08h\n", $time, regfile_rd_data, regfile_current_pc);
                    $fclose(fd_regfile[idx]);
                    regfile_prev_val[idx] = regfile_rd_data;

                end
            end

        end

    end
    endtask

initial tsk_regfile_monitor();

`endif

`ifdef MEMORY_LOG
    int mem_log_f = 0;

    task automatic tsk_lsu_store_log(); begin

        // Clear log file
        mem_log_f = $fopen("core_memory.log", "w");
        $fwrite(mem_log_f, "");
        $fclose(mem_log_f);

        forever @(posedge clk) begin
            if (lsu_wren && lsu_valid) begin
                    mem_log_f = $fopen("core_memory.log", "a");

                    $fwrite(mem_log_f, "STORE\t %08x %08x %08x %0t\n", lsu_masked_wdata, lsu_addr, dut.execute_lsu.db_pc, $time());

                    $fclose(mem_log_f);
            end

            if (dut.execute_lsu.LOAD_stage && dut.execute_lsu.i_dmem_valid && dut.execute_lsu.i_wb_ack) begin
                    mem_log_f = $fopen("core_memory.log", "a");

                    $fwrite(mem_log_f, "LOAD\t %08x %08x %08x %0t\n", dut.execute_lsu.masked_rdata, lsu_addr, dut.execute_lsu.db_pc, $time());

                    $fclose(mem_log_f);
            end
        end
    end
    endtask

    initial tsk_lsu_store_log();

`endif


















`ifdef RAS_CHECK
    int fd_ras   = 0;
    int call_cnt = 0;
    int ret_cnt  = 0;

    reg        ras_pop_q;

    reg        ras_push;
    reg        ras_pop;
    reg [31:0] ras_push_data;
    reg [31:0] ras_pop_data;

    reg [31:0] ras_push_pc;
    reg [31:0] ras_pop_pc;

    assign ras_push_pc = dut.execute_bru.pc;
    assign ras_pop_pc  = dut.execute_bru.pc;
    assign ras_push    = (dut.execute_bru.jal | dut.execute_bru.jalr) &
                        (dut.execute_bru.rd_addr == 5'b00001) & dut.execute_bru.valid;

    assign ras_pop  = (dut.execute_bru.i_abt_bru_pkg.branch_op[6] | dut.execute_bru.i_abt_bru_pkg.branch_op[7]) &
                    (dut.execute_bru.i_abt_bru_pkg.debug_pkg.rs1_addr == 5'b00001) & (dut.execute_bru.i_abt_bru_pkg.valid) &
                    ~(dut.execute_bru.i_abt_bru_pkg.rd_addr == 5'b00001);


    assign ras_push_data = dut.execute_bru.pc_return;


    prim_sync_lifo #(.DEPTH(1024), .WIDTH(32))  tb_ras  (
        .i_clk     (clk          ),
        .i_rstn    (rstn         ),
        .i_clr     (1'b0         ),
        .i_wr_en   (ras_push     ),
        .i_rd_en   (ras_pop      ),
        .i_wr_data (ras_push_data),
        .o_rd_data (ras_pop_data ),
        .o_full    (),
        .o_empty   ()
    );





task automatic tsk_ras_check();
    fd_ras = $fopen("call_ret_log.txt", "w");
    $fwrite(fd_ras, "");
    $fclose(fd);

    forever @(posedge clk) begin

        ras_pop_q <= ras_pop;
        if(ras_push) begin
            call_cnt <= call_cnt + 1;
            fd_ras = $fopen("call_ret_log.txt", "a");
            $fwrite(fd_ras, "Time: %0t\n", $time());
            $fwrite(fd_ras, "CALL   #%0d: Pushed 0x%h -- PC: 0x%h\n\n", call_cnt, ras_push_data, dut.execute_bru.pc);
            $fclose(fd);
        end
        if(ras_pop_q) begin
            ret_cnt <= ret_cnt + 1;
            fd_ras = $fopen("call_ret_log.txt", "a");
            $fwrite(fd_ras, "Time: %0t\n", $time());
            $fwrite(fd_ras, "RETURN #%0d: Expected Popped data = 0x%h -- PC: 0x%h\n",   ret_cnt, ras_pop_data, dut.execute_bru.pc);
            $fwrite(fd_ras, "RETURN #%0d: Actual data          = 0x%h -- PC: 0x%h\n\n", ret_cnt, dut.execute_bru.target, dut.execute_bru.pc);
            $fclose(fd);
        end

    end
endtask

initial tsk_ras_check();

`endif









/* verilator lint_on WIDTHEXPAND */
/* verilator lint_on WIDTHTRUNC  */
endmodule


