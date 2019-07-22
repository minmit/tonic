#include "ack_prio_queue.h"
#include <stddef.h>
#include <stdio.h>

void prioInit(struct AckPrioQueue* q){
    q->cnt = 0;
    q->head = 0;
}

int  prioSize(struct AckPrioQueue* q){
    return q->cnt;
}

bool prioIsEmpty (struct AckPrioQueue* q){
    return (q->cnt == 0);
}

bool prioIsFull (struct AckPrioQueue* q){
    return (q->cnt == MAX_QUEUE_SIZE);
}

struct AckQueueElement prioHead(struct AckPrioQueue* q){
    if (prioIsEmpty(q)){
        struct AckQueueElement tmp;
        return tmp;
    }
    else {
        return q->elems[q->head];
    }
}
    
struct AckQueueElement prioDequeue(struct AckPrioQueue* q){
    if (prioIsEmpty(q)){
        struct AckQueueElement tmp;
        return tmp;
    }
    else{
        int prev_head = q->head;
        q->head = (q->head + 1) % MAX_QUEUE_SIZE;
        q->cnt--;    
        return q->elems[prev_head];
    }
}
    
void prioEnqueue(struct AckPrioQueue* q, struct AckQueueElement a){
    if (!prioIsFull(q)){
        int i;
        int found_ind = (q->head + q->cnt) % MAX_QUEUE_SIZE;
        if (a.rcvd_time < q->elems[q->head].rcvd_time){
            int new_head = (q->head - 1 + MAX_QUEUE_SIZE) % MAX_QUEUE_SIZE; 
            q->elems[new_head] = a;
            q->head = new_head;
            q->cnt++;
        }
        else{
            for (i = 0; i < q->cnt; i++){
                int rcvd_time1 = q->elems[(q->head + i) % MAX_QUEUE_SIZE].rcvd_time;
                int rcvd_time2 = q->elems[(q->head + i + 1) % MAX_QUEUE_SIZE].rcvd_time;
                if (a.rcvd_time >= rcvd_time1 && a.rcvd_time < rcvd_time2){
                    found_ind = i + 1;
                    break;
                }
            }
            if (found_ind != (q->head + q->cnt) % MAX_QUEUE_SIZE){
                for (i = 0; i < found_ind; i++){
                    q->elems[(q->head + i - 1 + MAX_QUEUE_SIZE) % MAX_QUEUE_SIZE] = 
                        q->elems[(q->head + i) % MAX_QUEUE_SIZE];
                }
                q->elems[(q->head + found_ind - 1 + MAX_QUEUE_SIZE) % MAX_QUEUE_SIZE] = a;
                q->head = (q->head - 1 + MAX_QUEUE_SIZE) % MAX_QUEUE_SIZE;
            }
            else if(q->elems[(found_ind - 1 + MAX_QUEUE_SIZE)% MAX_QUEUE_SIZE].rcvd_time >
                    a.rcvd_time){
                q->elems[found_ind] = q->elems[(found_ind - 1 + MAX_QUEUE_SIZE)% MAX_QUEUE_SIZE];
                q->elems[(found_ind - 1 + MAX_QUEUE_SIZE)% MAX_QUEUE_SIZE] = a;
            }
            else{
                q->elems[found_ind] = a;
            }
            q->cnt++;
        }
    }
}

void prioPrint(struct AckPrioQueue* q){
    int i;
    printf("Ack queue: ");
    for (i = 0; i < q->cnt; i++){
        struct AckQueueElement tmp = q->elems[(q->head + i) % MAX_QUEUE_SIZE]; 
        printf("%d %d %d %d,", tmp.fid, tmp.cumulative_ack, tmp.selective_ack, tmp.rcvd_time);
    }
    printf("\n");
} 
