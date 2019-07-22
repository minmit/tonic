`include "system_params.vh"
`include "flow_state_defaults.vh"
`include "sim.vh"

module sim_top();

//*********************************************************************************
// Local Parameters
//*********************************************************************************

// Model Parameters

localparam  INIT_WND_SIZE       = `TONIC_INIT_WND_SIZE;
localparam  INIT_RTX_TIMER_AMNT = `TONIC_INIT_RTX_TIMER_AMNT;

`ifdef TONIC_INIT_CREDIT
localparam  INIT_CREDIT         = `TONIC_INIT_CREDIT;
`else
localparam  INIT_CREDIT         = 0;
`endif

`ifdef TONIC_INIT_RATE
localparam  INIT_RATE           = `TONIC_INIT_RATE;
`else
localparam  INIT_RATE           = 1;
`endif

//// Specs
localparam  CR_TYPE             = `CR_TYPE;
localparam  USER_CONTEXT_WIDTH  = `USER_CONTEXT_W;
localparam  INIT_USER_CNTXT     = `INIT_USER_CONTEXT;

// Simluation Parameters
localparam  CLOCK_PERIOD      = 10000;
localparam  CLOCK_HALF_PERIOD = CLOCK_PERIOD/2;
localparam  ACTIVE_FLOW_CNT   = `ACTIVE_FLOW_CNT;
localparam  RST_TIME          = (ACTIVE_FLOW_CNT / 2 + 10) * CLOCK_PERIOD;
localparam  SIM_CYCLES        = `SIM_CYCLES;
localparam  SIM_END_TIME      = RST_TIME + SIM_CYCLES * CLOCK_PERIOD + 1;
localparam  RTT               = `RTT;
localparam  LOSS_PROB         = `LOSS_PROB;

// helper param
localparam  GROUPS_OF_4_CNT   = ACTIVE_FLOW_CNT % 4 == 0 ? ACTIVE_FLOW_CNT / 4 
                                                         : ACTIVE_FLOW_CNT / 4 + 1; 

localparam  GROUPS_OF_2_CNT   = ACTIVE_FLOW_CNT % 2 == 0 ? ACTIVE_FLOW_CNT / 2 
                                                         : ACTIVE_FLOW_CNT / 2 + 1; 


localparam  TX_CNTR_W    = 10;

//*********************************************************************************
// Wires and Regs
//*********************************************************************************

reg                                 clk;
reg                                 rst_n;

wire    [`FLOW_ID_W-1:0]            incoming_fid_in;
wire    [`PKT_TYPE_W-1:0]           pkt_type_in;
wire    [`PKT_DATA_W-1:0]           pkt_data_in;

wire                                next_val;
wire    [`FLOW_SEQ_NUM_W-1:0]       next_seq_out;
wire    [`TX_CNT_W-1:0]             next_seq_tx_id_out;
wire    [`FLOW_ID_W-1:0]            next_seq_fid_out;

reg     [63:0]                      cnts [ACTIVE_FLOW_CNT-1:0];


/*
reg                                 link_avail;
reg                                 in_tx;
reg     [TX_CNTR_W-1:0]             tx_clk_cntr; 
*/

wire                                link_avail;

//*********************************************************************************
// Clock and Simulation Setup
//*********************************************************************************

// Clock generation
initial begin
    clk = 0;
    forever begin
        #(CLOCK_HALF_PERIOD) clk = ~clk;
    end
end

// Reset generation
initial begin
    rst_n = 1'b0;
    #RST_TIME rst_n = ~rst_n; 
end

// Set Time format
initial begin
    $timeformat(-9, 0, " ns", 1);
    $display("Starting Simulation");
end


integer i;
// End simulation
always @(posedge clk) begin
    if ($time > SIM_END_TIME) begin
        $display("Simulation finished @%t", $time);
        for (i = 0; i < ACTIVE_FLOW_CNT; i = i + 1) begin
            $display("%d %d", i + 1, (cnts[i] * `RST_TX_SIZE * 8 * (10 ** 6)) / (SIM_CYCLES * CLOCK_PERIOD));
        end

        for (i = 0; i < ACTIVE_FLOW_CNT; i = i + 1) begin
            $display("%d %d", i + 1, cnts[i]);
        end

        $finish;
    end
end

// generating src and sink
integer fsrc, fsink;

initial begin
    fsrc    = $fopen("src.data", "w");
    fsink   = $fopen("sink.data", "w");    
end

always @(posedge clk) begin
    if (rst_n) begin
        $fwrite(fsrc, "%b%b%b%b\n", incoming_fid_in,
                                    pkt_type_in,
                                    pkt_data_in,
                                    link_avail);

        $fwrite(fsink, "%b%b%b%b\n", next_val,
                                     next_seq_out,
                                     next_seq_tx_id_out,
                                     next_seq_fid_out);
    end
end

//*********************************************************************************
// Flow and Context Setup
//*********************************************************************************

// TODO add flow sizes

// Initializing the Fifo
integer fifo_i;
initial begin
    fifo_i = 0;
    # CLOCK_PERIOD;
    
    force tonic.dd.non_idle_fifo.rst_n = 1'b1;
    repeat (GROUPS_OF_4_CNT) begin

        force tonic.dd.non_idle_fifo.w_val_0 = 1'b1;
        force tonic.dd.non_idle_fifo.w_data_0 = (fifo_i * 4) + 1;

        force tonic.dd.non_idle_fifo.w_val_1 = 1'b1;
        force tonic.dd.non_idle_fifo.w_data_1 = (fifo_i * 4) + 2;

        force tonic.dd.non_idle_fifo.w_val_2 = 1'b1;
        force tonic.dd.non_idle_fifo.w_data_2 = (fifo_i * 4) + 3;

        force tonic.dd.non_idle_fifo.w_val_3 = 1'b1;
        force tonic.dd.non_idle_fifo.w_data_3 = (fifo_i * 4) + 4;

        force tonic.dd.non_idle_fifo.r_val = 1'b0;
       
        # CLOCK_PERIOD;
        fifo_i = fifo_i + 1;
    end

    force tonic.dd.non_idle_fifo.w_val_0 = 1'b0;
    force tonic.dd.non_idle_fifo.w_val_1 = 1'b0;
    force tonic.dd.non_idle_fifo.w_val_2 = 1'b0;
    force tonic.dd.non_idle_fifo.w_val_3 = 1'b0;
    force tonic.dd.non_idle_fifo.r_val = 1'b0;

    release tonic.dd.non_idle_fifo.w_data_0;
    release tonic.dd.non_idle_fifo.w_data_1;
    release tonic.dd.non_idle_fifo.w_data_2;
    release tonic.dd.non_idle_fifo.w_data_3;
end

initial begin
    #RST_TIME;
    
    release tonic.dd.non_idle_fifo.w_val_0;
    release tonic.dd.non_idle_fifo.w_val_1;
    release tonic.dd.non_idle_fifo.w_val_2;
    release tonic.dd.non_idle_fifo.w_val_3;
    release tonic.dd.non_idle_fifo.r_val;
end
 
//// Initializing the context stores

// Data Delivery Engine

wire    [`FLOW_SEQ_NUM_W-1:0]   rst_next_new;
wire    [`FLOW_SEQ_NUM_W-1:0]   rst_wnd_start;
wire    [`FLOW_WIN_IND_W-1:0]   rst_wnd_start_ind;
wire    [`TX_CNT_WIN_SIZE-1:0]  rst_tx_cnt_wnd;
wire    [`FLOW_WIN_SIZE-1:0]    rst_acked_wnd;
wire    [`FLOW_WIN_SIZE_W-1:0]  rst_wnd_size;

assign  rst_next_new        = `RST_NEXT_NEW;
assign  rst_wnd_start       = `RST_WND_START;
assign  rst_wnd_start_ind   = `RST_WND_START_IND;
assign  rst_tx_cnt_wnd      = `RST_TX_CNT_WND;
assign  rst_acked_wnd       = `RST_ACKED_WND;
assign  rst_wnd_size        = INIT_WND_SIZE;

wire    [`TIME_W-1:0]           rst_rtx_exptime;
wire    [`FLAG_W-1:0]           rst_active_rtx_timer;
wire    [`PKT_QUEUE_IND_W-1:0]  rst_pkt_queue_size;
wire    [`FLAG_W-1:0]           rst_back_pressure;
wire    [`FLAG_W-1:0]           rst_idle;
wire    [`FLOW_WIN_SIZE-1:0]    rst_rtx_wnd;
wire    [`TIMER_W-1:0]          rst_rtx_timer_amnt;
wire    [`USER_CONTEXT_W-1:0]   rst_user_cntxt;

assign  rst_rtx_exptime         = `RST_RTX_EXPTIME;
assign  rst_active_rtx_timer    = `RST_ACTIVE_RTX_TIMER;
assign  rst_pkt_queue_size      = `RST_PKT_QUEUE_SIZE;
assign  rst_back_pressure       = `RST_BACK_PRESSURE;
assign  rst_idle                = `RST_IDLE;
assign  rst_rtx_wnd             = `RST_RTX_WND;
assign  rst_rtx_timer_amnt      = INIT_RTX_TIMER_AMNT;
assign  rst_user_cntxt          = INIT_USER_CNTXT;


integer dd_ram_i;
wire    [tonic.dd.core.CONTEXT_1_W-1:0]  dd_init_cntxt_1;

assign  dd_init_cntxt_1 = {rst_next_new, rst_wnd_start,
                           rst_wnd_start_ind, rst_tx_cnt_wnd,
                           rst_acked_wnd, rst_wnd_size};


wire    [tonic.dd.core.CONTEXT_2_W-1:0]  dd_init_cntxt_2;

assign dd_init_cntxt_2 =  {rst_rtx_exptime, rst_active_rtx_timer,
                           rst_pkt_queue_size, rst_back_pressure,
                           rst_idle, rst_rtx_wnd, 
                           rst_rtx_timer_amnt, rst_user_cntxt};

initial begin : dd_store_init_other
    
    dd_ram_i = 0;
    # CLOCK_PERIOD;
    force tonic.dd.core.store1.rst_n = 1'b1; 
    force tonic.dd.core.store2.rst_n = 1'b1; 
            
    repeat (GROUPS_OF_4_CNT) begin
        // init store 1

        force tonic.dd.core.store1.r_fid0 = `FLOW_ID_NONE; 
        force tonic.dd.core.store1.r_fid1 = `FLOW_ID_NONE; 
        force tonic.dd.core.store1.r_fid2 = `FLOW_ID_NONE; 
        force tonic.dd.core.store1.r_fid3 = `FLOW_ID_NONE; 

        force tonic.dd.core.store1.w_fid0 = (dd_ram_i * 4) + 1; 
        force tonic.dd.core.store1.w_fid1 = (dd_ram_i * 4) + 2; 
        force tonic.dd.core.store1.w_fid2 = (dd_ram_i * 4) + 3; 
        force tonic.dd.core.store1.w_fid3 = (dd_ram_i * 4) + 4; 

        force tonic.dd.core.store1.w_cntxt0 = dd_init_cntxt_1; 
        force tonic.dd.core.store1.w_cntxt1 = dd_init_cntxt_1; 
        force tonic.dd.core.store1.w_cntxt2 = dd_init_cntxt_1; 
        force tonic.dd.core.store1.w_cntxt3 = dd_init_cntxt_1;

        // init store 2
        force tonic.dd.core.store2.r_fid0 = `FLOW_ID_NONE; 
        force tonic.dd.core.store2.r_fid1 = `FLOW_ID_NONE; 
        force tonic.dd.core.store2.r_fid2 = `FLOW_ID_NONE; 
        force tonic.dd.core.store2.r_fid3 = `FLOW_ID_NONE; 

        force tonic.dd.core.store2.w_fid0 = (dd_ram_i * 4) + 1; 
        force tonic.dd.core.store2.w_fid1 = (dd_ram_i * 4) + 2; 
        force tonic.dd.core.store2.w_fid2 = (dd_ram_i * 4) + 3; 
        force tonic.dd.core.store2.w_fid3 = (dd_ram_i * 4) + 4; 

        force tonic.dd.core.store2.w_cntxt0 = dd_init_cntxt_2; 
        force tonic.dd.core.store2.w_cntxt1 = dd_init_cntxt_2; 
        force tonic.dd.core.store2.w_cntxt2 = dd_init_cntxt_2; 
        force tonic.dd.core.store2.w_cntxt3 = dd_init_cntxt_2;
        
        #CLOCK_PERIOD; 
        dd_ram_i = dd_ram_i + 1; 
    end

    force tonic.dd.core.store1.w_fid0 = `FLOW_ID_NONE; 
    force tonic.dd.core.store1.w_fid1 = `FLOW_ID_NONE; 
    force tonic.dd.core.store1.w_fid2 = `FLOW_ID_NONE; 
    force tonic.dd.core.store1.w_fid3 = `FLOW_ID_NONE; 
    
    force tonic.dd.core.store2.w_fid0 = `FLOW_ID_NONE; 
    force tonic.dd.core.store2.w_fid1 = `FLOW_ID_NONE; 
    force tonic.dd.core.store2.w_fid2 = `FLOW_ID_NONE; 
    force tonic.dd.core.store2.w_fid3 = `FLOW_ID_NONE; 

    release tonic.dd.core.store1.w_cntxt0; 
    release tonic.dd.core.store1.w_cntxt1; 
    release tonic.dd.core.store1.w_cntxt2; 
    release tonic.dd.core.store1.w_cntxt3; 

    release tonic.dd.core.store2.w_cntxt0; 
    release tonic.dd.core.store2.w_cntxt1; 
    release tonic.dd.core.store2.w_cntxt2; 
    release tonic.dd.core.store2.w_cntxt3; 
end

initial begin: dd_store_other_release
    # RST_TIME;
    release tonic.dd.core.store1.r_fid0; 
    release tonic.dd.core.store1.r_fid1; 
    release tonic.dd.core.store1.r_fid2; 
    release tonic.dd.core.store1.r_fid3;

    release tonic.dd.core.store1.w_fid0; 
    release tonic.dd.core.store1.w_fid1; 
    release tonic.dd.core.store1.w_fid2; 
    release tonic.dd.core.store1.w_fid3;

    release tonic.dd.core.store2.r_fid0; 
    release tonic.dd.core.store2.r_fid1; 
    release tonic.dd.core.store2.r_fid2; 
    release tonic.dd.core.store2.r_fid3;

    release tonic.dd.core.store2.w_fid0; 
    release tonic.dd.core.store2.w_fid1; 
    release tonic.dd.core.store2.w_fid2; 
    release tonic.dd.core.store2.w_fid3;
end

// Credit Engine
wire    [`MAX_QUEUE_BITS-1:0]       rst_pkt_queue;
wire    [`MAX_TX_ID_BITS-1:0]       rst_tx_id_queue;
wire    [`PKT_QUEUE_IND_W-1:0]      rst_pkt_queue_head;
wire    [`PKT_QUEUE_IND_W-1:0]      rst_pkt_queue_tail;
wire    [`FLAG_W-1:0]               rst_ready_to_tx;
wire    [`CRED_W-1:0]               rst_cred;
wire    [`TX_SIZE_W-1:0]            rst_tx_size;

assign  rst_pkt_queue       = `RST_PKT_QUEUE;
assign  rst_tx_id_queue     = `RST_TX_ID_QUEUE;
assign  rst_pkt_queue_head  = `RST_PKT_QUEUE_HEAD;
assign  rst_pkt_queue_tail  = `RST_PKT_QUEUE_TAIL;
assign  rst_ready_to_tx     = `RST_READY_TO_TX;
assign  rst_cred            = INIT_CREDIT;
assign  rst_tx_size         = `RST_TX_SIZE;

wire    [`TIME_W-1:0]               rst_last_cred_update;
wire    [`RATE_W-1:0]               rst_rate;
wire    [`TIME_W-1:0]               rst_reach_cap;

assign  rst_last_cred_update    = `RST_LAST_CRED_UPDATE;
assign  rst_rate                = INIT_RATE * 64 / 100; 
assign  rst_reach_cap           = (`CRED_CAP / INIT_RATE) * 512;

integer cr_ram_i;

generate
    // Rate
    if (`CR_TYPE == `CR_TYPE_RATE) begin
        wire    [tonic.cr.core.CONTEXT_W-1:0]  cr_init_cntxt;

        assign  cr_init_cntxt =  {rst_pkt_queue, rst_tx_id_queue,
                                  rst_pkt_queue_head, rst_pkt_queue_tail,
                                  rst_pkt_queue_size, rst_ready_to_tx,
                                  rst_cred, rst_tx_size, 
                                  rst_last_cred_update, rst_rate,
                                  rst_reach_cap};


        initial begin: cr_store_init_rate
            cr_ram_i = 0;
            # CLOCK_PERIOD;
            force tonic.cr.core.store.rst_n = 1'b1; 
            
            repeat (GROUPS_OF_2_CNT) begin
                // init store 

                force tonic.cr.core.store.r_fid0 = `FLOW_ID_NONE; 
                force tonic.cr.core.store.r_fid1 = `FLOW_ID_NONE; 

                force tonic.cr.core.store.w_fid0 = (cr_ram_i * 2) + 1; 
                force tonic.cr.core.store.w_fid1 = (cr_ram_i * 2) + 2; 

                force tonic.cr.core.store.w_cntxt0 = cr_init_cntxt; 
                force tonic.cr.core.store.w_cntxt1 = cr_init_cntxt; 

                #CLOCK_PERIOD; 
                cr_ram_i = cr_ram_i + 1; 
            end

            force tonic.cr.core.store.w_fid0 = `FLOW_ID_NONE; 
            force tonic.cr.core.store.w_fid1 = `FLOW_ID_NONE; 
            
            release tonic.cr.core.store.w_cntxt0; 
            release tonic.cr.core.store.w_cntxt1; 
        end

        initial begin: cr_store_release_rate
            # RST_TIME;
            release tonic.cr.core.store.r_fid0; 
            release tonic.cr.core.store.r_fid1; 

            release tonic.cr.core.store.w_fid0; 
            release tonic.cr.core.store.w_fid1; 
        end
    end 
    // Cwnd
    else if (`CR_TYPE == `CR_TYPE_CWND) begin
        wire    [tonic.cr.core.CONTEXT_W-1:0]  cr_init_cntxt;

        assign  cr_init_cntxt =  {rst_pkt_queue, rst_tx_id_queue,
                                  rst_pkt_queue_head, rst_pkt_queue_tail,
                                  rst_pkt_queue_size, rst_ready_to_tx};


        initial begin: cr_store_init_rate
            cr_ram_i = 0;
            # CLOCK_PERIOD;
            force tonic.cr.core.store.rst_n = 1'b1; 
            
            repeat (GROUPS_OF_2_CNT) begin
                // init store 

                force tonic.cr.core.store.r_fid0 = `FLOW_ID_NONE; 
                force tonic.cr.core.store.r_fid1 = `FLOW_ID_NONE; 

                force tonic.cr.core.store.w_fid0 = (cr_ram_i * 2) + 1; 
                force tonic.cr.core.store.w_fid1 = (cr_ram_i * 2) + 2; 

                force tonic.cr.core.store.w_cntxt0 = cr_init_cntxt; 
                force tonic.cr.core.store.w_cntxt1 = cr_init_cntxt; 

                #CLOCK_PERIOD; 
                cr_ram_i = cr_ram_i + 1; 
            end

            force tonic.cr.core.store.w_fid0 = `FLOW_ID_NONE; 
            force tonic.cr.core.store.w_fid1 = `FLOW_ID_NONE; 
            
            release tonic.cr.core.store.w_cntxt0; 
            release tonic.cr.core.store.w_cntxt1; 
        end

        initial begin: cr_store_release_rate
            # RST_TIME;
            release tonic.cr.core.store.r_fid0; 
            release tonic.cr.core.store.r_fid1; 

            release tonic.cr.core.store.w_fid0; 
            release tonic.cr.core.store.w_fid1; 
        end
    end
endgenerate

//*********************************************************************************
// Logic
//*********************************************************************************

// Tonic

tonic tonic (
        .clk                (clk                ),
        .rst_n              (rst_n              ),
        
        .incoming_fid_in    (incoming_fid_in    ),
        .pkt_type_in        (pkt_type_in        ),
        .pkt_data_in        (pkt_data_in        ), 

        .link_avail         (link_avail         ),

        .next_val           (next_val           ),
        .next_seq_out       (next_seq_out       ),
        .next_seq_tx_id_out (next_seq_tx_id_out ),
        .next_seq_fid_out   (next_seq_fid_out   )
);

// Mock Receiver 
sim_receiver #(.RTT        (RTT            ),
               .LOSS_PROB  (LOSS_PROB      ))
    sim_receiver (
        .clk                (clk                ),
        .rst_n              (rst_n              ),
        
        .next_seq_in        (next_seq_out       ),
        .next_seq_tx_id_in  (next_seq_tx_id_out ),
        .next_seq_fid_in    (next_seq_fid_out   ),
    
        .resp_fid           (incoming_fid_in    ),
        .resp_pkt_type      (pkt_type_in        ),
        .resp_pkt_data      (pkt_data_in        )
);

//*********************************************************************************
// TX Channel 
//*********************************************************************************
/*
localparam  REQ_TX_CLKS = `RST_TX_SIZE % 125 == 0 ? `RST_TX_SIZE / 125 : 
                                                    (`RST_TX_SIZE / 125) + 1;

 

always @(posedge clk) begin
    if (~rst_n) begin
        link_avail      <= 1'b1;
    end
    else begin
        if (link_avail & next_val) begin
            link_avail  <= REQ_TX_CLKS == 1;
        end
        else if (in_tx) begin
            link_avail  <= tx_clk_cntr + 1 == REQ_TX_CLKS;
        end
        else begin
            link_avail  <= link_avail;
        end
    end
end

always @(posedge clk) begin
    if (~rst_n) begin
        in_tx   <= 1'b0;
    end
    else begin
        if (link_avail & next_val) begin
            in_tx  <= 1'b1;
        end
        else if (in_tx) begin
            in_tx  <= tx_clk_cntr < REQ_TX_CLKS;
        end
        else begin
            in_tx  <= in_tx;
        end
    end
end

always @(posedge clk) begin
    if (~rst_n) begin
        tx_clk_cntr     <= {TX_CNTR_W{1'b0}};
    end
    else begin
        if (link_avail & next_val) begin
            tx_clk_cntr <= {{(TX_CNTR_W - 1){1'b0}}, 1'b1};
        end
        else if (in_tx) begin
            tx_clk_cntr <= tx_clk_cntr + 1;
        end
        else begin
            tx_clk_cntr <= {TX_CNTR_W{1'b0}};
        end
    end
end 
*/
assign link_avail = 1'b1;        
//*********************************************************************************
// Pkts and Acks
//*********************************************************************************
integer cycle_no;

initial begin
    cycle_no = 0;
end

always @(posedge clk) begin
    cycle_no = cycle_no + 1;
end



always @(posedge clk) begin

    $display("------------------------------------------------");
    $display("Cycle: %d\n\n", cycle_no);
//    $display("outq:     %b %b %d", link_avail,
//                                   in_tx,
//                                   tx_clk_cntr);

    $display("next out: %d %d %d", next_seq_fid_out, 
                                   next_seq_out, 
                                   next_seq_tx_id_out);

    $display("next ack: %d %d %b", incoming_fid_in,
                                   pkt_type_in,
                                   pkt_data_in);
    
    $write("cnts: ");
    for (i = 0; i < ACTIVE_FLOW_CNT; i = i + 1) begin
        $write("%d", cnts[i]);
    end
    $display("");
end

// count TX pkts

initial begin
    for (i = 0; i < ACTIVE_FLOW_CNT; i = i + 1) begin
        cnts[i] = {64'd0};
    end
end

always @(posedge clk) begin
    cnts[next_seq_fid_out - 1] = link_avail ? cnts[next_seq_fid_out - 1] + 1 :
                                              cnts[next_seq_fid_out - 1];
end


//*********************************************************************************
// Debug
//*********************************************************************************

`ifdef DEBUG

// DD Core


integer iff;
always @(posedge clk) begin
    $display("------------------------------------------------");
    $display("Cycle: %d\n\n", cycle_no);
    $display("DD Core");
    $display("next fid in: %d", tonic.dd.core.next_fid_in);

    $display("-------------- Next ------------------");
    $display("next fid p %d", tonic.dd.core.next_fid_p);

    $display("next cntxt 1 p %b", tonic.dd.core.next_cntxt_1_p);
    $display("next mrged 1 c %b", tonic.dd.core.next_mrged_cntxt_1);

    $display("next cntxt 2 p %b", tonic.dd.core.next_cntxt_2_p);
    $display("next mrged 2 c %b", tonic.dd.core.next_mrged_cntxt_2);
    $display("next store 2 s %d %b", tonic.dd.core.next_fid_l_from_store,
                                     tonic.dd.core.next_cntxt_2_l_from_store);

    $display("next rtx wnd in %b", tonic.dd.core.next.rtx_wnd_in);
    $display("next rtx wnd out %b", tonic.dd.core.next.rtx_wnd_out);
    $display("next wnd start in %d", tonic.dd.core.next.wnd_start_in);

    $display("next mrged idle %b", tonic.dd.core.next_mrged_idle);
    //$display("next back pressure %b", tonic.dd.core.next.back_pressure_out);
    //$display("next mrged back pressure %b", tonic.dd.core.next_mrged_back_pressure);

    //$display("next packet queue size %d", tonic.dd.core.next.pkt_queue_size_out);
    //$display("next mrged packet queue size %d", tonic.dd.core.next_mrged_pkt_queue_size);
    $display("next next new out %d %d %d", tonic.dd.core.next_next_new_out,
                                        tonic.dd.core.next.rtx_exists,
                                        tonic.dd.core.next.end_wnd_seq);
    //$display("next masked %b", tonic.dd.core.next.masked_rtx_wnd);
    //$display("next start ind %d", tonic.dd.core.next.wnd_start_ind_in);
    //for (iff = 0; iff < 5; iff = iff + 1) begin
    //  $display("%b", tonic.dd.core.next.find_first.sfs1.ind_val_level[(iff + 1) * 128 - 1 -: 128]);

    //end

    //$display("ff info %b %b", tonic.dd.core.next.find_first.sfs1.ind_val_level,
    //                          tonic.dd.core.next.find_first.sfs1.val_out);
    //$display("ff info %b %b", tonic.dd.core.next.find_first.vect_wnd_set_bits_1,
    //                          tonic.dd.core.next.find_first.vect_wnd_set_bits_2);

    $display("next seq out %d", tonic.dd.core.next_seq_out);
    $display("next wnd size in %d", tonic.dd.core.next.wnd_size_in);
    
    $display("-------------- DP ------------------");
    $display("dp fid p %d", tonic.dd.core.dp_fid_p);

    $display("dp cntxt 2 p %b", tonic.dd.core.dp_cntxt_2_p);
    $display("dp mrged 2 c %b", tonic.dd.core.dp_mrged_cntxt_2);

    $display("-------------- Inc0 ------------------");

    $display("inc0 fid p %d %d %d", tonic.dd.core.inc0_fid_p, 
                                    tonic.dd.core.cumulative_ack_p, 
                                    tonic.dd.core.selective_ack_p);
    
    //$display("inc0_m in p: %b %b", tonic.dd.core.inc0_m_eq_next_p, tonic.dd.core.inc0_m_eq_inc0_p);
    //$display("inc0_m in p_prev: %b  %b", tonic.dd.core.inc0_m_eq_next_p_prev, tonic.dd.core.inc0_m_eq_inc0_p_prev); 

    $display("inc0 cntxt 1 p %h", tonic.dd.core.inc0_cntxt_1_p);
    $display("inc0 mrged 1 c %h", tonic.dd.core.inc0_mrged_cntxt_1);

    $display("inc0 acked wnd in %b", tonic.dd.core.incoming_0.acked_wnd_in);
    $display("inc0 acked wnd out %b", tonic.dd.core.incoming_0.acked_wnd_out);

    $display("inc0 wnd start in %d", tonic.dd.core.incoming_0.wnd_start_in);
    $display("inc0 wnd start out %d", tonic.dd.core.incoming_0.wnd_start_out);
  
    //$display("inc0 wnd start ind in %d", tonic.dd.core.incoming_0.wnd_start_ind_in);
    //$display("inc0 wnd start ind out %d", tonic.dd.core.incoming_0.wnd_start_ind_out);

    //$display("inc0 nwacks %b", tonic.dd.core.incoming_0.nwack_wnd);
    //$display("inc0 new acks cnt out %d", tonic.dd.core.incoming_0.new_c_acks_cnt);
    
    $display("-------------- Inc1 ------------------");

    $display("inc1 fid p %d %d %d", tonic.dd.core.inc1_fid_p, 
                                    tonic.dd.core.incoming_1.cumulative_ack_in, 
                                    tonic.dd.core.incoming_1.selective_ack_in);
    
    //$display("inc1_m in p: %b %b", tonic.dd.core.inc1_m_eq_next_p, tonic.dd.core.inc1_m_eq_inc1_p);
    //$display("inc1_m in p_prev: %b  %b", tonic.dd.core.inc1_m_eq_next_p_prev, tonic.dd.core.inc1_m_eq_inc1_p_prev); 

    $display("inc1 cntxt 2 p %h", tonic.dd.core.inc1_cntxt_2_p);
    $display("inc1 mrged 2 c %h", tonic.dd.core.inc1_mrged_cntxt_2);
   
    $display("inc1 rtx wnd in %b", tonic.dd.core.incoming_1.rtx_wnd_in);
    $display("inc1 rtx wnd out %b", tonic.dd.core.incoming_1.rtx_wnd_out);

    $display("inc1 acked wnd in %b", tonic.dd.core.incoming_1.acked_wnd_in);
    
    $display("inc1 wnd start in %d", tonic.dd.core.incoming_1.wnd_start_in);
    $display("inc1 wnd start ind in %d", tonic.dd.core.incoming_1.wnd_start_ind_in);

    $display("inc1 rtx timer amnt %d", tonic.dd.core.incoming_1.rtx_timer_amnt_out);

    $display("inc1 mrged idle %b", tonic.dd.core.inc1_mrged_idle);
    $display("window size: %d %d", tonic.dd.core.inc1_fid_p,
                                   tonic.dd.core.inc1_mrged_wnd_size); 

    $display("old wnd start: %d", tonic.dd.core.incoming_1.old_wnd_start_in);
    
    $display("-------------- Timeout ------------------");

    $display("timeout fid in %d", tonic.dd.core.timeout_fid_in);
    $display("timeout expired %d", tonic.dd.core.timeout_expired);
    $display("org timeout fid l %d", tonic.dd.core.org_timeout_fid_l);
    $display("timeout fid l %d", tonic.dd.core.timeout_fid_l);
    $display("timeout fid p %d", tonic.dd.core.timeout_fid_p);
    
    $display("timeout cntxt 2 p %b", tonic.dd.core.timeout_cntxt_2_p);
    $display("timeout mrged 2 c %b", tonic.dd.core.timeout_mrged_cntxt_2);
        
    $display("timeout rtx wnd in %b", tonic.dd.core.timeout.rtx_wnd_in);
    $display("timeout rtx wnd out %b", tonic.dd.core.timeout.rtx_wnd_out);

    
    $display("timeout mrged idle %b", tonic.dd.core.timeout_mrged_idle);
    
    $display("------------- Window Sizes -------------");
    $display("wnd size %d %d", tonic.dd.core.next_fid_p, tonic.dd.core.next_mrged_wnd_size); 
    $display("wnd size %d %d", tonic.dd.core.inc1_fid_p, tonic.dd.core.inc1_mrged_wnd_size); 
    $display("wnd size %d %d", tonic.dd.core.timeout_fid_p, tonic.dd.core.timeout_mrged_wnd_size); 

    $display("------------- RTX Exptime -------------");
    $display("rtx exptime %d %d", tonic.dd.core.next_fid_p, tonic.dd.core.next_mrged_rtx_exptime); 
    $display("rtx exptime %d %d", tonic.dd.core.dp_fid_p, tonic.dd.core.dp_mrged_rtx_exptime); 
    $display("rtx exptime %d %d", tonic.dd.core.inc1_fid_p, tonic.dd.core.inc1_mrged_rtx_exptime); 
    $display("rtx exptime %d %d", tonic.dd.core.timeout_fid_p, tonic.dd.core.timeout_mrged_rtx_exptime); 

    $display("------------- Other -------------");
    $display("dd core rst %b", tonic.dd.core.rst_n);
end

// Non-idle FIFO

/*
integer ind;
always @(posedge clk) begin
    $display("------------------------------------------------");
    $display("Cycle: %d\n\n", cycle_no);
    $display("Non Idle FIFO");
    $display("w0: %b %d", tonic.dd.non_idle_fifo.w_val_0,
                          tonic.dd.non_idle_fifo.w_data_0);

    $display("w1: %b %d", tonic.dd.non_idle_fifo.w_val_1,
                          tonic.dd.non_idle_fifo.w_data_1);

    $display("w2: %b %d", tonic.dd.non_idle_fifo.w_val_2,
                          tonic.dd.non_idle_fifo.w_data_2);

    $display("w3: %b %d", tonic.dd.non_idle_fifo.w_val_3,
                          tonic.dd.non_idle_fifo.w_data_3);

    $display("r : %b %d", tonic.dd.non_idle_fifo.r_val,
                         tonic.dd.non_idle_fifo.r_data);

    for (ind = 0; ind < ACTIVE_FLOW_CNT; ind = ind + 1) begin
        $write("%d ", tonic.dd.non_idle_fifo.fifo[
                    (tonic.dd.non_idle_fifo.head_ptr + ind) % 
                     tonic.dd.non_idle_fifo.FIFO_DEPTH]);
    end
    $write("\n");
end
*/
/*
initial begin
    $monitor ("TIME : %g CLK : %b RST : %b WRITES: %b %d %b %d %b %d %b %d READ: %b %d HEAD: %d ELEMS: %d %d %d %d ",
              $time, clk, 
              tonic.dd.non_idle_fifo.rst_n,
              tonic.dd.non_idle_fifo.w_val_0,
              tonic.dd.non_idle_fifo.w_data_0,
              tonic.dd.non_idle_fifo.w_val_1,
              tonic.dd.non_idle_fifo.w_data_1,
              tonic.dd.non_idle_fifo.w_val_2,
              tonic.dd.non_idle_fifo.w_data_2,
              tonic.dd.non_idle_fifo.w_val_3,
              tonic.dd.non_idle_fifo.w_data_3,
              tonic.dd.non_idle_fifo.r_val,
              tonic.dd.non_idle_fifo.r_data,
              tonic.dd.non_idle_fifo.head_ptr,
              tonic.dd.non_idle_fifo.fifo[0],
              tonic.dd.non_idle_fifo.fifo[1],
              tonic.dd.non_idle_fifo.fifo[2],
              tonic.dd.non_idle_fifo.fifo[3]
            
);
end
*/

/*
always @(posedge clk) begin
  $display("-------- store for context 2 -----------");
  $display("read fids %d %d %d %d", tonic.dd.core.store2.r_fid0,
                                    tonic.dd.core.store2.r_fid1,
                                    tonic.dd.core.store2.r_fid2,
                                    tonic.dd.core.store2.r_fid3);

  $display("write fids %d %d %d %d", tonic.dd.core.store2.w_fid0,
                                    tonic.dd.core.store2.w_fid1,
                                    tonic.dd.core.store2.w_fid2,
                                    tonic.dd.core.store2.w_fid3);

  $display("write context 0 %b", tonic.dd.core.store2.w_cntxt0);
  $display("write context 1 %b", tonic.dd.core.store2.w_cntxt1);
  $display("write context 2 %b", tonic.dd.core.store2.w_cntxt2);
  $display("write context 3 %b", tonic.dd.core.store2.w_cntxt3);

end
*/

/*
// CR Core
generate
  if (`CR_TYPE == `CR_TYPE_CWND) begin
    always @(posedge clk) begin: cr_core_cwnd_debug
      $display("------------------------------------------------");
      $display("Cycle: %d\n\n", cycle_no);
      $display("CR Core");

      $display("-------------- Enqueue ------------------");
      $display("enq fid in %d", tonic.cr.core.enq_fid_in);
      $display("enq fid p %d", tonic.cr.core.enq_fid_p);
      $display("enq cntxt p %b", tonic.cr.core.enq_cntxt_p);
      $display("enq mrged c %b", tonic.cr.core.enq_mrged_cntxt);

      $display("-------------- Transmit ------------------");
      $display("tx fid in %d", tonic.cr.core.tx_fid_in);
      $display("tx fid p %d", tonic.cr.core.tx_fid_p);
      $display("tx next seq out %d", tonic.cr.core.transmit.next_seq_out);
      $display("tx cntxt p %b", tonic.cr.core.tx_cntxt_p);
      $display("tx mrged c %b", tonic.cr.core.tx_mrged_cntxt);

      $display("-------------- Other ------------------");
      $display("cr dp fid out %d", tonic.cr_dp_fid);
      $display("cr tx fid tmp %b %d", tonic.cr.tx_val, tonic.cr.tx_fid_tmp);
      $display("cr tx fifo read info %b %d", tonic.cr.tx_fifo.empty, tonic.cr.tx_fifo.srtd_w_val_0);
      $display("cr rst %b", tonic.cr.rst_n);
    end 
  end
endgenerate

integer ind2;
always @(posedge clk) begin
    $display("------------------------------------------------");
    $display("Cycle: %d\n\n", cycle_no);
    $display("TX FIFO");
    $display("w0: %b %d", tonic.cr.tx_fifo.w_val_0,
                          tonic.cr.tx_fifo.w_data_0);

    $display("w1: %b %d", tonic.cr.tx_fifo.w_val_1,
                          tonic.cr.tx_fifo.w_data_1);

    $display("r : %b %d", tonic.cr.tx_fifo.r_val,
                         tonic.cr.tx_fifo.r_data);

    for (ind2 = 0; ind2 < ACTIVE_FLOW_CNT; ind2 = ind2 + 1) begin
        $write("%d ", tonic.cr.tx_fifo.fifo[
                    (tonic.cr.tx_fifo.head_ptr + ind2) % 
                     tonic.cr.tx_fifo.FIFO_DEPTH]);
    end
    $write("\n");
end
*/
/*
generate
    if (`CR_TYPE == `CR_TYPE_RATE) begin
        always @(posedge clk) begin: cr_core_rate_debug
            $display("------------------------------------------------");
            $display("Cycle: %d\n\n", cycle_no);
            $display("CR Core");

            $display("-------------- Enqueue ------------------");
            $display("enq fid p %d", tonic.cr.core.enq_fid_p);
            $display("enq cntxt p %b", tonic.cr.core.enq_cntxt_p);
            $display("enq mrged c %b", tonic.cr.core.enq_mrged_cntxt);

            $display("enq pkt queue size %d", tonic.cr.core.enq_mrged_pkt_queue_size);

            $display("-------------- Transmit ------------------");
            $display("tx fid p %d", tonic.cr.core.tx_fid_p);
            $display("tx next seq out %d", tonic.cr.core.transmit.next_seq_out);
            $display("tx cntxt p %b", tonic.cr.core.tx_cntxt_p);
            $display("tx mrged c %b", tonic.cr.core.tx_mrged_cntxt);

            $display("tx credit: %d %d", tonic.cr.core.transmit.credit_in,
                                         tonic.cr.core.transmit.credit_out);

            $display("tx pkt queue in %d %d", tonic.cr.core.transmit.pkt_queue_head_in,
                                              tonic.cr.core.transmit.pkt_queue_size_in);

            $display("tx pkt queue out %d %d", tonic.cr.core.transmit.pkt_queue_head_out,
                                              tonic.cr.core.transmit.pkt_queue_size_out);

            $display("tx pkt queue size %d", tonic.cr.core.tx_mrged_pkt_queue_size);
            $display("last_cred_update %d %d", tonic.cr.core.transmit.last_cred_update_in,
                                               tonic.cr.core.tx_mrged_last_cred_update);
           
            $display("cred comp 1: %d %d", tonic.cr.core.transmit.time_delta_1, 
                                           tonic.cr.core.transmit.added_cred_1);

            $display("cred comp 8: %d %d", tonic.cr.core.transmit.time_delta_8, 
                                           tonic.cr.core.transmit.added_cred_8);

            $display("cred comp 64: %d %d", tonic.cr.core.transmit.time_delta_64, 
                                           tonic.cr.core.transmit.added_cred_64);

            $display("cred comp 512: %d %d", tonic.cr.core.transmit.time_delta_512, 
                                           tonic.cr.core.transmit.added_cred_512);

            $display("credit %d %d", tonic.cr.core.transmit.credit_in,
                                     tonic.cr.core.transmit.credit_out);

            $display("--------------- Enq Calc Timer -------------------");

        
            $display("----- Stage 0 -------"); 

            $write("cred_1: ");
            for (i = 0; i < 7; i = i + 1) begin
                $write("%o ", tonic.cr.core.calc_timer_0.d_512.creds_1[i]);
            end
            $display("");
            
            $write("cred_8: ");
            for (i = 0; i < 7; i = i + 1) begin
                $write("%o ", tonic.cr.core.calc_timer_0.d_512.creds_8[i]);
            end
            $display("");

            $write("cred_64: ");
            for (i = 0; i < 7; i = i + 1) begin
                $write("%o ", tonic.cr.core.calc_timer_0.d_512.creds_64[i]);
            end
            $display("");

            $write("cred_512: ");
            for (i = 0; i < 7; i = i + 1) begin
                $write("%o ", tonic.cr.core.calc_timer_0.d_512.creds_512[i]);
            end
            $display("");

            $display("comp_bits: %b", tonic.cr.core.calc_timer_0.d_512.comp_bits);

            $display("look up res: %b %d %d %b %d %d", tonic.cr.core.calc_timer_0.d_512.found, 
                                                       tonic.cr.core.calc_timer_0.d_512.coeff_tmp, 
                                                       tonic.cr.core.calc_timer_0.d_512.base_tmp, 
                                                       tonic.cr.core.calc_timer_0.d_512.really_found, 
                                                       tonic.cr.core.calc_timer_0.d_512.part_coeff, 
                                                       tonic.cr.core.calc_timer_0.d_512.part_base);

            $display("Summary: %d %b %o %o %d %o 0", tonic.cr.core.calc_timer_0.timer_fid_in,
                                                     tonic.cr.core.calc_timer_0.timer_needed_in,
                                                     tonic.cr.core.calc_timer_0.cred_needed_in,
                                                     tonic.cr.core.calc_timer_0.rate_0,
                                                     tonic.cr.core.calc_timer_0.part_0,
                                                     tonic.cr.core.calc_timer_0.rem_0);


            
            $display("----- Stage 1 -------"); 
        
            $display("comp_bits: %b", tonic.cr.core.calc_timer_0.d_64.comp_bits);
            $display("Summary: %d %b %o %o %d %o %d", tonic.cr.core.calc_timer_0.timer_fid_1,
                                                      tonic.cr.core.calc_timer_0.timer_needed_1,
                                                      tonic.cr.core.calc_timer_0.cred_1,
                                                      tonic.cr.core.calc_timer_0.rate_1,
                                                      tonic.cr.core.calc_timer_0.part_1,
                                                      tonic.cr.core.calc_timer_0.rem_1,
                                                      tonic.cr.core.calc_timer_0.timer_amnt_1);

            $display("----- Stage 2 -------"); 
            $display("comp_bits: %b", tonic.cr.core.calc_timer_0.d_8.comp_bits);
            $display("Summary: %d %b %o %o %d %o %d", tonic.cr.core.calc_timer_0.timer_fid_2,
                                                      tonic.cr.core.calc_timer_0.timer_needed_2,
                                                      tonic.cr.core.calc_timer_0.cred_2,
                                                      tonic.cr.core.calc_timer_0.rate_2,
                                                      tonic.cr.core.calc_timer_0.part_2,
                                                      tonic.cr.core.calc_timer_0.rem_2,
                                                      tonic.cr.core.calc_timer_0.timer_amnt_2);

            $display("----- Stage 3 -------"); 
            $display("comp_bits: %b", tonic.cr.core.calc_timer_0.d_1.comp_bits);
            $display("Summary: %d %b %o %o %d %o %d", tonic.cr.core.calc_timer_0.timer_fid_3,
                                                      tonic.cr.core.calc_timer_0.timer_needed_3,
                                                      tonic.cr.core.calc_timer_0.cred_3,
                                                      tonic.cr.core.calc_timer_0.rate_3,
                                                      tonic.cr.core.calc_timer_0.part_3,
                                                      tonic.cr.core.calc_timer_0.rem_3,
                                                      tonic.cr.core.calc_timer_0.timer_amnt_3);

            
            $display("Stage_4: %d %b %d", tonic.cr.core.calc_timer_0.timer_fid_out,
                                          tonic.cr.core.calc_timer_0.timer_needed_out,
                                          tonic.cr.core.calc_timer_0.timer_amnt_out);


            $display("--------------- TX Calc Timer -------------------");

            
            $display("----- Stage 0 -------"); 

            $write("cred_1: ");
            for (i = 0; i < 7; i = i + 1) begin
                $write("%o ", tonic.cr.core.calc_timer_1.d_512.creds_1[i]);
            end
            $display("");
            
            $write("cred_8: ");
            for (i = 0; i < 7; i = i + 1) begin
                $write("%o ", tonic.cr.core.calc_timer_1.d_512.creds_8[i]);
            end
            $display("");

            $write("cred_64: ");
            for (i = 0; i < 7; i = i + 1) begin
                $write("%o ", tonic.cr.core.calc_timer_1.d_512.creds_64[i]);
            end
            $display("");

            $write("cred_512: ");
            for (i = 0; i < 7; i = i + 1) begin
                $write("%o ", tonic.cr.core.calc_timer_1.d_512.creds_512[i]);
            end
            $display("");

            $display("comp_bits: %b", tonic.cr.core.calc_timer_1.d_512.comp_bits);

            $display("look up res: %b %d %d %b %d %d", tonic.cr.core.calc_timer_1.d_512.found, 
                                                       tonic.cr.core.calc_timer_1.d_512.coeff_tmp, 
                                                       tonic.cr.core.calc_timer_1.d_512.base_tmp, 
                                                       tonic.cr.core.calc_timer_1.d_512.really_found, 
                                                       tonic.cr.core.calc_timer_1.d_512.part_coeff, 
                                                       tonic.cr.core.calc_timer_1.d_512.part_base);

            $display("Summary: %d %b %o %o %d %o 0", tonic.cr.core.calc_timer_1.timer_fid_in,
                                                     tonic.cr.core.calc_timer_1.timer_needed_in,
                                                     tonic.cr.core.calc_timer_1.cred_needed_in,
                                                     tonic.cr.core.calc_timer_1.rate_0,
                                                     tonic.cr.core.calc_timer_1.part_0,
                                                     tonic.cr.core.calc_timer_1.rem_0);


            
            $display("----- Stage 1 -------"); 
            
            $display("comp_bits: %b", tonic.cr.core.calc_timer_1.d_64.comp_bits);
            $display("Summary: %d %b %o %o %d %o %d", tonic.cr.core.calc_timer_1.timer_fid_1,
                                                      tonic.cr.core.calc_timer_1.timer_needed_1,
                                                      tonic.cr.core.calc_timer_1.cred_1,
                                                      tonic.cr.core.calc_timer_1.rate_1,
                                                      tonic.cr.core.calc_timer_1.part_1,
                                                      tonic.cr.core.calc_timer_1.rem_1,
                                                      tonic.cr.core.calc_timer_1.timer_amnt_1);

            $display("----- Stage 2 -------"); 
            $display("comp_bits: %b", tonic.cr.core.calc_timer_1.d_8.comp_bits);
            $display("Summary: %d %b %o %o %d %o %d", tonic.cr.core.calc_timer_1.timer_fid_2,
                                                      tonic.cr.core.calc_timer_1.timer_needed_2,
                                                      tonic.cr.core.calc_timer_1.cred_2,
                                                      tonic.cr.core.calc_timer_1.rate_2,
                                                      tonic.cr.core.calc_timer_1.part_2,
                                                      tonic.cr.core.calc_timer_1.rem_2,
                                                      tonic.cr.core.calc_timer_1.timer_amnt_2);

            $display("----- Stage 3 -------"); 
            $display("comp_bits: %b", tonic.cr.core.calc_timer_1.d_1.comp_bits);
            $display("Summary: %d %b %o %o %d %o %d", tonic.cr.core.calc_timer_1.timer_fid_3,
                                                      tonic.cr.core.calc_timer_1.timer_needed_3,
                                                      tonic.cr.core.calc_timer_1.cred_3,
                                                      tonic.cr.core.calc_timer_1.rate_3,
                                                      tonic.cr.core.calc_timer_1.part_3,
                                                      tonic.cr.core.calc_timer_1.rem_3,
                                                      tonic.cr.core.calc_timer_1.timer_amnt_3);

            
            $display("Stage_4: %d %b %d", tonic.cr.core.calc_timer_1.timer_fid_out,
                                          tonic.cr.core.calc_timer_1.timer_needed_out,
                                          tonic.cr.core.calc_timer_1.timer_amnt_out);

        end 


        // TX FIFO
        integer ind;
        always @(posedge clk) begin: tx_fifo_debug
            $display("------------------------------------------------");
            $display("Cycle: %d\n\n", cycle_no);
            $display("TX FIFO");
            $display("w0: %b %d", tonic.cr.tx_fifo.w_val_0,
                                  tonic.cr.tx_fifo.w_data_0);

            $display("w1: %b %d", tonic.cr.tx_fifo.w_val_1,
                                  tonic.cr.tx_fifo.w_data_1);

            $display("w2: %b %d", tonic.cr.tx_fifo.w_val_2,
                                  tonic.cr.tx_fifo.w_data_2);

            $display("r : %b %d", tonic.cr.tx_fifo.r_val,
                                 tonic.cr.tx_fifo.r_data);

            for (ind = 0; ind < ACTIVE_FLOW_CNT; ind = ind + 1) begin
                $write("%d ", tonic.cr.tx_fifo.fifo[
                                (tonic.cr.tx_fifo.head_ptr + ind) % 
                                 tonic.cr.tx_fifo.FIFO_DEPTH]);
            end
            $write("\n");
        end
    end
endgenerate
*/

// confirm cwnd cr engine correctness
reg [64:0] in_reg;
reg [64:0] out_reg;
generate
    if (`CR_TYPE == `CR_TYPE_CWND) begin
        initial begin: cr_innout_begin
            in_reg = 0;
            out_reg = 0;
        end

        always @(posedge clk) begin: cr_innout_check
            if (tonic.cr.enq_fid_in != `FLOW_ID_NONE) begin
                in_reg = in_reg + 1;
            end
            if (tonic.cr.next_seq_fid_out != `FLOW_ID_NONE) begin
                out_reg = out_reg + 1;
            end
            
            $display("INNOUT: %d %d", in_reg, out_reg);
        end
    end
endgenerate
`endif
// clogb2 function
`include "clogb2.vh"

endmodule
