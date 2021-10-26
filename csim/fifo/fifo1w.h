#ifndef FIFO1W_H
#define FIFO1W_H

#include <queue>
#include "system_defs.h"

using namespace std;

class Fifo1W{
  public:
    // Inputs

    uint8_t clk;
    uint8_t rst_n;

    uint8_t w_val;
    void* w_data;

    uint8_t r_val;

    // Outputs

    void* r_data;
    uint32_t size;
    uint8_t full;
    uint8_t data_avail;

    Fifo1W(int, void*);

    void eval();
  
  private:
    queue<void*> elems;
    uint32_t max_size;
    void* none_elem;

    // clock
    uint8_t prev_clk;
};

#endif
