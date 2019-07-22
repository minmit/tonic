#ifndef ACK_PRIO_QUEUE__H_
#define ACK_PRIO_QUEUE__H_

#include "constants.h"

struct AckQueueElement {
    unsigned int fid;
    unsigned int cumulative_ack;
    unsigned int selective_ack;
    unsigned int sack_tx_id;
    unsigned int rcvd_time;
};

struct AckPrioQueue {
    struct AckQueueElement elems[MAX_QUEUE_SIZE];
    int head;
    int cnt;
};

void prioInit(struct AckPrioQueue*);
int  prioSize(struct AckPrioQueue*);
bool prioIsEmpty (struct AckPrioQueue*);
bool prioIsFull (struct AckPrioQueue*);
struct AckQueueElement prioHead(struct AckPrioQueue*);
struct AckQueueElement prioDequeue(struct AckPrioQueue*);
void prioEnqueue(struct AckPrioQueue*, struct AckQueueElement); 
void prioPrint(struct AckPrioQueue*);

#endif
