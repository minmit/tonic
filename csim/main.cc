#include "system_defs.h"
#include "tonic.h"
#include "receiver/nreno_receiver.h"
#include "cr_engine/cwnd_cr_engine.h"
#include "dd_engine/dd_engine.h"

#include <iostream>
#include <sstream>
#include <string>
#include <stdlib.h>
#include <fstream>

#define NDEBUG
#include <assert.h>

using namespace std;

const uint32_t REF_FLOW_ID_NONE = 1023;

class TonicTestBench{
  public:

    TonicTestBench(uint32_t flow_cnt,
                   uint32_t loss_cnt_in_1000,
                   uint32_t rtt,
                   uint32_t sim_cycles){
      this->flow_cnt = flow_cnt;
      this->sim_cycles = sim_cycles;

      CREngine* cr_engine = new CwndCREngine(flow_cnt);
      DDEngine* dd_engine = new DDEngine(flow_cnt);

      tonic = new Tonic(dd_engine, cr_engine);

      receiver = new NewRenoReceiver(flow_cnt,
                                     loss_cnt_in_1000,
                                     rtt);

      src_fname = "refs/" + to_string(loss_cnt_in_1000) + "/src.txt"; 
      sink_fname = "refs/" + to_string(loss_cnt_in_1000) + "/sink.txt"; 
    }

    
    void run(){
      reset();
      tonic->link_avail = 1;

      ReceiverResp resp;

      // open refs
      ifstream src_file(src_fname);
      ifstream sink_file(sink_fname);

      for (int i = 0; i < sim_cycles; i++){
        if (PRINT_TRACE){
          cout << "####################################" << endl;
          cout << "Time " << i << endl;
          print_input();
        } 

        // check input with ref
        uint32_t ref_incoming_fid;
        uint32_t ref_pkt_type_int;
        string ref_pkt_data_str;

        src_file >> ref_incoming_fid >> ref_pkt_type_int >> ref_pkt_data_str;

        if (PRINT_TRACE){
          cout << "ref in " << ref_incoming_fid << " " << ref_pkt_type_int << " " << 
                               stoi(ref_pkt_data_str.substr(0, 32), nullptr, 2) << endl;
        }
        
        if (ref_incoming_fid != REF_FLOW_ID_NONE){
          assert(ref_incoming_fid == tonic->incoming_fid_in);
        
          // convert pkt_type
          PktType ref_pkt_type = ref_pkt_type_int < 4 ? ref_pkt_types[ref_pkt_type_int] : NONE_PKT;

          assert(ref_pkt_type == tonic->pkt_type_in);

          if (ref_pkt_type == CACK_PKT){
            string cack_str = ref_pkt_data_str.substr(0, 32);
            assert(stoi(cack_str, nullptr, 2) == tonic->pkt_data_in.cack_pkt.cack);
          }
        }
        else{
          assert(tonic->incoming_fid_in == FLOW_ID_NONE);
        }

        // calculate tonic output
        tick();

        if (PRINT_TRACE){
          print_output();
        }
 
        // check output with ref
        uint32_t ref_next_val;
        uint32_t ref_next_seq_fid_out;
        uint32_t ref_next_seq_out;
        uint32_t ref_next_seq_tx_id_out;

        sink_file >> ref_next_val >> ref_next_seq_fid_out >> ref_next_seq_out >> ref_next_seq_tx_id_out;
      
        if (PRINT_TRACE){ 
          cout << "ref out " << ref_next_seq_fid_out << " " << ref_next_seq_out << endl;
        }

        assert(ref_next_val == tonic->next_val);
        if (ref_next_val){
          assert(ref_next_seq_fid_out == tonic->next_seq_fid_out);
          assert(ref_next_seq_out == tonic->next_seq_out);
        }

        receiver->tick_clk();
        if (tonic->next_val){
          receiver->receive(tonic->next_seq_fid_out,
                           tonic->next_seq_out,
                           tonic->next_seq_tx_id_out);
        } 

        receiver->transmit(resp);
        tonic->incoming_fid_in = resp.fid;
        tonic->pkt_type_in = resp.pkt_type;
        tonic->pkt_data_in = resp.pkt_data;

      }

      src_file.close();
      sink_file.close();
    }

  private:
    Tonic* tonic;
    Receiver* receiver;

    uint32_t flow_cnt;
    uint32_t sim_cycles;

    PktType ref_pkt_types[4] = {SACK_PKT, PULL_PKT, NACK_PKT, CACK_PKT};

    string src_fname, sink_fname;

    void reset(){
      tonic->rst_n = 0;
      tonic->incoming_fid_in = FLOW_ID_NONE;
      tonic->pkt_type_in = NONE_PKT;
      tick();
      tonic->rst_n = 1;
    }

    void tick(){
      tonic->clk = 0;
      tonic->eval();

      tonic->clk = 1;
      tonic->eval();
    }
 
    string pkt_type_str(PktType type){
      string res = type == SACK_PKT ? "SACK" :
                   type == PULL_PKT ? "PULL" :
                   type == NACK_PKT ? "NACK" :
                   type == CACK_PKT ? "CACK" :
                   type == NONE_PKT ? "NONE" :
                   "UDEF";
      return res;
    }

    string pkt_data_str(PktType type, PktData data){
      stringstream ss;
      if (type == CACK_PKT){
        ss << data.cack_pkt.cack;
      }
      return ss.str();
    }

    void print_input(){
      cout << "pkt in " << tonic->incoming_fid_in << " "
                        << pkt_type_str(tonic->pkt_type_in) << " "
                        << pkt_data_str(tonic->pkt_type_in, 
                                        tonic->pkt_data_in) << endl;
    }

    void print_output(){
      if (tonic->next_val){
        cout << "pkt out " << tonic->next_seq_fid_out << " " <<
                              tonic->next_seq_out << " " <<
                              (int)tonic->next_seq_tx_id_out << endl;
      }
      else{
        cout << "pkt out NONE" << endl;
      }
    }

};

int main(){
  srand(123456789);
  uint32_t flow_cnt = 4;
  uint32_t rtt = 30;
  uint32_t loss_cnt_in_1000 = 300;
  uint32_t sim_cycles = 100000;

  TonicTestBench tb(flow_cnt, 
                    loss_cnt_in_1000,
                    rtt,
                    sim_cycles);
  tb.run();

  return 0;
}
