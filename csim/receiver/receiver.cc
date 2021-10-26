#include "receiver.h"

#include <iostream>
#include <stdlib.h>

using namespace std;

Receiver::Receiver(uint32_t flow_cnt, 
                   uint32_t loss_cnt_in_1000,
                   uint32_t rtt){
    this->flow_cnt = flow_cnt;
    rcvd = new SlidingWindow[flow_cnt];
    loss_prob = loss_cnt_in_1000 / 1000.0;
    this->rtt = rtt;
    time_in_ns = 0;
}

void Receiver::tick_clk(){
    time_in_ns += CYCLE_IN_NS;
}    

void Receiver::transmit(ReceiverResp& resp) {
    resp.fid = FLOW_ID_NONE;
    resp.pkt_type = NONE_PKT;
 
     
    if (!ack_queue.empty()){
        AckQueueElement ack = ack_queue.top();
        if (ack.rcvd_time <= time_in_ns){
            receiver_resp(ack.fid,
                          ack.cumulative_ack, 
                          ack.selective_ack, ack.sack_tx_id, resp);
            ack_queue.pop();
        }
    }

    if (DEBUG){
      cout << time_in_ns << " transmitted " << resp.fid << " " <<
                                             resp.pkt_data.cack_pkt.cack << endl;
    }
}


void Receiver::receive(uint32_t next_seq_fid, 
                       uint32_t next_seq, 
                       uint8_t next_seq_tx_id) {

    if (DEBUG){
    cout << time_in_ns << " received " << next_seq_fid << " " <<
                                          next_seq << " " << endl;
    }
    if (next_seq_fid > 0 &&
        next_seq_fid <= flow_cnt){
        double r = (double)rand() / (double)RAND_MAX;
        if (r > loss_prob){
            rcvd[next_seq_fid-1].ack(next_seq);
            
            AckQueueElement new_ack;
            new_ack.fid = next_seq_fid;
            new_ack.cumulative_ack = rcvd[next_seq_fid-1].get_cack();
            new_ack.selective_ack = next_seq;
            new_ack.sack_tx_id = next_seq_tx_id;
            new_ack.rcvd_time = time_in_ns + rtt; 
            ack_queue.push(new_ack);
        }
        else{
            if (PRINT_TRACE){
              cout << "dropped " << next_seq_fid << " " << next_seq << endl; 
            }
          }
    }
    else{
    }

}

