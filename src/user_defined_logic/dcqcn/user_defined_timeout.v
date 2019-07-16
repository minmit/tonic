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

wire                              alpha_timer_expired;
wire    [`ALPHA_W-1:0]            alpha_tmp;

wire    [`RATE_W+1:0]             t_rate_times_10;
wire                              rp_timer_expired;
wire    [`SUB_STAGE_W-1:0]        t_min_stage;
wire    [`RATE_W-1:0]             t_rhai_inc;
wire                              t_cond_1, t_cond_2, t_cond_3;
wire    [`STAGE_W-1:0]            t_stage;
wire    [`RATE_W-1:0]             t_target_change;
wire    [`RATE_W-1:0]             t_target_rate;
wire    [`RATE_W-1:0]             t_rate;
wire    [`RATE_W-1:0]             t_rate_tmp;

wire    [`RATE_W+1:0]             b_rate_times_10;
wire                              byte_cntr_expired;
wire                              b_cond_1, b_cond_2, b_cond_3;
wire    [`RATE_W-1:0]             b_target_change;
wire    [`RATE_W-1:0]             b_rate_tmp;

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
              

//*********************************************************************************
// Logic
//*********************************************************************************
assign {target_rate_in, alpha_in, stage_in, 
        byte_stage_in, time_stage_in, last_byte_cntr_in,
        alpha_timer_in,
        rp_timer_in, rhai_inc_in, min_stage_in,
        byte_counter_thresh_in, rate_in} = user_cntxt_in;

assign user_cntxt_out = {target_rate_out, alpha_out, stage_out, 
        byte_stage_out, time_stage_out, 
        last_byte_cntr_out, alpha_timer_out,
        rp_timer_out, rhai_inc_out, min_stage_out,
        byte_counter_thresh_out, rate_out};

// rtx
assign mark_rtx  = 1'b0;
assign rtx_start = `FLOW_SEQ_NONE;
assign rtx_end = `FLOW_SEQ_NONE;

// alpha
assign alpha_timer_expired  = now + 500 >= alpha_timer_in;
assign alpha_timer_out      = alpha_timer_expired ? now + `ALPHA_RESUME_INTERVAL : alpha_timer_in;
assign alpha_tmp            = {alpha_in[(`ALPHA_W - `DCQCN_G)-1:0], {`DCQCN_G{1'b0}}} - alpha_in;
assign alpha_out            = alpha_timer_expired ? {{`DCQCN_G{1'b0}}, alpha_tmp[`ALPHA_W-1 -: (`ALPHA_W - `DCQCN_G)]} : alpha_in;

// timer
assign t_rate_times_10      = {rate_in,3'd0} + {rate_in, 1'b0}; 

assign rp_timer_expired     = now + 500 >= rp_timer_in;
assign time_stage_out      = rp_timer_expired ? time_stage_in + 8'd1  : time_stage_in;
assign rp_timer_out         = rp_timer_expired ? now + `RP_TIMER        : rp_timer_in;

assign t_min_stage          = rp_timer_expired ? (time_stage_out < byte_stage_in ? time_stage_out : byte_stage_in) : min_stage_in;
assign t_rhai_inc           = rp_timer_expired & (t_min_stage > min_stage_in) ? rhai_inc_in + `RHAI_RATE : rhai_inc_in;

assign t_cond_1             = stage_in == 1 & time_stage_out  <  `RPG_THRESH;
assign t_cond_2             = (stage_in == 1 & time_stage_out >= `RPG_THRESH & byte_stage_in < `RPG_THRESH) |
                              (stage_in == 2 & time_stage_out <  `RPG_THRESH & byte_stage_in < `RPG_THRESH);
assign t_cond_3             = (stage_in == 3) |
                              ((stage_in == 2 | stage_in == 1) & time_stage_out >= `RPG_THRESH & byte_stage_in >= `RPG_THRESH); 

assign t_stage              = rp_timer_expired & t_cond_1 ? 2'd1 :
                              rp_timer_expired & t_cond_2 ? 2'd2 :
                              rp_timer_expired & t_cond_3 ? 2'd3 : stage_in;

assign t_target_change      = rp_timer_expired & t_cond_2 ? `RAI_RATE : 
                              rp_timer_expired & t_cond_3 ? t_rhai_inc - `RPG_THRESH + 8'd1 : 8'd0;

assign t_target_rate        = (rp_timer_expired & (time_stage_out == 8'd1 | byte_stage_in == 8'd1) & target_rate_in > t_rate_times_10) ? target_rate_in[`RATE_W-1 -: (`RATE_W-3)] : target_rate_in + t_target_change;

assign t_rate_tmp           = rate_in + t_target_rate;
assign t_rate               = (rp_timer_expired) ? t_rate_tmp[`RATE_W-1:1] : rate_in;

// byte
assign b_rate_times_10      = {t_rate,3'd0} + {t_rate, 1'b0}; 

assign byte_cntr_expired    = t_stage != 2'd0 & (total_tx_cnt_in - last_byte_cntr_in > byte_counter_thresh_in);
assign last_byte_cntr_out   = t_stage == 2'd0   ? total_tx_cnt_in :
                              byte_cntr_expired  ? total_tx_cnt_in - byte_counter_thresh_in : last_byte_cntr_in;
 
assign byte_stage_out       = byte_cntr_expired ? byte_stage_in + 8'd1  : byte_stage_in;

assign min_stage_out        = byte_cntr_expired ? (time_stage_out < byte_stage_out ? time_stage_out : byte_stage_out) : t_min_stage;
assign rhai_inc_out         = byte_cntr_expired & (min_stage_out > t_min_stage) ? t_rhai_inc + `RHAI_RATE : t_rhai_inc;

assign b_cond_1             = t_stage == 1 & byte_stage_out  <  `RPG_THRESH;
assign b_cond_2             = (t_stage == 1 & byte_stage_out >= `RPG_THRESH & time_stage_out < `RPG_THRESH) | (t_stage == 2);
assign b_cond_3             = (t_stage == 3) |
                              (stage_in == 1 & time_stage_out >= `RPG_THRESH & byte_stage_out >= `RPG_THRESH); 

assign stage_out            = byte_cntr_expired & b_cond_1 ? 2'd1 :
                              byte_cntr_expired & b_cond_2 ? 2'd2 :
                              byte_cntr_expired & b_cond_3 ? 2'd3 : t_stage;

assign b_target_change      = byte_cntr_expired & b_cond_2 ? `RAI_RATE : 
                              byte_cntr_expired & b_cond_3 ? rhai_inc_out - `RPG_THRESH + 8'd1 : 8'd0;

assign target_rate_out      = (byte_cntr_expired & (time_stage_out == 8'd1 | byte_stage_out == 8'd1) & t_target_rate > b_rate_times_10) ? t_target_rate[`RATE_W-1 -: (`RATE_W-3)] : t_target_rate + b_target_change;

assign b_rate_tmp           = t_rate + target_rate_out;
assign rate_out             = (byte_cntr_expired) ? b_rate_tmp[`RATE_W-1:1] : t_rate;


assign byte_counter_thresh_out = byte_counter_thresh_in;
assign wnd_size_out            = wnd_size_in;
assign rtx_timer_amnt_out      = rtx_timer_amnt_in;
// clogb2 function
`include "clogb2.vh"

endmodule
