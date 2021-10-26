#include "fifo2w.h"

#include <iostream>
using namespace std;

Fifo2W::Fifo2W(int max_size, void* none_elem){
  this->max_size = max_size;
  this->none_elem = none_elem;
};

void Fifo2W::eval (){
 
  uint8_t srtd_w_val_0, srtd_w_val_1;
  void *srtd_w_data_0, *srtd_w_data_1;

  srtd_w_val_0 = w_val_0 || w_val_1; 
  srtd_w_val_1 = w_val_0 && w_val_1;

  srtd_w_data_0 = w_val_0 ? w_data_0 : w_data_1;
  srtd_w_data_1 = w_data_1;

  bool was_empty = elems.empty();
  // Positive Edge of the Clock
  if (prev_clk == 0 &&
      clk == 1){
    if (rst_n){
      if (DEBUG){
        cout << (int)srtd_w_val_0 << " " << *(uint32_t*)srtd_w_data_0 << endl;
        cout << (int)srtd_w_val_1 << " " << *(uint32_t*)srtd_w_data_1 << endl;
      }
      bool was_empty = elems.empty();
      if (r_val && !elems.empty()) elems.pop();
      if (srtd_w_val_0 && elems.size() < max_size &&
          !(was_empty && r_val)) elems.push(srtd_w_data_0);

      if (srtd_w_val_1 && elems.size() < max_size) elems.push(srtd_w_data_1);
    }
  }

  prev_clk = clk;

  bool empty_queue = elems.empty();
  if (was_empty && srtd_w_val_0) r_data = srtd_w_data_0;
  else if (empty_queue) r_data = none_elem;
  else r_data = elems.front();

  size = elems.size();
  full = elems.size() >= max_size;
  data_avail = !empty_queue || (empty_queue & srtd_w_val_0);
}

void Fifo2W::init_enq(void* elem){
  elems.push(elem);
}
