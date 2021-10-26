#include "sliding_window.h"
#include "../utils/util.h"

#include <iostream>

using namespace std;

SlidingWindow::SlidingWindow(){
    head = 0;
}

void SlidingWindow::ack(uint32_t ack_seq){
    if (ack_seq < head) return;
    
    elems.insert(ack_seq);
    set<uint32_t>::iterator it = elems.begin();

    while(*it == head && it != elems.end()){
      head++;
      it++;
    }
    elems.erase(elems.begin(), it);
}

uint32_t SlidingWindow::get_cack(){
    return head;
}

