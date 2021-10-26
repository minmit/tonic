#ifndef DD_ENGINE__H
#define DD_ENGINE__H

#include "system_defs.h"
#include "../fifo/fifo4w.h"
#include <set>
#include <map>

using namespace std;

class DDEngine{
  public:
    
    // Inputs

    uint8_t clk;
    uint8_t rst_n;

    uint32_t dp_fid_in;
    uint32_t cr_cntxt_in;

    uint32_t incoming_fid_in;
    PktType pkt_type_in;
    PktData pkt_data_in;

    // Outputs

    uint32_t next_seq_fid_out;
    uint32_t next_seq_out;
    uint8_t next_seq_tx_id_out;

    uint8_t timeout_val_out;
    uint32_t timeout_fid_out;

    uint32_t dd_cntxt_out;

    DDEngine(uint32_t);
    void eval();

    struct Context1{
      uint32_t next_new;
      uint32_t wnd_start;
      set<uint32_t> acked_wnd;
      uint32_t wnd_size;

      friend ostream & operator << (ostream &out, const DDEngine::Context1 &c); 
    };

    struct Context2{
      set<uint32_t> rtx_wnd;
      uint8_t idle;
      uint8_t back_pressure;
      uint32_t pkt_queue_size; 
      uint32_t rtx_exptime;
      uint8_t active_rtx_timer;
      uint32_t rtx_timer_amnt; 
      void * user_cntxt;

      friend ostream & operator << (ostream &out, const DDEngine::Context2 &c); 
    };

    struct NewRenoContext{
      uint32_t prev_hgst_ack;
      bool in_recovery;
      uint32_t recover;
      bool in_timeout;
      uint32_t wnd_inc_cntr;
      uint32_t ss_thresh;
      uint32_t dup_acks;
    };

  private:
    uint32_t flow_cnt = 0;
    map<uint32_t, Context1*> ram1;
    map<uint32_t, Context2*> ram2;
    Fifo4W* non_idle;
    uint32_t none_elem = FLOW_ID_NONE;

    uint8_t prev_clk = 0;

    uint32_t *next_enq_fid1_q;
    uint32_t *next_enq_fid2_q;
    uint32_t *next_enq_fid3_q;
    uint32_t *next_enq_fid4_q;

    uint32_t cack_in = FLOW_SEQ_NONE; 
    uint32_t sack_in = FLOW_SEQ_NONE;
    uint32_t sack_tx_id_in = 0;

    uint32_t next_fid_in = FLOW_ID_NONE;
    uint32_t inc0_fid_in = FLOW_ID_NONE;
    uint32_t inc1_fid_in = FLOW_ID_NONE;
    uint32_t timeout_fid_in = FLOW_ID_NONE;

    uint32_t inc1_cack = FLOW_SEQ_NONE;
    uint32_t inc1_sack = FLOW_SEQ_NONE;
    uint32_t inc1_sack_tx_id = 0;

    uint32_t inc1_new_c_acks_cnt = 0;
    uint8_t inc1_valid_sack = 0;
    uint32_t inc1_old_wnd_start = 0;
    PktType inc1_pkt_type = NONE_PKT;

    uint32_t next_fid_p = FLOW_ID_NONE;
    uint32_t inc0_fid_p = FLOW_ID_NONE;
    uint32_t inc1_fid_p = FLOW_ID_NONE;
    uint32_t timeout_fid_p = FLOW_ID_NONE;
    uint32_t dp_fid_p = FLOW_ID_NONE;

    uint32_t cack_p = FLOW_SEQ_NONE;
    uint32_t sack_p = FLOW_SEQ_NONE;
    uint32_t sack_tx_id_p = 0;
    PktType pkt_type_p = NONE_PKT;

    uint32_t next_fid_l = FLOW_ID_NONE;
    uint32_t inc0_fid_l = FLOW_ID_NONE;
    uint32_t inc1_fid_l = FLOW_ID_NONE;
    uint32_t timeout_fid_l = FLOW_ID_NONE;
    uint32_t dp_fid_l = FLOW_ID_NONE;

    uint32_t cack_l = FLOW_SEQ_NONE;
    uint32_t sack_l = FLOW_SEQ_NONE;
    uint32_t sack_tx_id_l = 0;
    PktType pkt_type_l = NONE_PKT;

    uint64_t global_time = 0;

    uint32_t next_enq_fid1 = FLOW_ID_NONE;
    uint32_t next_enq_fid2 = FLOW_ID_NONE;
    uint32_t next_enq_fid3 = FLOW_ID_NONE;
    uint32_t next_enq_fid4 = FLOW_ID_NONE;

    uint32_t inc0_new_c_acks_cnt = 0;
    uint8_t inc0_valid_sack = 0;
    uint32_t inc0_old_wnd_start = 0;

    bool inc1_reset_rtx_timer = false;

};

#endif
