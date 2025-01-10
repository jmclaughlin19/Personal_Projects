module mem_rs
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
    input   mem_rs_data_t                   mem_rs_data,

    input   [$clog2(ROB_DEPTH)-1:0]         rob_head_idx,

    input                                   jump_commit,
    
    // From CDB, update ready bits if wakeup received and pd_broadcast match
    input   logic                           wakeup,
    input   logic   [DATA_WIDTH-1:0]        pd_broadcast,

    input   logic                           funit_ready_mem,

    input   logic                           mem_inst_complete,

    output  mem_rs_data_t                   mem_rs_data_out,

    
    output  logic                           rs_select_mem,

    // If reservation stations are full, prevent dequeue from iqueu
    output  logic                           rs_full_mem,
    output  logic                           rs_full_ld,

    input   logic   [31:0]                  ps1_v_mem,
    input   logic   [31:0]                  ps2_v_mem,


    output  logic                           mem_inst_sent_invalid_reg,
    input   logic   [31:0]                  pd_v_broadcast,
    input   logic   [31:0]                  dmem_addr,
    input   logic   [31:0]                  dmem_wdata,
    input   logic   [3:0]                   dmem_wmask
);




            mem_rs_data_t                   ld_rs[MEM_RS_DEPTH];
            mem_rs_data_t                   ld_rs_next[MEM_RS_DEPTH];

            // Store valid indices encoded
           
            logic   [$clog2(MEM_RS_DEPTH) - 1:0]    valid_ld_rs_idx;
            logic   [$clog2(MEM_RS_DEPTH) - 1:0]    ld_write_idx;
            logic                                   ld_valid_write_idx;


            // Mem reservation station queue variables
            logic [$clog2(MEM_RS_DEPTH)-1:0] head, tail, tail_next, head_next;
            logic                           head_parity, tail_parity, head_parity_next, tail_parity_next;
            logic                           full_reg, empty, empty_reg, full;
            mem_rs_data_t                   mem_rs[MEM_RS_DEPTH];
            mem_rs_data_t                   mem_rs_next[MEM_RS_DEPTH];
            logic                           dequeue;
            logic                           mem_inst_sent;
            logic                           mem_inst_sent_reg;
            logic                           mem_inst_complete_reg;

            int unsigned                    mem_rs_full_hk;

            logic                           store_sent_flag;

            logic       [MEM_RS_DEPTH-1:0]  store_count;
            logic       [MEM_RS_DEPTH-1:0]  store_count_next;
            logic       [MEM_RS_DEPTH-1:0]  store_address_found;
            logic       [MEM_RS_DEPTH-1:0]  store_address_found_next;
            logic                           invalid_load;
            logic                           invalid_load_data_mask;


            // send instructuion in order 
            int                             ld_count;
            int                             ld_count_next;               

    // Branch queue
    always_ff @( posedge clk ) begin
        if ( rst || jump_commit ) begin
            for ( int i = 0; i < MEM_RS_DEPTH; i++ ) begin
                store_count[i] <= '0;
                store_address_found[i] <= '0;
            end
            ld_count <= '0;
        end 
        else begin
            store_count <= store_count_next;
            ld_count <= ld_count_next;
        end
    end
    
    /* ======================================================================================================================================================  */
    
    // Memory queue
    always_ff @( posedge clk ) begin
        if ( rst || jump_commit ) begin
            head_parity <= '0;
            tail_parity <= '0;
            head <= '0;
            tail <= '0;
            full_reg <= '0;
            empty_reg <= '1;
            for ( int i = 0; i < MEM_RS_DEPTH; i++ ) begin
                mem_rs[i] <= '0;
            end
            if ( rst ) begin
                mem_inst_sent_invalid_reg <= '0;
                mem_inst_sent_reg <= '0;
            end
            else if ( jump_commit && ( mem_inst_sent || mem_inst_sent_reg ) ) begin
                mem_inst_sent_invalid_reg <= '1;
            end
        end 
        else begin
            head <= head_next;
            tail <= tail_next;
            head_parity <= head_parity_next;
            tail_parity <= tail_parity_next;
            full_reg <= full;
            empty_reg <= empty;
            mem_rs <= mem_rs_next;
        end

        if ( mem_inst_sent && !jump_commit ) begin
            mem_inst_sent_reg <= mem_inst_sent;
            mem_inst_sent_invalid_reg <= '0;
        end
        // else if ( mem_inst_sent && ( mem_inst_complete || mem_inst_complete_force) ) begin
        //     mem_inst_sent_reg <= '0;
        // end
        else if ( mem_inst_complete ) begin
            mem_inst_sent_reg <= '0;
        end
    end

    /* ======================================================================================================================================================  */

    always_ff @( posedge clk ) begin
        if ( rst || jump_commit ) begin
            for ( int i = 0; i < MEM_RS_DEPTH; i++ ) begin
                ld_rs[i] <= '0;
            end

            mem_inst_complete_reg <= '0;
        end
        else begin
            ld_rs <= ld_rs_next;

            mem_inst_complete_reg <= mem_inst_complete;
            if ( rs_full_mem ) begin
                mem_rs_full_hk <= mem_rs_full_hk + 1;
            end
            // if ( rs_full_ld ) begin
            //     ld_rs_full_hk <= ld_rs_full_hk + 1;
            // end
        end
    end

    always_comb begin
        ld_count_next = ld_count; 
        invalid_load_data_mask = '0;
        store_count_next = store_count;
        store_address_found_next = store_address_found;
        invalid_load = '0;

        ld_rs_next = ld_rs;
        ld_write_idx = '0;
        ld_valid_write_idx = '0;
        
        valid_ld_rs_idx = '0;
        

        
        // Assume rs are full, if an empty idx is found flip corresponding rs bit        
        rs_full_ld = '1;
        rs_select_mem = '0;


        //============================================MEMORY AND SUCH ========================================//

        if ( rst || jump_commit ) begin
            head_parity_next = '0;
            tail_parity_next = '0;
            tail_next = '0;
            head_next = '0;
            store_sent_flag = '0;

            for ( int i = 0; i < MEM_RS_DEPTH; i++ ) begin
                mem_rs_next[i] = '0;
            end
            dequeue = '0;
            mem_inst_sent = '0;
            mem_rs_data_out = '0;
        end
        else begin
            mem_rs_next = mem_rs;
            tail_next = tail;
            head_next = head;
            tail_parity_next = tail_parity;
            head_parity_next = head_parity;
            mem_inst_sent = '0;
            mem_rs_data_out = '0;
            store_sent_flag = '0;

            if ( funit_ready_mem && mem_rs_next[head].valid && mem_rs_next[head].ps1_ready && mem_rs_next[head].ps2_ready && !mem_inst_sent && (!mem_inst_sent_reg || mem_inst_complete_reg)) begin
                dequeue = 1'b1;
            end
            else begin
                dequeue = 1'b0;
            end
            if ( dequeue && !empty_reg ) begin
                if ((mem_rs_next[head].inst[6:0] == op_b_store && mem_rs_next[head].rob_idx == rob_head_idx)) begin 
                    store_count_next[head] = '0;
                    store_sent_flag = 1'b1;
                    head_next = head + 1'b1;
                    mem_rs_data_out = mem_rs_next[head];
                    if ( integer'( head_next ) == MEM_RS_DEPTH - 1 ) begin
                        head_parity_next = !head_parity_next;
                    end
                    mem_inst_sent = '1;
                    mem_rs_next[head].valid = '0;
                    rs_select_mem = '1;
                    store_address_found_next[head] = '0;
                end
            end
            if ( mem_rs_data.valid && !full_reg && mem_rs_data.inst[6:0] == op_b_store ) begin
                tail_next = tail + 1'b1;
                mem_rs_next[tail] = mem_rs_data;
                store_count_next[tail] = '1;
                // if ( mem_rs_next[tail].ps1_ready ) begin
                    mem_rs_next[tail].ps1_v = ps1_v_mem;
                // end 
                // if ( mem_rs_next[tail].ps2_ready ) begin
                    mem_rs_next[tail].ps2_v = ps2_v_mem;
                // end 
                if ( wakeup ) begin
                    if ( !mem_rs_next[tail].ps1_ready && mem_rs_next[tail].ps1 == pd_broadcast && mem_rs_next[tail].valid ) begin
                        mem_rs_next[tail].ps1_ready = '1;
                        mem_rs_next[tail].ps1_v = pd_v_broadcast;
                    end
                    if ( !mem_rs_next[tail].ps2_ready && mem_rs_next[tail].ps2 == pd_broadcast && mem_rs_next[tail].valid ) begin
                        mem_rs_next[tail].ps2_ready = '1;
                        mem_rs_next[tail].ps2_v = pd_v_broadcast;
                    end
                end
                if (mem_rs_next[tail].ps2_ready && mem_rs_next[tail].ps1_ready && mem_rs_next[tail].valid) begin
                    mem_rs_next[tail].mem_addr = mem_rs_next[tail].ps1_v + mem_rs_next[tail].imm;
                    store_address_found_next[tail] = '1;
                end
                if ( integer'( tail_next ) == MEM_RS_DEPTH - 1 ) begin
                    tail_parity_next = !tail_parity_next;
                end
            end 
        end
        
        for ( int i = 0; i < MEM_RS_DEPTH; i++ ) begin
            // On wakeup, update readiness for each reservation station element
            // Note that ready changes will take 1 cycle to come into effect
            if ( wakeup ) begin
                if ( !mem_rs[i].ps1_ready && mem_rs[i].ps1 == pd_broadcast && mem_rs[i].valid ) begin
                    mem_rs_next[i].ps1_ready = '1;
                    mem_rs_next[i].ps1_v = pd_v_broadcast;
                end
                if ( !mem_rs[i].ps2_ready && mem_rs[i].ps2 == pd_broadcast && mem_rs[i].valid ) begin
                    mem_rs_next[i].ps2_ready = '1;
                    mem_rs_next[i].ps2_v = pd_v_broadcast;
                end
                if (mem_rs_next[i].ps2_ready && mem_rs_next[i].ps1_ready && mem_rs_next[i].valid) begin
                    mem_rs_next[i].mem_addr = mem_rs_next[i].ps1_v + mem_rs_next[i].imm;
                    store_address_found_next[i] = '1;
                end
            end

        end
        // end store logic 

        // begin load logic 
        for ( int i = 0; i < MEM_RS_DEPTH; i++ ) begin

            // On wakeup, update readiness for each reservation station element
            // Note that ready changes will take 1 cycle to come into effect
            if ( wakeup ) begin
                if ( !ld_rs[i].ps1_ready && ld_rs[i].ps1 == pd_broadcast && ld_rs[i].valid ) begin
                    ld_rs_next[i].ps1_ready = '1;
                    ld_rs_next[i].ps1_v = pd_v_broadcast;
                end
                if ( !ld_rs[i].ps2_ready && ld_rs[i].ps2 == pd_broadcast && ld_rs[i].valid ) begin
                    ld_rs_next[i].ps2_ready = '1;
                    ld_rs_next[i].ps2_v = pd_v_broadcast;
                end
                if (ld_rs_next[i].ps2_ready && ld_rs_next[i].ps1_ready && ld_rs_next[i].valid) begin
                    ld_rs_next[i].mem_addr = ld_rs_next[i].ps1_v + ld_rs_next[i].imm;
                    unique case(ld_rs_next[i].inst[14:12])
                        load_f3_lb, load_f3_lbu: ld_rs_next[i].mem_rmask = 4'b0001 << ld_rs_next[i].mem_addr[1:0];
                        load_f3_lh, load_f3_lhu: ld_rs_next[i].mem_rmask = 4'b0011 << ld_rs_next[i].mem_addr[1:0];
                        load_f3_lw             : ld_rs_next[i].mem_rmask = 4'b1111;
                        default                : ld_rs_next[i].mem_rmask = '0;      
                    endcase
                end
            end

            if ( dmem_wmask != '0 ) begin
                if (ld_rs_next[i].ps2_ready && ld_rs_next[i].ps1_ready && ld_rs_next[i].valid) begin
                    if (ld_rs_next[i].mem_addr[31:2] == dmem_addr[31:2]) begin
                        invalid_load_data_mask = '0;
                        for (int j = 0; j < 4; j++) begin
                            if (ld_rs_next[i].mem_rmask[j]) begin
                                if (!dmem_wmask[j]) begin
                                    invalid_load_data_mask = '1;
                                end
                            end
                        end
                        if (!invalid_load_data_mask) begin
                            ld_rs_next[i].load_data_valid = '1;
                            ld_rs_next[i].load_data_rdata = dmem_wdata;
                        end
                    end
                end
            end

            // Mark alu as not full if any idx is invalid
            if ( !ld_rs[i].valid ) begin
                ld_write_idx = unsigned'( $clog2( MEM_RS_DEPTH )'(i) );
                ld_valid_write_idx = '1;
            end

            // If we have not found a ready index yet
            // if ( valid_ld_rs_idx == '0 ) begin
                // If rs value is valid and both ps are ready
                if ( ld_rs[i].valid && ld_rs[i].ps1_ready && ld_rs[i].ps2_ready && funit_ready_mem && !store_sent_flag && !mem_inst_sent && (!mem_inst_sent_reg || mem_inst_complete_reg)) begin
                    invalid_load = 1'b0;
                    if ( rs_select_mem ) begin
                        if ( ld_rs[i].ld_count < ld_rs[valid_ld_rs_idx].ld_count) begin
                            for ( int j = 0; j < MEM_RS_DEPTH; j++ ) begin
                                if (ld_rs[i].store_count[j] && store_address_found_next[j]) begin
                                    if (ld_rs[i].mem_addr[31:2] == mem_rs_next[j].mem_addr[31:2]) begin
                                        invalid_load = 1'b1;
                                    end
                                end
                                else if (ld_rs[i].store_count[j]) begin
                                    invalid_load = 1'b1;
                                end
                            end
                            if (!invalid_load) begin
                                rs_select_mem = '1;
                                valid_ld_rs_idx = unsigned'( $clog2( MEM_RS_DEPTH )'(i) );
                            end
                        end
                    end
                    else begin
                        for ( int j = 0; j < MEM_RS_DEPTH; j++ ) begin
                            if (ld_rs[i].store_count[j] && store_address_found_next[j]) begin
                                if (ld_rs[i].mem_addr[31:2] == mem_rs_next[j].mem_addr[31:2]) begin
                                    invalid_load = 1'b1;
                                end
                            end
                            else if (ld_rs[i].store_count[j]) begin
                                invalid_load = 1'b1;
                            end
                        end
                        if (!invalid_load) begin
                            rs_select_mem = '1;
                            valid_ld_rs_idx = unsigned'( $clog2( MEM_RS_DEPTH )'(i) );
                        end
                    end

                end
            // end

            if (store_sent_flag && ld_rs[i].valid) begin
                ld_rs_next[i].store_count[head] = '0;
            end
        end

        if ( rs_select_mem && !store_sent_flag) begin
            for (int i = 0; i < MEM_RS_DEPTH; i++) begin
                if ( ld_rs[i].valid ) begin
                    ld_rs_next[i].ld_count = ld_rs[i].ld_count - 1;
                end
            end
            ld_count_next = ld_count_next - 1;
        end

        if ( mem_rs_data.valid && ld_valid_write_idx && mem_rs_data.inst[6:0] == op_b_load ) begin
            ld_rs_next[ld_write_idx] = mem_rs_data;
            ld_rs_next[ld_write_idx].store_count = store_count_next;
            ld_rs_next[ld_write_idx].ld_count = ld_count_next;
            ld_count_next = ld_count_next + 1;
            // On wakeup, update readiness for each reservation station element
            // Note that ready changes will take 1 cycle to come into effect
            // if ( ld_rs_next[ld_write_idx].ps1_ready && ld_rs_next[ld_write_idx].valid ) begin
                ld_rs_next[ld_write_idx].ps1_v = ps1_v_mem;
            // end 
            // if ( ld_rs_next[ld_write_idx].ps2_ready && ld_rs_next[ld_write_idx].valid ) begin
                ld_rs_next[ld_write_idx].ps2_v = ps2_v_mem;
            // end   
            if ( wakeup ) begin
                if ( !ld_rs_next[ld_write_idx].ps1_ready && ld_rs_next[ld_write_idx].ps1 == pd_broadcast && ld_rs_next[ld_write_idx].valid ) begin
                    ld_rs_next[ld_write_idx].ps1_ready = '1;
                    ld_rs_next[ld_write_idx].ps1_v = pd_v_broadcast;
                end
                if ( !ld_rs_next[ld_write_idx].ps2_ready && ld_rs_next[ld_write_idx].ps2 == pd_broadcast && ld_rs_next[ld_write_idx].valid ) begin
                    ld_rs_next[ld_write_idx].ps2_ready = '1;
                    ld_rs_next[ld_write_idx].ps2_v = pd_v_broadcast;
                end
            end 
            if (ld_rs_next[ld_write_idx].ps2_ready && ld_rs_next[ld_write_idx].ps1_ready && ld_rs_next[ld_write_idx].valid) begin
                ld_rs_next[ld_write_idx].mem_addr = ld_rs_next[ld_write_idx].ps1_v + ld_rs_next[ld_write_idx].imm;
                unique case(ld_rs_next[ld_write_idx].inst[14:12])
                    load_f3_lb, load_f3_lbu: ld_rs_next[ld_write_idx].mem_rmask = 4'b0001 << ld_rs_next[ld_write_idx].mem_addr[1:0];
                    load_f3_lh, load_f3_lhu: ld_rs_next[ld_write_idx].mem_rmask = 4'b0011 << ld_rs_next[ld_write_idx].mem_addr[1:0];
                    load_f3_lw             : ld_rs_next[ld_write_idx].mem_rmask = 4'b1111;
                    default                : ld_rs_next[ld_write_idx].mem_rmask = '0;      
                endcase
            end
            if ( dmem_wmask != '0 ) begin
                if (ld_rs_next[ld_write_idx].ps2_ready && ld_rs_next[ld_write_idx].ps1_ready && ld_rs_next[ld_write_idx].valid) begin
                    if (ld_rs_next[ld_write_idx].mem_addr[31:2] == dmem_addr[31:2] ) begin
                        invalid_load_data_mask = '0;
                        for (int j = 0; j < 4; j++) begin
                            if (ld_rs_next[ld_write_idx].mem_rmask[j]) begin
                                if (!dmem_wmask[j]) begin
                                    invalid_load_data_mask = '1;
                                end
                            end
                        end
                        if (!invalid_load_data_mask) begin
                            ld_rs_next[ld_write_idx].load_data_valid = '1;
                            ld_rs_next[ld_write_idx].load_data_rdata = dmem_wdata;
                        end
                    end
                end
            end
        end

        /* ======================================================================================================================================================  */

        
        if ( !rst && !jump_commit) begin


            if ( ld_rs[valid_ld_rs_idx].valid && ld_rs[valid_ld_rs_idx].ps1_ready && ld_rs[valid_ld_rs_idx].ps2_ready && funit_ready_mem && !store_sent_flag && rs_select_mem) begin
                mem_rs_data_out = ld_rs[valid_ld_rs_idx];
                if (!ld_rs[valid_ld_rs_idx].load_data_valid) begin
                    mem_inst_sent = '1;
                end
                ld_rs_next[valid_ld_rs_idx].valid = '0;
                ld_rs_next[valid_ld_rs_idx].load_data_valid = '0;
                ld_rs_next[valid_ld_rs_idx].ld_count = '0;
            end

        end
    
        //======================================================END MEMORY AND SUCH=============================================//

        // After allowing time for alu to be written to and read from, check if it is full

        for ( int i = 0; i < MEM_RS_DEPTH; i++ ) begin
            if ( !ld_rs_next[i].valid ) begin
                rs_full_ld = '0;
            end
        end

        full = ( head_parity_next != tail_parity_next ) && ( head_next == tail_next );
        empty = ( head_parity_next == tail_parity_next ) && ( head_next == tail_next );
        rs_full_mem = full;

    end

endmodule : mem_rs




