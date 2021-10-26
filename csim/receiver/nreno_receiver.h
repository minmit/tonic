#ifndef NEW_RENO_RECEIVER__H
#define NEW_RENO_RECEIVER__H

#include "receiver.h"
#include <iostream>

using namespace std;

class NewRenoReceiver: public Receiver{
  public:
    NewRenoReceiver(uint32_t flow_cnt, 
                    uint32_t loss_cnt_in_1000,
                    uint32_t rtt) : Receiver(flow_cnt, 
                                            loss_cnt_in_1000,
                                            rtt){}

    void receiver_resp(uint32_t fid, uint32_t cack, 
                       uint32_t sack, uint8_t sack_tx_id,
                       ReceiverResp& resp){
      resp.fid = fid;
      resp.pkt_type = CACK_PKT;
      resp.pkt_data.cack_pkt.cack = cack;
    }
};

#endif
