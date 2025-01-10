module reservation_stations
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
    input   mul_rs_data_t                   mul_rs_data,
    input   div_rs_data_t                   div_rs_data,
    input   br_rs_data_t                    br_rs_data,

    input   [$clog2(ROB_DEPTH)-1:0]         rob_head_idx,

    input                                   jump_commit,
    
    // From CDB, update ready bits if wakeup received and pd_broadcast match
    input   logic                           wakeup,
    input   logic   [DATA_WIDTH-1:0]        pd_broadcast,

    input   logic                           funit_ready[5],

    input   state_t                         division_state,

    // To execute
    output  mul_rs_data_t                   mul_rs_data_out,
    output  div_rs_data_t                   div_rs_data_out, 
    output  br_rs_data_t                    br_rs_data_out,

    output  logic   [1:0]                   mul_shift_reg,

    
    output  logic                           rs_select_mul,
    output  logic                           rs_select_div,
    output  logic                           rs_select_br,

    // If reservation stations are full, prevent dequeue from iqueu
    output  logic                           rs_full_mul,
    output  logic                           rs_full_div,
    output  logic                           rs_full_br,
    output  logic                           multiplier_output_valid,

    output  logic   [DATA_WIDTH - 1: 0]     ps1_out_div,
    output  logic   [DATA_WIDTH - 1: 0]     ps2_out_div,
    output  logic   [DATA_WIDTH - 1: 0]     ps1_out_mul,
    output  logic   [DATA_WIDTH - 1: 0]     ps2_out_mul,
    output  logic   [DATA_WIDTH - 1: 0]     ps1_out_br,
    output  logic   [DATA_WIDTH - 1: 0]     ps2_out_br
);



            mul_rs_data_t                   mul_rs[MUL_RS_DEPTH]; 
            mul_rs_data_t                   mul_rs_next[MUL_RS_DEPTH]; 

            div_rs_data_t                   div_rs[DIV_RS_DEPTH]; 
            div_rs_data_t                   div_rs_next[DIV_RS_DEPTH]; 

            // Store valid indices encoded
            logic   [$clog2(MUL_RS_DEPTH) - 1:0]    valid_mul_rs_idx;
            logic   [$clog2(DIV_RS_DEPTH) - 1:0]    valid_div_rs_idx;
            


            logic   [$clog2(MUL_RS_DEPTH) - 1:0] mul_write_idx;
            logic                           mul_valid_write_idx;
            logic   [1:0]                   mul_shift_reg_next;

            logic   [$clog2(DIV_RS_DEPTH) - 1:0] div_write_idx;
            logic                           div_valid_write_idx;


            // Branch reservation station queue variables
            logic [$clog2(BR_RS_DEPTH)-1:0] head_br, tail_br, tail_next_br, head_next_br;
            logic                           head_parity_br, tail_parity_br, head_parity_next_br, tail_parity_next_br;
            logic                           full_reg_br, empty_br, empty_reg_br, full_br;
            br_rs_data_t                    br_rs[BR_RS_DEPTH];
            br_rs_data_t                    br_rs_next[BR_RS_DEPTH];
            logic                           dequeue_br;

            int unsigned                    mul_rs_full_hk;
            int unsigned                    div_rs_full_hk;
            int unsigned                    br_rs_full_hk;
            


            // send instructuion in order 
            int                             mul_count;
            int                             mul_count_next;
            int                             div_count;
            int                             div_count_next;
            

    // Branch queue
    always_ff @( posedge clk ) begin
        if ( rst || jump_commit ) begin
            head_parity_br <= '0;
            tail_parity_br <= '0;
            head_br <= '0;
            tail_br <= '0;
            full_reg_br <= '0;
            empty_reg_br <= '1;
            for ( int i = 0; i < BR_RS_DEPTH; i++ ) begin
                br_rs[i] <= '0;
            end
            mul_count <= '0;
            div_count <= '0;
        end 
        else begin
            head_br <= head_next_br;
            tail_br <= tail_next_br;
            head_parity_br <= head_parity_next_br;
            tail_parity_br <= tail_parity_next_br;
            full_reg_br <= full_br;
            empty_reg_br <= empty_br;
            br_rs <= br_rs_next;
            mul_count <= mul_count_next;
            div_count <= div_count_next;
        end
    end
    

    /* ======================================================================================================================================================  */

    always_ff @( posedge clk ) begin
        if ( rst || jump_commit ) begin
            for ( int i = 0; i < MUL_RS_DEPTH; i++ ) begin
                mul_rs[i] <= '0; 
            end
            for ( int i = 0; i < DIV_RS_DEPTH; i++ ) begin
                div_rs[i] <= '0; 
            end

            mul_shift_reg <= '0;
        end
        else begin
            mul_rs <= mul_rs_next; 
            div_rs <= div_rs_next; 

            mul_shift_reg <= mul_shift_reg_next;

            if ( rs_full_mul ) begin
                mul_rs_full_hk <= mul_rs_full_hk + 1;
            end
            if ( rs_full_div ) begin
                div_rs_full_hk <= div_rs_full_hk + 1;
            end
            if ( rs_full_br ) begin
                br_rs_full_hk <= br_rs_full_hk + 1;
            end
        end
    end

    // ------------------------------------ MUL ALWAYS COMB BLOCK ---------------------------------------------------------------------//
    always_comb begin
        mul_count_next = mul_count;
        mul_rs_next = mul_rs;
        mul_write_idx = '0;
        mul_valid_write_idx = '0;
        valid_mul_rs_idx = '0;
        ps1_out_mul = '0;
        ps2_out_mul = '0;
        mul_shift_reg_next = mul_shift_reg;
        multiplier_output_valid = mul_shift_reg[1];
        mul_shift_reg_next = mul_shift_reg_next << 1'b1;
        rs_full_mul = '1;
        rs_select_mul = '0;


        for ( int i = 0; i < MUL_RS_DEPTH; i++ ) begin
            // On wakeup, update readiness for each reservation station element
            // Note that ready changes will take 1 cycle to come into effect
            if ( wakeup ) begin
                if ( !mul_rs[i].ps1_ready && mul_rs[i].ps1 == pd_broadcast && mul_rs[i].valid ) begin
                    mul_rs_next[i].ps1_ready = '1;
                end
                if ( !mul_rs[i].ps2_ready && mul_rs[i].ps2 == pd_broadcast && mul_rs[i].valid ) begin
                    mul_rs_next[i].ps2_ready = '1;
                end
            end

            // Mark mul as not full if any idx is invalid
            if ( !mul_rs[i].valid ) begin
                mul_write_idx = unsigned'( $clog2( MUL_RS_DEPTH )'(i) );
                mul_valid_write_idx = '1;
            end

            // If we have not found a ready index yet and
            // Shift reg is empty meaning the mul unit is free
            // MIGHT HAVE TO CHANGE THIS TO MUL SHIFT REG
            if ( mul_shift_reg_next == '0 && funit_ready[mul] ) begin
                // If rs value is valid and both ps are ready
                if ( mul_rs[i].valid && mul_rs[i].ps1_ready && mul_rs[i].ps2_ready ) begin
                    if ( rs_select_mul ) begin
                        if ( mul_rs[valid_mul_rs_idx].mul_count > mul_rs[i].mul_count ) begin
                            valid_mul_rs_idx = unsigned'( $clog2( MUL_RS_DEPTH )'(i) );
                        end
                    end
                    else begin
                        rs_select_mul = '1;
                        valid_mul_rs_idx = unsigned'( $clog2( MUL_RS_DEPTH )'(i) );
                    end
                end
            end
        end
        if ( rs_select_mul ) begin
            for (int i = 0; i < MUL_RS_DEPTH; i++) begin
                if ( mul_rs[i].valid ) begin
                    mul_rs_next[i].mul_count = mul_rs[i].mul_count - 1;
                end
            end
            mul_count_next = mul_count_next - 1;
        end
        if ( mul_rs_data.valid && mul_valid_write_idx ) begin
            mul_rs_next[mul_write_idx] = mul_rs_data;
            mul_rs_next[mul_write_idx].mul_count = mul_count_next;
            mul_count_next = mul_count_next + 1;
            if ( wakeup ) begin
                if ( !mul_rs_next[mul_write_idx].ps1_ready && mul_rs_next[mul_write_idx].ps1 == pd_broadcast && mul_rs_next[mul_write_idx].valid ) begin
                    mul_rs_next[mul_write_idx].ps1_ready = '1;
                end
                if ( !mul_rs_next[mul_write_idx].ps2_ready && mul_rs_next[mul_write_idx].ps2 == pd_broadcast && mul_rs_next[mul_write_idx].valid ) begin
                    mul_rs_next[mul_write_idx].ps2_ready = '1;
                end
            end
        end

        if ( rst || jump_commit ) begin
            mul_rs_data_out = '0;
        end 
        else begin
            if ( mul_rs[valid_mul_rs_idx].valid && mul_rs[valid_mul_rs_idx].ps1_ready && mul_rs[valid_mul_rs_idx].ps2_ready && mul_shift_reg == '0 && funit_ready[mul]) begin
                mul_rs_data_out = mul_rs[valid_mul_rs_idx];
                ps2_out_mul = mul_rs[valid_mul_rs_idx].ps2;
                ps1_out_mul = mul_rs[valid_mul_rs_idx].ps1;
                mul_rs_next[valid_mul_rs_idx].valid = '0;
                mul_rs_next[valid_mul_rs_idx].mul_count = '0;

                // Update the shift register to indicate that the functional unit has began computation
                mul_shift_reg_next[0] = 1'b1;
            end
            else begin
                mul_rs_data_out = '0;
            end
        end

        // After allowing time for alu to be written to and read from, check if it is full

        for ( int i = 0; i < MUL_RS_DEPTH; i++ ) begin
            if ( !mul_rs_next[i].valid ) begin
                rs_full_mul = '0;
            end
        end
    end
    // ----------------------------------------- END MUL RS ------------------------------------------------------------------------

    // ----------------------------------------- DIV RS ALWAYS COMB BLOCK ----------------------------------------------------------
    always_comb begin
        div_count_next = div_count;
        div_rs_next = div_rs;
        div_write_idx = '0;
        div_valid_write_idx = '0;
        valid_div_rs_idx = '0;
        ps1_out_div = '0;
        ps2_out_div = '0;
        rs_full_div = '1;
        rs_select_div = '0;

        for ( int i = 0; i < DIV_RS_DEPTH; i++ ) begin
            // On wakeup, update readiness for each reservation station element
            // Note that ready changes will take 1 cycle to come into effect
            if ( wakeup ) begin
                if ( !div_rs[i].ps1_ready && div_rs[i].ps1 == pd_broadcast && div_rs[i].valid ) begin
                    div_rs_next[i].ps1_ready = '1;
                end
                if ( !div_rs[i].ps2_ready && div_rs[i].ps2 == pd_broadcast && div_rs[i].valid ) begin
                    div_rs_next[i].ps2_ready = '1;
                end
            end

            // Mark div as not full if any idx is invalid
            if ( !div_rs[i].valid ) begin
                div_write_idx = unsigned'( $clog2( DIV_RS_DEPTH )'(i) );
                div_valid_write_idx = '1;
            end

            // If we have not found a ready index yet and
            // Shift reg is empty meaning the div unit is free
            // MIGHT HAVE TO CHANGE THIS TO div SHIFT REG
            // if ( valid_div_rs_idx == '0 ) begin
                // If rs value is valid and both ps are ready
                if ( div_rs[i].valid && div_rs[i].ps1_ready && div_rs[i].ps2_ready && funit_ready[div] ) begin
                    if ( rs_select_div ) begin
                        if ( div_rs[i].div_count < div_rs[valid_div_rs_idx].div_count ) begin
                            valid_div_rs_idx = unsigned'( $clog2( DIV_RS_DEPTH )'(i) );
                        end
                    end
                    else begin
                        rs_select_div = '1;
                        valid_div_rs_idx = unsigned'( $clog2( DIV_RS_DEPTH )'(i) );
                    end
                end
            // end
        end

        if (rs_select_div) begin
            for (int i = 0; i < DIV_RS_DEPTH; i++) begin
                if ( div_rs[i].valid ) begin
                    div_rs_next[i].div_count = div_rs[i].div_count - 1;
                end
            end
            div_count_next = div_count_next - 1;
        end

        if ( div_rs_data.valid && div_valid_write_idx ) begin
            div_rs_next[div_write_idx] = div_rs_data;
            div_rs_next[div_write_idx].div_count = div_count_next;
            div_count_next = div_count_next + 1;
            if ( wakeup ) begin
                if ( !div_rs_next[div_write_idx].ps1_ready && div_rs_next[div_write_idx].ps1 == pd_broadcast && div_rs_next[div_write_idx].valid ) begin
                    div_rs_next[div_write_idx].ps1_ready = '1;
                end
                if ( !div_rs_next[div_write_idx].ps2_ready && div_rs_next[div_write_idx].ps2 == pd_broadcast && div_rs_next[div_write_idx].valid ) begin
                    div_rs_next[div_write_idx].ps2_ready = '1;
                end
            end
        end
        if ( rst || jump_commit ) begin
            div_rs_data_out = '0;
        end 
        else begin
            if ( div_rs[valid_div_rs_idx].valid && div_rs[valid_div_rs_idx].ps1_ready && div_rs[valid_div_rs_idx].ps2_ready && division_state == IDLE && funit_ready[div] ) begin
                div_rs_data_out = div_rs[valid_div_rs_idx];
                ps2_out_div = div_rs[valid_div_rs_idx].ps2;
                ps1_out_div = div_rs[valid_div_rs_idx].ps1;
                div_rs_next[valid_div_rs_idx].valid = '0;
                div_rs_next[valid_div_rs_idx].div_count = '0;
            end
            else begin
                div_rs_data_out = '0;
            end
        end

        for ( int i = 0; i < DIV_RS_DEPTH; i++ ) begin
            if ( !div_rs_next[i].valid ) begin
                rs_full_div = '0;
            end
        end
    end
    // ------------------------------------------ END DIV RS ---------------------------------------------------------------

    // ----------------------------------------- BR RS START ---------------------------------------------------------------
    always_comb begin
        ps1_out_br = '0;
        ps2_out_br = '0;
        rs_full_br = '1;
        rs_full_br = '0;
        rs_select_br = '0;

        // branch
        if ( rst || jump_commit ) begin
            head_parity_next_br = '0;
            tail_parity_next_br = '0;
            tail_next_br = '0;
            head_next_br = '0;

            for ( int i = 0; i < BR_RS_DEPTH; i++ ) begin
                br_rs_next[i] = '0;
            end
            dequeue_br = '0;
            br_rs_data_out = '0;
        end
        else begin
            br_rs_next = br_rs;
            tail_next_br = tail_br;
            head_next_br = head_br;
            tail_parity_next_br = tail_parity_br;
            head_parity_next_br = head_parity_br;
            br_rs_data_out = '0;

            if ( funit_ready[br] && br_rs_next[head_br].valid && br_rs_next[head_br].ps1_ready && br_rs_next[head_br].ps2_ready) begin
                dequeue_br = 1'b1;
            end
            else begin
                dequeue_br = 1'b0;
            end
            if ( br_rs_data.valid && !full_reg_br ) begin
                tail_next_br = tail_br + 1'b1;
                br_rs_next[tail_br] = br_rs_data;
                if ( wakeup ) begin
                    if ( !br_rs_next[tail_br].ps1_ready && br_rs_next[tail_br].ps1 == pd_broadcast && br_rs_next[tail_br].valid ) begin
                        br_rs_next[tail_br].ps1_ready = '1;
                    end
                    if ( !br_rs_next[tail_br].ps2_ready && br_rs_next[tail_br].ps2 == pd_broadcast && br_rs_next[tail_br].valid ) begin
                        br_rs_next[tail_br].ps2_ready = '1;
                    end
                end
                if ( integer'( tail_next_br ) == BR_RS_DEPTH - 1 ) begin
                    tail_parity_next_br = !tail_parity_next_br;
                end
            end 
            if ( dequeue_br && !empty_reg_br ) begin
                if ( br_rs_next[head_br].rob_idx == rob_head_idx && ( br_rs_next[head_br].inst[6:0] == op_b_br ||
                                                                      br_rs_next[head_br].inst[6:0] == op_b_jal ||
                                                                      br_rs_next[head_br].inst[6:0] == op_b_jalr ) ) begin 

                    head_next_br = head_br + 1'b1;
                    br_rs_data_out = br_rs_next[head_br];
                    if ( integer'( head_next_br ) == BR_RS_DEPTH - 1 ) begin
                        head_parity_next_br = !head_parity_next_br;
                    end
                    br_rs_next[head_br].valid = '0;
                    rs_select_br = '1;
                    ps1_out_br = br_rs_data_out.ps1;
                    ps2_out_br = br_rs_data_out.ps2;
                end
            end
        end

        for ( int i = 0; i < BR_RS_DEPTH; i++ ) begin
            // On wakeup, update readiness for each reservation station element
            // Note that ready changes will take 1 cycle to come into effect
            if ( wakeup ) begin
                if ( !br_rs[i].ps1_ready && br_rs[i].ps1 == pd_broadcast && br_rs[i].valid ) begin
                    br_rs_next[i].ps1_ready = '1;
                end
                if ( !br_rs[i].ps2_ready && br_rs[i].ps2 == pd_broadcast && br_rs[i].valid ) begin
                    br_rs_next[i].ps2_ready = '1;
                end
            end
        end

        full_br = ( head_parity_next_br != tail_parity_next_br ) && ( head_next_br == tail_next_br );
        empty_br = ( head_parity_next_br == tail_parity_next_br ) && ( head_next_br == tail_next_br);
        rs_full_br = full_br;

    end



endmodule : reservation_stations




