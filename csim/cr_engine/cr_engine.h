#ifndef CR_ENGINE__H
#define CR_ENGINE__H

#include "system_defs.h"

class CREngine{
  public:

    // Inputs

    uint8_t clk;
    uint8_t rst_n;

    uint32_t enq_fid_in;
    uint32_t enq_seq_in;
    uint32_t enq_seq_tx_id_in;

    uint32_t dd_cntxt_in;

    uint32_t incoming_fid_in;
    PktType pkt_type_in;
    PktData pkt_data_in;

    uint32_t timeout_fid_in;

    uint8_t tx_val;

    // Outputs
    uint32_t next_seq_fid_out;
    uint32_t next_seq_out;
    uint8_t next_seq_tx_id_out;

    uint32_t dp_fid_out;
    uint32_t cr_cntxt_out;

    virtual void eval() = 0;
};

#endif 
