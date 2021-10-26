#ifndef RECEIVER_H
#define RECEIVER_H

#include <queue>
#include "system_defs.h"
#include "sliding_window.h"

using namespace std;

struct ReceiverResp{
  uint32_t fid;
  PktType pkt_type;
  PktData pkt_data;
};

class Receiver{
  public:
    Receiver(uint32_t, uint32_t, uint32_t);

    void tick_clk();
    

    void transmit(ReceiverResp&);
    void receive(uint32_t, uint32_t, uint8_t);
    virtual void receiver_resp(uint32_t, uint32_t,
                              uint32_t, uint8_t, ReceiverResp&) = 0;

    
  private:
    struct AckQueueElement {
      uint32_t fid;
      uint32_t cumulative_ack;
      uint32_t selective_ack;
      uint8_t sack_tx_id;
      uint64_t rcvd_time;

      bool operator<(const AckQueueElement& rhs) const{
        return rcvd_time > rhs.rcvd_time;
      }
    };

    uint32_t flow_cnt;
    float loss_prob;
    uint32_t rtt;

    uint64_t time_in_ns;

    priority_queue<AckQueueElement> ack_queue;

    SlidingWindow* rcvd;
};

#endif
