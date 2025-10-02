
// Task Declaration
task automatic tsk_clk_gen (ref logic clock, input int CLOCK_DURATION);
    begin
        #0 clock = 1'b0;
        forever #(CLOCK_DURATION/2) clock = ~clock;
    end
endtask


task automatic tsk_rstn_gen (ref logic reset_n, input int RESET_DURATION);
    begin
        #0 reset_n = 1'b0;
        #RESET_DURATION reset_n = 1'b1;
    end
endtask

task automatic tsk_timeout (input longint unsigned TIMEOUT);
    begin
        #TIMEOUT $display("\nTest end\n");
        $finish();
    end
endtask


task automatic tsk_latency(ref logic clock, input int DELAY_CYCLE);
    begin
        for (int i = 0; i < DELAY_CYCLE; i++) begin
            @(posedge clock);
        end
    end
endtask

