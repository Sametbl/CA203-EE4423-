// ----------------
// Author: wonk.ptn
// ----------------

module tb_icache_model
    #(
    parameter string PROGRAMFILE = "",
    parameter int    SIZE        = 2**17
    ) (
    input  logic i_clk          ,
    input  logic i_rstn         ,

    output logic        o_ready ,
    input  logic        i_valid ,
    input  logic [31:0] i_addr  ,
    input  logic [ 7:0] i_bmsk  ,

    input  logic        i_ready ,
    output logic        o_valid ,
    output logic [63:0] o_data  //
    );

    typedef enum logic [1:0] {
        IDLE  = 2'h0,
        STDBY = 2'h1,
        ACK   = 2'h2
    } state_e;

    state_e              crn_st;
    state_e              nxt_st;
    logic   [71:0] ascii_crn_st;
    logic   [71:0] ascii_nxt_st;

    logic [ 7:0] cache_mem_model [SIZE];
    logic [31:0] mem_addr;
    logic [ 7:0] mem_bmsk;

    logic [31:0] addr_d, addr_q;
    logic [ 7:0] bmsk_d, bmsk_q;
    logic [63:0] data_d, data_q;
    logic [ 2:0]  cnt_d,  cnt_q;

    logic [31:0] insr0_data_d;
    logic [31:0] insr1_data_d;
    logic [31:0] insr0_data_q;
    logic [31:0] insr1_data_q;

    initial $readmemh(PROGRAMFILE, cache_mem_model);

    always_ff @(posedge i_clk or negedge i_rstn) begin : proc_st_update
        if (!i_rstn) begin crn_st <=   IDLE; end
        else         begin crn_st <= nxt_st; end
    end: proc_st_update

    always_ff @(posedge i_clk or negedge i_rstn) begin: proc_logic_update
        if (!i_rstn) begin
            addr_q <= {32{1'b0}};
            bmsk_q <= { 8{1'b0}};
            data_q <= {64{1'b0}};
            cnt_q  <= { 3{1'b0}};
        end else begin
            addr_q <= addr_d;
            bmsk_q <= bmsk_d;
            data_q <= data_d;
            cnt_q  <=  cnt_d;
        end
    end: proc_logic_update

    always_comb begin: b_get_nxt_st
        case (crn_st)
            IDLE : nxt_st = (i_valid) ? ((cnt_d==3'h0) ? ACK : STDBY) : IDLE;
            STDBY: nxt_st = (cnt_d==3'h0) ? ACK : STDBY;
            ACK  : nxt_st = (i_ready) ? ((i_valid) ? ((cnt_d==3'h0) ? ACK : STDBY) : IDLE) : ACK;
            default : nxt_st = IDLE;
        endcase
    end: b_get_nxt_st

    always_comb begin
        cnt_d    = (((crn_st==IDLE) & i_valid) | ((crn_st==ACK) & i_valid & i_ready)) ?
                    3'h0                                                              :
                    (crn_st==STDBY) ? cnt_q - 3'h1 : cnt_q                            ;
        addr_d   = ((crn_st==IDLE ) | (crn_st==ACK) & i_valid & i_ready) ? i_addr : addr_q;
        bmsk_d   = ((crn_st==IDLE ) | (crn_st==ACK) & i_valid & i_ready) ? i_bmsk : bmsk_q;
        mem_addr =  (crn_st==IDLE & i_valid & cnt_d==3'h0 |
                     crn_st==ACK  & i_valid & i_ready     ) ? i_addr : addr_q;
        mem_bmsk =  (crn_st==IDLE & i_valid & cnt_d==3'h0 |
                     crn_st==ACK  & i_valid & i_ready     ) ? i_bmsk : bmsk_q;

        if (crn_st==IDLE  & cnt_d==3'h0 & i_valid           |
            crn_st==STDBY & cnt_d==3'h0                     |
            crn_st==ACK   & cnt_d==3'h0 & i_valid & i_ready
        ) begin
            data_d[63:56] = (mem_bmsk[7]) ? cache_mem_model[mem_addr + 7] : 8'h00;
            data_d[55:48] = (mem_bmsk[6]) ? cache_mem_model[mem_addr + 6] : 8'h00;
            data_d[47:40] = (mem_bmsk[5]) ? cache_mem_model[mem_addr + 5] : 8'h00;
            data_d[39:32] = (mem_bmsk[4]) ? cache_mem_model[mem_addr + 4] : 8'h00;
            data_d[31:24] = (mem_bmsk[3]) ? cache_mem_model[mem_addr + 3] : 8'h00;
            data_d[23:16] = (mem_bmsk[2]) ? cache_mem_model[mem_addr + 2] : 8'h00;
            data_d[15: 8] = (mem_bmsk[1]) ? cache_mem_model[mem_addr + 1] : 8'h00;
            data_d[ 7: 0] = (mem_bmsk[0]) ? cache_mem_model[mem_addr    ] : 8'h00;
        end else begin
            data_d = data_q;
        end

        case (crn_st)
            2'h0    : ascii_crn_st = "IDLE     ";
            2'h1    : ascii_crn_st = "STDBY    ";
            2'h2    : ascii_crn_st = "ACK      ";
            default : ascii_crn_st = "UNDEFINED";
        endcase

        case (nxt_st)
            2'h0    : ascii_nxt_st = "IDLE     ";
            2'h1    : ascii_nxt_st = "STDBY    ";
            2'h2    : ascii_nxt_st = "ACK      ";
            default : ascii_nxt_st = "UNDEFINED";
        endcase
    end

    assign insr1_data_d = data_d[63:32];
    assign insr0_data_d = data_d[31: 0];

    assign insr1_data_q = data_q[63:32];
    assign insr0_data_q = data_q[31: 0];

    assign o_data =  data_q;
    assign o_valid = (crn_st==ACK) ? i_rstn : 1'b0;
    assign o_ready = (crn_st==IDLE) ? i_rstn : ((crn_st==ACK) ? i_ready : 1'b0);

    // property out_hndshk;
    //     @(posedge i_clk) disable iff (!i_rstn)
    //     (o_valid) |-> (o_valid)[*0:$] ##1 i_ready;
    // endproperty

    // property hndshk;
    //     @(posedge i_clk) disable iff (!i_rstn)
    //     (o_ready && i_valid)
    //     |-> ##1 (o_valid)
    //     |-> (o_valid)[*0:$] ##1 i_ready;
    // endproperty

    // OutHandShakeCheck: assert property (out_hndshk) else $error();
    // HandShakeCheck   : assert property (hndshk    ) else $error();

endmodule: tb_icache_model
