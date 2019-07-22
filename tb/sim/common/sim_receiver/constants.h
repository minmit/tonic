#ifndef CONSTANTS_H
#define CONSTANTS_H

typedef int bool;
#define true 1
#define false 0

#define CYCLE_IN_NS         10

#define PKT_DATA_W          100
#define FLOW_ID_NONE        0xFFFF
#define MAX_FLOW_CNT        1024
#define MAX_FLOW_ID         (1 << 16)
#define FLOW_SEQ_NUM_NONE   0xFFFFFFFF
#define MAX_QUEUE_SIZE      2000
#define FLOW_WIN_SIZE       1024

#define NONE_PKT            0xFFFF
#define SACK_PKT            0
#define PULL_PKT            1
#define NACK_PKT            2
#define CACK_PKT            3


#define NEXT_SEQ_PATH       "sim_top.sim_receiver.next_seq_in"
#define NEXT_SEQ_TX_ID_PATH "sim_top.sim_receiver.next_seq_tx_id_in"
#define NEXT_SEQ_FID_PATH   "sim_top.sim_receiver.next_seq_fid_in"

#define RESP_FID_PATH       "sim_top.sim_receiver.read_resp_fid"
#define RESP_PKT_TYPE_PATH  "sim_top.sim_receiver.read_resp_pkt_type"
#define RESP_PKT_DATA_PATH  "sim_top.sim_receiver.read_resp_pkt_data"

#define LOSS_PATH           "sim_top.sim_receiver.LINK_LOSS_PROB"
#define RTT_PATH            "sim_top.sim_receiver.LINK_RTT"

#endif
