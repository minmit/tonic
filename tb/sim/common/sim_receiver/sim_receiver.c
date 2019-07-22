#include <stddef.h>
#include <stdlib.h>
#include "vpi_user.h"

#include "constants.h"
#include "ack_prio_queue.h"
#include "sliding_window.h"

#include "receiver_resp.h"

double LOSS_PROB = 1;
double RTT_IN_NS = 0;

long long int time_in_ns = 0;

struct AckPrioQueue ackQueue;

struct SlidingWindow rcvd[MAX_FLOW_CNT];


void init(void){
    vpiHandle loss_handle = vpi_handle_by_name(LOSS_PATH, NULL);
    s_vpi_value loss_val = {vpiIntVal};
    vpi_get_value(loss_handle, &loss_val); 
    LOSS_PROB = loss_val.value.integer / 1000.0;
   
    vpiHandle rtt_handle = vpi_handle_by_name(RTT_PATH, NULL);
    s_vpi_value rtt_val = {vpiIntVal};
    vpi_get_value(rtt_handle, &rtt_val);
    RTT_IN_NS = rtt_val.value.integer;

    srand(123456789);
}

void send_clk(void){
    time_in_ns += CYCLE_IN_NS;
}    

void read_inputs(void) {
//    vpi_printf("-------------\n");

        
    struct ReceiverResp resp;
    resp.fid = FLOW_ID_NONE;
    resp.pkt_type = NONE_PKT;
    sprintf(resp.pkt_data, "%0*d", PKT_DATA_W, 0);
 
     
    if (!prioIsEmpty(&ackQueue)){
        struct AckQueueElement ack = prioHead(&ackQueue);

        if (ack.rcvd_time <= time_in_ns){
            receiver_resp(ack.fid,
                          ack.cumulative_ack, 
                          ack.selective_ack, ack.sack_tx_id, &resp);
            prioDequeue(&ackQueue);
        }
    }

    vpiHandle resp_fid_handle = vpi_handle_by_name(RESP_FID_PATH, NULL);
    s_vpi_value resp_fid_val = {vpiIntVal, resp.fid};
    vpi_put_value(resp_fid_handle, &resp_fid_val, NULL, vpiNoDelay);
    
    vpiHandle resp_pkt_type_handle = vpi_handle_by_name(RESP_PKT_TYPE_PATH, NULL);
    s_vpi_value resp_pkt_type_val = {vpiIntVal, resp.pkt_type};
    vpi_put_value(resp_pkt_type_handle, &resp_pkt_type_val, NULL, vpiNoDelay);

    vpiHandle resp_pkt_data_handle = vpi_handle_by_name(RESP_PKT_DATA_PATH, NULL);
    s_vpi_value resp_pkt_data_val = {vpiBinStrVal, resp.pkt_data};
    vpi_put_value(resp_pkt_data_handle, &resp_pkt_data_val, NULL, vpiNoDelay);
}


void write_outputs(void) {
    vpiHandle next_seq_handle = vpi_handle_by_name(NEXT_SEQ_PATH, NULL);
    s_vpi_value next_seq_val = {vpiIntVal};
    vpi_get_value(next_seq_handle, &next_seq_val);
    int next_seq = next_seq_val.value.integer;
   
    vpiHandle next_seq_tx_id_handle = vpi_handle_by_name(NEXT_SEQ_TX_ID_PATH, NULL);
    s_vpi_value next_seq_tx_id_val = {vpiIntVal};
    vpi_get_value(next_seq_tx_id_handle, &next_seq_tx_id_val);
    int next_seq_tx_id = next_seq_tx_id_val.value.integer;
 
    vpiHandle next_seq_fid_handle = vpi_handle_by_name(NEXT_SEQ_FID_PATH, NULL);
    s_vpi_value next_seq_fid_val = {vpiIntVal};
    vpi_get_value(next_seq_fid_handle, &next_seq_fid_val);
    int next_seq_fid = next_seq_fid_val.value.integer;

    if (next_seq_fid > 0 &&
        next_seq_fid < MAX_FLOW_CNT - 1){
        double r = (double)rand() / (double)RAND_MAX;
        if (r > LOSS_PROB){
            SWAck(&rcvd[next_seq_fid], next_seq);
            
            struct AckQueueElement new_ack;
            new_ack.fid = next_seq_fid;
            new_ack.cumulative_ack = SWGetCumulativeAck(&rcvd[next_seq_fid]);
            new_ack.selective_ack = next_seq;
            new_ack.sack_tx_id = next_seq_tx_id;
            new_ack.rcvd_time = time_in_ns + RTT_IN_NS; 
            prioEnqueue(&ackQueue, new_ack);
            /*vpi_printf("enqueued %d %d %d %d\n", new_ack.fid,
                                                 new_ack.cumulative_ack,
                                                 new_ack.selective_ack,
                                                 new_ack.sack_tx_id);
            */
        }
        else{
            vpi_printf("dropped %d %d\n", next_seq_fid, next_seq);
        }
    }
    else{
    }

}

/******** register vpi calls ***********/

void registerReadInputsSystfs() {
  s_vpi_systf_data task_data_s;
  p_vpi_systf_data task_data_p = &task_data_s;
  task_data_p->type = vpiSysTask;
  task_data_p->tfname = "$read_inputs";
  task_data_p->calltf = read_inputs;
  task_data_p->compiletf = 0;

  vpi_register_systf(task_data_p);
}

void registerWriteOutputsSystfs() {
  s_vpi_systf_data task_data_s;
  p_vpi_systf_data task_data_p = &task_data_s;
  task_data_p->type = vpiSysTask;
  task_data_p->tfname = "$write_outputs";
  task_data_p->calltf = write_outputs;
  task_data_p->compiletf = 0;

  vpi_register_systf(task_data_p);
}

void registerInitSystfs() {
  s_vpi_systf_data task_data_s;
  p_vpi_systf_data task_data_p = &task_data_s;
  task_data_p->type = vpiSysTask;
  task_data_p->tfname = "$init_vpi";
  task_data_p->calltf = init;
  task_data_p->compiletf = 0;

  vpi_register_systf(task_data_p);
}

void registerSendClkSystfs() {
  s_vpi_systf_data task_data_s;
  p_vpi_systf_data task_data_p = &task_data_s;
  task_data_p->type = vpiSysTask;
  task_data_p->tfname = "$send_clk";
  task_data_p->calltf = send_clk;
  task_data_p->compiletf = 0;

  vpi_register_systf(task_data_p);
}

