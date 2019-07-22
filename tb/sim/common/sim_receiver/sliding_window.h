#ifndef SLIDING_WINDOW__H
#define SLIDING_WINDOW__H

#include "constants.h"

struct SlidingWindow{
    int elems[FLOW_WIN_SIZE];
    int head;
    int head_seq;
};

void SWInit(struct SlidingWindow*);
void SWAck(struct SlidingWindow*, int);
int SWGetCumulativeAck(struct SlidingWindow*);
void SWPrint(struct SlidingWindow*);
#endif
