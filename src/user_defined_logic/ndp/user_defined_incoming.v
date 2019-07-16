`timescale 1ns/1ns

`include "user_constants.vh"

module user_defined_incoming (
    // input
    input   [`PKT_TYPE_W-1:0]       pkt_type_in,
    input   [`PKT_DATA_W-1:0]       pkt_data_in,
    input   [`FLOW_SEQ_NUM_W-1:0]   cumulative_ack_in,
    input   [`FLOW_SEQ_NUM_W-1:0]   selective_ack_in,
    input   [`TX_CNT_W-1:0]         sack_tx_id_in,

    input   [`TIME_W-1:0]           now,
    input   [`FLAG_W-1:0]           valid_selective_ack,
    input   [`FLOW_WIN_IND_W-1:0]   new_c_acks_cnt,
    input   [`FLOW_SEQ_NUM_W-1:0]   old_wnd_start_in,
    
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
    output  [`FLAG_W-1:0]           reset_rtx_timer,
    output  [`TIMER_W-1:0]          rtx_timer_amnt_out,
    output  [`USER_CONTEXT_W-1:0]   user_cntxt_out
);

//------------------------------------------------------------------------
// Combinational logic
// Invarient: everything outside of the window should always be zero

assign user_cntxt_out = user_cntxt_in;

assign wnd_size_out = wnd_size_in;
assign rtx_timer_amnt_out = rtx_timer_amnt_in;
assign reset_rtx_timer = 1'b1;

// rtx
assign mark_rtx = pkt_type_in == `NACK_PKT &
                  selective_ack_in >= wnd_start_in &
                  selective_ack_in < wnd_start_in + wnd_size_in;

assign rtx_start = selective_ack_in;
assign rtx_end = selective_ack_in + 1;

// clogb2 function
`include "clogb2.vh"

endmodule
