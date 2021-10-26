#ifndef TONIC_H
#define TONIC_H

#include "system_defs.h"
#include "dd_engine/dd_engine.h"
#include "cr_engine/cr_engine.h"
#include "fifo/fifo1w.h"

class Tonic{
  public:

    // Inputs

    uint8_t clk;
    uint8_t rst_n;

    uint32_t incoming_fid_in;
    PktType pkt_type_in;
    PktData pkt_data_in;

    uint8_t link_avail;

    // Outputs
    uint8_t next_val;
    uint32_t next_seq_fid_out;
    uint32_t next_seq_out;
    uint8_t next_seq_tx_id_out;


    Tonic(DDEngine*, CREngine*);

    void eval();

  private:

    // Engines
    DDEngine* dd_engine;
    CREngine* cr_engine;

    // Outgoing Queue
    Fifo1W* outq;

    // fifo elements
    struct OutQElem{
      uint32_t fid;
      uint32_t seq;
      uint8_t tx_id;
    };

    // clock
    uint32_t prev_clk;

    // DD Output
    uint32_t dd_next_seq;
    uint8_t dd_next_seq_tx_id;
    uint32_t dd_next_seq_fid;

    uint8_t dd_timeout_val;
    uint32_t dd_timeout_fid;

    uint32_t dd_cntxt;

    // CR Output
    uint32_t tonic_next_seq;
    uint8_t tonic_next_seq_tx_id;
    uint32_t tonic_next_seq_fid;

    uint32_t cr_dp_fid;
    uint32_t cr_cntxt;

    // CR Input
    uint8_t tx_val;

    // Registers

    // DD to CR
    uint32_t enq_fid_0;
    uint32_t enq_fid_1;
    uint32_t enq_fid_2;
    uint32_t enq_fid_3;
    uint32_t cr_enq_fid;

    uint32_t enq_seq_0;
    uint32_t enq_seq_1;
    uint32_t enq_seq_2;
    uint32_t enq_seq_3;
    uint32_t cr_enq_seq;

    uint8_t enq_seq_tx_id_0;
    uint8_t enq_seq_tx_id_1;
    uint8_t enq_seq_tx_id_2;
    uint8_t enq_seq_tx_id_3;
    uint8_t cr_enq_seq_tx_id;

    uint8_t timeout_val_0;
    uint8_t timeout_val_1;
    uint8_t timeout_val_2;
    uint8_t timeout_val_3;
    uint8_t cr_timeout_val;

    uint32_t timeout_fid_0;
    uint32_t timeout_fid_1;
    uint32_t timeout_fid_2;
    uint32_t timeout_fid_3;
    uint32_t cr_timeout_fid;

    uint32_t dd_cntxt_0;
    uint32_t dd_cntxt_1;
    uint32_t dd_cntxt_2;
    uint32_t dd_cntxt_3;
    uint32_t cr_dd_cntxt;

    // CR to DD

    uint32_t dp_fid_0;
    uint32_t dp_fid_1;
    uint32_t dp_fid_2;
    uint32_t dp_fid_3;
    uint32_t dd_dp_fid;

    uint32_t cr_cntxt_0;
    uint32_t cr_cntxt_1;
    uint32_t cr_cntxt_2;
    uint32_t cr_cntxt_3;
    uint32_t dd_cr_cntxt;
};

#endif
