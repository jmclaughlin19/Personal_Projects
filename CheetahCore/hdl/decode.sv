module decode
import rv32i_types::*;
(   
    input   logic               clk,
    input   logic               rst,

    // From iqueue
    input   logic   [31:0]      inst,
    input   logic   [31:0]      pc,
    input   logic   [31:0]      pc_next,
    input   logic               iqueue_out_valid,

    input   logic               jump_commit,

    // branch prediction inputs
    input   logic   [31:0]      btb_addr,
    input   logic   [1:0]       br_prediction,
    input   logic               btb_valid_out,
    input   logic               predictor_valid_out,
    input   logic   [7:0]       predictor_index,

    // To rename_dispatch
    output  id_ex_stage_reg_t   decode_rename_reg
);
            logic   [2:0]       funct3;
            logic   [6:0]       funct7;
            logic   [6:0]       opcode;
            logic   [31:0]      i_imm;
            logic   [31:0]      s_imm;
            logic   [31:0]      b_imm;
            logic   [31:0]      u_imm;
            logic   [31:0]      j_imm;
            logic   [4:0]       rd_s;

            logic               regf_we;
            logic               commit;

            logic   [4:0]       rs1_s;
            logic   [4:0]       rs2_s;
            
            logic   [31:0]      imm;
            logic   [2:0]       cmpop;
            logic   [2:0]       aluop;

            logic   [4:0]       rd_s_store;
            logic               jump_flag_decode;

            alu_m1_sel_t        alu_input_1;
            alu_m2_sel_t        alu_input_2;
            rd_v_sel_t          rd_v_sel;

    assign funct3 = inst[14:12];
    assign funct7 = inst[31:25];
    assign opcode = inst[6:0];
    assign i_imm  = {{21{inst[31]}}, inst[30:20]};
    assign s_imm  = {{21{inst[31]}}, inst[30:25], inst[11:7]};
    assign b_imm  = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
    assign u_imm  = {inst[31:12], 12'h000};
    assign j_imm  = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
    assign rd_s   = inst[11:7];

always_comb begin
    imm = '0;
    cmpop = '0;
    aluop = '0;
    rd_s_store = '0;
    jump_flag_decode = '0;

    unique case ( opcode ) 
        op_b_lui: begin
            imm = u_imm;
            regf_we = 1'b1;
            alu_input_1 = pc_out;
            alu_input_2 = imm_out;
            rd_v_sel = imm_only_out;
            rs1_s = '0;
            rs2_s = '0;
        end
        op_b_auipc: begin
            alu_input_1 = pc_out;
            alu_input_2 = imm_out;
            imm = u_imm;
            regf_we = 1'b1;
            aluop = alu_op_add;
            rd_v_sel = pc_imm_out;
            rs1_s = '0;
            rs2_s = '0;
        end 
        op_b_imm: begin
            alu_input_1 = rs1_out;
            alu_input_2 = imm_out;
            imm = i_imm;
            rs1_s = inst[19:15];
            rs2_s = '0;
            unique case ( funct3 )
                arith_f3_slt: begin
                    cmpop = branch_f3_blt;
                    rd_v_sel = br_en_out;
                end
                arith_f3_sltu: begin
                    cmpop = branch_f3_bltu;
                    rd_v_sel = br_en_out;
                end 
                arith_f3_sr: begin
                    if ( funct7[5] ) begin
                        aluop = alu_op_sra;
                    end 
                    else begin
                        aluop = alu_op_srl;
                    end 
                    rd_v_sel = aluout_out;
                end 
                
                default: begin
                    aluop = funct3;
                    rd_v_sel = aluout_out;
                end 
            endcase 

            regf_we = 1'b1;
        end 

        op_b_reg: begin
            alu_input_1 = rs1_out;
            alu_input_2 = rs2_out;
            rs1_s = inst[19:15];
            rs2_s = inst[24:20];
            unique case ( funct3 )
                arith_f3_slt: begin
                    cmpop = branch_f3_blt;
                    rd_v_sel = br_en_out;
                end 
                arith_f3_sltu: begin
                    cmpop = branch_f3_bltu;
                    rd_v_sel = br_en_out;
                end 
                arith_f3_sr: begin
                    if ( funct7[5] ) begin
                        aluop = alu_op_sra;
                    end else begin 
                        aluop = alu_op_srl;
                    end 
                    rd_v_sel = aluout_out;
                end 
                arith_f3_add: begin 
                    if( funct7[5] ) begin
                        aluop = alu_op_sub;
                    end else begin
                        aluop = alu_op_add;
                    end 
                    rd_v_sel = aluout_out;
                end 
                default: begin
                    aluop = funct3;
                    rd_v_sel = aluout_out;
                end 
            endcase 

            regf_we = 1'b1;
        end 

        op_b_load: begin
            imm = i_imm;
            alu_input_1 = rs1_out;
            alu_input_2 = imm_out;
            aluop = alu_op_add;
            rs1_s = inst[19:15];
            rs2_s = '0;
            regf_we = 1'b1;
            rd_v_sel = br_en_out;
        end

        op_b_store: begin
            imm = s_imm;
            alu_input_1 = rs1_out;
            alu_input_2 = imm_out;
            aluop = alu_op_add;
            rs1_s = inst[19:15]; 
            rs2_s = inst[24:20];
            regf_we = 1'b0;
            rd_v_sel = br_en_out;
            rd_s_store = '0;
        end

        op_b_jal: begin
            alu_input_1 = pc_out;
            alu_input_2 = imm_out;
            aluop = alu_op_add;
            regf_we = 1'b1;
            imm = j_imm;
            rs1_s = '0;
            rs2_s = '0;
            rd_v_sel = br_en_out;
            jump_flag_decode = 1'b1;
        end

        op_b_jalr: begin
            alu_input_1 = rs1_out;
            alu_input_2 = imm_out;
            regf_we = 1'b1;
            rs1_s = inst[19:15];
            rs2_s = '0;
            imm = i_imm;
            aluop = alu_op_add;
            rd_v_sel = br_en_out;
            jump_flag_decode = 1'b1;
        end

        op_b_br: begin
            cmpop = funct3;
            alu_input_1 = rs1_out;
            alu_input_2 = rs2_out;
            regf_we = 1'b0;
            imm = b_imm;
            rs1_s = inst[19:15];
            rs2_s = inst[24:20];
            rd_v_sel = br_en_out;
            
        end
        // Multiply, divide, and remainder operations are the same opcode as op_b_reg so should be accounted for already
        default: begin
            regf_we = 1'b0;
            imm = '0;
            cmpop = '0;
            aluop = '0;
            alu_input_1 = pc_out;
            alu_input_2 = imm_out;
            rd_v_sel = br_en_out;
            rs1_s = '0;
            rs2_s = '0;
            jump_flag_decode = 1'b0;
        end 
    endcase 
end 

always_ff @( posedge clk ) begin
    if ( rst || jump_commit ) begin
        decode_rename_reg.pc <= '0;
        decode_rename_reg.inst <= '0;
        decode_rename_reg.regf_we <= '0;
        decode_rename_reg.imm <= '0;
        decode_rename_reg.cmpop <= '0;
        decode_rename_reg.aluop <= '0;
        decode_rename_reg.rd_s <= '0;
        decode_rename_reg.pc_next <= '0;
        decode_rename_reg.commit <= '0;
        decode_rename_reg.rs1_s <= '0;
        decode_rename_reg.rs2_s <= '0;
        decode_rename_reg.alu_m1_sel <= pc_out;
        decode_rename_reg.alu_m2_sel <= imm_out;
        decode_rename_reg.rd_v_sel <= br_en_out;            // this has no significance but avoid latch
        decode_rename_reg.load_sel <= load_f3_lb;           // ^^
        decode_rename_reg.store_sel <= store_f3_sb;         // ^^
        decode_rename_reg.jump_flag <= '0;
        decode_rename_reg.btb_addr <= '0;
        decode_rename_reg.br_prediction <= '0;
        decode_rename_reg.btb_valid_out <= '0;
        decode_rename_reg.predictor_valid_out <= '0;
        decode_rename_reg.predictor_index <= '0;
    end 
    else if ( iqueue_out_valid ) begin
        decode_rename_reg.pc <= pc;
        decode_rename_reg.inst <= inst;
        decode_rename_reg.regf_we <= regf_we;
        decode_rename_reg.imm <= imm;
        decode_rename_reg.cmpop <= cmpop;
        decode_rename_reg.aluop <= aluop;

        if ( inst[6:0] == op_b_store || inst[6:0] == op_b_br ) begin
            decode_rename_reg.rd_s <= rd_s_store;
        end 
        else begin
            decode_rename_reg.rd_s <= rd_s;
        end

        decode_rename_reg.alu_m1_sel <= alu_input_1;
        decode_rename_reg.alu_m2_sel <= alu_input_2;
        decode_rename_reg.rd_v_sel <= rd_v_sel;
        decode_rename_reg.pc_next <= pc_next;
        decode_rename_reg.rs1_s <= rs1_s;
        decode_rename_reg.rs2_s <= rs2_s;
        decode_rename_reg.commit <= '1;                     // was previously imem_resp!!! not sure what it should be now since we are pulling from a queue it should be fine as 1 but worry later
        decode_rename_reg.load_sel <= load_f3_t'( funct3 );
        decode_rename_reg.store_sel <= store_f3_t'( funct3 );
        decode_rename_reg.jump_flag <= jump_flag_decode;

        decode_rename_reg.btb_addr <= btb_addr;
        decode_rename_reg.br_prediction <= br_prediction;
        decode_rename_reg.btb_valid_out <= btb_valid_out;
        decode_rename_reg.predictor_valid_out <= predictor_valid_out;
        decode_rename_reg.predictor_index <= predictor_index;
    end
    else if (!iqueue_out_valid) begin
        decode_rename_reg <= '0;
    end
end

endmodule: decode

