module rrf
import rv32i_types::*;
             #( parameter ROB_DATA_WIDTH = 12, 
              parameter PS_WIDTH = 6 )
(
    input   logic                               clk,
    input   logic                               rst,

    // From ROB, if valid_out, update free list
    input   logic   [ROB_DATA_WIDTH - 1:0]      rob_data_out,
    input   logic                               rob_data_out_valid,

    output  logic   [PS_WIDTH - 1:0]            rrf_pd,
    output  logic                               free_list_enqueue,

    input   rvfi_t                              rrf_rvfi,

    input   logic                               jump_commit,
    output  logic   [PS_WIDTH - 1:0]            rrf_out[31:0]
);

            logic   [PS_WIDTH - 1:0]            rrf[31:0];
            logic   [PS_WIDTH - 1:0]            rrf_next[31:0];
            rvfi_t                              rvfi;
            logic                               rob_data_out_valid_reg;

            // Performance Hooks
            int unsigned                        branch_committed_hk;
            int unsigned                        imm_committed_hk;
            int unsigned                        reg_committed_hk;
            int unsigned                        load_committed_hk;
            int unsigned                        store_committed_hk;
            int unsigned                        jump_committed_hk;

            int unsigned                        total_committed_hk;

            localparam int RRF_WIDTH = 5;

    /*
        1) Evict RRF entry corresponding to rd from rob, send that pd to free list
        2) Update RRF to contain the modern mapping of rd -> pd 
    */

always_ff @( posedge clk ) begin
    if ( rst ) begin
        for ( int i = 0; i < 32; i++ ) begin
            rrf[i] <= {{( PS_WIDTH - 5 ){1'b0}}, RRF_WIDTH'(i)};
        end
        rvfi <= '0;
        rob_data_out_valid_reg <= '0;
    end
    else begin
        for ( int i = 0; i < 32; i++ ) begin
            rrf[i] <= rrf_next[i];
        end
        rvfi.valid <= rob_data_out_valid;
        if (rob_data_out_valid_reg) begin
            rvfi.order <= rvfi.order + 1'b1;
        end
        rob_data_out_valid_reg <= rob_data_out_valid;
        rvfi.inst <= rrf_rvfi.inst;
        rvfi.rs1_addr <= rrf_rvfi.rs1_addr;
        rvfi.rs2_addr <= rrf_rvfi.rs2_addr;
        rvfi.rs1_v <= rrf_rvfi.rs1_v;
        rvfi.rs2_v <= rrf_rvfi.rs2_v;
        rvfi.rd_addr <= rrf_rvfi.rd_addr;
        rvfi.rd_wdata <= rrf_rvfi.rd_wdata;
        rvfi.pc_rdata <= rrf_rvfi.pc_rdata;
        rvfi.pc_wdata <= rrf_rvfi.pc_wdata;
        rvfi.mem_addr <= rrf_rvfi.mem_addr;
        rvfi.mem_rmask <= rrf_rvfi.mem_rmask;
        rvfi.mem_wmask <= rrf_rvfi.mem_wmask;
        rvfi.mem_wdata <= rrf_rvfi.mem_wdata;
        rvfi.mem_rdata <= rrf_rvfi.mem_rdata;
    end

    if ( rvfi.inst[6:0] == op_b_br ) begin
        branch_committed_hk <= branch_committed_hk + 1;
    end
    if ( rvfi.inst[6:0] == op_b_imm ) begin
        imm_committed_hk <= imm_committed_hk + 1;
    end
    if ( rvfi.inst[6:0] == op_b_reg ) begin
        reg_committed_hk <= reg_committed_hk + 1;
    end
    if ( rvfi.inst[6:0] == op_b_load ) begin
        load_committed_hk <= load_committed_hk + 1;
    end
    if ( rvfi.inst[6:0] == op_b_store ) begin
        store_committed_hk <= store_committed_hk + 1;
    end
    if ( rvfi.inst[6:0] == op_b_jal || rvfi.inst[6:0] == op_b_jalr ) begin
        jump_committed_hk <= jump_committed_hk + 1;
    end
    
    if ( rvfi.valid ) begin
        total_committed_hk <= total_committed_hk + 1;
    end
end
    
always_comb begin

    rrf_pd = '0;
    rrf_next = rrf;
    free_list_enqueue = '0;

    for ( int i = 0; i < 32; i++ ) begin
        rrf_out[i] = '0;
    end
    
    // If the ROB has a valid output, process it
    if ( rob_data_out_valid && ( rob_data_out[ROB_DATA_WIDTH - 1 - 1: PS_WIDTH] != '0 ) ) begin

        // Get saved pd from RRF and enqueue it in free list
        rrf_pd = rrf[rob_data_out[ROB_DATA_WIDTH - 1 - 1: PS_WIDTH]];
        free_list_enqueue = '1;

        // Update mapping to new rob_data_out pd
        // EX. Assume ROB_DATA_WIDTH = 12, PS_WIDTH = 6, RS_WIDTH = 5
        // rd = rob[12 - 1 - 1 : 6] = rob[10:6]
        // pd = rob[6 - 1 : 0] = rob[5:0]
        rrf_next[rob_data_out[ROB_DATA_WIDTH - 1 - 1: PS_WIDTH]] = rob_data_out[PS_WIDTH - 1:0];
    end

    if ( jump_commit ) begin
        rrf_out = rrf_next;
    end
end 

endmodule : rrf


