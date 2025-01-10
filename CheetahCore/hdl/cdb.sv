module cdb
import rv32i_types::*;
                  #( parameter DATA_WIDTH = 6,
                     parameter ROB_DEPTH = 16 )
(   
    input   logic                               clk,
    input   logic                               rst,

    // From execute, marks if CDB data is valid and should be broadcast
    input   logic                               valid_to_broadcast,

    // To regfile, update physical reg value
    // These signals should be raised no matter what, so no logic needed
    output  logic                               regf_we_cdb,

    // To reservation stations, trigger wakeup with pd_cdb
    output  logic                               wakeup,

    // To RAT, if rd still maps to pd, update mapping to valid 
    output  logic                               update_rat,

    // To ROB, write ready_to_commit
    output  logic                               ready_to_commit,
    
    input   logic                               regf_we_reg,

    input   logic                               jump_reg,
    output  logic                               jump_commit,
    input   logic   [31:0]                      jump_pc_next_reg,
    output  logic   [31:0]                      jump_pc_next_commit
);

    /*
        1) Write to regfile to update value
        2) Wakeup (check all rs entries, if ready = 0 and ps1 or ps2 match broadcast pd, set ready = 1)
        3) Update RAT, if rd still maps to pd, set mapping to valid
        4) Update ROB at rob_idx to be ready to commit
    */

    always_ff @( posedge clk ) begin
        if ( rst ) begin
            jump_commit <= '0;
            jump_pc_next_commit <= '0;
        end
        else begin
            jump_commit <= jump_reg;
            jump_pc_next_commit <= jump_pc_next_reg;
        end
    end

    always_comb begin
        if ( rst || jump_commit ) begin
            regf_we_cdb = '0;
            wakeup = '0;
            update_rat = '0;
            ready_to_commit = '0;
        end
        else begin
            // If the broadcast is valid, send data out
            if ( valid_to_broadcast ) begin
                regf_we_cdb = regf_we_reg;
                wakeup = regf_we_reg;
                update_rat = regf_we_reg;
                ready_to_commit = '1;
            end
            else begin
                regf_we_cdb = '0;
                wakeup = '0;
                update_rat = '0;
                ready_to_commit = '0;
            end
        end
    end      

endmodule: cdb 
