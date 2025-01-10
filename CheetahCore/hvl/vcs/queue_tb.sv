import "DPI-C" function string getenv(input string env_name);

module queue_tb;

    timeunit 1ps;
    timeprecision 1ps;

    int clock_half_period_ps = getenv("ECE411_CLOCK_PERIOD_PS").atoi() / 2;

    bit clk;
    always #(clock_half_period_ps) clk = ~clk;

    bit rst;

    // int timeout = 10000000; // in cycles, change according to your needs
    int timeout = 100000000;

    mon_itf #(.CHANNELS(8)) mon_itf(.*);
    monitor #(.CHANNELS(8)) monitor(.itf(mon_itf));


    logic                   enqueue;
    logic                   dequeue;
    logic [96-1:0]          data_in;
    logic [96-1:0]          data_out;
    logic                   full;
    logic                   empty;
    logic                   data_out_valid;

    int                   counter;

    // freelist #( .DATA_WIDTH(6), .DEPTH(64) )  queue(
    queue queue (
        .clk            ( clk ),
        .rst            ( rst ), 
        .enqueue        ( enqueue ),
        .dequeue        ( dequeue ),
        .data_in        ( data_in ),
        .data_out       ( data_out ),
        .full           ( full ),
        .empty_reg      ( empty ),
        .data_out_valid ( data_out_valid )
    );


    `include "rvfi_reference.svh"

    task wait_cycles( int num_cycles );
    begin
        repeat ( num_cycles ) @( posedge clk );
    end
    endtask

    task read_from_empty_queue();
    begin
        enqueue <= 1'b0;
        dequeue <= 1'b1;
        data_in <= 'x;
    end
    endtask

    task test_queue_full();
    begin
        counter <= 0;
        for (int i = 0; i < 16; i++) begin
            counter <= counter + 1;
            enqueue <= 1'b1;
            dequeue <= '0;
            data_in <= 96'hBBBBBBBBBBBBBBBBBBBBBBBB;
            wait_cycles(1);
            enqueue <= 1'b0;
            wait_cycles(3);
        end

        if (full != 1'b1) begin
                $display("Error: queue not displaying full correctly at time %t", $time);
        end
        
    end
    endtask

    task test_queue_full_signal_timing();
    begin
        counter <= 0;
        for (int i = 0; i < 16; i++) begin
            counter <= counter + 1;
            enqueue <= 1'b1;
            dequeue <= '0;
            data_in <= 96'hBBBBBBBBBBBBBBBBBBBBBBBB;
            wait_cycles(1);
        end
        if (full != 1'b1) begin
                $display("Error: queue not displaying full correctly at time %t", $time);
        end
    end
    endtask

    task simultaneous_enq_deq();
    begin
        enqueue <= 1'b1;
        dequeue <= '0;
        data_in <= 96'hAAAAAAAAAAAAAAAAAAAAAAAA;
        wait_cycles(1);
        enqueue <= 1'b0;
        wait_cycles(3);

        enqueue <= 1'b1;
        dequeue <= '0;
        data_in <= 96'hBBBBBBBBBBBBBBBBBBBBBBBB;
        wait_cycles(1);
        enqueue <= 1'b0;
        wait_cycles(3);
        
        enqueue <= 1'b1;
        dequeue <= 1'b1;
        data_in <= 96'hCCCCCCCCCCCCCCCCCCCCCCCC;
        wait_cycles(1);
        enqueue <= 1'b0;
        dequeue <= 1'b0;
        wait_cycles(3);

        dequeue <= 1'b1;
        enqueue <= '0;
        data_in <= 'x;
        wait_cycles(1);
        dequeue <= 1'b0;
        wait_cycles(3);

        dequeue <= 1'b1;
        enqueue <= '0;
        data_in <= 'x;
        wait_cycles(1);
        dequeue <= 1'b0;
        wait_cycles(3);

    end
    endtask

    task consecutive_enq_without_deq_same_data();
    begin
        for(int i=0; i<6; i++) begin
            enqueue <= 1'b1;
            dequeue <= '0;
            data_in <= 96'hBBBBBBBBBBBBBBBBBBBBBBBB;
            wait_cycles(1);
            enqueue <= 1'b0;
            wait_cycles(3);
        end
    end
    endtask

    task consecutive_deq_without_enq_same_data();
    begin
        for(int i=0; i<6; i++) begin
            enqueue <= '0;
            dequeue <= 1'b1;
            data_in <= 'x;
            wait_cycles(1);
            dequeue <= 1'b0;
            wait_cycles(3);
        end
    end
    endtask

    task consecutive_enq_without_deq_diff_data();
    begin
        enqueue <= 1'b1;
        dequeue <= '0;
        data_in <= 96'hAAAAAAAAAAAAAAAAAAAAAAAA;
        wait_cycles(1);
        enqueue <= 1'b0;
        wait_cycles(3);

        enqueue <= 1'b1;
        dequeue <= '0;
        data_in <= 96'hBBBBBBBBBBBBBBBBBBBBBBBB;
        wait_cycles(1);
        enqueue <= 1'b0;
        wait_cycles(3);

        enqueue <= 1'b1;
        dequeue <= '0;
        data_in <= 96'hCCCCCCCCCCCCCCCCCCCCCCCC;
        wait_cycles(1);
        enqueue <= 1'b0;
        wait_cycles(3);

        enqueue <= 1'b1;
        dequeue <= '0;
        data_in <= 96'hDDDDDDDDDDDDDDDDDDDDDDDD;
        wait_cycles(1);
        enqueue <= 1'b0;
        wait_cycles(3);
    end
    endtask

    task consecutive_deq_without_enq_diff_data();
    begin
        dequeue <= 1'b1;
        enqueue <= '0;
        data_in <= 'x;
        wait_cycles(1);
        dequeue <= 1'b0;
        wait_cycles(3);

        dequeue <= 1'b1;
        enqueue <= '0;
        data_in <= 'x;
        wait_cycles(1);
        dequeue <= 1'b0;
        wait_cycles(3);

        dequeue <= 1'b1;
        enqueue <= '0;
        data_in <= 'x;
        wait_cycles(1);
        dequeue <= 1'b0;
        wait_cycles(3);

        dequeue <= 1'b1;
        enqueue <= '0;
        data_in <= 'x;
        wait_cycles(1);
        dequeue <= 1'b0;
        wait_cycles(3);
    end
    endtask

    // expected behavior is queue full again
    task queue_full_deq_then_enq();
    begin
        for(int i=0; i<15; i++) begin
            enqueue <= 1'b1;
            dequeue <= '0;
            data_in <= 96'hBBBBBBBBBBBBBBBBBBBBBBBB;
            wait_cycles(3);
        end

        wait_cycles(2);

        dequeue <= 1'b1;
        enqueue <= 1'b0;
        wait_cycles(1);

        enqueue <= 1'b1;
        dequeue <= 1'b0;
        data_in <= 96'hCCCCCCCCCCCCCCCCCCCCCCCC;
        wait_cycles(3);
    end
    endtask

    // expected behavior is queue full again
    task queue_test_free_list();
    begin
        // enqueue <= '1;
        // data_in <= 5'b11111;
        // wait_cycles(1);
        // enqueue <= 1'b0;
        // wait_cycles(3);
        
    end
    endtask


    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, "+all");

        rst = 1'b1;
        enqueue = '0;
        dequeue = '0;
        data_in = 'x;
        repeat (2) @(posedge clk);
        rst <= 1'b0;

        // queue_test_free_list();
        // read_from_empty_queue();

        test_queue_full();

        // test_queue_full_signal_timing();

        // simultaneous_enq_deq();

        // consecutive_enq_without_deq_same_data();
        // consecutive_deq_without_enq_same_data();

        // consecutive_enq_without_deq_diff_data();
        // consecutive_deq_without_enq_diff_data();

        // queue_full_deq_then_enq();

        wait_cycles( 40 );
        $finish;
    end

    always @(posedge clk) begin
        if (timeout == 0) begin
            $error("TB Error: Timed out");
            $finish;
        end
        timeout <= timeout - 1;
    end

endmodule
