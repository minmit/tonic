#ifndef SLIDING_WINDOW__H
#define SLIDING_WINDOW__H

#include <set>
#include "system_defs.h"

using namespace std;

class SlidingWindow{
  public:
    SlidingWindow();

    void ack(uint32_t);
    uint32_t get_cack();

  private:
    set<uint32_t> elems;
    uint32_t head;
};

#endif
