#include "cwnd_cr_engine.h"

#include <iostream>

CwndCREngine::CwndCREngine(uint32_t flow_cnt){
  this->flow_cnt = flow_cnt;
  none_elem = FLOW_ID_NONE;
  tx_fifo = new Fifo2W(flow_cnt, &none_elem);

  queue_w_data_0 = new uint32_t(FLOW_ID_NONE);
  queue_w_data_1 = new uint32_t(FLOW_ID_NONE);
  
  for (uint32_t i = 0; i < flow_cnt; i++){

    // init ram
    Context* flow_cntxt = new Context();
    ram[i + 1] = flow_cntxt;
  }
  
  Context* flow_cntxt = new Context();
  ram[FLOW_ID_NONE] = flow_cntxt;  

  // other inits
  incoming_fid_in = FLOW_ID_NONE;
  enq_fid_in = FLOW_ID_NONE;

}

void CwndCREngine::eval(){
  // Fifo
  tx_fifo->clk = clk;
  tx_fifo->rst_n = rst_n;

  uint8_t tx_fifo_w_val_0, tx_fifo_w_val_1;
  tx_fifo_w_val_0 = *queue_w_data_0 != FLOW_ID_NONE;
  tx_fifo_w_val_1 = *queue_w_data_1 != FLOW_ID_NONE;

  tx_fifo->w_val_0  = tx_fifo_w_val_0;
  tx_fifo->w_data_0 = queue_w_data_0;
  tx_fifo->w_val_1  = tx_fifo_w_val_1;
  tx_fifo->w_data_1 = queue_w_data_1;
  tx_fifo->r_val    = tx_val;
  
  tx_fifo->eval();
 
  //// CR Core
  
  // Positive edge of clock
  if (prev_clk == 0 &&
      clk == 1){
    if (!rst_n){

      // Fifo
      queue_w_data_0 = new uint32_t(FLOW_ID_NONE);
      queue_w_data_1 = new uint32_t(FLOW_ID_NONE);

      // Ps
      enq_fid_p = FLOW_ID_NONE;
      tx_fid_p = FLOW_ID_NONE;
      
      enq_seq_p = FLOW_SEQ_NONE;
      // Ls
      enq_fid_l = FLOW_ID_NONE;
      tx_fid_l = FLOW_ID_NONE;

      enq_seq_l = FLOW_SEQ_NONE;
    }
    else{
      // Fifo
      queue_w_data_0 = new uint32_t(tx_enq_fid1);
      queue_w_data_1 = new uint32_t(tx_enq_fid2);

      // Ps
      enq_fid_p = enq_fid_l;
      tx_fid_p = tx_fid_l;

      enq_seq_p = enq_seq_l;

      // Ls
      enq_fid_l = enq_fid_in;
      tx_fid_l = tx_fid_in;

      enq_seq_l = enq_seq_in;
    }
    
    ////////// Look up P contexts ////////////
    Context *enq_cntxt_p, *tx_cntxt_p;

    enq_cntxt_p = ram[enq_fid_p];
    tx_cntxt_p = ram[tx_fid_p];
    
    if (DEBUG){

      cout << "enq_fid_in: " << enq_fid_in << endl;
      cout << "tx_fid_in: " << tx_fid_in << endl;
      cout << "--------------------------" << endl;

      cout << "enq_fid_p: " << enq_fid_p << endl;
      cout << "enq_cntxt_p: " << endl << *enq_cntxt_p << endl;
      cout << "--------------------------" << endl;
      
      cout << "tx_fid_p: " << tx_fid_p << endl;
      cout << "tx_cntxt_p: " << endl << *tx_cntxt_p << endl;
      cout << "--------------------------" << endl;
 
    }
    //////// Process events //////////

    //// Enq
    enq_cntxt_p->pkt_queue.push(enq_seq_p);

    ////
    next_seq_out = FLOW_SEQ_NONE;
    next_seq_fid_out = tx_fid_p;
    next_seq_tx_id_out = 0;

    if (tx_fid_p != FLOW_ID_NONE) { 
      next_seq_out = tx_cntxt_p->pkt_queue.front();
      tx_cntxt_p->pkt_queue.pop();
    }  
    
    ///////////// Merge //////////////
       
    // ready_to_tx and output
   
    tx_enq_fid1 = FLOW_ID_NONE;
    tx_enq_fid2 = FLOW_ID_NONE;

 
    tx_cntxt_p->ready_to_tx = !tx_cntxt_p->pkt_queue.empty();
    if (tx_cntxt_p->ready_to_tx) tx_enq_fid2 = tx_fid_p;
    if (tx_fid_p != enq_fid_p &&
        enq_cntxt_p->pkt_queue.size() == 1){
      enq_cntxt_p->ready_to_tx = true;
      tx_enq_fid1 = enq_fid_p;
    }
    
   
    dp_fid_out = tx_fid_p;
    cr_cntxt_out = 0;

    // Print updated contexts
    if (DEBUG){
      cout << "enq_fid_p: " << enq_fid_p << endl;
      cout << "updated enq_cntxt_p: " << endl << *enq_cntxt_p << endl;
      cout << "--------------------------" << endl;
      
      cout << "tx_fid_p: " << tx_fid_p << endl;
      cout << "updated tx_cntxt_p: " << endl << *tx_cntxt_p << endl;
      cout << "--------------------------" << endl;
    }
    
  }

  prev_clk = clk;

  
  // Apply Changes

  uint32_t* tx_fid_tmp_ptr = (uint32_t*)(tx_fifo->r_data);
  uint32_t tx_fid_tmp = *tx_fid_tmp_ptr;
  tx_fid_in = tx_val ? tx_fid_tmp : FLOW_ID_NONE;
  // FIXME:delete next_fid_in_ptr;
}

ostream & operator << (ostream &out, const CwndCREngine::Context &c) 
{ 
  out << "ready to tx: " << c.ready_to_tx << endl
      << "pkt queue head: " << (c.pkt_queue.empty() ? FLOW_SEQ_NONE : c.pkt_queue.front()) << endl
      << "pkt queue size: " << c.pkt_queue.size() << endl; 
  
  
  return out; 
}


