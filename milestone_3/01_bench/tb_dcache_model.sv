// ----------------
// Author: wonk.ptn
// ----------------

module tb_dcache_model
    #(
    parameter string PROGRAMFILE = "",
    parameter int    SIZE        = 2**17
    ) (
    input  logic i_clk          ,
    input  logic i_rstn         ,

    output logic        o_ready ,
    input  logic        i_valid ,
    input  logic [31:0] i_addr  ,
    input  logic [ 3:0] i_bmsk  ,
    input  logic        i_wren  ,
    input  logic [31:0] i_data  ,

    input  logic        i_ready ,
    output logic        o_valid ,
    output logic [31:0] o_data  //
    );

    /* verilator lint_off WIDTHEXPAND */
    /* verilator lint_off INITIALDLY */
    /* verilator lint_off WIDTHTRUNC */

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
    logic        mem_wren;

    logic        wren_d, wren_q;
    logic [31:0] addr_d, addr_q;
    logic [ 3:0] bmsk_d, bmsk_q;
    logic [31:0] data_d, data_q;
    logic [ 2:0]  cnt_d,  cnt_q;

    logic [31:0] insr0_data_d;
    logic [31:0] insr1_data_d;
    logic [31:0] insr0_data_q;
    logic [31:0] insr1_data_q;


    always_ff @(posedge i_clk or negedge i_rstn) begin : proc_st_update
        if (!i_rstn) begin crn_st <=   IDLE; end
        else         begin crn_st <= nxt_st; end
    end: proc_st_update

    initial begin : proc_cache_mem_update

        if (PROGRAMFILE.len()==0) begin
            for (int i = 0; i < SIZE; i++) begin
                cache_mem_model[i] <= {8{1'b0}};
            end
        end else begin
            $readmemh(PROGRAMFILE, cache_mem_model);
        end

        forever @(posedge i_clk) begin
            if (mem_wren) begin
                cache_mem_model[i_addr + 3] <= (i_bmsk[3]) ? i_data[31:24] : cache_mem_model[i_addr + 3];
                cache_mem_model[i_addr + 2] <= (i_bmsk[2]) ? i_data[23:16] : cache_mem_model[i_addr + 2];
                cache_mem_model[i_addr + 1] <= (i_bmsk[1]) ? i_data[15: 8] : cache_mem_model[i_addr + 1];
                cache_mem_model[i_addr    ] <= (i_bmsk[0]) ? i_data[ 7: 0] : cache_mem_model[i_addr    ];
            end
        end
    end: proc_cache_mem_update

    always_ff @(posedge i_clk or negedge i_rstn) begin: proc_logic_update
        if (!i_rstn) begin
            wren_q <= { 1{1'b0}};
            addr_q <= {32{1'b0}};
            bmsk_q <= { 4{1'b0}};
            data_q <= {32{1'b0}};
            cnt_q  <= { 3{1'b0}};
        end else begin
            wren_q <= wren_d;
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

    always_comb begin : b_brain_rot
        cnt_d    = (((crn_st==IDLE) & i_valid          )|
                    ((crn_st==ACK ) & i_valid & i_ready)) ? $urandom_range(0,0)%(2**3)
                                                          : (crn_st==STDBY) ? cnt_q - 3'h1 : cnt_q;
        wren_d   = ((crn_st==IDLE) | (crn_st==ACK) & i_valid & i_ready) ? i_wren : wren_q;
        addr_d   = ((crn_st==IDLE) | (crn_st==ACK) & i_valid & i_ready) ? i_addr : addr_q;
        bmsk_d   = ((crn_st==IDLE) | (crn_st==ACK) & i_valid & i_ready) ? i_bmsk : bmsk_q;

        mem_wren = ((crn_st==IDLE) & i_valid |
                    (crn_st==ACK ) & i_valid & i_ready     ) ? i_wren : 1'b0  ;
        mem_addr = ((crn_st==IDLE) & i_valid & (cnt_d==3'h0) |
                    (crn_st==ACK ) & i_valid & i_ready     ) ? i_addr : addr_q;
        mem_bmsk = ((crn_st==IDLE) & i_valid & (cnt_d==3'h0) |
                    (crn_st==ACK ) & i_valid & i_ready     ) ? i_bmsk : bmsk_q;

        if (~i_wren & (crn_st==IDLE ) & (cnt_d==3'h0) & i_valid           |
            ~wren_q & (crn_st==STDBY) & (cnt_d==3'h0)                     |
            ~i_wren & (crn_st==ACK  ) & (cnt_d==3'h0) & i_valid & i_ready
        ) begin
            data_d[31:24] = (mem_bmsk[3] & (mem_addr<SIZE)) ? cache_mem_model[mem_addr + 3] : 8'h00;
            data_d[23:16] = (mem_bmsk[2] & (mem_addr<SIZE)) ? cache_mem_model[mem_addr + 2] : 8'h00;
            data_d[15: 8] = (mem_bmsk[1] & (mem_addr<SIZE)) ? cache_mem_model[mem_addr + 1] : 8'h00;
            data_d[ 7: 0] = (mem_bmsk[0] & (mem_addr<SIZE)) ? cache_mem_model[mem_addr    ] : 8'h00;
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
    end: b_brain_rot

    assign o_data  = data_q;
    assign o_valid = (crn_st==ACK ) ? i_rstn : 1'b0;
    assign o_ready = (crn_st==IDLE) ? i_rstn : ((crn_st==ACK) ? i_ready : 1'b0);

    /* verilator lint_on WIDTHEXPAND */
    /* verilator lint_on INITIALDLY */
    /* verilator lint_on WIDTHTRUNC */

    // property out_hndshk;
    //     @(posedge i_clk) disable iff (!i_rstn)
    //     (o_valid) |-> (o_valid)[*0:$] ##1 i_ready;
    // endproperty: out_hndshk

    // property hndshk;
    //     @(posedge i_clk) disable iff (!i_rstn)
    //     (o_ready && i_valid)
    //     |-> ##1 (o_valid)
    //     |-> (o_valid)[*0:$] ##1 i_ready;
    // endproperty: hndshk

    // property wrchk;
    //     logic [31:0] data;
    //     logic [31:0] addr;
    //     @(posedge i_clk) disable iff (!i_rstn)
    //     (o_ready && i_valid && i_wren
    //     ,data = i_data
    //     ,addr = i_addr
    //     ) |-> mem_wren |-> ##1 (
    //     cache_mem_model[addr + 3] == data[31:24] &&
    //     cache_mem_model[addr + 2] == data[23:16] &&
    //     cache_mem_model[addr + 1] == data[15: 8] &&
    //     cache_mem_model[addr    ] == data[ 7: 0]
    //     );
    // endproperty: wrchk

    // OutHandShakeCheck: assert property (out_hndshk) else $error();
    // HandShakeCheck   : assert property (hndshk    ) else $error();
    // WriteCheck       : assert property (wrchk     ) else $error();

endmodule: tb_dcache_model
