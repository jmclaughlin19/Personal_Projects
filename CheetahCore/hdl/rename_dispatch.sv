module rename_dispatch 
import rv32i_types::*;
                        #( parameter DATA_WIDTH = 6, 
                           parameter ROB_DATA_WIDTH = 12,
                           parameter ROB_DEPTH = 16 )
(
    // From decode, contains relevant instruction info
    input   id_ex_stage_reg_t                   decode_rename_reg,
    // From ROB, receive index mapped
    input   logic   [$clog2( ROB_DEPTH ) - 1:0] rob_idx_in,
    // From free list, receive dequeued data
    input   logic   [DATA_WIDTH-1:0]            free_list_pd,
    // From RAT, receive mappings
    input   logic   [DATA_WIDTH-1:0]            ps1,
    input   logic                               ps1_valid,
    input   logic   [DATA_WIDTH-1:0]            ps2,
    input   logic                               ps2_valid,

    // To free list, trigger dequeue
    output  logic                               free_list_dequeue,
    // To RAT, request mappings     
    output  logic   [4:0]                       rs1,
    output  logic   [4:0]                       rs2,
    // To RAT, update mapping for destination reg
    output  logic   [4:0]                       rd,
    output  logic   [DATA_WIDTH-1:0]            pd,
    // Active high      
    output  logic                               regf_we,
    // To reservation stations, contains relevant meta data 
    output  alu_rs_data_t                       alu_rs_data,
    output  mul_rs_data_t                       mul_rs_data,
    output  div_rs_data_t                       div_rs_data,
    output  mem_rs_data_t                       mem_rs_data,
    output  br_rs_data_t                        br_rs_data,
    // To ROB, enqueue the mapppings for dispatched instruction
    output  logic                               enqueue,
    output  logic   [ROB_DATA_WIDTH-1:0]        rob_data_out,
    
    input   logic                               jump_commit,
    // To register file
    output  logic   [DATA_WIDTH - 1: 0]     ps1_out_mem,
    output  logic   [DATA_WIDTH - 1: 0]     ps2_out_mem
);
       
            logic   [6:0]               opcode;
            logic   [6:0]               funct7;
            logic   [2:0]               funct3;

always_comb begin
    free_list_dequeue = '0;
    rd = 'x;
    // Physical destination reg
    pd = 'x;
    rob_data_out = '0;
    enqueue = '0;
    regf_we = '0;

    funct7 = decode_rename_reg.inst[31:25];
    funct3 = decode_rename_reg.inst[14:12];

    alu_rs_data = '0;
    mul_rs_data = '0;
    div_rs_data = '0;
    mem_rs_data = '0;
    br_rs_data = '0;
    ps1_out_mem = '0;
    ps2_out_mem = '0;

    // If write enable, set outputs to ROB
    if ( decode_rename_reg.regf_we && !jump_commit ) begin
        // If rd = 0, prevent free list dequeue since 0 -> 0 is a fixed mapping
        rd = decode_rename_reg.rd_s;
        if ( rd != '0 ) begin
            free_list_dequeue = '1;
            pd = free_list_pd;
            regf_we = '1;
        end
        else begin
            pd = '0;
            regf_we = '0;
        end

        rob_data_out = {1'b0, rd, pd}; // check that 0 here is lsb
        enqueue = 1'b1;
    end

    // If write enable, set outputs to ROB
    if ( ( decode_rename_reg.inst[6:0] == op_b_store ||  decode_rename_reg.inst[6:0] == op_b_br ) && !jump_commit ) begin
        free_list_dequeue = '0;
        rd = '0;
        pd = '0;
        regf_we = '0;
        rob_data_out = {1'b0, rd, pd}; // check that 0 here is lsb
        enqueue = 1'b1;
    end

    rs1 = decode_rename_reg.rs1_s;
    rs2 = decode_rename_reg.rs2_s;
    
    // Output ps1 and ps2 to reservation stations if valid
    opcode = decode_rename_reg.inst[6:0];

    if ( jump_commit ) begin
        free_list_dequeue = '0;
        rs1 = '0;
        rs2 = '0;
        rd = '0;
        pd = '0;
        regf_we = '0;
        alu_rs_data = '0;
        mul_rs_data = '0;
        div_rs_data = '0;
        mem_rs_data = '0;
        br_rs_data = '0;
        enqueue = '0;
        rob_data_out = '0;
        opcode = '0;
        funct3 = '0;
        funct7 = '0;
    end
    // ADD, MUL, DIV reservation stations
    else if ( opcode == op_b_auipc ||
         opcode == op_b_imm || 
         opcode == op_b_lui ||
         opcode == op_b_reg ) begin

        if ( funct7 == 7'b0000001 && opcode == op_b_reg ) begin
                        
            if ( funct3 == 3'b000 || funct3 == 3'b001 || funct3 == 3'b010 || funct3 == 3'b011) begin
                mul_rs_data.valid = '1;
                mul_rs_data.ps1 = ps1;
                mul_rs_data.ps1_ready = ps1_valid;
                mul_rs_data.ps2 = ps2;
                mul_rs_data.ps2_ready = ps2_valid;
                mul_rs_data.rd = rd;
                mul_rs_data.pd = pd;
                mul_rs_data.rob_idx = rob_idx_in;
                mul_rs_data.inst = decode_rename_reg.inst;
                mul_rs_data.pc_next = decode_rename_reg.pc_next;
                mul_rs_data.rs1_s = decode_rename_reg.rs1_s;
                mul_rs_data.rs2_s = decode_rename_reg.rs2_s;
                mul_rs_data.pc = decode_rename_reg.pc;
            end
            else if ( funct3 == 3'b100 || funct3 == 3'b101 || funct3 == 3'b110 || funct3 == 3'b111 ) begin
                div_rs_data.valid = '1;
                div_rs_data.ps1 = ps1;
                div_rs_data.ps1_ready = ps1_valid;
                div_rs_data.ps2 = ps2;
                div_rs_data.ps2_ready = ps2_valid;
                div_rs_data.rd = rd;
                div_rs_data.pd = pd;
                div_rs_data.rob_idx = rob_idx_in;
                div_rs_data.inst = decode_rename_reg.inst;
                div_rs_data.pc_next = decode_rename_reg.pc_next;
                div_rs_data.rs1_s = decode_rename_reg.rs1_s;
                div_rs_data.rs2_s = decode_rename_reg.rs2_s;
                div_rs_data.pc = decode_rename_reg.pc;
            end
        end
        else begin    
            alu_rs_data.valid = '1;
            alu_rs_data.pc = decode_rename_reg.pc;

            
            alu_rs_data.ps1 = ps1;
            alu_rs_data.ps1_ready = ps1_valid;

            // If using imm, skip checking ps2
            if ( decode_rename_reg.alu_m2_sel == imm_out ) begin
                alu_rs_data.ps2 = '0;
                alu_rs_data.ps2_ready = '1;
            end
            else begin
                alu_rs_data.ps2 = ps2;
                alu_rs_data.ps2_ready = ps2_valid;
            end

            alu_rs_data.rd = rd;
            alu_rs_data.pd = pd;

            alu_rs_data.rob_idx = rob_idx_in;

            alu_rs_data.imm = decode_rename_reg.imm;
            alu_rs_data.aluop = decode_rename_reg.aluop;

            alu_rs_data.alu_m1_sel = decode_rename_reg.alu_m1_sel;
            alu_rs_data.alu_m2_sel = decode_rename_reg.alu_m2_sel;

            alu_rs_data.inst = decode_rename_reg.inst;
            alu_rs_data.cmpop = decode_rename_reg.cmpop;

            alu_rs_data.pc_next = decode_rename_reg.pc_next;
            alu_rs_data.rs1_s = decode_rename_reg.rs1_s;
            alu_rs_data.rs2_s = decode_rename_reg.rs2_s;
        end
    end
    else if ( opcode == op_b_load || opcode == op_b_store ) begin
        mem_rs_data.aluop = decode_rename_reg.aluop;
        mem_rs_data.valid = '1;
        mem_rs_data.ps1 = ps1;
        mem_rs_data.ps1_ready = ps1_valid;
        mem_rs_data.ps2 = ps2;
        mem_rs_data.ps2_ready = ps2_valid;
        mem_rs_data.rd = rd;
        mem_rs_data.pd = pd;
        mem_rs_data.rob_idx = rob_idx_in;
        mem_rs_data.inst = decode_rename_reg.inst;
        mem_rs_data.pc_next = decode_rename_reg.pc_next;
        mem_rs_data.rs1_s = decode_rename_reg.rs1_s;
        mem_rs_data.rs2_s = decode_rename_reg.rs2_s;
        mem_rs_data.pc = decode_rename_reg.pc;
        mem_rs_data.imm = decode_rename_reg.imm;
        ps1_out_mem = ps1;
        ps2_out_mem = ps2;
    end
    else if ( opcode == op_b_br || opcode == op_b_jal || opcode == op_b_jalr ) begin
        br_rs_data.aluop = decode_rename_reg.aluop;
        br_rs_data.valid = '1;
        br_rs_data.ps1 = ps1;
        br_rs_data.ps1_ready = ps1_valid;
        br_rs_data.ps2 = ps2;
        br_rs_data.ps2_ready = ps2_valid;
        br_rs_data.rd = rd;
        br_rs_data.pd = pd;
        br_rs_data.rob_idx = rob_idx_in;
        br_rs_data.inst = decode_rename_reg.inst;
        br_rs_data.pc_next = decode_rename_reg.pc_next;
        br_rs_data.rs1_s = decode_rename_reg.rs1_s;
        br_rs_data.rs2_s = decode_rename_reg.rs2_s;
        br_rs_data.pc = decode_rename_reg.pc;
        br_rs_data.imm = decode_rename_reg.imm;
        br_rs_data.cmpop = decode_rename_reg.cmpop;
        br_rs_data.alu_m1_sel = decode_rename_reg.alu_m1_sel;
        br_rs_data.alu_m2_sel = decode_rename_reg.alu_m2_sel;

        br_rs_data.btb_addr = decode_rename_reg.btb_addr;
        br_rs_data.br_prediction = decode_rename_reg.br_prediction;
        br_rs_data.btb_valid_out = decode_rename_reg.btb_valid_out;
        br_rs_data.predictor_valid_out = decode_rename_reg.predictor_valid_out;
        br_rs_data.predictor_index = decode_rename_reg.predictor_index;
    end
end

endmodule : rename_dispatch


