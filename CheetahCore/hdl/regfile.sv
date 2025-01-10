module regfile
import rv32i_types::*;
                        #( parameter DATA_WIDTH = 6, 
                           parameter NUM_REGS = 64 )
(
    input   logic                           clk,
    input   logic                           rst,
    input   logic                           regf_we,
    input   logic   [31:0]                  pd_v,
    input   logic   [DATA_WIDTH - 1: 0]     ps1_out_alu,
    input   logic   [DATA_WIDTH - 1: 0]     ps2_out_alu,
    input   logic   [DATA_WIDTH - 1: 0]     ps1_out_mem,
    input   logic   [DATA_WIDTH - 1: 0]     ps2_out_mem,
    input   logic   [DATA_WIDTH - 1: 0]     ps1_out_div,
    input   logic   [DATA_WIDTH - 1: 0]     ps2_out_div,
    input   logic   [DATA_WIDTH - 1: 0]     ps1_out_mul,
    input   logic   [DATA_WIDTH - 1: 0]     ps2_out_mul,
    input   logic   [DATA_WIDTH - 1: 0]     ps1_out_br,
    input   logic   [DATA_WIDTH - 1: 0]     ps2_out_br,
    input   logic   [DATA_WIDTH-1:0]        pd_s,
    output  logic   [31:0]                  ps1_v[5], ps2_v[5]
);

            logic   [31:0]                  data [NUM_REGS];
            logic   [DATA_WIDTH - 1: 0]     ps1_s[5], ps2_s[5];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < NUM_REGS; i++) begin
                data[i] <= '0;
            end
        end 
        else begin
            // Allow each functional unit to write to the regfile if necessary
            if ( regf_we && pd_s != '0 ) begin
                data[pd_s] <= pd_v;
            end
        end
    end

    always_comb begin
        ps1_s[alu] = ps1_out_alu;
        ps2_s[alu] = ps2_out_alu;
        ps1_s[mem] = ps1_out_mem;
        ps2_s[mem] = ps2_out_mem;
        ps1_s[div] = ps1_out_div;
        ps2_s[div] = ps2_out_div;
        ps1_s[mul] = ps1_out_mul;
        ps2_s[mul] = ps2_out_mul;
        ps1_s[br] = ps1_out_br;
        ps2_s[br] = ps2_out_br;
        for ( int i = 0; i < 5; i++ ) begin
            if (rst) begin
                ps1_v[i] = 'x;
                ps2_v[i] = 'x;
            end
            else begin
                ps1_v[i] = data[ps1_s[i]];
                ps2_v[i] = data[ps2_s[i]];
            end
        end
    end

endmodule : regfile
