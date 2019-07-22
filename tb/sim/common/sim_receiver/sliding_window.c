#include "sliding_window.h"
#include "constants.h"

void SWInit(struct SlidingWindow* sw){
    sw->head = 0;
    sw->head_seq = 0; 
}

void SWAck(struct SlidingWindow* sw, int ack_seq){
    int ack_rel = ack_seq - sw->head_seq;
    if (ack_rel < 0 || ack_rel >= FLOW_WIN_SIZE) return;
    int ack = (sw->head + ack_rel) % FLOW_WIN_SIZE;
    sw->elems[ack] = 1;
    int i;
    int did_break = false;
    for (i = 0; i < FLOW_WIN_SIZE; i++){
        int ind = (sw->head + i) % FLOW_WIN_SIZE;
        if (sw->elems[ind]){
            sw->elems[ind] = 0;
        }
        else{
            did_break = true;
            break;
        }
    }
    
    if (did_break){
        sw->head = (sw->head + i) % FLOW_WIN_SIZE;
        sw->head_seq += i;
    }
    else{
        sw->head_seq += FLOW_WIN_SIZE;
    } 
}

int SWGetCumulativeAck(struct SlidingWindow* sw){
    return sw->head_seq;
}

void SWPrint(struct SlidingWindow* sw){
    int i;
    for (i = 0; i < FLOW_WIN_SIZE; i++){
        printf("%d:%d, ", sw->head_seq + i,
                          sw->elems[(sw->head + i) % FLOW_WIN_SIZE]);
    }
    printf("\n");             
}

