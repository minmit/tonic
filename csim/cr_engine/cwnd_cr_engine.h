#ifndef CWND_CR_ENGINE__H
#define CWND_CR_ENGINE__H

#include "cr_engine.h"
#include "../fifo/fifo2w.h"

#include <queue>
#include <map>

using namespace std;

class CwndCREngine : public CREngine {
  public:
    CwndCREngine(uint32_t);

    void eval();

  struct Context{
      bool ready_to_tx;
      queue<uint32_t> pkt_queue;

      friend ostream & operator << (ostream &out, const CwndCREngine::Context &c); 
    };

  private:
    uint32_t flow_cnt = 0;
    map<uint32_t, Context*> ram;
    Fifo2W* tx_fifo;
    uint32_t none_elem = FLOW_ID_NONE;

    uint8_t prev_clk = 0;

    uint32_t *queue_w_data_0;
    uint32_t *queue_w_data_1;

    uint32_t tx_fid_in = FLOW_ID_NONE;

    uint32_t enq_fid_p = FLOW_ID_NONE;
    uint32_t tx_fid_p = FLOW_ID_NONE;
    uint32_t enq_seq_p = FLOW_SEQ_NONE;

    uint32_t enq_fid_l = FLOW_ID_NONE;
    uint32_t tx_fid_l = FLOW_ID_NONE;
    uint32_t enq_seq_l = FLOW_SEQ_NONE;

    uint32_t tx_enq_fid1 = FLOW_ID_NONE;
    uint32_t tx_enq_fid2 = FLOW_ID_NONE;
};

#endif 
