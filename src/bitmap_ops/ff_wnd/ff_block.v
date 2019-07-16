// Description:
//      Input: Multiple {val, ind} pairs, where several pairs can be valid
//      Output: least significant valid pair
// Note:
//      BLOCK_WIDTH must be power of 2
module ff_block #(
    parameter   BLOCK_WIDTH = 4,
    parameter   BLOCK_IND_WIDTH = 10,
    parameter   BLOCK_LEVEL = -1
)(
    input       [BLOCK_WIDTH-1:0]                   ind_val_in,
    input       [BLOCK_IND_WIDTH*BLOCK_WIDTH-1:0]   ind_flat_in,

    output                                          val_out,
    output      [BLOCK_IND_WIDTH-1:0]               ind_out
);
localparam  INPUT_DIR_NUM_WIDTH     = clogb2(BLOCK_WIDTH);
localparam  INPUT_DIR_SHIFT         = clogb2(BLOCK_WIDTH)*BLOCK_LEVEL;
localparam  IND_MATR_WIDTH          = BLOCK_IND_WIDTH * BLOCK_WIDTH;
localparam  IND_REV_MATR_WIDTH      = BLOCK_IND_WIDTH * BLOCK_WIDTH;
localparam  DIR_MATRIX_WIDTH        = INPUT_DIR_NUM_WIDTH * BLOCK_WIDTH;
localparam  INV_DIR_MATRIX_WIDTH    = BLOCK_WIDTH * INPUT_DIR_NUM_WIDTH;

wire    [BLOCK_WIDTH-1:0]           single_valid_bus;
wire    [BLOCK_IND_WIDTH-1:0]       selected_ind;
wire    [IND_MATR_WIDTH-1:0]        ind_matr;
wire    [INPUT_DIR_NUM_WIDTH-1:0]   selected_direction;
wire    [IND_REV_MATR_WIDTH-1:0]    ind_in_revert_matrix;
wire    [DIR_MATRIX_WIDTH-1:0]      direction_matrix;
wire    [INV_DIR_MATRIX_WIDTH-1:0]  direction_matrix_inv;

genvar ii, jj;

assign val_out = |ind_val_in;

assign ind_out = (selected_direction << INPUT_DIR_SHIFT) + selected_ind;

// Vector with at most one valid bit set
generate begin
    for (ii = 0; ii < BLOCK_WIDTH; ii = ii + 1) begin: single_valid_bus_gen
        if (ii == 0) begin
            assign single_valid_bus[ii] = ind_val_in[ii];
        end
        else begin
            assign single_valid_bus[ii] = ~(|ind_val_in[ii-1:0]) & ind_val_in[ii];
        end
    end
end
endgenerate

// Parallel OR input indexes masked by a vector with at most one valid bit set
generate begin
    for (ii = 0; ii < BLOCK_WIDTH; ii = ii + 1) begin: ind_matr_gen
        assign ind_matr[(ii+1)*BLOCK_IND_WIDTH-1 -: BLOCK_IND_WIDTH] = ind_flat_in[(ii+1)*BLOCK_IND_WIDTH-1:ii*BLOCK_IND_WIDTH];
    end


    for (ii = 0; ii < BLOCK_IND_WIDTH; ii = ii + 1) begin: selected_ind_gen
        for (jj = 0; jj < BLOCK_WIDTH; jj = jj + 1) begin: ind_in_revert_gen
            assign ind_in_revert_matrix[ii * BLOCK_WIDTH + jj] = ind_matr[jj * BLOCK_IND_WIDTH + ii] & single_valid_bus[jj];
        end
        assign selected_ind[ii] = |ind_in_revert_matrix[(ii+1) * BLOCK_WIDTH-1 -: BLOCK_WIDTH];
    end
end
endgenerate

// Get Input Direction number curresponding to a set bit in single_valid_bus
generate begin
    for (ii = 0; ii < BLOCK_WIDTH; ii = ii + 1) begin: direction_matrix_gen
        assign direction_matrix[(ii+1) * INPUT_DIR_NUM_WIDTH-1 -: INPUT_DIR_NUM_WIDTH] = (ii % 2 == 0) ? 1'b0 : 1'b1;
    end

    for (ii = 0; ii < INPUT_DIR_NUM_WIDTH; ii = ii + 1) begin: selected_direction_gen
        for (jj = 0; jj < BLOCK_WIDTH; jj = jj + 1) begin: direction_matrix_gen
            assign direction_matrix_inv[ii * BLOCK_WIDTH + jj] = direction_matrix[jj * INPUT_DIR_NUM_WIDTH + ii] & single_valid_bus[jj];
        end
        assign selected_direction[ii] = |direction_matrix_inv[(ii+1)*BLOCK_WIDTH-1 -: BLOCK_WIDTH];
    end
end
endgenerate

// clogb2 function
`include "clogb2.vh"

endmodule
