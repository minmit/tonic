#include "fifo1w.h"

Fifo1W::Fifo1W(int max_size, void* none_elem){
  this->max_size = max_size;
  this->none_elem = none_elem;
};

void Fifo1W::eval (){
  
  // Positive Edge of the Clock
  if (prev_clk == 0 &&
      clk == 1){
    if (r_val && !elems.empty()) elems.pop();
    if (w_val && elems.size() < max_size &&
        !(elems.empty() && r_val)) elems.push(w_data);

  }

  prev_clk = clk;

  bool empty_queue = elems.empty();
  if (empty_queue && w_val) r_data = w_data;
  else if (empty_queue) r_data = none_elem;
  else r_data = elems.front();

  full = elems.size() >= max_size;
  data_avail = !empty_queue || (empty_queue & w_val);
}
