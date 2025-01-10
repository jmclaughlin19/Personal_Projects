import "DPI-C" function string getenv(input string env_name);

module rat_tb;

    timeunit 1ps;
    timeprecision 1ps;

    int clock_half_period_ps = getenv("ECE411_CLOCK_PERIOD_PS").atoi() / 2;

    bit clk;
    always #(clock_half_period_ps) clk = ~clk;

    bit rst;

    int timeout = 1000000;

    mon_itf #(.CHANNELS(8)) mon_itf(.*);
    monitor #(.CHANNELS(8)) monitor(.itf(mon_itf));

    localparam int NUM_REGS = 64;
    localparam int PS_WIDTH = $clog2(NUM_REGS);

    // Signals to/from dispatch and rename stage
    logic   [4:0]               rd;
    logic   [PS_WIDTH - 1:0]    pd;
    logic                       regf_we;

    logic   [4:0]               rs1;
    logic   [PS_WIDTH - 1: 0]   ps1;
    logic                       ps1_valid;

    logic   [4:0]               rs2;
    logic   [PS_WIDTH - 1: 0]   ps2;
    logic                       ps2_valid;

    // Signals from CDB
    logic   [4:0]               rd_cdb;
    logic   [PS_WIDTH - 1:0]    pd_cdb;
    logic                       regf_we_cdb;   

    logic                       valid_out;

    // Default num_regs = 64
    rat rat (
        .clk            ( clk ),
        .rst            ( rst ),
        // Dispatch and rename stage connections
        .rd             ( rd ),
        .pd             ( pd ),
        .regf_we        ( regf_we ),
        .rs1            ( rs1 ),
        .ps1            ( ps1 ),
        .ps1_valid      ( ps1_valid ),
        .rs2            ( rs2 ),
        .ps2            ( ps2 ),
        .ps2_valid      ( ps2_valid ),
        // CDB connections
        .rd_cdb         ( rd_cdb ),
        .pd_cdb         ( pd_cdb ),
        .regf_we_cdb    ( regf_we_cdb ),

        .valid_out      ( valid_out )
    );

    `include "rvfi_reference.svh"

    task wait_cycles( int num_cycles );
    begin
        repeat ( num_cycles ) @( posedge clk );
    end
    endtask

    task check_rat_output_rs1( logic [PS_WIDTH - 1:0] expected_ps1, output int error_count );
    begin
        if ( ( ps1 != expected_ps1 || !ps1_valid ) && valid_out ) begin
            $display( "     ERROR: ps1: %h, expected ps1: %h, valid: %h", ps1, expected_ps1, ps1_valid );
            error_count = error_count + 1;
        end
    end
    endtask

    task check_error( int error_count );
    begin
        if ( error_count == '0 ) begin
            $display( "SUCCESS" );
        end
        else begin
            $display( "FAILURE: Error Count: %d", error_count );
        end
    end
    endtask

    task test_rat_init();
    begin
        int error_count;
        $display( "BEGINNING RAT INIT TEST" );
        // Loop over all architectural regs, check that they are mapped after init
        for ( int i = 0; i < 32; i++ ) begin
            rs1 = i[4:0];
            check_rat_output_rs1( i[PS_WIDTH - 1:0], error_count );
            wait_cycles( 1 );
        end

        check_error( error_count );
        $display( "RAT INIT TEST COMPLETE" );
    end
    endtask

    // WAVEFORM NOTE: Even though ps1/2 valids are low, they are high for the brief cycle where data comparisons are made
    task test_update();
    begin
        int error_count;
        int j;
        $display( "BEGINNING RAT UPDATE TEST" );
        for ( int i = 0; i < 32; i++ ) begin
            rd = i[4:0];
            pd = i[4:0] + 6'b100000;
            regf_we = '1;

            if ( i != '0 ) begin
                j = i - 1;
                rs1 = j[4:0];
                check_rat_output_rs1( j[PS_WIDTH - 1:0] + 6'b100000, error_count );
            end
            wait_cycles( 1 );
        end

        check_error( error_count );
        $display( "RAT UPDATE TEST COMPLETE" );
    end
    endtask

    task test_repeated_update();
    begin
        int error_count;
        $display( "BEGINNING RAT REPEATED UPDATE TEST" );

        for ( int i = 0; i < 4; i++ ) begin
            rs1 = '0;

            // RAT output should be consistent
            check_rat_output_rs1( '0, error_count );

            wait_cycles( 1 );
        end

        rd = '0;
        pd = 6'b100000;
        regf_we = '1;

        wait_cycles( 1 );

        // Ensure that after reads, RAT can still be updated
        check_rat_output_rs1( 6'b100000, error_count );
        
        check_error( error_count );
        $display( "RAT REPEATED UPDATE TEST COMPLETE" );
    end
    endtask

    task reset();
    begin
        rst = 1'b1;

        rd = 'x;
        pd = 'x;
        regf_we = '0;

        rs1 = '0;
        rs2 = '0;

        rd_cdb = 'x;
        pd_cdb = 'x;
        regf_we_cdb = '0; 

        repeat (2) @(posedge clk);
        rst <= 1'b0;
    end
    endtask

    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, "+all");
         
        // wait_cycles( 1 );
        reset();

        $display( "" );
        $display( "******************* STARTING RAT TESTS *******************" );
        $display( "" );

        test_rat_init();
        reset();

        test_update();
        reset();

        test_repeated_update();

        $display( "" );
        $display( "******************* RAT TESTS FINISHED *******************" );
        $display( "" );

        wait_cycles( 5 );
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