`define SEND_DD_CONTEXT       1'b1
`define ALPHA_W               32
`define STAGE_W               2
`define SUB_STAGE_W           8

`define ECN_W                 2
`define ALPHA_RESUME_INTERVAL 5500
`define RP_TIMER              6000
`define ALPHA_B               20
`define DCQCN_G               8
`define RPG_THRESH            8'd5

`define MIN_RATE (100000000 / `BASE_RATE)
`define RHAI_RATE (200000000 / `BASE_RATE)
`define RAI_RATE (40000000 / `BASE_RATE)

`define USER_CONTEXT_W      (`RATE_W + `ALPHA_W + `STAGE_W + `SUB_STAGE_W + `SUB_STAGE_W + `FLOW_SEQ_NUM_W + `TIMER_W + `TIMER_W + `RATE_W + `SUB_STAGE_W + `RATE_W + `FLOW_SEQ_NUM_W)
