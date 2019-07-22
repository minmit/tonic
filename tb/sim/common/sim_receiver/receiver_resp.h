#include "constants.h"

struct ReceiverResp{
    int fid;
    unsigned int pkt_type;
    char pkt_data[PKT_DATA_W];
};

void receiver_resp(int, int,
                   int, int,
                   struct ReceiverResp*);
