#include "tonic.h"

#include <iostream>

using namespace std;

Tonic::Tonic(DDEngine* dd_engine, CREngine* cr_engine){
  this->dd_engine = dd_engine;
  this->cr_engine = cr_engine;

  OutQElem* none_elem = new OutQElem();
  none_elem->fid = FLOW_ID_NONE;
  outq = new Fifo1W(OUTQ_MAX_SIZE, none_elem);
}

void Tonic::eval(){
  
  // DD Engine
  dd_engine->clk = clk;
  dd_engine->rst_n = rst_n;
  
  dd_engine->dp_fid_in = dd_dp_fid;
  dd_engine->cr_cntxt_in = dd_cr_cntxt;

  uint32_t dd_incoming_fid = (pkt_type_in == SACK_PKT ||
                              pkt_type_in == CACK_PKT ||
                              pkt_type_in == NACK_PKT) ? incoming_fid_in : FLOW_ID_NONE;

  dd_engine->incoming_fid_in = dd_incoming_fid;
  dd_engine->pkt_type_in = pkt_type_in;
  dd_engine->pkt_data_in = pkt_data_in;

  dd_engine->eval();

  
  // CR Engine
  cr_engine->clk = clk;
  cr_engine->rst_n = rst_n;

  cr_engine->enq_fid_in = cr_enq_fid;
  cr_engine->enq_seq_in = cr_enq_seq;
  cr_engine->enq_seq_tx_id_in = cr_enq_seq_tx_id;

  cr_engine->dd_cntxt_in = cr_dd_cntxt;

  uint32_t cr_incoming_fid = (pkt_type_in == PULL_PKT) ? incoming_fid_in : FLOW_ID_NONE;
  cr_engine->incoming_fid_in = cr_incoming_fid;
  cr_engine->pkt_type_in = pkt_type_in;
  cr_engine->pkt_data_in = pkt_data_in;

  uint32_t timeout_fid = cr_timeout_val ? cr_timeout_fid : FLOW_ID_NONE;
  cr_engine->timeout_fid_in = timeout_fid;

  cr_engine->tx_val = tx_val;

  cr_engine->eval();

  // Fifo

  outq->clk = clk;
  outq->rst_n = rst_n;

  uint8_t outq_w_val = tonic_next_seq_fid != FLOW_ID_NONE;
  outq->w_val = outq_w_val;

  if (outq_w_val){
    OutQElem* outq_w_data = new OutQElem();
    outq_w_data->fid = tonic_next_seq_fid;
    outq_w_data->seq = tonic_next_seq;
    outq_w_data->tx_id = tonic_next_seq_tx_id;

    outq->w_data = outq_w_data;
  }
  else{
    outq->w_data = 0;
  }

  outq->r_val = link_avail;

  outq->eval();
  
  // Clock Positive Edge
  if (prev_clk == 0 &&
      clk == 1) {
    if (!rst_n){

      // Enq Fid 
      enq_fid_0 = FLOW_ID_NONE;
      enq_fid_1 = FLOW_ID_NONE;
      enq_fid_2 = FLOW_ID_NONE;
      enq_fid_3 = FLOW_ID_NONE;
      cr_enq_fid = FLOW_ID_NONE;

      // Enq Seq
      enq_seq_0 = FLOW_SEQ_NONE;
      enq_seq_1 = FLOW_SEQ_NONE;
      enq_seq_2 = FLOW_SEQ_NONE;
      enq_seq_3 = FLOW_SEQ_NONE;
      cr_enq_seq = FLOW_SEQ_NONE;

      // TX ID
      enq_seq_tx_id_0 = 0;
      enq_seq_tx_id_1 = 0;
      enq_seq_tx_id_2 = 0;
      enq_seq_tx_id_3 = 0;
      cr_enq_seq_tx_id = 0;

      // Timeout Val
      timeout_val_0 = 0;
      timeout_val_1 = 0;
      timeout_val_2 = 0;
      timeout_val_3 = 0;
      cr_timeout_val = 0;
 
      // Timeout FID
      timeout_fid_0 = 0;
      timeout_fid_1 = 0;
      timeout_fid_2 = 0;
      timeout_fid_3 = 0;
      cr_timeout_fid = 0;

      // DD Context
      dd_cntxt_0 = 0;
      dd_cntxt_1 = 0;
      dd_cntxt_2 = 0;
      dd_cntxt_3 = 0;
      cr_dd_cntxt = 0;

      // DP FID
      dp_fid_0 = FLOW_ID_NONE;
      dp_fid_1 = FLOW_ID_NONE;
      dp_fid_2 = FLOW_ID_NONE;
      dp_fid_3 = FLOW_ID_NONE;
      dd_dp_fid = FLOW_ID_NONE;

      // CR Context
      cr_cntxt_0 = FLOW_ID_NONE;
      cr_cntxt_1 = FLOW_ID_NONE;
      cr_cntxt_2 = FLOW_ID_NONE;
      cr_cntxt_3 = FLOW_ID_NONE;
      dd_cr_cntxt = FLOW_ID_NONE;

    }
    else{

      // Enq fid 
      cr_enq_fid = enq_fid_3;
      enq_fid_3 = enq_fid_2;
      enq_fid_2 = enq_fid_1;
      enq_fid_1 = enq_fid_0;
      enq_fid_0 = dd_next_seq_fid;

      // Enq Seq
      cr_enq_seq = enq_seq_3;
      enq_seq_3 = enq_seq_2;
      enq_seq_2 = enq_seq_1;
      enq_seq_1 = enq_seq_0;
      enq_seq_0 = dd_next_seq;

      // TX ID
      cr_enq_seq_tx_id = enq_seq_tx_id_3;
      enq_seq_tx_id_3 = enq_seq_tx_id_2;
      enq_seq_tx_id_2 = enq_seq_tx_id_1;
      enq_seq_tx_id_1 = enq_seq_tx_id_0;
      enq_seq_tx_id_0 = dd_next_seq_tx_id;

      // Timeout Val
      cr_timeout_val = timeout_val_3;
      timeout_val_3 = timeout_val_2;
      timeout_val_2 = timeout_val_1;
      timeout_val_1 = timeout_val_0;
      timeout_val_0 = dd_timeout_val;

      // Timeout Fid
      cr_timeout_fid = timeout_fid_3;
      timeout_fid_3 = timeout_fid_2;
      timeout_fid_2 = timeout_fid_1;
      timeout_fid_1 = timeout_fid_0;
      timeout_fid_0 = dd_timeout_fid;

      // DD Context
      cr_dd_cntxt = dd_cntxt_3;
      dd_cntxt_3 = dd_cntxt_2;
      dd_cntxt_2 = dd_cntxt_1;
      dd_cntxt_1 = dd_cntxt_0;
      dd_cntxt_0 = dd_cntxt;

      // DP FID
      dd_dp_fid = dp_fid_3;
      dp_fid_3 = dp_fid_2;
      dp_fid_2 = dp_fid_1;
      dp_fid_1 = dp_fid_0;
      dp_fid_0 = cr_dp_fid;

      // CR Context
      dd_cr_cntxt = cr_cntxt_3;
      cr_cntxt_3 = cr_cntxt_2;
      cr_cntxt_2 = cr_cntxt_1;
      cr_cntxt_1 = cr_cntxt_0;
      cr_cntxt_0 = cr_cntxt;

    }

    if (DEBUG){
      cout << "enq fid chain: " << enq_fid_0 << " " << enq_fid_1 << " " 
                                << enq_fid_2 << " " << enq_fid_3 << " " 
                                << cr_enq_fid << " " << endl;

      cout << "dp fid chain: " << dp_fid_0 << " " << dp_fid_1 << " " 
                                << dp_fid_2 << " " << dp_fid_3 << " " 
                                << dd_dp_fid << " " << endl;

    }
  }

  prev_clk = clk;

  //// Apply Changes

  // DD Engine
  dd_next_seq = dd_engine->next_seq_out;
  dd_next_seq_tx_id = dd_engine->next_seq_tx_id_out;
  dd_next_seq_fid = dd_engine->next_seq_fid_out;

  dd_timeout_val = dd_engine->timeout_val_out;
  dd_timeout_fid = dd_engine->timeout_fid_out;

  dd_cntxt = dd_engine->dd_cntxt_out;

  // CR Engine
  tonic_next_seq = cr_engine->next_seq_out;
  tonic_next_seq_tx_id = cr_engine->next_seq_tx_id_out;
  tonic_next_seq_fid = cr_engine->next_seq_fid_out;

  cr_dp_fid = cr_engine->dp_fid_out;
  cr_cntxt = cr_engine->cr_cntxt_out;

  // Fifo
  tx_val = outq->size < OUTQ_THRESH;
  OutQElem* outq_r_data = (struct OutQElem*) outq->r_data;
  
  next_seq_fid_out = outq_r_data->fid;
  next_seq_out = outq_r_data->seq;
  next_seq_tx_id_out = outq_r_data->tx_id;

  // TODO: delete the element?

  next_val = next_seq_fid_out != FLOW_ID_NONE;
};
