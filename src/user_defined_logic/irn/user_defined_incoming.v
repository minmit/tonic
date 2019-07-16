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

// wires
wire                                                is_selective_nack;
wire                                                still_in_recovery;
wire    [`FLOW_SEQ_NUM_W-1:0]                       in_flight_cnt_tmp;   
wire    [`FLOW_WIN_IND_W-1:0]                       in_flight_cnt;   

// user-defined context

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

//------------------------------------------------------------------------
// Combinational logic
assign still_in_recovery = in_recovery_in & cumulative_ack_in < recovery_seq_in; 
 
assign in_recovery_out = still_in_recovery | mark_rtx;
assign recovery_seq_out = still_in_recovery ? recovery_seq_in : next_new_in;
assign max_marked_sack_out = mark_rtx ? selective_ack_in : max_marked_sack_in;

assign is_selective_nack = pkt_type_in == `CACK_PKT & valid_selective_ack;

// rtx
assign mark_rtx = is_selective_nack &
                  ((still_in_recovery & selective_ack_in > max_marked_sack_in) | (~still_in_recovery));
                    

assign wnd_size_out = wnd_size_in;

assign max_sack_out = (pkt_type_in == `CACK_PKT) & max_sack_in < selective_ack_in ? selective_ack_in : max_sack_in;

wire    [`FLOW_SEQ_NUM_W-1:0]   wnd_jump_tmp;
assign wnd_jump_tmp      = wnd_start_in - old_wnd_start_in;
assign acked_cnt_out     = acked_cnt_in - wnd_jump_tmp[`FLOW_WIN_IND_W-2:0] + new_c_acks_cnt + is_selective_nack;
assign in_flight_cnt_tmp = next_new_in - wnd_start_in - acked_cnt_out; 
assign in_flight_cnt     = in_flight_cnt_tmp[`FLOW_WIN_IND_W-2:0]; 


assign reset_rtx_timer = 1'b1;
assign rtx_timer_amnt_out = in_flight_cnt > `RTO_LOW_THRESH ? `RTO_HIGH : `RTO_LOW;

assign rtx_start = still_in_recovery ? max_marked_sack_in : wnd_start_in;
assign rtx_end = selective_ack_in;

assign wnd_size_out = wnd_size_in;

assign {acked_cnt_in, max_sack_in, max_marked_sack_in,
        recovery_seq_in, in_recovery_in} = user_cntxt_in;
assign user_cntxt_out = {acked_cnt_out, max_sack_out, max_marked_sack_out,
        recovery_seq_out, in_recovery_out} ;


// clogb2 function
`include "clogb2.vh"

endmodule

