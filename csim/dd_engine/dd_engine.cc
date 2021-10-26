#include "dd_engine.h"
#include "../utils/util.h"

#include <iostream>

using namespace std;

DDEngine::DDEngine(uint32_t flow_cnt){
  this->flow_cnt = flow_cnt;
  none_elem = FLOW_ID_NONE;
  non_idle = new Fifo4W(flow_cnt, &none_elem);

  next_enq_fid1_q = new uint32_t(FLOW_ID_NONE);
  next_enq_fid2_q = new uint32_t(FLOW_ID_NONE);
  next_enq_fid3_q = new uint32_t(FLOW_ID_NONE);
  next_enq_fid4_q = new uint32_t(FLOW_ID_NONE);
  
  for (uint32_t i = 0; i < flow_cnt; i++){

    // init ram
    Context1* flow_cntxt1 = new Context1();
    flow_cntxt1->wnd_size = 10;

    ram1[i + 1] = flow_cntxt1;
    
    NewRenoContext* nreno_cntxt = new NewRenoContext();
    nreno_cntxt->ss_thresh = 60;

    Context2* flow_cntxt2 = new Context2();
    flow_cntxt2->rtx_timer_amnt = 2000;
    flow_cntxt2->user_cntxt = nreno_cntxt;
    
    ram2[i + 1] = flow_cntxt2;

    // add to queue
    non_idle->init_enq(new uint32_t(i + 1));
  }
  
  Context1* flow_cntxt1 = new Context1();
  flow_cntxt1->wnd_size = 50;
  ram1[FLOW_ID_NONE] = flow_cntxt1;  

  NewRenoContext* nreno_cntxt = new NewRenoContext();
  nreno_cntxt->ss_thresh = 60;

  Context2* flow_cntxt2 = new Context2();
  flow_cntxt2->rtx_exptime = 2000;
  flow_cntxt2->user_cntxt = nreno_cntxt;

  ram2[FLOW_ID_NONE] = flow_cntxt2;

  // other inits
  incoming_fid_in = FLOW_ID_NONE;
  dp_fid_in = FLOW_ID_NONE;
};


void DDEngine::eval(){
  // Fifo
  non_idle->clk = clk;
  non_idle->rst_n = rst_n;

  uint8_t w_val_fid1, w_val_fid2, w_val_fid3, w_val_fid4;
  w_val_fid1 = *next_enq_fid1_q != FLOW_ID_NONE;
  w_val_fid2 = *next_enq_fid2_q != FLOW_ID_NONE;
  w_val_fid3 = *next_enq_fid3_q != FLOW_ID_NONE;
  w_val_fid4 = *next_enq_fid4_q != FLOW_ID_NONE;

  non_idle->w_val_0  = w_val_fid1;
  non_idle->w_data_0 = next_enq_fid1_q;
  non_idle->w_val_1  = w_val_fid2;
  non_idle->w_data_1 = next_enq_fid2_q;
  non_idle->w_val_2  = w_val_fid3;
  non_idle->w_data_2 = next_enq_fid3_q; 
  non_idle->w_val_3  = w_val_fid4;
  non_idle->w_data_3 = next_enq_fid4_q;
  non_idle->r_val    = 1;
  
  non_idle->eval();
 
  //// DD Core
  
  // Ack Init
  cack_in = pkt_data_in.cack_pkt.cack; 
  sack_in = FLOW_SEQ_NONE;
  sack_tx_id_in = 0;
  inc0_fid_in = incoming_fid_in; 
 
  // Positive edge of clock
  if (prev_clk == 0 &&
      clk == 1){
    if (!rst_n){

      // Fifo
      next_enq_fid1_q = new uint32_t(FLOW_ID_NONE);
      next_enq_fid2_q = new uint32_t(FLOW_ID_NONE);
      next_enq_fid3_q = new uint32_t(FLOW_ID_NONE);
      next_enq_fid4_q = new uint32_t(FLOW_ID_NONE);

      // Inc1
      inc1_cack = FLOW_SEQ_NONE;
      inc1_sack = FLOW_SEQ_NONE;
      inc1_sack_tx_id = 0;

      inc1_new_c_acks_cnt = 0;
      inc1_valid_sack = 0;
      inc1_old_wnd_start = 0;
      inc1_pkt_type = NONE_PKT;
      
      // Ps
      next_fid_p = FLOW_ID_NONE;
      inc0_fid_p = FLOW_ID_NONE;
      inc1_fid_p = FLOW_ID_NONE;
      timeout_fid_p = FLOW_ID_NONE;
      dp_fid_p = FLOW_ID_NONE;

      cack_p = FLOW_SEQ_NONE;
      sack_p = FLOW_SEQ_NONE;
      sack_tx_id_p = 0;
      pkt_type_p = NONE_PKT;

      // Ls
      next_fid_l = FLOW_ID_NONE;
      inc0_fid_l = FLOW_ID_NONE;
      inc1_fid_l = FLOW_ID_NONE;
      timeout_fid_l = FLOW_ID_NONE;
      dp_fid_l = FLOW_ID_NONE;

      cack_l = FLOW_SEQ_NONE;
      sack_l = FLOW_SEQ_NONE;
      sack_tx_id_l = 0;
      pkt_type_l = NONE_PKT;

      // Ack Init
      inc1_fid_in = FLOW_ID_NONE;

      // Timeout FID
      timeout_fid_in = TIMEOUT_INIT_FID;

      // Global Time
      global_time = 0;

    }
    else{
      // Fifo
      next_enq_fid1_q = new uint32_t(next_enq_fid1);
      next_enq_fid2_q = new uint32_t(next_enq_fid2);
      next_enq_fid3_q = new uint32_t(next_enq_fid3);
      next_enq_fid4_q = new uint32_t(next_enq_fid4);

      // Global Time
      global_time++;

      // Inc1
      inc1_cack = cack_p;
      inc1_sack = sack_p;
      inc1_sack_tx_id = sack_tx_id_p;

      inc1_new_c_acks_cnt = inc0_new_c_acks_cnt;
      inc1_valid_sack = inc0_valid_sack;
      inc1_old_wnd_start = inc0_old_wnd_start;
      inc1_pkt_type = pkt_type_p;

      // Ps
      next_fid_p = next_fid_l;
      inc0_fid_p = inc0_fid_l;
      inc1_fid_p = inc1_fid_l;
      timeout_fid_p = timeout_fid_l;
      dp_fid_p = dp_fid_l;

      cack_p = cack_l;
      sack_p = sack_l;
      sack_tx_id_p = sack_tx_id_l;
      pkt_type_p = pkt_type_l;

      // Ls
      next_fid_l = next_fid_in;
      inc0_fid_l = inc0_fid_in;
      inc1_fid_l = inc1_fid_in;
      timeout_fid_l = timeout_fid_in;
      dp_fid_l = dp_fid_in;

      pkt_type_l = pkt_type_in;

      cack_l = cack_in;
      sack_l = sack_in;
      sack_tx_id_l = sack_tx_id_in; 
     
      // Ack Init
      inc1_fid_in = inc0_fid_in;

      // Timeout FID
      timeout_fid_in = timeout_fid_in == FLOW_CNT ? 1 : timeout_fid_in + 1;
    }
    
    ////////// Look up P contexts ////////////
    Context1 *next_cntxt_1_p, *inc0_cntxt_1_p, *inc1_cntxt_1_p, *timeout_cntxt_1_p;
    Context2 *next_cntxt_2_p, *inc1_cntxt_2_p, *timeout_cntxt_2_p, *dp_cntxt_2_p;

    next_cntxt_1_p = ram1[next_fid_p]; 
    inc0_cntxt_1_p = ram1[inc0_fid_p]; 
    inc1_cntxt_1_p = ram1[inc1_fid_p];

    next_cntxt_2_p = ram2[next_fid_p]; 
    inc1_cntxt_2_p = ram2[inc1_fid_p];
    dp_cntxt_2_p = ram2[dp_fid_p];
    
    bool timeout_expired = false;
    if (timeout_fid_p > 0 && timeout_fid_p <= flow_cnt){
      timeout_cntxt_1_p = ram1[timeout_fid_p];
      timeout_cntxt_2_p = ram2[timeout_fid_p];

      timeout_expired = (timeout_cntxt_2_p->active_rtx_timer &&
                         timeout_cntxt_2_p->rtx_exptime <= global_time &&
                         timeout_fid_p != inc0_fid_p &&
                         timeout_fid_p != inc1_fid_p &&
                         timeout_fid_p != FLOW_ID_NONE);
    }
    timeout_fid_p = timeout_expired ? timeout_fid_p : FLOW_ID_NONE;
    timeout_cntxt_1_p = ram1[timeout_fid_p];
    timeout_cntxt_2_p = ram2[timeout_fid_p];

    if (DEBUG){
      cout << "next_fid_in: " << next_fid_in << endl;
      cout << "inc0_fid_in: " << inc0_fid_in << endl;
      cout << "inc1_fid_in: " << inc1_fid_in << endl;
      cout << "timeout_fid_in: " << timeout_fid_in << endl;
      cout << "dp_fid_in: " << dp_fid_in << endl;
      cout << "--------------------------" << endl;
    }

    if (DEBUG){
      cout << "next_fid_l: " << next_fid_l << endl;
      cout << "inc0_fid_l: " << inc0_fid_l << endl;
      cout << "inc1_fid_l: " << inc1_fid_l << endl;
      cout << "timeout_fid_l: " << timeout_fid_l << endl;
      cout << "dp_fid_l: " << dp_fid_l << endl;
      cout << "--------------------------" << endl;
    }

    if (DEBUG){
      cout << "next_fid_p: " << next_fid_p << endl;
      cout << "next_cntxt_1_p: " << endl << *next_cntxt_1_p << endl;
      cout << "next_cntxt_2_p: " << endl << *next_cntxt_2_p << endl;
      cout << "--------------------------" << endl;
      
      cout << "inc0_fid_p: " << inc0_fid_p << endl;
      cout << "inc0_cntxt_1_p: " << endl << *inc0_cntxt_1_p << endl;
      cout << "--------------------------" << endl;

      cout << "inc1_fid_p: " << inc1_fid_p << " " << inc1_cack << endl;
      cout << "inc1_cntxt_1_p: " << endl << *inc1_cntxt_1_p << endl;
      cout << "inc1_cntxt_2_p: " << endl << *inc1_cntxt_2_p << endl;
      cout << "--------------------------" << endl;

      cout << "timeout_fid_p: " << timeout_fid_p << endl;
      cout << "timeout_cntxt_1_p: " << endl << *timeout_cntxt_1_p << endl;
      cout << "timeout_cntxt_2_p: " << endl << *timeout_cntxt_2_p << endl;
      cout << "--------------------------" << endl;

      cout << "dp_fid_p: " << dp_fid_p << endl;
      cout << "dp_cntxt_2_p: " << endl << *dp_cntxt_2_p << endl;
      cout << "--------------------------" << endl;

    }
    //////// Process events //////////

    //// Next


    set<uint32_t> next_rtx_wnd_out;
    uint32_t next_next_new_out = next_cntxt_1_p->next_new;

    next_seq_out = FLOW_SEQ_NONE;
    next_seq_fid_out = FLOW_ID_NONE;
    next_seq_tx_id_out = 0;

    // Apply mask and find first seq marked for rtx
    uint32_t next_wnd_start = next_cntxt_1_p->wnd_start;
    uint32_t next_wnd_size = next_cntxt_1_p->wnd_size;
    uint32_t next_wnd_end = next_wnd_start + next_wnd_size;


    for (set<uint32_t>::iterator it = next_cntxt_2_p->rtx_wnd.begin();
                                 it != next_cntxt_2_p->rtx_wnd.end();
                                 it++){
      uint32_t rtx_seq = *it;
      if (next_cntxt_1_p->acked_wnd.find(rtx_seq) == next_cntxt_1_p->acked_wnd.end() &&
          rtx_seq >= next_wnd_start &&
          rtx_seq < next_wnd_end){
        next_rtx_wnd_out.insert(rtx_seq);
      }
    }

    
    if (!next_rtx_wnd_out.empty()){
      next_seq_out = *(next_rtx_wnd_out.begin());
      next_rtx_wnd_out.erase(next_rtx_wnd_out.begin());
      next_seq_fid_out = next_fid_p;
    }
    else if (next_cntxt_1_p->next_new < next_wnd_start + 
                                      next_wnd_size){
      next_seq_out = next_cntxt_1_p->next_new;
      next_seq_fid_out = next_fid_p;
      next_next_new_out = next_cntxt_1_p->next_new + 1;
    }
      
    uint32_t next_pkt_queue_size_out = next_cntxt_2_p->pkt_queue_size + 1;
    bool next_back_pressure_out = next_pkt_queue_size_out >= PKT_QUEUE_STOP_THRESH;

    // DP
    uint32_t dp_pkt_queue_size_out = dp_cntxt_2_p->pkt_queue_size - 1;
    bool old_dp_back_pressure = dp_cntxt_2_p->back_pressure;
    bool dp_back_pressure_out = !(old_dp_back_pressure && dp_pkt_queue_size_out < PKT_QUEUE_START_THRESH) 
                                 && old_dp_back_pressure; 
    bool activated_by_dp = old_dp_back_pressure && dp_pkt_queue_size_out < PKT_QUEUE_START_THRESH;
 
    /// Inc0 Setup
    uint32_t inc0_wnd_size_in = inc0_cntxt_1_p->wnd_size;

    //// Inc1
    NewRenoContext* inc1_nreno_cntxt = (NewRenoContext*)(inc1_cntxt_2_p->user_cntxt);
    bool is_dup_ack = inc1_old_wnd_start == inc1_cack;
    bool is_new_ack = inc1_cntxt_1_p->wnd_start > inc1_old_wnd_start;

    // update dup acks
    uint32_t old_dup_acks = inc1_nreno_cntxt->dup_acks;
    if (is_new_ack) inc1_nreno_cntxt->dup_acks = 0;
    else if (is_dup_ack) inc1_nreno_cntxt->dup_acks++;
    
    bool do_fast_rtx = (inc1_nreno_cntxt->dup_acks == DUP_ACKS_THRESH &
                       ((inc1_cack > inc1_nreno_cntxt->recover) ||
                        (inc1_cntxt_1_p->wnd_size > 1 &&
                         inc1_cack - inc1_nreno_cntxt->prev_hgst_ack <= 4)));


    bool full_ack = is_new_ack && inc1_cack > inc1_nreno_cntxt->recover;
    bool partial_ack = is_new_ack && inc1_cack <= inc1_nreno_cntxt->recover;

    bool mark_rtx = do_fast_rtx || partial_ack;

    if (mark_rtx){
      inc1_cntxt_2_p->rtx_wnd.insert(inc1_cntxt_1_p->wnd_start);
    }
    
    // update wnd size
    uint32_t inc1_wnd_size_out;
    uint32_t inc1_wnd_size_in = inc1_cntxt_1_p->wnd_size;
    if (inc1_nreno_cntxt->in_recovery &&
        !inc1_nreno_cntxt->in_timeout){
      if(full_ack) inc1_wnd_size_out = inc1_nreno_cntxt->ss_thresh;
      else if (partial_ack) inc1_wnd_size_out = inc1_wnd_size_in +
                                                inc1_cntxt_1_p->wnd_start -
                                                inc1_old_wnd_start + 1;
      else if (is_dup_ack) inc1_wnd_size_out = inc1_wnd_size_in + 1;
      else inc1_wnd_size_out = inc1_wnd_size_in;
    }
    else if (is_new_ack){
      if (inc1_wnd_size_in < inc1_nreno_cntxt->ss_thresh)
        inc1_wnd_size_out = inc1_wnd_size_in - old_dup_acks + 1;
      else if (inc1_nreno_cntxt->wnd_inc_cntr == inc1_wnd_size_in)
        inc1_wnd_size_out = inc1_wnd_size_in - old_dup_acks + 1;
      else inc1_wnd_size_out = inc1_wnd_size_in - old_dup_acks;
    }
    else if (is_dup_ack){
      inc1_wnd_size_out = inc1_wnd_size_in + 1;
    }
    else {
      inc1_wnd_size_out = inc1_wnd_size_in;
    }

    inc1_cntxt_1_p->wnd_size = inc1_wnd_size_out > MAX_FLOW_WIN_SIZE ? MAX_FLOW_WIN_SIZE : inc1_wnd_size_out;

    // update in_recovery
    inc1_nreno_cntxt->in_recovery = (inc1_nreno_cntxt->in_recovery && 
                                     inc1_cack <= inc1_nreno_cntxt->recover) || do_fast_rtx;
    inc1_reset_rtx_timer = !inc1_nreno_cntxt->in_recovery;
    // update wnd inc cntr
    if (inc1_nreno_cntxt->in_recovery &&
        !inc1_nreno_cntxt->in_timeout){
      inc1_nreno_cntxt->wnd_inc_cntr = 0;
    }
    else if (is_new_ack && 
             inc1_wnd_size_in >= inc1_nreno_cntxt->ss_thresh){
      inc1_nreno_cntxt->wnd_inc_cntr = (inc1_nreno_cntxt->wnd_inc_cntr == inc1_wnd_size_in) ? 0 : 
                                        inc1_nreno_cntxt->wnd_inc_cntr + 1;
    }

    // update in_timeout
    inc1_nreno_cntxt->in_timeout = inc1_nreno_cntxt->in_timeout && !full_ack;

    // update prev_hgst_ack
    if (is_new_ack) inc1_nreno_cntxt->prev_hgst_ack = inc1_old_wnd_start;

    // update recover
    if (do_fast_rtx) inc1_nreno_cntxt->recover = inc1_cntxt_1_p->next_new - 1;

    // update ss_thresh
    if (do_fast_rtx) inc1_nreno_cntxt->ss_thresh = inc1_wnd_size_in/2;

    //// Inc0
    
    inc0_old_wnd_start = inc0_cntxt_1_p->wnd_start;
    if (cack_p > inc0_old_wnd_start){
      inc0_cntxt_1_p->wnd_start = cack_p;
    }
    uint32_t inc0_new_wnd_start = inc0_cntxt_1_p->wnd_start;

    inc0_valid_sack = (inc0_cntxt_1_p->acked_wnd.find(sack_p) != inc0_cntxt_1_p->acked_wnd.end() &&
                      sack_p > inc0_new_wnd_start &&
                      sack_p < inc0_new_wnd_start + inc0_wnd_size_in);

    uint32_t prev_sacks = 0;
    if (inc0_new_wnd_start > inc0_old_wnd_start){
      for (set<uint32_t>::iterator it = inc0_cntxt_1_p->acked_wnd.begin();
                                   it != inc0_cntxt_1_p->acked_wnd.end();
                                   it++){
        uint32_t prev_sacked_seq = *it;
        if (prev_sacked_seq < inc0_new_wnd_start) prev_sacks++;
        else break;
      }
      inc0_cntxt_1_p->acked_wnd.erase(inc0_cntxt_1_p->acked_wnd.begin(),
                                    std::next(inc0_cntxt_1_p->acked_wnd.begin(), prev_sacks));
    }

    inc0_new_c_acks_cnt = inc0_new_wnd_start - inc0_old_wnd_start - prev_sacks;

    if (inc0_valid_sack){
      inc0_cntxt_1_p->acked_wnd.insert(sack_p);
    }

    //// Timeout
    timeout_cntxt_2_p->rtx_wnd.insert(timeout_cntxt_1_p->wnd_start);
    
    timeout_cntxt_1_p->wnd_size = 1;
    
    NewRenoContext* timeout_nreno_cntxt = (NewRenoContext*)timeout_cntxt_2_p->user_cntxt;
    timeout_nreno_cntxt->dup_acks = 0;
    timeout_nreno_cntxt->ss_thresh = std::min((int)timeout_nreno_cntxt->ss_thresh, 2);
    timeout_nreno_cntxt->wnd_inc_cntr = 0; 
    timeout_nreno_cntxt->in_timeout = true;
    timeout_nreno_cntxt->recover = timeout_cntxt_1_p->next_new - 1;

    ///////////// Merge //////////////
    // rtx_wnd
    if (next_fid_p == inc1_fid_p){
      inc1_cntxt_2_p->rtx_wnd.erase(next_seq_out);
    }
    else if (next_fid_p == timeout_fid_p){
      timeout_cntxt_2_p->rtx_wnd.erase(next_seq_out);
    }
    else{
      next_cntxt_2_p->rtx_wnd.swap(next_rtx_wnd_out);
    }

    // next_new
    next_cntxt_1_p->next_new = next_next_new_out;
    if (next_fid_p == inc0_fid_p){
      inc0_cntxt_1_p->next_new = next_next_new_out;
    }
    if (next_fid_p == inc1_fid_p){
      inc1_cntxt_1_p->next_new = next_next_new_out;
    }
    if (next_fid_p == timeout_fid_p){
      timeout_cntxt_1_p->next_new = next_next_new_out;
    }

    
    // rtx_exptime
    if (!dp_cntxt_2_p->active_rtx_timer ||
        dp_fid_p == timeout_fid_p)
      dp_cntxt_2_p->rtx_exptime = dp_cntxt_2_p->rtx_timer_amnt + global_time;
    if (inc1_reset_rtx_timer) 
      inc1_cntxt_2_p->rtx_exptime = inc1_cntxt_2_p->rtx_timer_amnt + global_time;

    // active_rtx_timer
    timeout_cntxt_2_p->active_rtx_timer = false;
    if (inc1_reset_rtx_timer) inc1_cntxt_2_p->active_rtx_timer = true;
    dp_cntxt_2_p->active_rtx_timer = true;
    
    
    // idle
    bool old_next_idle = next_cntxt_2_p->idle;
    bool old_inc1_idle = inc1_cntxt_2_p->idle;
    bool old_timeout_idle = timeout_cntxt_2_p->idle;
    
    next_cntxt_2_p->idle = (next_cntxt_1_p->next_new >= next_cntxt_1_p->wnd_start + next_cntxt_1_p->wnd_size) && next_cntxt_2_p->rtx_wnd.empty();
    inc1_cntxt_2_p->idle = (inc1_cntxt_1_p->next_new >= inc1_cntxt_1_p->wnd_start + inc1_cntxt_1_p->wnd_size) && inc1_cntxt_2_p->rtx_wnd.empty();
    timeout_cntxt_2_p->idle = (timeout_cntxt_1_p->next_new >= timeout_cntxt_1_p->wnd_start + timeout_cntxt_1_p->wnd_size) && timeout_cntxt_2_p->rtx_wnd.empty();

    // pkt queue size
    if (next_fid_p != dp_fid_p){
      next_cntxt_2_p->pkt_queue_size = next_pkt_queue_size_out;
      dp_cntxt_2_p->pkt_queue_size = dp_pkt_queue_size_out;
    }
    // back pressure
    if (next_fid_p == dp_fid_p){
      next_cntxt_2_p->back_pressure = 0;
      dp_cntxt_2_p->back_pressure = 0;
    }
    else{
      next_cntxt_2_p->back_pressure = next_back_pressure_out;
      dp_cntxt_2_p->back_pressure = dp_back_pressure_out;
    }

    next_enq_fid1 = FLOW_ID_NONE;
    next_enq_fid2 = FLOW_ID_NONE;
    next_enq_fid3 = FLOW_ID_NONE;
    next_enq_fid4 = FLOW_ID_NONE;

    if (!next_cntxt_2_p->idle &&
        !next_cntxt_2_p->back_pressure) next_enq_fid1 = next_fid_p;

    if (next_fid_p != dp_fid_p &&
        !dp_cntxt_2_p->idle &&
        activated_by_dp) next_enq_fid2= dp_fid_p;

    if (next_fid_p != inc1_fid_p &&
        old_inc1_idle &&
        !inc1_cntxt_2_p->idle &&
        !inc1_cntxt_2_p->back_pressure) next_enq_fid3 = inc1_fid_p;

    if (next_fid_p != timeout_fid_p &&
        old_timeout_idle &&
        !timeout_cntxt_2_p->idle &&
        !timeout_cntxt_2_p->back_pressure) next_enq_fid4 = timeout_fid_p;
      
    timeout_val_out = timeout_fid_p != FLOW_ID_NONE;
    timeout_fid_out = timeout_fid_p;

    // Print updated contexts
    if (DEBUG){
      cout << endl << "updated next_cntxt_2_p: " << endl << *next_cntxt_2_p << endl;
      cout << endl << "updated next_cntxt_1_p: " << endl << *next_cntxt_1_p << endl;
      cout << "---------------------------------\n";

      cout << endl << "updated inc0_cntxt_1_p: " << endl << *inc0_cntxt_1_p << endl;
      cout << "---------------------------------\n";
      
      cout << endl << "updated inc1_cntxt_2_p: " << endl << *inc1_cntxt_2_p << endl;
      cout << endl << "updated inc1_cntxt_1_p: " << endl << *inc1_cntxt_1_p << endl;
      cout << "---------------------------------\n";

      cout << endl << "updated timeout_cntxt_2_p: " << endl << *timeout_cntxt_2_p << endl;
      cout << endl << "updated timeout_cntxt_1_p: " << endl << *timeout_cntxt_1_p << endl;
      cout << "---------------------------------\n";
      
      cout << endl << "updated dp_cntxt_2_p: " << endl << *dp_cntxt_2_p << endl;
      cout << "---------------------------------\n";

      cout << "dd out " << next_seq_fid_out << " " << next_seq_out << endl;
      cout << "---------------------------------\n";

      cout << "wnd size " << next_fid_p << " " << next_cntxt_1_p->wnd_size << endl;
      cout << "wnd size " << inc1_fid_p << " " << inc1_cntxt_1_p->wnd_size << endl;
      cout << "wnd size " << timeout_fid_p << " " << timeout_cntxt_1_p->wnd_size << endl;

      uint32_t time_offset = 11;
      cout << "rtx exptime " << next_fid_p << " " << (next_cntxt_2_p->rtx_exptime + time_offset) << endl;
      cout << "rtx exptime " << dp_fid_p << " " << (dp_cntxt_2_p->rtx_exptime + time_offset) << endl;
      cout << "rtx exptime " << inc1_fid_p << " " << (inc1_cntxt_2_p->rtx_exptime + time_offset)<< endl;
      cout << "rtx exptime " << timeout_fid_p << " " << (timeout_cntxt_2_p->rtx_exptime + time_offset)<< endl;

    }
    
  }

  prev_clk = clk;

  
  // Apply Changes

  uint32_t* next_fid_in_ptr = (uint32_t*)(non_idle->r_data);
  next_fid_in = *next_fid_in_ptr;
  // FIXME:delete next_fid_in_ptr;
  
};

ostream & operator << (ostream &out, const DDEngine::Context1 &c) 
{ 
  out << "next new: " << c.next_new << endl
      << "wnd start: " << c.wnd_start << endl
      << "wnd size: " << c.wnd_size << endl
      << "acked wnd: " << set_str(&(c.acked_wnd)) << endl;
  return out; 
}

ostream & operator << (ostream &out, const DDEngine::Context2 &c) 
{ 
  out << "idle: " << (int)c.idle << endl
      << "rtx exptime: " << c.rtx_exptime << endl
      << "active rtx timer: " << (int)c.active_rtx_timer << endl
      << "rtx timer amnt: " << c.rtx_timer_amnt << endl
      << "rtx wnd: " << set_str(&(c.rtx_wnd)) << endl
      << "back pressure: " << (int)c.back_pressure << endl
      << "pkt queue size: " << c.pkt_queue_size << endl;

  DDEngine::NewRenoContext* nreno_cntxt = (DDEngine::NewRenoContext*)c.user_cntxt;
  out << "prev hgst ack: " << nreno_cntxt->prev_hgst_ack << endl
      << "in recovery: " << nreno_cntxt->in_recovery << endl
      << "recover: " << nreno_cntxt->recover << endl
      << "in timeout: " << nreno_cntxt->in_timeout << endl
      << "wnd inc cntr: " << nreno_cntxt->wnd_inc_cntr << endl
      << "ss thresh: " << nreno_cntxt->ss_thresh << endl
      << "dup acks: " << nreno_cntxt->dup_acks << endl
;
  return out; 
}

