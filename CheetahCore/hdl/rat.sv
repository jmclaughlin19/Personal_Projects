module rat #( parameter NUM_REGS = 64, 
              parameter PS_WIDTH = $clog2(NUM_REGS) )
(
    input   logic                       clk,
    input   logic                       rst,

    // From/to rename_dispatch, update rd mapping and return rs1 and rs2 mappings
    input   logic   [4:0]               rd,
    input   logic   [PS_WIDTH - 1:0]    pd,
    input   logic                       regf_we,

    input   logic   [4:0]               rs1,
    output  logic   [PS_WIDTH - 1: 0]   ps1,
    output  logic                       ps1_valid,

    input   logic   [4:0]               rs2,
    output  logic   [PS_WIDTH - 1: 0]   ps2,
    output  logic                       ps2_valid,

    // From CDB, update rd -> pd mapping to valid on writeback
    input   logic   [4:0]               rd_cdb,
    input   logic   [PS_WIDTH - 1:0]    pd_cdb,
    input   logic                       regf_we_cdb,

    input   logic   [PS_WIDTH - 1:0]    rrf[31:0],
    input   logic                       jump_commit
);

            // RAT = (reg_idx -> {busy bit, ps})
            // 0 = not busy / valid, 1 = busy
            logic   [PS_WIDTH:0]        rat[31:0];
            logic   [PS_WIDTH:0]        rat_next[31:0];

            localparam int RAT_WIDTH = 5;

always_ff @( posedge clk ) begin
    if ( rst ) begin
        for ( int i = 0; i < 32; i++ ) begin
            // Zero-extend 5 bit index to match PS_WIDTH
            // Add in a busy bit of 0 at MSB
            rat[i] <= {{( PS_WIDTH - 4 ){1'b0}}, RAT_WIDTH'(i)};
        end
    end
    else if ( jump_commit ) begin
        for ( int i = 0; i < 32; i++ ) begin
            rat[i] <= {1'b0, rrf[i]};
        end
    end
    else begin
        for ( int i = 0; i < 32; i++ ) begin
            rat[i] <= rat_next[i];
        end
    end
end
    
always_comb begin
    // Restore rat for combinational updates
    rat_next = rat;

    ps1_valid = '0;
    ps2_valid = '0;
    ps1 = 'x;
    ps2 = 'x;

    // if ( rst || jump_commit ) begin        
    //     ps1_valid = '0;
    //     ps2_valid = '0;
    //     ps1 = 'x;
    //     ps2 = 'x;
    // end
    if ( !rst && !jump_commit ) begin
        // If there is a broadcast and the mapping still exits, update busy
        if ( regf_we_cdb && rat[rd_cdb] == {1'b1, pd_cdb} ) begin
            rat_next[rd_cdb] = {1'b0, pd_cdb};
        end

        // If write_enable set and rd != 0, update rat
        if ( regf_we && rd != '0 ) begin
            rat_next[rd] = {1'b1, pd};
        end

        // Return physical memory mappings at all times for rs1 and rs2
        ps1 = rat[rs1][PS_WIDTH - 1:0];
        ps1_valid = !rat[rs1][PS_WIDTH];

        ps2 = rat[rs2][PS_WIDTH - 1:0];
        ps2_valid = !rat[rs2][PS_WIDTH];
    end
end 

endmodule : rat


