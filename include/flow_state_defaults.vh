`define     RST_NEXT_NEW            {`FLOW_SEQ_NUM_W{1'b0}}
`define     RST_WND_START           {`FLOW_SEQ_NUM_W{1'b0}}
`define     RST_WND_START_IND       {`FLOW_WIN_IND_W{1'b0}}
`define     RST_IDLE                1'b0
`define     RST_ACKED_WND           {`FLOW_WIN_SIZE{1'b0}}
`define     RST_TX_CNT_WND          {(`FLOW_WIN_SIZE * `TX_CNT_W){1'b0}}
`define     RST_RTX_WND             {`FLOW_WIN_SIZE{1'b0}}
`define     RST_BACK_PRESSURE       1'b0
`define     RST_ACTIVE_RTX_TIMER    1'b0
`define     RST_WND_MASK            {{(`FLOW_WIN_SIZE-`RST_WND_SIZE){1'b0}}, {`RST_WND_SIZE{1'b1}}}
`define     RST_RTX_EXPTIME         {`TIME_W{1'b1}}

`define     RST_PKT_QUEUE           {(`MAX_PKT_QUEUE_SIZE * `FLOW_SEQ_NUM_W){1'b0}}
`define     RST_TX_ID_QUEUE         {(`MAX_PKT_QUEUE_SIZE * `TX_CNT_W){1'b0}}
`define     RST_PKT_QUEUE_HEAD      {`PKT_QUEUE_IND_W{1'b0}}
`define     RST_PKT_QUEUE_TAIL      {`PKT_QUEUE_IND_W{1'b0}}
`define     RST_PKT_QUEUE_SIZE      {`PKT_QUEUE_IND_W{1'b0}}
`define     RST_LAST_CRED_UPDATE    {`TIME_W{1'b0}}

`define     RST_READY_TO_TX         1'b0
`define     RST_TX_SIZE             {{(`TX_SIZE_W - 10){1'b0}}, 10'd1000}

`define     RST_EX_CREDIT           (`RST_TX_SIZE * `MAX_PKT_QUEUE_SIZE)
`define     RST_LAST_PULL_CNTR      {`PULL_CNTR_W{1'b0}}
`define     RST_TIMEOUT_CRED        `RST_EX_CREDIT
`define     RST_CRED_CAP            `CRED_CAP

