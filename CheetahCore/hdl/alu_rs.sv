module alu_rs
import rv32i_types::*;
                        #( parameter ALU_RS_DEPTH = 4,
                           parameter MUL_RS_DEPTH = 4,
                           parameter DIV_RS_DEPTH = 4,
                           parameter MEM_RS_DEPTH = 4,
                           parameter BR_RS_DEPTH = 4,
                           parameter DATA_WIDTH = 6,
                           parameter ROB_DEPTH = 16 )
(
    input   logic                           clk,
    input   logic                           rst,
    
    // From rename_dispatch
    input   alu_rs_data_t                   alu_rs_data,
    input                                   jump_commit,
    // From CDB, update ready bits if wakeup received and pd_broadcast match
    input   logic                           wakeup,
    input   logic   [DATA_WIDTH-1:0]        pd_broadcast,
    input   logic                           funit_ready_alu,
    // To execute
    output  alu_rs_data_t                   alu_rs_data_out,
    output  logic                           rs_select_alu,
    // If reservation stations are full, prevent dequeue from iqueu
    output  logic                           rs_full_alu,
    // To register file
    output  logic   [DATA_WIDTH - 1: 0]     ps1_out_alu,
    output  logic   [DATA_WIDTH - 1: 0]     ps2_out_alu
);

            alu_rs_data_t                   alu_rs[ALU_RS_DEPTH]; 
            alu_rs_data_t                   alu_rs_next[ALU_RS_DEPTH];
            logic   [$clog2(ALU_RS_DEPTH) - 1:0] alu_write_idx;
            logic                           alu_valid_write_idx;
            int unsigned                    alu_rs_full_hk;
            // send instructuion in order 
            int                             alu_count;
            int                             alu_count_next; 
            logic   [$clog2(ALU_RS_DEPTH) - 1:0]    valid_alu_rs_idx;
            
    /* ======================================================================================================================================================  */

    always_ff @( posedge clk ) begin
        if ( rst || jump_commit ) begin
            for ( int i = 0; i < ALU_RS_DEPTH; i++ ) begin
                // Ensures that valid is set to 0 right away
                alu_rs[i] <= '0;
                alu_count <= '0; 
            end
        end
        else begin
            alu_rs <= alu_rs_next; 
            if ( rs_full_alu ) begin
                alu_rs_full_hk <= alu_rs_full_hk + 1;
            end
            alu_count <= alu_count_next;
        end
    end


    // -------------------------------------------------- alu always comb -----------------------------------------------------------------
    always_comb begin 
        alu_count_next = alu_count;
        alu_rs_next = alu_rs;
        alu_write_idx = '0;
        alu_valid_write_idx = '0;
        valid_alu_rs_idx = '0;
        ps1_out_alu = '0;
        ps2_out_alu = '0;
        rs_full_alu = '1;
        rs_select_alu = '0;

        for ( int i = 0; i < ALU_RS_DEPTH; i++ ) begin

            // On wakeup, update readiness for each reservation station element
            // Note that ready changes will take 1 cycle to come into effect
            if ( wakeup ) begin
                if ( !alu_rs[i].ps1_ready && alu_rs[i].ps1 == pd_broadcast && alu_rs[i].valid ) begin
                    alu_rs_next[i].ps1_ready = '1;
                end
                if ( !alu_rs[i].ps2_ready && alu_rs[i].ps2 == pd_broadcast && alu_rs[i].valid ) begin
                    alu_rs_next[i].ps2_ready = '1;
                end
            end

            // Mark alu as not full if any idx is invalid
            if ( !alu_rs[i].valid ) begin
                alu_write_idx = unsigned'( $clog2( ALU_RS_DEPTH )'(i) );
                alu_valid_write_idx = '1;
            end

            // // If we have not found a ready index yet

                // If rs value is valid and both ps are ready
            if ( alu_rs[i].valid && alu_rs[i].ps1_ready && alu_rs[i].ps2_ready && funit_ready_alu ) begin
                // If using imm, read from register 0 but ignore output
                if (rs_select_alu) begin
                    if ( alu_rs[i].alu_count < alu_rs[valid_alu_rs_idx].alu_count) begin
                        valid_alu_rs_idx = unsigned'( $clog2( ALU_RS_DEPTH )'(i) );
                    end
                end
                else begin
                    rs_select_alu = '1;
                    valid_alu_rs_idx = unsigned'( $clog2( ALU_RS_DEPTH )'(i) );
                end
            end
        end

        if ( rs_select_alu ) begin
            for (int i = 0; i < ALU_RS_DEPTH; i++) begin
                if ( alu_rs[i].valid ) begin
                    alu_rs_next[i].alu_count = alu_rs[i].alu_count - 1;
                end
            end
            alu_count_next = alu_count_next - 1;
        end

        if ( alu_rs_data.valid && alu_valid_write_idx ) begin
            alu_rs_next[alu_write_idx] = alu_rs_data;
            alu_rs_next[alu_write_idx].alu_count = alu_count_next; 
            alu_count_next = alu_count_next + 1;
            
            // On wakeup, update readiness for each reservation station element
            // Note that ready changes will take 1 cycle to come into effect
            if ( wakeup ) begin
                if ( !alu_rs_next[alu_write_idx].ps1_ready && alu_rs_next[alu_write_idx].ps1 == pd_broadcast && alu_rs_next[alu_write_idx].valid ) begin
                    alu_rs_next[alu_write_idx].ps1_ready = '1;
                end
                if ( !alu_rs_next[alu_write_idx].ps2_ready && alu_rs_next[alu_write_idx].ps2 == pd_broadcast && alu_rs_next[alu_write_idx].valid ) begin
                    alu_rs_next[alu_write_idx].ps2_ready = '1;
                end
            end
        end

        if ( rst || jump_commit ) begin
            alu_rs_data_out = '0;
        end 
        else begin
            if ( alu_rs[valid_alu_rs_idx].valid && alu_rs[valid_alu_rs_idx].ps1_ready && alu_rs[valid_alu_rs_idx].ps2_ready && funit_ready_alu) begin
                alu_rs_data_out = alu_rs[valid_alu_rs_idx];
                if ( alu_rs[valid_alu_rs_idx].alu_m2_sel == imm_out ) begin
                    ps2_out_alu = '0;
                end
                else begin
                    ps2_out_alu = alu_rs[valid_alu_rs_idx].ps2;
                end

                ps1_out_alu = alu_rs[valid_alu_rs_idx].ps1;
                alu_rs_next[valid_alu_rs_idx].valid = '0;
                alu_rs_next[valid_alu_rs_idx].alu_count = '0;
            end
            else begin
                alu_rs_data_out = '0;
            end
        end

        // After allowing time for alu to be written to and read from, check if it is full
        for ( int i = 0; i < ALU_RS_DEPTH; i++ ) begin
            if ( !alu_rs_next[i].valid ) begin
                rs_full_alu = '0;
            end
        end
    end
    // ------------------------- END ALU ----------------------------------------------------------------------------------------------//

endmodule : alu_rs




