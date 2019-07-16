`define SEND_DD_CONTEXT     1'b0
`define USER_CONTEXT_W      98

`define DUP_ACKS_THRESH     {{(`FLOW_WIN_SIZE_W-2){1'b0}}, 2'd3}
`define MAX_DUP_ACKS        {{(`FLOW_WIN_SIZE_W-4){1'b0}}, 4'd10}
