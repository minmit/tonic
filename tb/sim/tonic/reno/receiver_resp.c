#include "receiver_resp.h"
#include "vpi_user.h"

#include <string.h>

int INT_BUFF_SIZE = 32;

char* int2bin(int a, char* buffer) {
    int i;
    for (i = INT_BUFF_SIZE-1; i >= 0; i--) {
        if (a % 2) buffer[i] = '1';
        else buffer[i] = '0';
        
        a /= 2;
    }
    return buffer;
}

void receiver_resp(int fid, int cumulative_ack,
                   int selective_ack, int sack_tx_id,
                   struct ReceiverResp* resp){
   
    resp->fid = fid;
    resp->pkt_type = CACK_PKT;
    
    resp->pkt_data[100] = '\0';
    int ind_in_data = 0; 
    int2bin(cumulative_ack, resp->pkt_data + ind_in_data);
    ind_in_data += INT_BUFF_SIZE;

    sprintf(resp->pkt_data + ind_in_data, "%0*d", PKT_DATA_W - ind_in_data, 0); 
}
