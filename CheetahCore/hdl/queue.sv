module queue 
import rv32i_types::*;
             #( parameter DATA_WIDTH = 96,             // holds an instruction, pc, and pc_next 
                parameter DEPTH = 16 )
(
    input   logic                               clk,
    input   logic                               rst,
            
    input   logic                               enqueue,


    input   logic                               free_list_empty,
    input   logic                               rs_full_alu,
    input   logic                               rs_full_mul,
    input   logic                               rs_full_mem,
    input   logic                               rs_full_div,
    input   logic                               rs_full_br,
    input   logic                               rs_full_ld,
    input   logic                               rob_full,

    input   logic                               jump_commit,

    // input   logic                               dequeue,

    input   logic [DATA_WIDTH-1:0]              data_in,
            
    output  logic [DATA_WIDTH-1:0]              data_out,
    output  logic                               data_out_valid,
    output  logic                               full,
    output  logic                               empty_reg
);
            // tail_parity_next and head_parity_next are used to combinationally know when the queue is full or empty so it isn't delayed by a cycle
            logic   [$clog2(DEPTH) - 1:0]   head, tail, head_next, tail_next;
            logic                           head_parity, tail_parity, head_parity_next, tail_parity_next;

            logic                           full_reg, empty;

            logic   [DATA_WIDTH - 1:0]      queue[DEPTH - 1:0];
            logic   [DATA_WIDTH - 1:0]      queue_next[DEPTH - 1:0];

            logic                           dequeue;
            


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
    end
end
    
always_comb begin
    data_out = 'x;
    data_out_valid = 1'b0;
    if ( rst || jump_commit ) begin
        head_parity_next = '0;
        tail_parity_next = '0;
        tail_next = '0;
        head_next = '0;
        for ( int i = 0; i < DEPTH; i++ ) begin
            queue_next[i] = '0;
        end
        dequeue = '0;
    end
    else begin
        if ( !free_list_empty && !rob_full && !empty_reg ) begin
            if ( queue[head][6:0] == op_b_reg && queue[head][31:25] == 7'b0000001 ) begin
                if ( queue[head][14:12] == 3'b000 || queue[head][14:12] == 3'b001 || queue[head][14:12] == 3'b010 || queue[head][14:12] == 3'b011 ) begin
                    dequeue = !rs_full_mul;
                end
                else if ( queue[head][14:12] == 3'b100 || queue[head][14:12] == 3'b101 || queue[head][14:12] == 3'b110 || queue[head][14:12] == 3'b111 ) begin
                    dequeue = !rs_full_div;
                end
                // Should never get here
                else begin
                    dequeue = '0;
                end
            end
            else if ( queue[head][6:0] == op_b_reg ||
                      queue[head][6:0] == op_b_auipc || 
                      queue[head][6:0] == op_b_lui ||
                      queue[head][6:0] == op_b_imm ) begin
                dequeue = !rs_full_alu;
            end
            else if ( queue[head][6:0] == op_b_store ) begin
                dequeue = !rs_full_mem;
            end
            else if ( queue[head][6:0] == op_b_load ) begin
                dequeue = !rs_full_ld;
            end
            else if ( queue[head][6:0] == op_b_br ||
                      queue[head][6:0] == op_b_jalr ||
                      queue[head][6:0] == op_b_jal ) begin
                dequeue = !rs_full_br;
            end
            else begin
                dequeue = '1;
            end
        end
        else begin
            dequeue = '0;
        end

        queue_next = queue;
        tail_next = tail;
        head_next = head;
        tail_parity_next = tail_parity;
        head_parity_next = head_parity;
        if ( enqueue && !full_reg ) begin
            tail_next = tail + 1'b1;
            queue_next[tail] = data_in;
            if ( integer'( tail_next ) == DEPTH - 1 ) begin
                tail_parity_next = !tail_parity_next;
            end
        end 
        if ( dequeue && !empty_reg ) begin
            head_next = head + 1'b1;
            data_out = queue[head];
            data_out_valid = 1'b1;
            if ( integer'( head_next ) == DEPTH - 1 ) begin
                head_parity_next = !head_parity_next;
            end
        end
        if ( empty_reg ) begin
            data_out_valid = 1'b0;
            data_out = '0;
        end
    end
end 

endmodule : queue


