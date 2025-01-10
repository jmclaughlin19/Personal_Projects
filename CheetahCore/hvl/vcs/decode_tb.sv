// import "DPI-C" function string getenv(input string env_name);
// import rv32i_types::*;
// module decode_tb;

//     timeunit 1ps;
//     timeprecision 1ps;

//     int clock_half_period_ps = getenv("ECE411_CLOCK_PERIOD_PS").atoi() / 2;

//     bit clk;
//     always #(clock_half_period_ps) clk = ~clk;

//     bit rst;

//     // int timeout = 10000000; // in cycles, change according to your needs
//     int timeout = 100000000;

//     mon_itf #(.CHANNELS(8)) mon_itf(.*);
//     monitor #(.CHANNELS(8)) monitor(.itf(mon_itf));

//     logic   [31:0]      inst;
//     logic   [31:0]      pc;
//     logic   [31:0]      pc_next;
//     id_ex_stage_reg_t   decode_rename_reg;

//     decode decode (
//         .clk                (clk),
//         .rst                (rst),

//         .inst               (inst),
//         .pc                 (pc),
//         .pc_next            (pc_next),

//         .decode_rename_reg  (decode_rename_reg)
//     );


//     `include "rvfi_reference.svh"

//     task wait_cycles( int num_cycles );
//     begin
//         repeat ( num_cycles ) @( posedge clk );
//     end
//     endtask

//     task send_inst ( logic [31:0] inst_in, logic [31:0] pc_in, logic [31:0] pc_next_in );
//     begin
//         inst = inst_in;
//         pc = pc_in;
//         pc_next = pc_next_in;
//         // valid_data = '1;

//         wait_cycles( 1 );

//         // valid_data = '1;
//     end
//     endtask
 
//     task reset();
//     begin
//         rst = 1'b1;
//         inst = 'x;
//         pc = 'x;
//         pc_next = 'x;
//         // valid_data = 1'b0;
        
//         repeat (2) @(posedge clk);
//         rst <= 1'b0;
//     end
//     endtask


//     initial begin
//         $fsdbDumpfile("dump.fsdb");
//         $fsdbDumpvars(0, "+all");

//         reset();

//         // ADD x3, x1, x2
//         send_inst( 32'h002081B3, 32'h00000004, 32'h00000008 );
        
//         wait_cycles( 5 );
//         $finish;
//     end

//     always @(posedge clk) begin
//         if (timeout == 0) begin
//             $error("TB Error: Timed out");
//             $finish;
//         end
//         timeout <= timeout - 1;
//     end

// endmodule
