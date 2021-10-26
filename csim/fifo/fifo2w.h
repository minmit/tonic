#ifndef FIFO2W_H
#define FIFO2W_H

#include <queue>
#include "system_defs.h"

using namespace std;

class Fifo2W{
  public:
    // Inputs

    uint8_t clk;
    uint8_t rst_n;

    uint8_t w_val_0;
    void* w_data_0;

    uint8_t w_val_1;
    void* w_data_1;

    uint8_t r_val;

    // Outputs

    void* r_data;
    uint32_t size;
    uint8_t full;
    uint8_t data_avail;

    Fifo2W(int, void*);

    void eval();
    void init_enq(void*);

  private:
    queue<void*> elems;
    uint32_t max_size;
    void* none_elem;

    // clock
    uint8_t prev_clk;
};

#endif
