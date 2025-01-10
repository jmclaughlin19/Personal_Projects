module rob #( parameter DATA_WIDTH = 12,             // holds flag bit, physical reg idx bits, r reg inex bits
              parameter DEPTH = 16,
              parameter PS_WIDTH = 6 )
(
    input   logic                           clk,
    input   logic                           rst,

    // From rename_dispatch, add new ROB element
    input   logic                           enqueue,
    input   logic   [DATA_WIDTH-1:0]        data_in,
    // From CDB, mark item at rob_idx ready to commit
    input   logic   [$clog2(DEPTH)-1:0]     rob_idx_in,
    input   logic                           ready_to_commit,

    // To RRF, send data to retire instruction
    output  logic   [DATA_WIDTH-1:0]        data_out,
    output  logic                           data_out_valid, 
    output  logic   [$clog2(DEPTH)-1:0]     rob_idx_out,

    output  logic                           full,
    output  logic                           empty_reg,
    output  logic   [$clog2(DEPTH)-1:0]     rvfi_rob_idx_out,
    output  logic   [$clog2(DEPTH)-1:0]     head,

    input   logic                           jump_commit,
    // output  logic   [PS_WIDTH - 1:0]        rob_pds[DEPTH],
    output  int                             rob_pd_count
);

            logic   [$clog2(DEPTH) - 1:0]   tail, head_next, tail_next;
            logic                           head_parity, tail_parity, head_parity_next, tail_parity_next;
            int                             rob_size, rob_size_next;

            logic                           full_reg, empty;

            logic   [DATA_WIDTH - 1:0]      queue[DEPTH - 1:0];
            logic   [DATA_WIDTH - 1:0]      queue_next[DEPTH - 1:0];

            logic                           dequeue;

            int                             count;
            logic                           queue_end;

            int unsigned                    num_clock_cycles;
            int unsigned                    total_cur_sizes;
            int unsigned                    cur_rob_size;

            int unsigned                    rob_full_hk;


assign full = ( head_parity_next != tail_parity_next ) && ( head_next == tail_next );
assign empty = ( head_parity_next == tail_parity_next ) && ( head_next == tail_next );

always_ff @( posedge clk ) begin
    if ( rst || jump_commit ) begin
        head_parity <= '0;
        tail_parity <= '0;
        head <= '0;
        tail <= '0;
        full_reg <= '0;
        empty_reg <= '1;
        rob_size <= '0;
        for ( int i = 0; i < DEPTH; i++ ) begin
            queue[i] <= '0;
        end
    end 
    else begin
        head <= head_next;
        tail <= tail_next;
        head_parity <= head_parity_next;
        tail_parity <= tail_parity_next;
        full_reg <= full;
        empty_reg <= empty;
        queue <= queue_next;
        rob_size <= rob_size_next;
    end

    if ( full_reg ) begin
        rob_full_hk <= rob_full_hk + 1;
    end
    if ( enqueue && !full_reg ) begin
        if ( cur_rob_size != DEPTH ) begin
            cur_rob_size <= cur_rob_size + 1;
        end
    end
    if ( dequeue && !empty_reg ) begin
        if ( cur_rob_size > 0 ) begin
            cur_rob_size <= cur_rob_size - 1;
        end
    end
    total_cur_sizes <= cur_rob_size + total_cur_sizes;
    num_clock_cycles <= num_clock_cycles + 1;
end
    
always_comb begin
    data_out = 'x;
    rob_idx_out = 'x;
    data_out_valid = '0;
    rvfi_rob_idx_out = '0;
    rob_pd_count = '0;
    count = '0;

    if ( rst ) begin
        head_parity_next = '0;
        tail_parity_next = '0;
        tail_next = '0;
        head_next = '0;
        rob_size_next = '0;

        for ( int i = 0; i < DEPTH; i++ ) begin
            queue_next[i] = '0;
        end
        dequeue = '0;
    end
    else begin
        queue_next = queue;
        tail_next = tail;
        head_next = head;
        tail_parity_next = tail_parity;
        head_parity_next = head_parity;
        rob_size_next = rob_size;
        if ( queue[head][DATA_WIDTH - 1] == 1'b1 ) begin
            dequeue = 1'b1;
        end 
        else begin
            dequeue = '0;
        end
        if ( enqueue && !full_reg ) begin
            tail_next = tail + 1'b1;
            if (data_in[DATA_WIDTH - 1 - PS_WIDTH:0] != '0) begin
                rob_size_next = rob_size_next + 1;
            end
            queue_next[tail] = data_in;
            if ( integer'( tail_next ) == DEPTH - 1 ) begin
                tail_parity_next = !tail_parity_next;
            end
            rob_idx_out = tail;
        end 
        if ( dequeue && !empty_reg ) begin
            head_next = head + 1'b1;
            data_out = queue[head];
            rvfi_rob_idx_out = head;
            if (data_out[DATA_WIDTH - 1 - PS_WIDTH:0] != '0) begin
                rob_size_next = rob_size_next - 1;
            end
            data_out_valid = '1;
            if ( integer'( head_next ) == DEPTH - 1 ) begin
                head_parity_next = !head_parity_next;
            end
        end
        if ( ready_to_commit ) begin
            if ( head < tail ) begin
                if ( head <= rob_idx_in && rob_idx_in < tail ) begin
                    queue_next[rob_idx_in][DATA_WIDTH - 1] = 1'b1;
                end
            end 
            else begin
                if ( rob_idx_in >= head || rob_idx_in < tail ) begin
                    queue_next[rob_idx_in][DATA_WIDTH - 1] = 1'b1;
                end
            end
        end
    end

    // head_flush = head_next;
    // tail_flush = tail_next;
    // head_parity_flush = head_parity_next;
    // queue_end = '0;

    // On jump commit, store all in use pds and send them to free list
    if ( jump_commit ) begin
        // for ( int i = 0; i < DEPTH; i++ ) begin
        //     if ( head_flush == tail_flush && head_parity_flush == tail_parity_next ) begin
        //         queue_end = '1;
        //     end
        //     if ( !queue_end && ( queue[head_flush][DATA_WIDTH - 1 - PS_WIDTH:0] != '0 ) ) begin
        //         count = count + 1;
        //     end
        //     head_flush = head_flush + 1'b1;
        //     if ( integer'( head_flush ) == DEPTH - 1 ) begin
        //         head_parity_flush = !head_parity_flush;
        //     end
        // end
        rob_pd_count = rob_size;
        if (data_out[DATA_WIDTH - 1 - PS_WIDTH:0] != '0) begin
            rob_pd_count = rob_pd_count -1;
        end
        // if (data_in[DATA_WIDTH - 1 - PS_WIDTH:0] != '0 && enqueue) begin
        //     rob_pd_count = rob_pd_count + 1;
        // end
        // rob_pd_count = rob_size;

        // Set queue empty
        head_next = '0;
        tail_next = '0;
        head_parity_next = '0;
        tail_parity_next = '0;
        rob_size_next = '0;
    end

end 

endmodule : rob



