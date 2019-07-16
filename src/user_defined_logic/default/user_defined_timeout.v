`timescale 1ns/1ns

module user_defined_timeout (
    // input
    input                           timeout_expired,
    input   [`FLOW_WIN_SIZE-1:0]    acked_wnd_in,
    input   [`FLOW_WIN_SIZE-1:0]    rtx_wnd_in,
    input   [`TX_CNT_WIN_SIZE-1:0]  tx_cnt_wnd_in,
    input   [`FLOW_SEQ_NUM_W-1:0]   wnd_start_in,
    input   [`FLOW_WIN_SIZE_W-1:0]  wnd_size_in,
    input   [`FLOW_SEQ_NUM_W-1:0]   next_new_in,
    input   [`TIMER_W-1:0]          rtx_timer_amnt_in,
    input   [`USER_CONTEXT_W-1:0]   user_cntxt_in,

    // output
    output  [`FLAG_W-1:0]           mark_rtx,
    output  [`FLOW_SEQ_NUM_W-1:0]   rtx_start,
    output  [`FLOW_SEQ_NUM_W-1:0]   rtx_end,
    output  [`FLOW_WIN_SIZE_W-1:0]  wnd_size_out,
    output  [`TIMER_W-1:0]          rtx_timer_amnt_out,
    output  [`USER_CONTEXT_W-1:0]   user_cntxt_out
);

localparam  R_FLOW_WIN_IND_W = `FLOW_WIN_IND_W - 1;

assign mark_rtx  = timeout_expired; 

assign rtx_start = wnd_start_in;
assign rtx_end = next_new_in; 

assign wnd_size_out = wnd_size_in;
assign rtx_timer_amnt_out = rtx_timer_amnt_in;

assign user_cntxt_out = user_cntxt_in;

// clogb2 function
`include "clogb2.vh"
endmodule
