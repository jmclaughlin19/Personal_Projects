module freelist #( parameter DATA_WIDTH = 6,             // holds an instruction, pc, and pc_next 
                   parameter DEPTH = 64,
                   parameter ROB_DEPTH = 16 )
(
    // See CPU for port information
    input   logic                           clk,
    input   logic                           rst,
    input   logic                           enqueue,
    input   logic                           dequeue,
    input   logic   [DATA_WIDTH-1:0]        data_in,

    output  logic   [DATA_WIDTH-1:0]        data_out,
    // output  logic                           data_out_valid,
    output  logic                           full,
    output  logic                           empty_reg,

    input   logic                           jump_commit,
    // input   logic   [DATA_WIDTH - 1:0]      rob_pds[ROB_DEPTH],
    input   int                             rob_pd_count
);

            localparam int FREE_LIST_DEPTH_WIDTH = $clog2( DEPTH );
            // tail_parity_next and head_partiy_next are used to combinationall know when the queue is full or empty so it isn't delayed by a cycle
            logic   [FREE_LIST_DEPTH_WIDTH - 1:0]   head, tail, head_next, tail_next;
            logic                           head_parity, tail_parity, head_partiy_next, tail_parity_next;
            logic   [FREE_LIST_DEPTH_WIDTH - 1:0]                  free_list_size, free_list_size_next;

            logic                           full_reg, empty;

            logic   [DATA_WIDTH - 1:0]      queue[DEPTH - 1:0];
            logic   [DATA_WIDTH - 1:0]      queue_next[DEPTH - 1:0];


assign full = ( head_partiy_next != tail_parity_next ) && ( head_next == tail_next );
assign empty = ( head_partiy_next == tail_parity_next ) && ( head_next == tail_next );

always_ff @( posedge clk ) begin
    if ( rst ) begin
        head_parity <= '0;
        tail_parity <= '1;
        head <= unsigned'(DATA_WIDTH'( 1 << DATA_WIDTH - 1 ));
        tail <= DATA_WIDTH'( 1'b1 ); 
        full_reg <= '1;
        empty_reg <= '0;
        free_list_size <= unsigned'(DATA_WIDTH'( 1 << ( DATA_WIDTH - 1 ) ));
        for ( int i = 0; i < DEPTH; i++ ) begin
            queue[i] <= unsigned'( DATA_WIDTH'( ( i % ( 1 << DATA_WIDTH ) ) ) );
        end
    end 
    else begin
        head <= head_next;
        tail <= tail_next;
        head_parity <= head_partiy_next;
        tail_parity <= tail_parity_next;
        full_reg <= full;
        empty_reg <= empty;
        free_list_size <= free_list_size_next;
        queue <= queue_next;
    end
end
    
always_comb begin
    data_out = 'x;
    // data_out_valid = 1'b0;
    if ( rst ) begin
        head_partiy_next = '0;
        tail_parity_next = '0;
        tail_next = '0;
        head_next = '0;
        for ( int i = 0; i < DEPTH; i++ ) begin
            queue_next[i] = '0;
        end
        free_list_size_next = unsigned'(DATA_WIDTH'( 1 << ( DATA_WIDTH - 1 ) ));
    end
    else begin
        queue_next = queue;
        tail_next = tail;
        head_next = head;
        tail_parity_next = tail_parity;
        head_partiy_next = head_parity;
        free_list_size_next = free_list_size;
    end


    if (jump_commit) begin
        // for (int i = 0; i < ROB_DEPTH; i++) begin
        //     if (i >= rob_pd_count) begin
        //         break;
        //     end
        //     free_list_size_next = free_list_size_next + 1'b1;
        //     head_next = head_next - 1'b1;

        //     if (head_next == 0) begin
        //         head_next = FREE_LIST_DEPTH_WIDTH'(unsigned'(DEPTH - 1));
        //         head_partiy_next = !head_partiy_next;
        //     end
        
        // end
        if ( rob_pd_count >= int'(head_next)) begin
            head_next = head_next - FREE_LIST_DEPTH_WIDTH'(unsigned'(rob_pd_count)) - 1'b1;
            head_partiy_next = !head_partiy_next;
        end
        else begin
            head_next = head_next - FREE_LIST_DEPTH_WIDTH'(unsigned'(rob_pd_count));
        end

    end

    
    if ( !rst ) begin
        if ( enqueue && !full_reg ) begin
            queue_next[tail_next] = data_in;
            tail_next = tail_next + 1'b1;
            free_list_size_next = free_list_size_next + 1'b1;
            if ( tail_next == '0 ) begin
                tail_next = tail_next + 1'b1;
            end
            if ( integer'( tail_next ) == DEPTH - 1 ) begin
                tail_parity_next = !tail_parity_next;
            end
        end 
        if ( dequeue && !empty_reg ) begin
            data_out = queue[head_next];
            head_next = head_next + 1'b1;
            free_list_size_next = free_list_size_next - 1'b1;
            if ( head_next == '0 ) begin
                head_next = head_next + 1'b1;
            end
            // data_out_valid = 1'b1;
            if ( integer'( head_next ) == DEPTH - 1 ) begin
                head_partiy_next = !head_partiy_next;
            end
        end
    end
end 

endmodule : freelist



