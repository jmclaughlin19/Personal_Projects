module rvfi_array
import rv32i_types::*;
             #( ARR_DEPTH = 16 )
(
    input               clk,
    input               rst,
    input   rvfi_t      rvfi_ex,
    input   [$clog2(ARR_DEPTH)-1:0]       rob_idx_in,
    input   [$clog2(ARR_DEPTH)-1:0]       rob_idx_out,
    input               read_enable,

    output  rvfi_t      rvfi_data
);

rvfi_t  rvfi_arr[ARR_DEPTH];
rvfi_t  rvfi_arr_next[ARR_DEPTH];

always_ff @(posedge clk) begin
    if ( rst ) begin
        for ( int i = 0; i < ARR_DEPTH; i++ ) begin
            rvfi_arr[i] <= '0;
        end
    end
    else begin
        for ( int i = 0; i < ARR_DEPTH; i++ ) begin
            rvfi_arr[i] <= rvfi_arr_next[i];
        end
    end
end

always_comb begin
    rvfi_arr_next = rvfi_arr;
    rvfi_data = '0;

    if (rvfi_ex.valid) begin
        rvfi_arr_next[rob_idx_in] = rvfi_ex;
    end

    if (read_enable) begin
        rvfi_data = rvfi_arr[rob_idx_out];
    end
end


endmodule : rvfi_array


