task automatic tsk_clk_gen (ref logic clk, input int CLOCK_DURATION);
    begin
        #0 clk = 1'b0;
        forever #(CLOCK_DURATION/2) clk = ~clk;
    end
endtask

task automatic tsk_rstn_gen (ref logic rstn, input int RESET_DURATION);
    begin
        #0 rstn = 1'b0;
        #RESET_DURATION rstn = 1'b1;
    end
endtask

task automatic tsk_timeout (input longint unsigned TIMEOUT);
    begin
        #TIMEOUT $display("\nTest end\n");
        $finish();
    end
endtask
