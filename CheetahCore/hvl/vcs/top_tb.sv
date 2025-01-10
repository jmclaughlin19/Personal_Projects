module top_tb;

    timeunit 1ps;
    timeprecision 1ps;

    int clock_half_period_ps;
    longint timeout;
    initial begin
        $value$plusargs("CLOCK_PERIOD_PS_ECE411=%d", clock_half_period_ps);
        clock_half_period_ps = clock_half_period_ps / 2;
        $value$plusargs("TIMEOUT_ECE411=%d", timeout);
    end

    bit clk;
    always #(clock_half_period_ps) clk = ~clk;

    bit rst;

    mem_itf_banked mem_itf(.*);
    dram_w_burst_frfcfs_controller mem(.itf(mem_itf));

    mon_itf #(.CHANNELS(8)) mon_itf(.*);
    monitor #(.CHANNELS(8)) monitor(.itf(mon_itf));

    cpu dut(
        .clk                          ( clk ),
        .rst                          ( rst ),
    
        .bmem_addr                    ( mem_itf.addr  ),
        .bmem_read                    ( mem_itf.read  ),
        .bmem_write                   ( mem_itf.write ),
        .bmem_wdata                   ( mem_itf.wdata ),
        .bmem_ready                   ( mem_itf.ready ),
        .bmem_raddr                   ( mem_itf.raddr ),
        .bmem_rdata                   ( mem_itf.rdata ),
        .bmem_rvalid                  ( mem_itf.rvalid )
    );

    `include "rvfi_reference.svh"

    initial begin
        $fsdbDumpfile("dump.fsdb");
        if ($test$plusargs("NO_DUMP_ALL_ECE411")) begin
            $fsdbDumpvars(0, dut, "+all");
            $fsdbDumpoff();
        end else begin
            $fsdbDumpvars(0, "+all");
        end
        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst <= 1'b0;
    end

    real branch_percent;
    real imm_percent;
    real reg_percent;
    real load_percent;
    real store_percent;
    real jump_percent;

    real branch_taken_percent;
    real branch_not_taken_percent;
    real branch_predictor_accuracy;

    real icache_hit_percent;
    real icache_miss_percent;
    real dcache_hit_percent;
    real dcache_miss_percent;

    always @(posedge clk) begin
        for (int unsigned i = 0; i < 8; ++i) begin
            if (mon_itf.halt[i]) begin
                branch_percent = ( dut.rrf_inst.branch_committed_hk * 100.0 ) / dut.rrf_inst.total_committed_hk;
                imm_percent    = ( dut.rrf_inst.imm_committed_hk * 100.0 ) / dut.rrf_inst.total_committed_hk;
                reg_percent    = ( dut.rrf_inst.reg_committed_hk * 100.0 ) / dut.rrf_inst.total_committed_hk;
                load_percent   = ( dut.rrf_inst.load_committed_hk * 100.0 ) / dut.rrf_inst.total_committed_hk;
                store_percent  = ( dut.rrf_inst.store_committed_hk * 100.0 ) / dut.rrf_inst.total_committed_hk;
                jump_percent   = ( dut.rrf_inst.jump_committed_hk * 100.0 ) / dut.rrf_inst.total_committed_hk;

                branch_taken_percent = ( dut.execute_inst.branch_taken_hk * 100.0 ) / dut.rrf_inst.branch_committed_hk;
                branch_not_taken_percent = ( dut.execute_inst.branch_not_taken_hk * 100.0 ) / dut.rrf_inst.branch_committed_hk;
                // For now, will change when we implement a real branch predictor
                branch_predictor_accuracy = branch_not_taken_percent;
                
                // Divide by cache hits - cache misses + cache misses = cache hits, since hits are counted on misses now
                icache_hit_percent = ( ( dut.icache_inst.icache_hit_hk - dut.icache_inst.icache_miss_hk ) * 100.0 ) / ( dut.icache_inst.icache_hit_hk );
                icache_miss_percent = ( dut.icache_inst.icache_miss_hk * 100.0 ) / ( dut.icache_inst.icache_hit_hk );
                dcache_hit_percent = ( ( dut.dcache_inst.dcache_hit_hk - dut.dcache_inst.dcache_miss_hk ) * 100.0 ) / ( dut.dcache_inst.dcache_hit_hk );
                dcache_miss_percent = ( dut.dcache_inst.dcache_miss_hk * 100.0 ) / ( dut.dcache_inst.dcache_hit_hk  );

                $display( "********** PERFORMANCE HOOKS **********" );
                $display( "TOTAL CYCLES: %0d", dut.rob_inst.num_clock_cycles );

                $display( "Instruction Distribution Information:");
                $display( "Total Instructions Committed: %0d", dut.rrf_inst.total_committed_hk );
                $display( "Branches Committed:         %0d (%0.2f%%)", dut.rrf_inst.branch_committed_hk, branch_percent );          
                $display( "Imm Instructions Committed: %0d (%0.2f%%)", dut.rrf_inst.imm_committed_hk, imm_percent );
                $display( "Reg Instructions Committed: %0d (%0.2f%%)", dut.rrf_inst.reg_committed_hk, reg_percent );
                $display( "Loads Committed:            %0d (%0.2f%%)", dut.rrf_inst.load_committed_hk, load_percent );
                $display( "Stores Committed:           %0d (%0.2f%%)", dut.rrf_inst.store_committed_hk, store_percent );
                $display( "Jumps Committed:            %0d (%0.2f%%)", dut.rrf_inst.jump_committed_hk, jump_percent );
                $display( "" );

                $display( "Branch Predictor Information:" );
                $display( "Branches Taken:             %0d (%0.2f%%)", dut.execute_inst.branch_taken_hk, branch_taken_percent );
                $display( "Branches Not Taken:         %0d (%0.2f%%)", dut.execute_inst.branch_not_taken_hk, branch_not_taken_percent );
                $display( "BRANCH PREDICTOR ACCURACY: (%0.2f%%)", ((dut.execute_inst.branch_in_execute - dut.execute_inst.branch_wrong_hk) * 100.0) / (dut.execute_inst.branch_in_execute) );
                $display( "Branch :():                 %0d", dut.execute_inst.branch_wrong_hk);
                $display( "Branch :)):                 %0d", dut.execute_inst.branch_in_execute - dut.execute_inst.branch_wrong_hk);

                $display( "" );

                $display( "Cache Information" );
                $display( "ICache Hits:                %0d (%0.2f%%)",  dut.icache_inst.icache_hit_hk - dut.icache_inst.icache_miss_hk, icache_hit_percent );
                $display( "ICache Misses:              %0d (%0.2f%%)",  dut.icache_inst.icache_miss_hk, icache_miss_percent );
                $display( "ICache Miss Cycles:         %0d",            dut.icache_inst.miss_wait_cycles);
                $display( "DCache Hits:                %0d (%0.2f%%)",  dut.dcache_inst.dcache_hit_hk - dut.dcache_inst.dcache_miss_hk, dcache_hit_percent );
                $display( "DCache Misses:              %0d (%0.2f%%)",  dut.dcache_inst.dcache_miss_hk, dcache_miss_percent );
                $display( "DCache Miss Cycles:         %0d",            dut.dcache_inst.miss_wait_cycles);
                $display( "" );

                $display( "Reservation Station Information:" );
                $display( "ALU RS was full for         %0d cycles", dut.alu_rs_inst.alu_rs_full_hk );
                $display( "MUL RS was full for         %0d cycles", dut.reservation_stations_inst.mul_rs_full_hk );
                $display( "DIV RS was full for         %0d cycles", dut.reservation_stations_inst.div_rs_full_hk );
                $display( "MEM RS was full for         %0d cycles", dut.mem_rs_inst.mem_rs_full_hk );
                $display( "BR RS was full for          %0d cycles", dut.reservation_stations_inst.br_rs_full_hk );
                // $display( "Multiple valid outputs for  %0d cycles", dut.reservation_stations_inst.hk_multiple_valid_inst_count );
                $display( "" );

                $display( "ROB Information:" );
                $display( "ROB was full for            %0d cycles", dut.rob_inst.rob_full_hk );
                $display( "ROB's average size is       %0d", dut.rob_inst.total_cur_sizes / dut.rob_inst.num_clock_cycles );


                $display( "LOAD INFORMATION: ");
                $display( "Store load case occured:            %0d", dut.execute_inst.store_f_count );



                $finish;
            end
        end
        if (timeout == 0) begin
        $error("TB Error: Timed out");
            $fatal;
        end
        if (mon_itf.error != 0) begin
            repeat (5) @(posedge clk);
            $fatal;
        end
        if (mem_itf.error != 0) begin
            repeat (5) @(posedge clk);
            $fatal;
        end
        timeout <= timeout - 1;
    end

endmodule
