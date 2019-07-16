`timescale 1ns/1ns

module user_defined_timeout (
    // input
    input                           timeout_expired,
    input   [`TIME_W-1:0]           now,
    input   [`FLOW_WIN_SIZE-1:0]    acked_wnd_in,
    input   [`FLOW_WIN_SIZE-1:0]    rtx_wnd_in,
    input   [`TX_CNT_WIN_SIZE-1:0]  tx_cnt_wnd_in,
    input   [`FLOW_SEQ_NUM_W-1:0]   wnd_start_in,
    input   [`FLOW_WIN_SIZE_W-1:0]  wnd_size_in,
    input   [`FLOW_SEQ_NUM_W-1:0]   next_new_in,
    input   [`TIMER_W-1:0]          rtx_timer_amnt_in,
    input   [`FLOW_SEQ_NUM_W-1:0]   total_tx_cnt_in,
    input   [`USER_CONTEXT_W-1:0]   user_cntxt_in,
    
    // output
    output  [`FLAG_W-1:0]           mark_rtx,
    output  [`FLOW_SEQ_NUM_W-1:0]   rtx_start,
    output  [`FLOW_SEQ_NUM_W-1:0]   rtx_end,
    output  [`FLOW_WIN_SIZE_W-1:0]  wnd_size_out,
    output  [`TIMER_W-1:0]          rtx_timer_amnt_out,
    output  [`USER_CONTEXT_W-1:0]   user_cntxt_out
);
 
//*********************************************************************************
// Wires and Regs
//*********************************************************************************
wire    [`FLOW_SEQ_NUM_W-1:0]   in_flight_cnt_tmp;   
wire    [`FLOW_WIN_IND_W-1:0]   in_flight_cnt;   


// user
wire   [`FLAG_W-1:0]           in_recovery_in;
wire   [`FLOW_SEQ_NUM_W-1:0]   recovery_seq_in;
wire   [`FLOW_SEQ_NUM_W-1:0]   max_marked_sack_in; 
wire   [`FLOW_SEQ_NUM_W-1:0]   max_sack_in;
wire   [`FLOW_WIN_IND_W-1:0]   acked_cnt_in;

wire   [`FLAG_W-1:0]           in_recovery_out;
wire   [`FLOW_SEQ_NUM_W-1:0]   recovery_seq_out;
wire   [`FLOW_SEQ_NUM_W-1:0]   max_marked_sack_out; 
wire   [`FLOW_SEQ_NUM_W-1:0]   max_sack_out;
wire   [`FLOW_WIN_IND_W-1:0]   acked_cnt_out;

//*********************************************************************************
// Logic
//*********************************************************************************
assign wnd_size_out = wnd_size_in;

assign in_flight_cnt_tmp = next_new_in - wnd_start_in - acked_cnt_in; 
assign in_flight_cnt     = in_flight_cnt_tmp[`FLOW_WIN_IND_W-2:0]; 

assign rtx_timer_amnt_out = in_flight_cnt > `RTO_LOW_THRESH ? `RTO_HIGH : `RTO_LOW;

assign in_recovery_out = 1'b1;
assign recovery_seq_out = next_new_in;
assign max_marked_sack_out = max_sack_in;
assign max_sack_out = max_sack_in;
assign acked_cnt_out = acked_cnt_in;

assign mark_rtx  = 1'b1;

assign rtx_start = wnd_start_in;
assign rtx_end = max_sack_in;

assign {acked_cnt_in, max_sack_in, max_marked_sack_in,
        recovery_seq_in, in_recovery_in} = user_cntxt_in;
assign user_cntxt_out = {acked_cnt_out, max_sack_out, max_marked_sack_out,
        recovery_seq_out, in_recovery_out} ;


// clogb2 function
`include "clogb2.vh"

endmodule



