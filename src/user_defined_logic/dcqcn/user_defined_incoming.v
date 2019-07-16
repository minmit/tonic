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

localparam TMP_RATE_W = 32;
// wires and regs

wire    [`FLOW_SEQ_NUM_W-1:0]     nack_seq;
wire                              is_cnp;
wire    [`ECN_W-1:0]              ecn_val;
wire    [`ALPHA_W-1:0]            alpha_tmp;

wire    [TMP_RATE_W-1:0]          tmp_rate_1;
wire    [`RATE_W-1:0]             tmp_rate_2;
wire    [`RATE_W-1:0]             tmp_rate_3;
// user-defined context

wire    [`RATE_W-1:0]             target_rate_in;
wire    [`ALPHA_W-1:0]            alpha_in;
wire    [`STAGE_W-1:0]            stage_in;
wire    [`SUB_STAGE_W-1:0]        byte_stage_in;
wire    [`SUB_STAGE_W-1:0]        time_stage_in;
wire    [`FLOW_SEQ_NUM_W-1:0]     last_byte_cntr_in;
wire    [`TIMER_W-1:0]            alpha_timer_in;
wire    [`TIMER_W-1:0]            rp_timer_in;
wire    [`RATE_W-1:0]             rhai_inc_in;
wire    [`SUB_STAGE_W-1:0]        min_stage_in;
wire    [`FLOW_SEQ_NUM_W-1:0]     byte_counter_thresh_in;
wire    [`RATE_W-1:0]             rate_in;

wire    [`RATE_W-1:0]             target_rate_out;
wire    [`ALPHA_W-1:0]            alpha_out;
wire    [`STAGE_W-1:0]            stage_out;
wire    [`SUB_STAGE_W-1:0]        byte_stage_out;
wire    [`SUB_STAGE_W-1:0]        time_stage_out;
wire    [`FLOW_SEQ_NUM_W-1:0]     last_byte_cntr_out;
wire    [`TIMER_W-1:0]            alpha_timer_out;
wire    [`TIMER_W-1:0]            rp_timer_out;
wire    [`RATE_W-1:0]             rhai_inc_out;
wire    [`SUB_STAGE_W-1:0]        min_stage_out;
wire    [`FLOW_SEQ_NUM_W-1:0]     byte_counter_thresh_out;
wire    [`RATE_W-1:0]             rate_out;
              
//------------------------------------------------------------------------
// Combinational logic

assign {target_rate_in, alpha_in, stage_in, 
        byte_stage_in, time_stage_in, last_byte_cntr_in,
        alpha_timer_in,
        rp_timer_in, rhai_inc_in, min_stage_in,
        byte_counter_thresh_in, rate_in} = user_cntxt_in;

assign user_cntxt_out = {target_rate_out, alpha_out, stage_out, 
        byte_stage_out, time_stage_out, last_byte_cntr_out, 
        alpha_timer_out,
        rp_timer_out, rhai_inc_out, min_stage_out,
        byte_counter_thresh_out, rate_out};


// rtx
assign mark_rtx   = pkt_type_in == `NACK_PKT;

assign nack_seq   = pkt_data_in[`FLOW_SEQ_NUM_W-1:0];
assign rtx_start  = nack_seq;
assign rtx_end    = nack_seq + 1;

// other variables

assign is_cnp   = pkt_type_in == `CNP_PKT;
assign ecn_val  = pkt_data_in[`ECN_W-1:0];

assign target_rate_out    = is_cnp & ecn_val == 3 ? rate_in : target_rate_in;
assign last_byte_cntr_out = is_cnp & ecn_val == 3 ? total_tx_cnt_in : last_byte_cntr_in;

assign byte_stage_out     = is_cnp ? {`SUB_STAGE_W{1'b0}} : byte_stage_in;
assign time_stage_out     = is_cnp ? {`SUB_STAGE_W{1'b0}} : time_stage_in;
assign rhai_inc_out       = is_cnp ? {`RATE_W{1'b0}}      : rhai_inc_in;
assign min_stage_out      = is_cnp ? {`SUB_STAGE_W{1'b0}} : min_stage_in;
assign stage_out          = is_cnp ? 1                    : stage_in;

assign alpha_timer_out    = is_cnp ? now + `ALPHA_RESUME_INTERVAL : alpha_timer_in; 
assign rp_timer_out       = is_cnp ? now + `RP_TIMER              : rp_timer_in;

assign alpha_tmp          = {alpha_in[(`ALPHA_W - `DCQCN_G)-1:0], {`DCQCN_G{1'b0}}} - alpha_in + {1'b1, {`ALPHA_B{1'b0}}};
assign alpha_out          = is_cnp ? {{`DCQCN_G{1'b0}}, alpha_tmp[`ALPHA_W-1 -: (`ALPHA_W - `DCQCN_G)]} : alpha_in;

assign tmp_rate_1         = rate_in * {1'b0, alpha_out[`ALPHA_W-1:1]};
assign tmp_rate_2         = rate_in - {{`ALPHA_B{1'b0}}, tmp_rate_1[TMP_RATE_W-1 -: (TMP_RATE_W - `ALPHA_B)]};
assign tmp_rate_3         = tmp_rate_2 < `MIN_RATE ? `MIN_RATE : tmp_rate_2;
assign rate_out           = is_cnp ? tmp_rate_3 : rate_in;

assign byte_counter_thresh_out  = byte_counter_thresh_in; 
assign wnd_size_out             = wnd_size_in;
assign rtx_timer_amnt_out       = rtx_timer_amnt_in;
assign reset_rtx_timer          = 1'b1;
// clogb2 function
`include "clogb2.vh"

endmodule
