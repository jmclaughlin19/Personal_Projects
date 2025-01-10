import "DPI-C" function string getenv(input string env_name);

module rob_tb;

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
    logic [11:0]            data_in;
    logic [3:0]             rob_idx_in;
    logic                   ready_to_commit;

    logic [11:0]            data_out;
    logic                   full;
    logic                   empty_reg;
    logic [3:0]             rob_idx_out;



    int                   counter;

    // freelist #( .DATA_WIDTH(6), .DEPTH(64) )  queue(
    // queue queue (
    //     .clk            ( clk ),
    //     .rst            ( rst ), 
    //     .enqueue        ( enqueue ),
    //     .dequeue        ( dequeue ),
    //     .data_in        ( data_in ),
    //     .data_out       ( data_out ),
    //     .full           ( full ),
    //     .empty_reg      ( empty ),
    //     .data_out_valid ( data_out_valid )
    // );

    rob rob (
        .clk                (clk),
        .rst                (rst),
        .enqueue            (enqueue),
        .data_in            (data_in),
        .rob_idx_in          (rob_idx_in),
        .ready_to_commit    (ready_to_commit),

        .data_out           (data_out),
        .full               (full),
        .empty_reg          (empty_reg),
        .rob_idx_out        (rob_idx_out)
    );


    `include "rvfi_reference.svh"

    task wait_cycles( int num_cycles );
    begin
        repeat ( num_cycles ) @( posedge clk );
    end
    endtask




    // Test enqueues 3 piece of data and checks the rob_idx_out for each one and then
    // sets commit signal to high and checks that dequeue is raised on the next cycle 
    // and then data out is the correct values on the following cycle (should be rob_idx 1 here)
    task simple_rob();
    begin
        enqueue <= '1;
        data_in <= 12'b000010111111;
        ready_to_commit <= '0;
        rob_idx_in <= '0;
        if(rob_idx_out != '0) begin
            $display("Error: the rob index does not match expected");
        end else begin
            $display("Success! the rob index matches expected");
        end
        wait_cycles(1);
        enqueue <= '0;
        wait_cycles(1);
        enqueue <= '1;
        data_in <= 12'b000100100011;
        ready_to_commit <= '0;
        rob_idx_in <= '0;
        if(rob_idx_out != 4'b0001) begin
            $display("Error: the rob index does not match expected: %d", rob_idx_out);
        end
        wait_cycles(1);
        enqueue <= '0;
        wait_cycles(1);
        enqueue <= '1;
        data_in <= 12'b010000111100;
        ready_to_commit <= '0;
        rob_idx_in <= '0;
        if(rob_idx_out != 4'b0010) begin
            $display("Error: the rob index does not match expected %d", rob_idx_out);
        end
        wait_cycles(1);
        enqueue <= '0;
        wait_cycles(1);
        ready_to_commit <= '1;
        rob_idx_in <= '0;
        // Check the queue data here and make sure it put a 1 into the upper bits of the right spot here
        wait_cycles(1);
        ready_to_commit <= '0;
        if(data_out != 12'b000010111111) begin
            $display("Error: the data out when you actually committed isn't what's expected");
        end

    end
    endtask

    task fill_rob_no_dequeue();
    begin
        for(int i=0; i<16; i++) begin
            enqueue <= 1'b1;
            data_in <= 12'b000000010001;
            rob_idx_in <= 'x;
            ready_to_commit = '0;
            wait_cycles(1);
            enqueue <= '0;
            data_in <= '0;
            wait_cycles(1);
        end

        ready_to_commit <= 1'b1;
        rob_idx_in <= 4'b1111;
        wait_cycles(1);
        ready_to_commit <= '0;
        rob_idx_in <= 'x;
    end
    endtask

    task fill_rob_no_dequeue_2();
    begin
        for(int i=0; i<16; i++) begin
            enqueue <= 1'b1;
            data_in <= 12'b000000010001;
            rob_idx_in <= 'x;
            ready_to_commit = '0;
            wait_cycles(1);
            enqueue <= '0;
            data_in <= '0;
            wait_cycles(1);
        end

        ready_to_commit <= 1'b1;
        rob_idx_in <= 4'b0100;
        wait_cycles(1);
        ready_to_commit <= '0;
        rob_idx_in <= 'x;
    end
    endtask

    task fill_rob_dequeue();
    begin
        for(int i=0; i<16; i++) begin
            enqueue <= 1'b1;
            data_in <= 12'b000000010001;
            rob_idx_in <= 'x;
            ready_to_commit = '0;
            wait_cycles(1);
            enqueue <= '0;
            data_in <= '0;
            wait_cycles(1);
        end

        ready_to_commit <= 1'b1;
        rob_idx_in <= 4'b0000;
        wait_cycles(1);
        ready_to_commit <= '0;
        rob_idx_in <= 'x;
    end
    endtask


    task mixed_comprehensive();
    begin
        // enqueues 3 items
        for(int i=0; i<3; i++) begin
            enqueue <= 1'b1;
            data_in <= 12'b000000010001;
            rob_idx_in <= 'x;
            ready_to_commit = '0;
            wait_cycles(1);
            enqueue <= '0;
            data_in <= '0;
            wait_cycles(1);
        end

        ready_to_commit <= 1'b1;
        rob_idx_in <= 4'b0000;
        wait_cycles(1);
        ready_to_commit <= '0;
        rob_idx_in <= 'x;

        ready_to_commit <= 1'b1;
        rob_idx_in <= 4'b0001;
        wait_cycles(1);
        ready_to_commit <= '0;
        rob_idx_in <= 'x;

        ready_to_commit <= 1'b1;
        rob_idx_in <= 4'b0010;
        wait_cycles(1);
        ready_to_commit <= '0;
        rob_idx_in <= 'x;


        // should not return data for this one because we only enqueued 3 items
        ready_to_commit <= 1'b1;
        rob_idx_in <= 4'b0011;
        wait_cycles(1);
        ready_to_commit <= '0;
        rob_idx_in <= 'x;

        // enqueue 3 more items
        for(int i=0; i<3; i++) begin
            enqueue <= 1'b1;
            data_in <= 12'b000000001111;
            rob_idx_in <= 'x;
            ready_to_commit = '0;
            wait_cycles(1);
            enqueue <= '0;
            data_in <= '0;
            wait_cycles(1);
        end

        ready_to_commit <= 1'b1;
        rob_idx_in <= 4'b0100;
        wait_cycles(1);
        ready_to_commit <= '0;
        rob_idx_in <= 'x;

        wait_cycles(3);


        ready_to_commit <= 1'b1;
        rob_idx_in <= 4'b0011;
        wait_cycles(1);
        ready_to_commit <= '0;
        rob_idx_in <= 'x;
    end
    endtask


    // logic                   enqueue;
    // logic [11:0]            data_in;
    // logic [3:0]             rob_idx_in;
    // logic                   ready_to_commit;

    // logic [11:0]            data_out;
    // logic                   full;
    // logic                   empty_reg;
    // logic [3:0]             rob_idx_out;
    // logic                   dequeue;


    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, "+all");

        rst = 1'b1;
        enqueue = '0;
        data_in = 'x;
        rob_idx_in = 'x;
        ready_to_commit = '0;
        repeat (2) @(posedge clk);
        rst <= 1'b0;


        // ****************************************************************************************************************

        // simple_rob();

        // fill_rob_no_dequeue();

        // fill_rob_no_dequeue_2();

        // fill_rob_dequeue();

        mixed_comprehensive();

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
