import "DPI-C" function string getenv(input string env_name);

module cpu_tb;

    timeunit 1ps;
    timeprecision 1ps;

    int clock_half_period_ps = getenv("ECE411_CLOCK_PERIOD_PS").atoi() / 2;

    bit clk;
    always #(clock_half_period_ps) clk = ~clk;

    bit rst;

    // int timeout = 10000000; // in cycles, change according to your needs
    int timeout = 1000000;

    // mem_itf_banked bmem_itf(.*);
    // banked_memory banked_memory(.itf(bmem_itf));

    mon_itf #(.CHANNELS(8)) mon_itf(.*);
    monitor #(.CHANNELS(8)) monitor(.itf(mon_itf));

    logic   [31:0]  bmem_addr;
    logic           bmem_read;
    logic           bmem_write;
    logic   [63:0]  bmem_wdata;
    logic           bmem_ready;
    logic   [31:0]  bmem_raddr;
    logic   [63:0]  bmem_rdata;
    logic           bmem_rvalid;

    cpu dut(
        .clk            (clk),
        .rst            (rst),

        .bmem_addr  (bmem_addr  ),
        .bmem_read  (bmem_read  ),
        .bmem_write (bmem_write ),
        .bmem_wdata (bmem_wdata ),
        .bmem_ready (bmem_ready ),
        .bmem_raddr (bmem_raddr ),
        .bmem_rdata (bmem_rdata ),
        .bmem_rvalid(bmem_rvalid)
    );

    // logic                   enqueue;
    // logic                   dequeue;
    // logic [64-1:0]          data_in;
    // logic [64-1:0]          data_out;
    // logic                   full;
    // logic                   empty;

    // queue queue (
    //     .clk            ( clk ),
    //     .rst            ( rst ), 
    //     .enqueue        ( enqueue ),
    //     .dequeue        ( dequeue ),
    //     .data_in        ( data_in ),
    //     .data_out       ( data_out ),
    //     .full           ( full ),
    //     .empty          ( empty )
    // );


    `include "rvfi_reference.svh"

    task wait_cycles( int num_cycles );
    begin
        repeat ( num_cycles ) @( posedge clk );
    end
    endtask

    task wait_for_bmem_read();
    begin
        // Clear response signals
        bmem_raddr <= 'x;
        bmem_rvalid <= '0;
        bmem_rdata <= 'x;

        $display( "     NOTICE: Waiting for bmem_read signal to be raised at time %t.", $time );

        while ( !bmem_read ) begin
            wait_cycles( 1 );
        end
    end
    endtask

    task send_bmem_rdata( logic [63:0] burst[4] );
    begin
        // Send out the four bursts across four cycles
        for ( int i = 0; i < 4; i++ ) begin
            bmem_rdata = burst[i];
            $display( "Sending burst %d with data %h at time %t.", i, bmem_rdata, $time );
            wait_cycles( 1 );
        end
        bmem_rvalid = '0;
        bmem_raddr = 'x;
        bmem_rdata = 'x;

        $display( "     NOTICE: Bursts sent, bmem_response concluded at time %t", $time );
    end
    endtask

    task bmem_read_response( logic [31:0] raddr, logic [63:0] burst[4] );
    begin
        // Wait for the bmem_read signal to be raised
        wait_for_bmem_read();

        wait_cycles( 5 );
        
        // Indicate return addr and rvalid
        bmem_raddr <= raddr;
        bmem_rvalid <= '1;
        send_bmem_rdata( burst );
    end
    endtask

    logic [63:0] burst[4];

    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, "+all");
        rst = 1'b1;
        bmem_rvalid <= '0;
        bmem_raddr <= 'x;
        bmem_rdata <= 'x;
        repeat (2) @(posedge clk);
        rst <= 1'b0; // changed to blocking

        /*          QUEUE TESTS           */
        // For now, force ready to high
        bmem_ready = '1;
        
        // Create a burst of response data 
        burst[0] = 64'hAAAAAAAAAAAAAAAA;
        burst[1] = 64'hBBBBBBBBBBBBBBBB;
        burst[2] = 64'hCCCCCCCCCCCCCCCC;
        burst[3] = 64'hDDDDDDDDDDDDDDDD;

        bmem_read_response( 32'h1ECEB000, burst );

        wait_cycles( 5 );
        $finish;
    end

    always @(posedge clk) begin
        // for (int unsigned i=0; i < 8; ++i) begin
        //     if (mon_itf.halt[i]) begin
        //         $finish;
        //     end
        // end
        if (timeout == 0) begin
            $error("TB Error: Timed out");
            $finish;
        end
        // if (mon_itf.error != 0) begin
        //     repeat (5) @(posedge clk);
        //     $finish;
        // end
        // if (bmem_itf.error != 0) begin
        //     repeat (5) @(posedge clk);
        //     $finish;
        // end
        timeout <= timeout - 1;
        // $display(timeout);
    end

endmodule
