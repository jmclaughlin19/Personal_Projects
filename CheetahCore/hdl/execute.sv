module execute
import rv32i_types::*;
                  #( parameter DATA_WIDTH = 6,
                     parameter ROB_DEPTH = 16 )
(   
    input   logic                               clk,
    input   logic                               rst,

    // From register file
    input   logic     [31:0]                    ps1_v[5],
    input   logic     [31:0]                    ps2_v[5],
    
    // From reservation stations
    input   alu_rs_data_t                       alu_unit_data,
    input   mul_rs_data_t                       mul_unit_data,
    input   div_rs_data_t                       div_unit_data,
    input   mem_rs_data_t                       mem_unit_data,
    input   br_rs_data_t                        br_unit_data,

    input   logic   [1:0]                       mul_shift_reg,

    input   logic                           rs_select_alu,
    input   logic                           rs_select_mul,
    input   logic                           rs_select_mem,
    input   logic                           rs_select_div,
    input   logic                           rs_select_br,

    // input   logic   [65:0]                      multiplier_output_66_mulhsu,
    input   logic   [65:0]                      multiplier_output_66,

    // Divider unit signals from signed and unsigned units both
    input   logic                               complete_inst_signed, 
    // input   logic                               complete_inst_unsigned,
    input   logic                               divide_by_0_signed,
    // input   logic                               divide_by_0_unsigned,
    input   logic   [32:0]                      remainder_signed,
    // input   logic   [31:0]                      remainder_unsigned,
    input   logic   [32:0]                      quotient_signed,
    // input   logic   [31:0]                      quotient_unsigned,

    // Register output signals to separate execute and writeback pipeline stages
    output  logic   [31:0]                      cdb_pd_v,
    output  logic   [4:0]                       cdb_rd,
    output  logic   [DATA_WIDTH - 1:0]          cdb_pd,
    output  logic   [$clog2(ROB_DEPTH) - 1:0]   cdb_rob_idx,
    output  logic                               cdb_regf_we,

    // Used to signal when a valid pd_v has been set
    output  logic                               cdb_valid_out,
    output  rvfi_t                              cdb_rvfi_ex,
    
    output  logic                               funit_ready[5],

    // These signals are used to send out to multiplier unit
    output  logic                               signed_flag,
    output  logic    [32:0]                     multiply_operand_a,
    output  logic    [32:0]                     multiply_operand_b,

    // These signals are used to send out to divider unit
    output  logic                               div_rem_sign_flag,
    output  logic    [32:0]                     div_rem_operand_a,
    output  logic    [32:0]                     div_rem_operand_b,
    output  logic                               start,
    output  logic                               hold,

    // From multiplier, determines if the output is valid
    input   logic                               multiplier_output_valid,

    output  state_t                             division_state,

    // Mem operation inputs/outputs
    output  logic   [31:0]                      dmem_addr,
    output  logic   [3:0]                       dmem_rmask,
    output  logic   [31:0]                      dmem_wdata,
    output  logic   [3:0]                       dmem_wmask,
    input   logic                               dmem_resp,
    input   logic   [31:0]                      dmem_rdata,

    // Outputs for the jump/branch instructions   
    output  logic                               jump,
    output  logic   [31:0]                      jump_pc_next,
    output  logic                               jump_reg,

    input   logic                               jump_commit,
    output  logic  [31:0]                       jump_pc_next_reg,
    // output  logic   [63:0]                   jump_order_next,        // don't know how this works now with the next order on jumps

    input   logic                               mem_inst_sent_invalid_reg,

    output  logic   [3:0]                       rvfi_mem_rmask,            
    output  logic   [3:0]                       rvfi_mem_wmask, 

    // branch prediction signals
    output  logic                               ghr_din,
    output  logic   [7:0]                       predictor_idx,
    output  logic   [4:0]                       btb_index,
    output  logic   [31:0]                      btb_addr_new,
    output  logic                               web_btb,
    output  logic                               ghr_shift_en,
    output  logic                               web_predictor,
    output  logic   [1:0]                       predictor_data_in
);

            logic   [31:0]                      pd_v[5];

            logic   [31:0]                      a[5];
            logic   [31:0]                      b[5];

            logic signed   [31:0]               as[5];
            logic signed   [31:0]               bs[5];
            logic unsigned [31:0]               au[5];
            logic unsigned [31:0]               bu[5];

            logic   [31:0]                      aluout[5];
            logic                               br_en[5];

            logic   [6:0]                       opcode[5];
            logic   [2:0]                       funct3[5];

            logic                               valid_out[5];
            logic                               mul_sent_flag;
            logic                               mul_sent_flag_reg;

            state_t                             division_state_next;

            logic   [31:0]                      div_rem_operand_a_reg;
            logic   [31:0]                      div_rem_operand_b_reg;


            // VERY IMPORTANT MAKE SURE TO PASS full_addr TO RVFI NOT mem_addr BECAUSE LOWEST 2 BITS OF mem_addr ARE CLEARED FOR CACHE INPUT
            logic   [31:0]                      mem_addr, full_addr;
            logic   [2:0]                       load_store_select;            // This is simply funct3 for load/store instructions
            logic                               mem_sent_request;
            // logic                               mem_sent_request_reg;

            int unsigned                        branch_taken_hk;
            int unsigned                        branch_not_taken_hk;

            logic   [31:0]                      pd_v_reg[5];
            logic   [4:0]                       rd_reg[5];
            logic   [DATA_WIDTH - 1:0]          pd_reg[5];
            logic   [$clog2(ROB_DEPTH) - 1:0]   rob_idx_reg[5];
            logic                               regf_we_reg[5];
            rvfi_t                              rvfi_ex[5];
            logic                               valid_out_reg[5];
            logic                               funit_ready_reg[5];
            rs_select_t                         rs_select_reg;

            logic   [31:0]                      rvfi_br_pc_next;
            
            int                                 branch_wrong_hk;
            int                                 branch_in_execute;
            


    assign ghr_din = br_en[br];
    assign predictor_idx = br_unit_data.predictor_index;
    assign btb_index = br_unit_data.pc[6:2];
    assign btb_addr_new = br_unit_data.pc + br_unit_data.imm;


    always_ff @(posedge clk) begin
        if ( rst || jump_commit ) begin
            division_state <= IDLE;
        end 
        else begin
            division_state <= division_state_next;
        end

        if(br_unit_data.inst[6:0] == op_b_br && br_en[br] == 1'b1) begin
            branch_taken_hk <= branch_taken_hk + 1;
        end 
        if(br_unit_data.inst[6:0] == op_b_br && br_en[br] == 1'b0) begin
            branch_not_taken_hk <= branch_not_taken_hk + 1;
        end
    end
    int store_f_count;
    always_ff @( posedge clk ) begin
        for ( int i = 0; i < 5; i++ ) begin
            if ( rst || jump_commit ) begin
                funit_ready_reg[i] <= '1;
                pd_v_reg[i] <= '0;
                rd_reg[i] <= '0;
                pd_reg[i] <= '0;
                rob_idx_reg[i] <= '0;
                valid_out_reg[i] <= '0;
                rvfi_ex[i] <= '0;
                mul_sent_flag_reg <= '0;
                div_rem_operand_a_reg <= '0;
                div_rem_operand_b_reg <= '0;
                regf_we_reg[i] <= '0;
                jump_pc_next_reg <= '0;
                jump_reg <= '0;
                rs_select_reg <= '0;
            end
            // else begin
            //     pd_v_reg[i] <= pd_v[i];
            // end
            // mem_sent_request_reg <= '0;
        end

        if (rst) begin
            rvfi_mem_rmask <= '0;
            rvfi_mem_wmask <= '0;
            store_f_count <= '0;
            branch_wrong_hk <= '0;
            branch_in_execute <= '0;
        end

        if ( !rst && !jump_commit ) begin
            funit_ready_reg <= funit_ready;
            rs_select_reg.alu_rs_select <= rs_select_alu;
            rs_select_reg.mul_rs_select <= rs_select_mul;
            rs_select_reg.mem_rs_select <= rs_select_mem;
            rs_select_reg.div_rs_select <= rs_select_div;
            rs_select_reg.br_rs_select <= rs_select_br;

            if ( rs_select_br && jump) begin
                branch_wrong_hk <= branch_wrong_hk + 1;
            end
            if ( rs_select_br ) begin
                branch_in_execute <= branch_in_execute + 1;
            end
            
            if ( funit_ready[alu] ) begin
                rd_reg[alu] <= alu_unit_data.rd;
                pd_reg[alu] <= alu_unit_data.pd;
                rob_idx_reg[alu] <= alu_unit_data.rob_idx;
                valid_out_reg[alu] <= valid_out[alu];
                regf_we_reg[alu] <= valid_out[alu];
                pd_v_reg[alu] <= pd_v[alu];

                rvfi_ex[alu].valid <= valid_out[alu];
                rvfi_ex[alu].inst <= alu_unit_data.inst;
                rvfi_ex[alu].rs1_addr <= alu_unit_data.rs1_s;
                rvfi_ex[alu].rs2_addr <= alu_unit_data.rs2_s;
                rvfi_ex[alu].pc_rdata <= alu_unit_data.pc;
                rvfi_ex[alu].pc_wdata <= alu_unit_data.pc_next;
                rvfi_ex[alu].rd_addr <= alu_unit_data.rd;
                rvfi_ex[alu].rs1_v <= ps1_v[alu];
                rvfi_ex[alu].rs2_v <= ps2_v[alu];
                rvfi_ex[alu].rd_wdata <= pd_v[alu];
                rvfi_ex[alu].mem_addr <= '0;
                rvfi_ex[alu].mem_rmask <= '0;
                rvfi_ex[alu].mem_wmask <= '0;
                rvfi_ex[alu].mem_wdata <= '0;
                rvfi_ex[alu].mem_rdata <= '0;

            end

            if ( funit_ready[br] ) begin
                rvfi_ex[br].valid <= valid_out[br];
                rvfi_ex[br].inst <= br_unit_data.inst;
                rvfi_ex[br].rs1_addr <= br_unit_data.rs1_s;
                rvfi_ex[br].rs2_addr <= br_unit_data.rs2_s;
                rvfi_ex[br].pc_rdata <= br_unit_data.pc;
                rvfi_ex[br].rd_addr <= br_unit_data.rd;
                rvfi_ex[br].rs1_v <= ps1_v[br];
                rvfi_ex[br].rs2_v <= ps2_v[br];
                rvfi_ex[br].rd_wdata <= pd_v[br];
                rvfi_ex[br].mem_addr <= '0;
                rvfi_ex[br].mem_rmask <= '0;
                rvfi_ex[br].mem_wmask <= '0;
                rvfi_ex[br].mem_wdata <= '0;
                rvfi_ex[br].mem_rdata <= '0;
                jump_reg <= jump;

                rd_reg[br] <= br_unit_data.rd;
                pd_reg[br] <= br_unit_data.pd;
                rob_idx_reg[br] <= br_unit_data.rob_idx;
                valid_out_reg[br] <= valid_out[br];
                pd_v_reg[br] <= pd_v[br];

                if ( br_unit_data.inst[6:0] == op_b_jal ) begin
                    regf_we_reg[br] <= '1;
                    rvfi_ex[br].pc_wdata <= jump_pc_next;
                    jump_pc_next_reg <= jump_pc_next;

                end
                else if (br_unit_data.inst[6:0] == op_b_jalr) begin
                    regf_we_reg[br] <= '1;
                    rvfi_ex[br].pc_wdata <= jump_pc_next;
                    jump_pc_next_reg <= jump_pc_next;
                end
                else begin
                    regf_we_reg[br] <= '0;
                    // if ( br_en[br] ) begin
                    //     rvfi_ex[br].pc_wdata <= jump_pc_next;
                    //     jump_pc_next_reg <= jump_pc_next;
                    // end 
                    // else begin
                    //     rvfi_ex[br].pc_wdata <= br_unit_data.pc_next;
                    // end
                    if ( jump ) begin
                        rvfi_ex[br].pc_wdata <= rvfi_br_pc_next;
                        jump_pc_next_reg <= rvfi_br_pc_next;
                    end else begin
                        rvfi_ex[br].pc_wdata <= rvfi_br_pc_next;
                    end
                end
            end
            
            if ( mul_shift_reg == '0 && funit_ready[mul] ) begin
                rvfi_ex[mul].valid <= '0;
                rvfi_ex[mul].inst <= mul_unit_data.inst;
                rvfi_ex[mul].rs1_addr <= mul_unit_data.rs1_s;
                rvfi_ex[mul].rs2_addr <= mul_unit_data.rs2_s;
                rvfi_ex[mul].pc_rdata <= mul_unit_data.pc;
                rvfi_ex[mul].pc_wdata <= mul_unit_data.pc_next;
                rvfi_ex[mul].rd_addr <= mul_unit_data.rd;
                rvfi_ex[mul].rs1_v <= ps1_v[mul];
                rvfi_ex[mul].rs2_v <= ps2_v[mul];
                rvfi_ex[mul].mem_addr <= '0;
                rvfi_ex[mul].mem_rmask <= '0;
                rvfi_ex[mul].mem_wmask <= '0;
                rvfi_ex[mul].mem_wdata <= '0;
                rvfi_ex[mul].mem_rdata <= '0;
                
                rd_reg[mul] <= mul_unit_data.rd;
                pd_reg[mul] <= mul_unit_data.pd;
                rob_idx_reg[mul] <= mul_unit_data.rob_idx;
                valid_out_reg[mul] <= '0;
                pd_v_reg[mul] <= pd_v[mul];
            end
            else if ( multiplier_output_valid ) begin
                rvfi_ex[mul].valid <= valid_out[mul];
                mul_sent_flag_reg <= '0;
                valid_out_reg[mul] <= valid_out[mul];
                rvfi_ex[mul].rd_wdata <= pd_v[mul];
                regf_we_reg[mul] <= valid_out[mul];
                pd_v_reg[mul] <= pd_v[mul];
            end

            if ( mul_sent_flag ) begin
                mul_sent_flag_reg <= '1;
            end

            if ( division_state == IDLE && funit_ready[div] ) begin
                rvfi_ex[div].valid <= '0;
                rvfi_ex[div].inst <= div_unit_data.inst;
                rvfi_ex[div].rs1_addr <= div_unit_data.rs1_s;
                rvfi_ex[div].rs2_addr <= div_unit_data.rs2_s;
                rvfi_ex[div].pc_rdata <= div_unit_data.pc;
                rvfi_ex[div].pc_wdata <= div_unit_data.pc_next;
                rvfi_ex[div].rd_addr <= div_unit_data.rd;
                rvfi_ex[div].rs1_v <= ps1_v[div];
                rvfi_ex[div].rs2_v <= ps2_v[div];

                rvfi_ex[div].mem_addr <= '0;
                rvfi_ex[div].mem_rmask <= '0;
                rvfi_ex[div].mem_wmask <= '0;
                rvfi_ex[div].mem_wdata <= '0;
                rvfi_ex[div].mem_rdata <= '0;
                
                rd_reg[div] <= div_unit_data.rd;
                pd_reg[div] <= div_unit_data.pd;
                rob_idx_reg[div] <= div_unit_data.rob_idx;
                valid_out_reg[div] <= '0;
                pd_v_reg[div] <= pd_v[div];
            end
            else if ( complete_inst_signed ) begin
                valid_out_reg[div] <= valid_out[div];
                rvfi_ex[div].rd_wdata <= pd_v[div];
                rvfi_ex[div].valid <= valid_out[div];
                regf_we_reg[div] <= valid_out[div];
                pd_v_reg[div] <= pd_v[div];
            end        

            if ( start ) begin
                div_rem_operand_a_reg <= a[div];
                div_rem_operand_b_reg <= b[div];
            end  

            if ( (mem_sent_request || mem_unit_data.load_data_valid) && funit_ready[mem] ) begin
                // mem_sent_request_reg <= mem_sent_request;
                if (mem_unit_data.load_data_valid) begin
                    store_f_count <= store_f_count + 1;
                    rvfi_ex[mem].valid <= '1;
                    valid_out_reg[mem] <= '1;
                    rvfi_ex[mem].mem_rdata <= mem_unit_data.load_data_rdata;
                    rvfi_ex[mem].rd_wdata <= pd_v[mem];
                    pd_v_reg[mem] <= pd_v[mem];
                    regf_we_reg[mem] <= '1;
                    rvfi_mem_rmask <= mem_unit_data.mem_rmask;
                    rvfi_mem_wmask <= '0;
                    rvfi_ex[mem].mem_rmask <= mem_unit_data.mem_rmask;
                    rvfi_ex[mem].mem_wmask <= '0;
                    rvfi_ex[mem].mem_wdata <= '0;
                end
                else begin
                    rvfi_ex[mem].valid <= '0;
                    valid_out_reg[mem] <= '0;
                    regf_we_reg[mem] <= '0;
                    pd_v_reg[mem] <= pd_v[mem];
                    rvfi_mem_rmask <= dmem_rmask;
                    rvfi_mem_wmask <= dmem_wmask;
                    rvfi_ex[mem].mem_rmask <= dmem_rmask;
                    rvfi_ex[mem].mem_wmask <= dmem_wmask;
                    rvfi_ex[mem].mem_wdata <= dmem_wdata;
                    rvfi_ex[mem].mem_rdata <= dmem_rdata;
                end
                
                rvfi_ex[mem].inst <= mem_unit_data.inst;
                rvfi_ex[mem].rs1_addr <= mem_unit_data.rs1_s;
                rvfi_ex[mem].rs2_addr <= mem_unit_data.rs2_s;
                rvfi_ex[mem].pc_rdata <= mem_unit_data.pc;
                rvfi_ex[mem].pc_wdata <= mem_unit_data.pc_next;
                rvfi_ex[mem].rd_addr <= mem_unit_data.rd;
                rvfi_ex[mem].rs1_v <= mem_unit_data.ps1_v;
                rvfi_ex[mem].rs2_v <= mem_unit_data.ps2_v;
                rvfi_ex[mem].mem_addr <= full_addr;
                rd_reg[mem] <= mem_unit_data.rd;
                pd_reg[mem] <= mem_unit_data.pd;
                rob_idx_reg[mem] <= mem_unit_data.rob_idx;
                
            end 
            
            if ( dmem_resp && !mem_inst_sent_invalid_reg ) begin
                rvfi_ex[mem].valid <= '1;
                valid_out_reg[mem] <= '1;
                rvfi_ex[mem].mem_rdata <= dmem_rdata;
                rvfi_ex[mem].rd_wdata <= pd_v[mem];
                pd_v_reg[mem] <= pd_v[mem];
                if ( rvfi_ex[mem].inst[6:0] == op_b_store) begin
                    regf_we_reg[mem] <= '0;
                end
                else begin
                    regf_we_reg[mem] <= '1;
                end
            end
            else if ( funit_ready[mem] && !mem_sent_request && !mem_unit_data.load_data_valid ) begin
                regf_we_reg[mem] <= '0;
                valid_out_reg[mem] <= '0;
                rvfi_ex[mem].valid <= '0;
            end  
        end
    end

    always_comb begin    
        web_btb = '1;
        ghr_shift_en = '0;
        web_predictor = '1;
        predictor_data_in = '0;
        rvfi_br_pc_next = '0;

        funit_ready = funit_ready_reg;
        full_addr = '0;

        opcode[alu] = alu_unit_data.inst[6:0];
        funct3[alu] = alu_unit_data.inst[14:12];

        if ( mul_sent_flag_reg ) begin
            opcode[mul] = rvfi_ex[mul].inst[6:0];
            funct3[mul] = rvfi_ex[mul].inst[14:12];
        end
        else begin
            opcode[mul] = mul_unit_data.inst[6:0];
            funct3[mul] = mul_unit_data.inst[14:12];
        end

        if ( division_state == WAITING || division_state == INIT ) begin
            opcode[div] = rvfi_ex[div].inst[6:0];
            funct3[div] = rvfi_ex[div].inst[14:12];
        end
        else begin
            opcode[div] = div_unit_data.inst[6:0];
            funct3[div] = div_unit_data.inst[14:12];
        end

        opcode[mem] = mem_unit_data.inst[6:0];
        funct3[mem] = mem_unit_data.inst[14:12];

        opcode[br] = br_unit_data.inst[6:0];
        funct3[br] = br_unit_data.inst[14:12];

        for ( int i = 0; i < 5; i++ ) begin
            valid_out[i] = '0;
            as[i] = signed'( 32'h00000000 );
            bs[i] = signed'( 32'h00000000 );
            au[i] = 'x;
            bu[i] = 'x;
            a[i] = 'x;
            b[i] = 'x;
        end
        
        if ( rs_select_alu ) begin 

                unique case ( alu_unit_data.alu_m1_sel )
                    rs1_out: a[alu] = ps1_v[alu];
                    pc_out:  a[alu] = alu_unit_data.pc;
                    default: a[alu] = '0;
                endcase

                unique case ( alu_unit_data.alu_m2_sel )
                    imm_out:   b[alu] = alu_unit_data.imm;
                    rs2_out:   b[alu] = ps2_v[alu];
                    default:   b[alu] = '0;
                endcase

                as[alu] =   signed'( a[alu] );
                bs[alu] =   signed'( b[alu] );
                au[alu] = unsigned'( a[alu] );
                bu[alu] = unsigned'( b[alu] );

                // Signal that a valid output is ready for the CDB
                valid_out[alu] = '1;
        end
        if ( rs_select_mul ) begin

            a[mul] = ps1_v[mul];
            b[mul] = ps2_v[mul];

            as[mul] =   signed'( a[mul] );
            bs[mul] =   signed'( b[mul] );
            au[mul] = unsigned'( a[mul] );
            bu[mul] = unsigned'( b[mul] );

            
        end
        if ( rs_select_div ) begin
            a[div] = ps1_v[div];
            b[div] = ps2_v[div];

            as[div] =   signed'( a[div] );
            bs[div] =   signed'( b[div] );
            au[div] = unsigned'( a[div] );
            bu[div] = unsigned'( b[div] );

        end
        
        if ( rs_select_br ) begin

            unique case ( br_unit_data.alu_m1_sel )
                    rs1_out: a[br] = ps1_v[br];
                    pc_out:  a[br] = br_unit_data.pc;
                    default: a[br] = '0;
            endcase

            unique case ( br_unit_data.alu_m2_sel )
                imm_out:   b[br] = br_unit_data.imm;
                rs2_out:   b[br] = ps2_v[br];
                default:   b[br] = '0;
            endcase

            as[br] =   signed'( a[br] );
            bs[br] =   signed'( b[br] );
            au[br] = unsigned'( a[br] );
            bu[br] = unsigned'( b[br] );

            // valid_out[br] = '0;
        end

        for ( int i = 0; i < 5; i++ ) begin
            aluout[i] = '0;
            br_en[i] = '0;
        end        

        // b I'm from Texas, where we still ride in swangas and got diamonds on our necklace
        // for ( int i = 0; i < 5; i++ ) begin
        unique case ( alu_unit_data.aluop )
            alu_op_add: aluout[alu] = au[alu] +   bu[alu];
            alu_op_sll: aluout[alu] = au[alu] <<  bu[alu][4:0];
            alu_op_sra: aluout[alu] = unsigned'(as[alu] >>> bu[alu][4:0]);  
            alu_op_sub: aluout[alu] = au[alu] -   bu[alu];
            alu_op_xor: aluout[alu] = au[alu] ^   bu[alu];
            alu_op_srl: aluout[alu] = au[alu] >>  bu[alu][4:0];
            alu_op_or : aluout[alu] = au[alu] |   bu[alu];
            alu_op_and: aluout[alu] = au[alu] &   bu[alu];
            default   : aluout[alu] = '0;
        endcase

        unique case ( alu_unit_data.cmpop ) 
            branch_f3_beq : br_en[alu] = ( au[alu] == bu[alu] );
            branch_f3_bne : br_en[alu] = ( au[alu] != bu[alu] ); 
            branch_f3_blt : br_en[alu] = ( as[alu] <  bs[alu] );
            branch_f3_bge : br_en[alu] = ( as[alu] >= bs[alu] ); 
            branch_f3_bltu: br_en[alu] = ( au[alu] <  bu[alu] );
            branch_f3_bgeu: br_en[alu] = ( au[alu] >= bu[alu] ); 
            default       : br_en[alu] = 1'bx;
        endcase

        unique case ( br_unit_data.aluop )
            alu_op_add: aluout[br] = au[br] +   bu[br];
            alu_op_sll: aluout[br] = au[br] <<  bu[br][4:0];
            alu_op_sra: aluout[br] = unsigned'(as[br] >>> bu[br][4:0]);  
            alu_op_sub: aluout[br] = au[br] -   bu[br];
            alu_op_xor: aluout[br] = au[br] ^   bu[br];
            alu_op_srl: aluout[br] = au[br] >>  bu[br][4:0];
            alu_op_or : aluout[br] = au[br] |   bu[br];
            alu_op_and: aluout[br] = au[br] &   bu[br];
            default   : aluout[br] = '0;
        endcase

        unique case ( br_unit_data.cmpop ) 
            branch_f3_beq : br_en[br] = ( au[br] == bu[br] );
            branch_f3_bne : br_en[br] = ( au[br] != bu[br] ); 
            branch_f3_blt : br_en[br] = ( as[br] <  bs[br] );
            branch_f3_bge : br_en[br] = ( as[br] >= bs[br] ); 
            branch_f3_bltu: br_en[br] = ( au[br] <  bu[br] );
            branch_f3_bgeu: br_en[br] = ( au[br] >= bu[br] ); 
            default       : br_en[br] = 1'bx;
        endcase
        // end
    
        signed_flag = '0;
        div_rem_sign_flag = '0;
        mul_sent_flag = '0;

        start = '0;
        hold = '0;
        division_state_next = division_state;

        multiply_operand_a = '0;
        multiply_operand_b = '0;

        // New memory signals
        dmem_wmask = '0;
        dmem_wdata = '0;
        dmem_rmask = '0;
        dmem_addr = '0;
        load_store_select = mem_unit_data.inst[14:12];
        // mem_sent_request = mem_sent_request_reg;
        mem_sent_request = '0;

        // New jump/branch signals
        jump_pc_next = '0;
        jump = '0;

        pd_v[0] = '0;
        pd_v[1] = '0;
        pd_v[2] = '0;
        pd_v[3] = '0;
        pd_v[4] = '0;

        for ( int i = 0; i < 5; i++ ) begin
            case ( rv32i_opcode'( opcode[i] ) ) 
                op_b_lui: begin
                    if ( i == 0 ) begin
                        pd_v[i] = alu_unit_data.imm;
                    end
                end

                op_b_auipc: begin
                    if ( i == 0 ) begin
                        pd_v[i] = aluout[alu];
                    end
                end

                op_b_imm: begin
                    if ( i == 0 ) begin
                        unique case ( funct3[i] ) 
                            arith_f3_slt: begin
                                pd_v[i] = {31'd0, br_en[i]}; 
                            end
                            arith_f3_sltu: begin
                                pd_v[i] = {31'd0, br_en[i]};
                            end
                            arith_f3_sr: begin
                                pd_v[i] = aluout[i];
                            end
                            default: begin
                                pd_v[i] = aluout[i];
                            end
                        endcase
                    end
                end

                op_b_reg: begin
                    if ( i == 1 ) begin
                        unique case ( funct3[i] )
                            3'b000: begin
                                // this is for MUL
                                signed_flag = 1'b1;
                                multiply_operand_a = {{1{a[mul][32-1]}}, a[mul]};
                                multiply_operand_b = {{1{b[mul][32-1]}}, b[mul]};
                               
                                if (!mul_sent_flag_reg) begin
                                    mul_sent_flag = '1;
                                end
                                if ( multiplier_output_valid ) begin
                                    pd_v[i] = multiplier_output_66[31:0];
                                    valid_out[mul] = '1;
                                end
                            end
                            3'b001: begin
                                // this is for MULH
                                signed_flag = 1'b1;
                                multiply_operand_a = {{1{a[mul][32-1]}}, a[mul]};
                                multiply_operand_b = {{1{b[mul][32-1]}}, b[mul]};
                                if ( !mul_sent_flag_reg ) begin
                                    mul_sent_flag = '1;
                                end
                                if ( multiplier_output_valid ) begin
                                    pd_v[i] = multiplier_output_66[63:32];
                                    valid_out[mul] = '1;
                                end
                            end
                            3'b010: begin
                                // this is for MULHSU
                                signed_flag = 1'b1;
                                multiply_operand_a = {{1{a[mul][32-1]}}, a[mul]};
                                multiply_operand_b = {1'b0, b[mul]}; 
                                if ( !mul_sent_flag_reg ) begin
                                    mul_sent_flag = '1;
                                end
                               
                                if ( multiplier_output_valid ) begin
                                    pd_v[i] = multiplier_output_66[63:32];
                                    valid_out[mul] = '1;
                                end
                            end
                            3'b011: begin
                                // this is for MULHU
                                signed_flag = 1'b0;
                                multiply_operand_a = {1'b0, a[mul]};
                                multiply_operand_b = {1'b0, b[mul]};
                                if ( !mul_sent_flag_reg ) begin

                                    mul_sent_flag = '1;
                                end
                                if ( multiplier_output_valid ) begin
                                    pd_v[i] = multiplier_output_66[63:32];
                                    valid_out[mul] = '1;
                                end
                            end
                            default: begin
                                signed_flag = '0;
                                pd_v[i] = 'x;
                            end
                        endcase
                    end 
                    else if ( i == 2 ) begin
                        unique case ( funct3[i] )
                            // DIV
                            3'b100: begin
                                div_rem_sign_flag = 1'b1;
                                unique case ( division_state )
                                    IDLE: begin
                                        start = '1;
                                        division_state_next = INIT;
                                    end
                                    INIT: begin
                                        start = '0;
                                        hold = '0;
                                        division_state_next = WAITING;
                                    end
                                    WAITING: begin
                                        hold = '0;
                                        if ( complete_inst_signed ) begin
                                            hold = '0;
                                            division_state_next = IDLE;
                                            pd_v[i] = ( divide_by_0_signed ) ? '1 : quotient_signed[31:0];
                                            valid_out[div] = '1;
                                        end
                                    end
                                    default: begin
                                        start = '0;
                                        hold = '0;
                                        division_state_next = IDLE;
                                    end
                                endcase
                            end
                            3'b101: begin
                                // DIVU
                                div_rem_sign_flag = '0;
                                unique case ( division_state )
                                    IDLE: begin
                                        start = '1;
                                        division_state_next = INIT;
                                    end
                                    INIT: begin
                                        start = '0;
                                        hold = '0;
                                        division_state_next = WAITING;
                                    end
                                    WAITING: begin
                                        hold = '0;
                                        if( complete_inst_signed ) begin
                                            hold = '0;
                                            division_state_next = IDLE;
                                            pd_v[i] = ( divide_by_0_signed ) ? '1 : quotient_signed[31:0];
                                            valid_out[div] = '1;
                                        end
                                    end
                                    default: begin
                                        start = '0;
                                        hold = '0;
                                        division_state_next = IDLE;
                                    end
                                endcase
                            end
                            // REM
                            3'b110: begin
                                div_rem_sign_flag = 1'b1;
                                unique case ( division_state )
                                    IDLE: begin
                                        start = '1;
                                        division_state_next = INIT;
                                    end
                                    INIT: begin
                                        start = '0;
                                        hold = '0;
                                        division_state_next = WAITING;
                                    end
                                    WAITING: begin
                                        hold = '0;
                                        if ( complete_inst_signed ) begin
                                            hold = '0;
                                            division_state_next = IDLE;
                                            pd_v[i] = ( divide_by_0_signed ) ? div_rem_operand_a_reg : remainder_signed[31:0];
                                            valid_out[div] = '1;
                                        end
                                    end
                                    default: begin
                                        start = '0;
                                        hold = '0;
                                        division_state_next = IDLE;
                                    end
                                endcase
                            end
                            // REMU
                            3'b111: begin
                                div_rem_sign_flag = '0;
                                unique case ( division_state )
                                    IDLE: begin
                                        start = '1;
                                        division_state_next = INIT;
                                    end
                                    INIT: begin
                                        start = '0;
                                        hold = '0;
                                        division_state_next = WAITING;
                                    end
                                    WAITING: begin
                                        hold = '0;
                                        if ( complete_inst_signed ) begin
                                            hold = '0;
                                            division_state_next = IDLE;
                                            pd_v[i] = ( divide_by_0_signed ) ? div_rem_operand_a_reg : remainder_signed[31:0];
                                            valid_out[div] = '1;
                                        end
                                    end
                                    default: begin
                                        start = '0;
                                        hold = '0;
                                        division_state_next = IDLE;
                                    end
                                endcase
                            end
                            default: begin
                                div_rem_sign_flag = '0;
                                pd_v[i] = '0;
                                valid_out[div] = '0;
                            end
                        endcase
                    end
                    // Handles the case where i = 0 
                    else begin
                        unique case ( funct3[i] )
                            arith_f3_slt: begin
                                pd_v[i] = {31'd0, br_en[i]};
                            end
                            arith_f3_sltu: begin
                                pd_v[i] = {31'd0, br_en[i]};
                            end
                            arith_f3_sr: begin
                                pd_v[i] = aluout[i];
                            end
                            arith_f3_add: begin
                                pd_v[i] = aluout[i];
                            end
                            default: begin
                                pd_v[i] = aluout[i];
                            end
                        endcase 
                    end
                end


                op_b_load: begin
                    mem_addr = mem_unit_data.mem_addr;
                    full_addr = mem_unit_data.mem_addr;
                    if (!mem_unit_data.load_data_valid) begin
                        dmem_rmask = mem_unit_data.mem_rmask;
                        mem_addr[1:0] = 2'd0;
                        dmem_addr = mem_addr;
                        mem_sent_request = '1;
                    end
                    
                end                                     

                op_b_store: begin
                    mem_addr = mem_unit_data.mem_addr;
                    full_addr = mem_unit_data.mem_addr;
                    unique case(load_store_select)
                        store_f3_sb: begin
                            dmem_wmask = 4'b0001 << full_addr[1:0];  
                            dmem_wdata[8 *full_addr[1:0] +: 8 ] = mem_unit_data.ps2_v[7 :0]; 
                            mem_sent_request = '1;  
                        end 
                        store_f3_sh: begin
                            dmem_wmask = 4'b0011 << full_addr[1:0];
                            dmem_wdata[16*full_addr[1]   +: 16] = mem_unit_data.ps2_v[15:0];
                            mem_sent_request = '1;
                        end 
                        store_f3_sw: begin
                            dmem_wmask = 4'b1111;
                            dmem_wdata = mem_unit_data.ps2_v;
                            mem_sent_request = '1;
                        end
                        default    :  begin 
                            dmem_wmask = '0;
                            dmem_wdata = '0;
                        end 
                    endcase
                    mem_addr[1:0] = 2'd0;
                    dmem_addr = mem_addr;
                end

                op_b_jal: begin
                    jump_pc_next = aluout[br];
                    jump = 1'b1;
                    valid_out[br] = '1;
                    pd_v[br] = br_unit_data.pc + 'd4;
                    


                end

                op_b_jalr: begin
                    jump_pc_next = aluout[br] & 32'hfffffffe;
                    jump = 1'b1;
                    valid_out[br] = '1;
                    pd_v[br] = br_unit_data.pc + 'd4;
                end

                op_b_br: begin
                    // if(br_en[br]) begin
                    //     jump_pc_next = br_unit_data.pc + br_unit_data.imm;
                    //     jump = 1'b1;
                    //     valid_out[br] = '1;
                    //     pd_v[br] = '0;
                    // end
                    // else begin
                    //     valid_out[br] = '1;
                    //     pd_v[br] = '0;
                    // end

                    ghr_shift_en = '1;
                    // web_predictor = '0;

                    unique case (br_unit_data.br_prediction)

                        2'b00: begin
                            if (br_en[br]) begin
                                jump_pc_next = btb_addr_new;
                                jump = 1'b1;
                                valid_out[br] = '1;
                                pd_v[br] = '0;
                                web_btb = '0;
                                web_predictor = '0;
                                predictor_data_in = 2'b01;
                                rvfi_br_pc_next = btb_addr_new;
                            end else begin
                                valid_out[br] = '1;
                                pd_v[br] = '0;
                                rvfi_br_pc_next = br_unit_data.pc_next;
                            end
                        end

                        2'b01: begin
                            if (br_en[br]) begin
                                jump_pc_next = btb_addr_new;
                                jump = 1'b1;
                                valid_out[br] = '1;
                                pd_v[br] = '0;
                                web_btb = '0;
                                web_predictor = '0;
                                predictor_data_in = 2'b10;
                                rvfi_br_pc_next = btb_addr_new;
                            end else begin
                                valid_out[br] = '1;
                                pd_v[br] = '0;
                                web_predictor = '0;
                                predictor_data_in = 2'b00;
                                rvfi_br_pc_next = br_unit_data.pc_next;
                            end
                        end

                        2'b10: begin
                            if (br_en[br]) begin
                                if (br_unit_data.btb_addr != btb_addr_new) begin
                                    jump_pc_next = btb_addr_new;
                                    jump = 1'b1;
                                    web_btb = '0;
                                end
                                valid_out[br] = '1;
                                pd_v[br] = '0;
                                web_predictor = '0;
                                predictor_data_in = 2'b11;
                                rvfi_br_pc_next = btb_addr_new;
                            end else begin
                                jump_pc_next = br_unit_data.pc + 4;
                                jump = 1'b1;
                                valid_out[br] = '1;
                                pd_v[br] = '0;
                                web_predictor = '0;
                                predictor_data_in = 2'b01;
                                rvfi_br_pc_next = br_unit_data.pc_next;
                            end
                        end

                        2'b11: begin
                            if (br_en[br]) begin
                                if (br_unit_data.btb_addr != btb_addr_new) begin
                                    jump_pc_next = btb_addr_new;
                                    jump = 1'b1;
                                    web_btb = '0;
                                end
                                valid_out[br] = '1;
                                pd_v[br] = '0;
                                rvfi_br_pc_next = btb_addr_new;
                            end else begin
                                jump_pc_next = br_unit_data.pc + 4;
                                jump = 1'b1;
                                valid_out[br] = '1;
                                pd_v[br] = '0;
                                web_predictor = '0;
                                predictor_data_in = 2'b10;
                                rvfi_br_pc_next = br_unit_data.pc_next;
                            end
                        end

                        default: begin
                            valid_out[br] = '1;
                            pd_v[br] = '0;
                        end

                    endcase

                end

                default: begin
                    pd_v[i] = 'x;
                end
            endcase
        end

        if ( start ) begin
            unique case ( funct3[2] )
                // If DIV or REM, sign extend by MSB
                3'b100: begin
                    div_rem_operand_a = {{1{a[div][32-1]}}, a[div]};
                    div_rem_operand_b = {{1{b[div][32-1]}}, b[div]};
                end
                3'b110: begin
                    div_rem_operand_a = {{1{a[div][32-1]}}, a[div]};
                    div_rem_operand_b = {{1{b[div][32-1]}}, b[div]};
                end
                // For DIVU and REMU, sign extend by 0
                3'b101: begin
                    div_rem_operand_a = {{1'b0, a[div]}};
                    div_rem_operand_b = {{1'b0, b[div]}};
                end
                3'b111: begin
                    div_rem_operand_a = {{1'b0, a[div]}};
                    div_rem_operand_b = {{1'b0, b[div]}};
                end
                default: begin
                    div_rem_operand_a = '0;
                    div_rem_operand_b = '0;
                end
            endcase
        end
        else begin
            unique case ( funct3[2] )
                // If DIV or REM, sign extend by MSB
                3'b100: begin
                    div_rem_operand_a = {{{{{{{{{{{{{{1{a[div][32-1]}}, div_rem_operand_a_reg}}}}}}}}}}}}};
                    div_rem_operand_b = {{{{{{{{{{{{{{1{b[div][32-1]}}, div_rem_operand_b_reg}}}}}}}}}}}}};
                end
                3'b110: begin
                    div_rem_operand_a = {{{{{{{{{{{{{{1{a[div][32-1]}}, div_rem_operand_a_reg}}}}}}}}}}}}};
                    div_rem_operand_b = {{{{{{{{{{{{{{1{b[div][32-1]}}, div_rem_operand_b_reg}}}}}}}}}}}}};
                end
                // For DIVU and REMU, sign extend by 0
                3'b101: begin
                    div_rem_operand_a = {{{{{{{{{{{{{1'b0, div_rem_operand_a_reg}}}}}}}}}}}}};
                    div_rem_operand_b = {{{{{{{{{{{{{1'b0, div_rem_operand_b_reg}}}}}}}}}}}}};
                end
                3'b111: begin
                    div_rem_operand_a = {{{{{{{{{{{{{1'b0, div_rem_operand_a_reg}}}}}}}}}}}}};
                    div_rem_operand_b = {{{{{{{{{{{{{1'b0, div_rem_operand_b_reg}}}}}}}}}}}}};
                end
                default: begin
                    div_rem_operand_a = '0;
                    div_rem_operand_b = '0;
                end
            endcase
        end
        if ( dmem_resp ) begin 
            if ( rvfi_ex[mem].inst[6:0] == op_b_load ) begin
                unique case ( rvfi_ex[mem].inst[14:12] ) 
                    load_f3_lb : pd_v[mem] = {{24{dmem_rdata[7 +8 *rvfi_ex[mem].mem_addr[1:0]]}}, dmem_rdata[8 * rvfi_ex[mem].mem_addr[1:0] +: 8 ]};
                    load_f3_lbu: pd_v[mem] = {{24{1'b0}}                          , dmem_rdata[8 *rvfi_ex[mem].mem_addr[1:0] +: 8 ]};
                    load_f3_lh : pd_v[mem] = {{16{dmem_rdata[15+16*rvfi_ex[mem].mem_addr[1]  ]}}, dmem_rdata[16*rvfi_ex[mem].mem_addr[1]   +: 16]};
                    load_f3_lhu: pd_v[mem] = {{16{1'b0}}                          , dmem_rdata[16*rvfi_ex[mem].mem_addr[1]   +: 16]};
                    load_f3_lw : pd_v[mem] = dmem_rdata;
                    default    : pd_v[mem] = '0;
                endcase
            end
            if ( rvfi_ex[mem].inst[6:0] == op_b_store ) begin
                pd_v[mem] = '0;
            end
        end
        if (mem_unit_data.load_data_valid) begin
            if ( mem_unit_data.inst[6:0] == op_b_load ) begin
                unique case ( mem_unit_data.inst[14:12] ) 
                    load_f3_lb : pd_v[mem] = {{24{mem_unit_data.load_data_rdata[7 +8 *mem_unit_data.mem_addr[1:0]]}}, mem_unit_data.load_data_rdata[8 * mem_unit_data.mem_addr[1:0] +: 8 ]};
                    load_f3_lbu: pd_v[mem] = {{24{1'b0}}                          , mem_unit_data.load_data_rdata[8 *mem_unit_data.mem_addr[1:0] +: 8 ]};
                    load_f3_lh : pd_v[mem] = {{16{mem_unit_data.load_data_rdata[15+16*mem_unit_data.mem_addr[1]  ]}}, mem_unit_data.load_data_rdata[16*mem_unit_data.mem_addr[1]   +: 16]};
                    load_f3_lhu: pd_v[mem] = {{16{1'b0}}                          , mem_unit_data.load_data_rdata[16*mem_unit_data.mem_addr[1]   +: 16]};
                    load_f3_lw : pd_v[mem] = mem_unit_data.load_data_rdata;
                    default    : pd_v[mem] = '0;
                endcase
            end
        end

        cdb_valid_out = '0;
        cdb_pd = '0;
        cdb_pd_v = '0;
        cdb_rd = '0;
        cdb_regf_we = '0;
        cdb_rob_idx = '0;
        cdb_rvfi_ex = '0;

        if ( rs_select_reg.alu_rs_select ) begin
            funit_ready[alu] = '0;
        end
        if ( rs_select_reg.br_rs_select ) begin
            funit_ready[br] = '0;
        end
        if ( rs_select_reg.div_rs_select ) begin
            funit_ready[div] = '0;
        end
        if ( rs_select_reg.mul_rs_select ) begin
            funit_ready[mul] = '0;
        end
        if ( rs_select_reg.mem_rs_select ) begin
            funit_ready[mem] = '0;
        end
        
        // Select the functional output to be sent on the CDB, mark funit as ready to receive next value
        // Priority: BR, MEM, MUL, DIV, ALU
        if ( rvfi_ex[br].valid ) begin
            cdb_valid_out   = '1;
            cdb_pd          = pd_reg[br];
            cdb_pd_v        = pd_v_reg[br];
            cdb_rd          = rd_reg[br];
            cdb_regf_we     = regf_we_reg[br];
            cdb_rob_idx     = rob_idx_reg[br];

            cdb_rvfi_ex     = rvfi_ex[br];

            funit_ready[br] = '1;
        end
        else if ( rvfi_ex[mem].valid ) begin
            cdb_valid_out   = '1;
            cdb_pd          = pd_reg[mem];
            cdb_pd_v        = pd_v_reg[mem];
            cdb_rd          = rd_reg[mem];
            cdb_regf_we     = regf_we_reg[mem];
            cdb_rob_idx     = rob_idx_reg[mem];

            cdb_rvfi_ex     = rvfi_ex[mem];

            funit_ready[mem] = '1;
        end
        else if ( rvfi_ex[mul].valid ) begin
            cdb_valid_out   = '1;
            cdb_pd          = pd_reg[mul];
            cdb_pd_v        = pd_v_reg[mul];
            cdb_rd          = rd_reg[mul];
            cdb_regf_we     = regf_we_reg[mul];
            cdb_rob_idx     = rob_idx_reg[mul];

            cdb_rvfi_ex     = rvfi_ex[mul];

            funit_ready[mul] = '1;
        end
        else if ( rvfi_ex[div].valid ) begin
            cdb_valid_out   = '1;
            cdb_pd          = pd_reg[div];
            cdb_pd_v        = pd_v_reg[div];
            cdb_rd          = rd_reg[div];
            cdb_regf_we     = regf_we_reg[div];
            cdb_rob_idx     = rob_idx_reg[div];

            cdb_rvfi_ex     = rvfi_ex[div];

            funit_ready[div] = '1;
        end
        else if ( rvfi_ex[alu].valid ) begin
            cdb_valid_out   = '1;
            cdb_pd          = pd_reg[alu];
            cdb_pd_v        = pd_v_reg[alu];
            cdb_rd          = rd_reg[alu];
            cdb_regf_we     = regf_we_reg[alu];
            cdb_rob_idx     = rob_idx_reg[alu];

            cdb_rvfi_ex     = rvfi_ex[alu];

            funit_ready[alu] = '1;
        end
    end

endmodule: execute


