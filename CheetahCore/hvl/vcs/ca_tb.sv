
import "DPI-C" function string getenv(input string env_name);

module ca_tb;

    timeunit 1ps;
    timeprecision 1ps;

    int clock_half_period_ps = getenv("ECE411_CLOCK_PERIOD_PS").atoi() / 2;

    bit clk;
    always #(clock_half_period_ps) clk = ~clk;

    bit rst;

    int timeout = 1000000;

    mon_itf #(.CHANNELS(8)) mon_itf(.*);
    monitor #(.CHANNELS(8)) monitor(.itf(mon_itf));


    // Inputs from bmem
       logic   [31:0]      bmem_raddr;
       logic   [63:0]      bmem_rdata;
       logic               bmem_rvalid;
       logic   [255:0]     write_data;
       logic               write_enable;   
       logic               read_enable;
       logic   [31:0]      addr;

    // Outputs to cache
      logic   [255:0]     data_out;
      logic   [31:0]      addr_out;

    // Might not need (valid output to cache)
      logic               valid_out;

      logic   [63:0]      bmem_wdata;
      logic               bmem_write;

      logic               bmem_read; 
      logic   [31:0]      bmem_addr;


    // Cache -> cacheline adapter -> bmem
    cacheline_adapter dut (
        .clk            ( clk ),
        .rst            ( rst ),

        // Response, receive from bmem 
        .bmem_raddr     ( bmem_raddr ),
        .bmem_rdata     ( bmem_rdata ),
        .bmem_rvalid    ( bmem_rvalid ),

        // Response, format for cache
        .data_out       ( data_out ),
        .addr_out       ( addr_out ),
        .valid_out      ( valid_out ),

        // Request, receive from cache and send to bmem
        .bmem_wdata     ( bmem_wdata ),
        .bmem_write     ( bmem_write ),
        .bmem_read      ( bmem_read ),
        .bmem_addr      ( bmem_addr ),

        // Request, receive from cache and format for bmem
        .write_enable   ( write_enable ),
        .read_enable    ( read_enable ),

        .write_data     ( write_data ),
        // Input from cache then send as bmem_addr
        .addr           ( addr )
    );

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
            bmem_rdata <= burst[i];
            $display( "Sending burst %d with data %h at time %t.", i, burst[i], $time );
            wait_cycles( 1 );
        end
        bmem_rvalid <= '0;
        bmem_raddr <= 'x;
        bmem_rdata <= 'x;

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

    task wait_for_ca_resp();
    begin
        $display( "     NOTICE: Waiting for cacheline adapter resp to be raised at time %t.", $time );

        while ( !valid_out ) begin
            wait_cycles( 1 );
        end
    end
    endtask

    task single_read_miss( logic [31:0] addr_in, logic [63:0] burst[4] );
    begin
        write_enable <= '0;
        read_enable <= '1;
        addr <= addr_in;
        write_data <= 'x;
        
        wait_cycles( 1 );

        bmem_read_response( addr, burst );
        // Bursts have been sent, check validity

        wait_for_ca_resp();
        $display( "Cacheline has been set to value %h at time %t", data_out, $time );
    end
    endtask 

    logic [63:0] burst[4];

    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, "+all");
        rst = 1'b1;
        bmem_rvalid = '0;
        bmem_raddr = 'x;
        bmem_rdata = 'x;

        read_enable = '0;
        write_enable = '0;
        write_data = 'x;
        addr = '0;

        repeat (2) @(posedge clk);
        rst <= 1'b0; 
        
        $display( "" );
        $display( "******************* STARTING CACHELINE ADAPTER TESTS *******************" );
        $display( "" );

        // For now, force ready to high
        // bmem_ready = '1;
        
        // Create a burst of response data 
        burst[0] = 64'hAAAAAAAAAAAAAAAA;
        burst[1] = 64'hBBBBBBBBBBBBBBBB;
        burst[2] = 64'hCCCCCCCCCCCCCCCC;
        burst[3] = 64'hDDDDDDDDDDDDDDDD;

        single_read_miss( 32'h1ECEB000, burst );

        wait_cycles( 5 );

        $display( "" );
        $display( "******************* CACHELINE ADAPTER TESTS FINISHED *******************" );
        $display( "" );
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

