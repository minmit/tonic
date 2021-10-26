#include "util.h"

#include <sstream>

string set_str(const set<uint32_t>* s){
    stringstream ss;
    ss << "{";
    for (set<uint32_t>::iterator it = s->begin();
                                 it != s->end();
                                 it++){
      ss << *it << ", ";
    }
    ss << "}";
    return ss.str();
}
