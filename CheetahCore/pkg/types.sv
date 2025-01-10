
package cache_types;


    typedef struct packed {
        logic   [31:0]  addr;
        logic   [3:0]   rmask;
        logic   [3:0]  wmask;
        logic   [31:0] wdata;

    } shadow_reg_t;


endpackage

package cache_types_l2;


    typedef struct packed {
        logic   [31:0]  addr;
        logic   [3:0]   rmask;
        logic   [3:0]  wmask;
        logic   [255:0] wdata;

    } shadow_reg_t;


endpackage

package rv32i_types;

    localparam int VALID_ARRAY_S_INDEX              = 4;
    localparam int VALID_ARRAY_WIDTH                = 1;

    localparam int LRU_ARRAY_S_INDEX                = 4;
    localparam int LRU_ARRAY_WIDTH                  = 3;

    localparam int RAT_NUM_REGS_TOP                 = 64;
    localparam int RAT_PS_WIDTH_TOP                 = $clog2( RAT_NUM_REGS_TOP );

    localparam int QUEUE_DATA_WIDTH_TOP             = 140;  // previously 96
    localparam int QUEUE_DEPTH_TOP                  = 16;

    localparam int FREE_LIST_DATA_WIDTH_TOP         = RAT_PS_WIDTH_TOP;
    localparam int FREE_LIST_DEPTH_TOP              = 64;

    localparam int RENAME_DISPATCH_DATA_WIDTH_TOP   = FREE_LIST_DATA_WIDTH_TOP;

    localparam int ROB_DATA_WIDTH_TOP               = RAT_PS_WIDTH_TOP + 5 + 1;
    localparam int ROB_DEPTH_TOP                    = 16;

    localparam int ALU_RS_DEPTH_TOP                 = 8;
    localparam int MUL_RS_DEPTH_TOP                 = 8; 
    localparam int DIV_RS_DEPTH_TOP                 = 8; 
    localparam int MEM_RS_DEPTH_TOP                 = 8;
    localparam int BR_RS_DEPTH_TOP                  = 8;

    localparam int RS_DATA_WIDTH_TOP                = RAT_PS_WIDTH_TOP;

    localparam int REG_DATA_WIDTH_TOP               = RAT_PS_WIDTH_TOP;

    localparam int EXECUTE_DATA_WIDTH_TOP           = RAT_PS_WIDTH_TOP;

    localparam int CDB_DATA_WIDTH_TOP               = RAT_PS_WIDTH_TOP;

    typedef enum logic {
        rs1_out = 1'b0,
        pc_out  = 1'b1
    } alu_m1_sel_t;

    typedef enum logic {
        imm_out = 1'b0,
        rs2_out = 1'b1
    } alu_m2_sel_t;

    typedef enum logic [1:0] {
        br_en_out       = 2'b00,
        aluout_out      = 2'b01,
        imm_only_out    = 2'b10,
        pc_imm_out      = 2'b11
    } rd_v_sel_t;

    typedef enum logic [2:0] {
        load_f3_lb     = 3'b000,
        load_f3_lh     = 3'b001,
        load_f3_lw     = 3'b010,
        load_f3_lbu    = 3'b100,
        load_f3_lhu    = 3'b101
    } load_f3_t;


    typedef enum logic [2:0] {
        store_f3_sb    = 3'b000,
        store_f3_sh    = 3'b001,
        store_f3_sw    = 3'b010
    } store_f3_t;

    typedef struct packed {
        logic   [31:0]      inst;
        logic   [31:0]      pc;
        logic   [31:0]      pc_next;
        logic               commit;

        // control signals
        logic               regf_we; 
        logic   [31:0]      imm;
        logic   [2:0]       cmpop;
        logic   [2:0]       aluop;
        logic   [4:0]       rd_s;
        logic   [4:0]       rs1_s;
        logic   [4:0]       rs2_s;

        logic               jump_flag;

        alu_m1_sel_t        alu_m1_sel;
        alu_m2_sel_t        alu_m2_sel;
        rd_v_sel_t          rd_v_sel;
        load_f3_t           load_sel;
        store_f3_t          store_sel;

        // for branch prediction
        logic   [31:0]      btb_addr;
        logic   [1:0]       br_prediction;
        logic               btb_valid_out;
        logic               predictor_valid_out;
        logic   [7:0]       predictor_index;

    } id_ex_stage_reg_t;


    typedef struct packed {
        logic   [31:0]      inst;
        logic   [31:0]      pc;
        logic   [63:0]      order;
        logic   [31:0]        pc_next;
        logic               commit;
  

        // control signals
        logic               regf_we; 
        logic   [4:0]       rd_s;
        logic   [31:0]      rd_v;
        logic   [4:0]       rs1_s;
        logic   [4:0]       rs2_s;
        logic   [31:0]      rs1_v;
        logic   [31:0]      rs2_v;
        logic   [31:0]  dmem_addr;
        logic   [3:0]   dmem_rmask;
        logic   [31:0]  dmem_wdata;
        logic   [3:0]   dmem_wmask;

        load_f3_t load_sel;
    } ex_mm_stage_reg_t;


    typedef struct packed {
        logic   [31:0]      inst;
        logic   [31:0]      pc;
        logic   [63:0]      order;
        logic   [31:0]      pc_next;
        logic               commit;
    
        logic               regf_we; 
        logic   [4:0]       rd_s;
        logic   [31:0]      rd_v;
        logic   [4:0]       rs1_s;
        logic   [4:0]       rs2_s;
        logic   [31:0]      rs1_v;
        logic   [31:0]      rs2_v;
        logic   [31:0]  dmem_addr;
        logic   [3:0]   dmem_rmask;
        logic   [31:0]  dmem_rdata;
        logic   [31:0]  dmem_wdata;
        logic   [3:0]   dmem_wmask;

    } mm_wb_stage_reg_t;


    typedef struct packed {
       
        logic   [31:0]      pc;
        logic   [63:0]      order;
        logic   [31:0]      pc_next;

        logic               jump_ignore;

    } if_id_stage_reg_t;

    typedef enum logic [6:0] {
        //add
        op_b_lui       = 7'b0110111, // load upper immediate (U type)
        op_b_auipc     = 7'b0010111, // add upper immediate PC (U type)
        // br
        op_b_jal       = 7'b1101111, // jump and link (J type)
        op_b_jalr      = 7'b1100111, // jump and link register (I type)
        op_b_br        = 7'b1100011, // branch (B type)
        // mem
        op_b_load      = 7'b0000011, // load (I type)
        op_b_store     = 7'b0100011, // store (S type)
        // add
        op_b_imm       = 7'b0010011, // arith ops with register/immediate operands (I type)
        // add/mul/div
        // mul/div -> funct7 = 0000001
        op_b_reg       = 7'b0110011  // arith ops with register operands (R type)
    } rv32i_opcode;

    typedef enum logic [2:0] {
        arith_f3_add   = 3'b000, // check logic 30 for sub if op_reg op
        arith_f3_sll   = 3'b001,
        arith_f3_slt   = 3'b010,
        arith_f3_sltu  = 3'b011,
        arith_f3_xor   = 3'b100,
        arith_f3_sr    = 3'b101, // check logic 30 for logical/arithmetic
        arith_f3_or    = 3'b110,
        arith_f3_and   = 3'b111
    } arith_f3_t;

    typedef enum logic [2:0] {
        branch_f3_beq  = 3'b000,
        branch_f3_bne  = 3'b001,
        branch_f3_blt  = 3'b100,
        branch_f3_bge  = 3'b101,
        branch_f3_bltu = 3'b110,
        branch_f3_bgeu = 3'b111
    } branch_f3_t;
    
typedef enum logic [6:0] {
        base           = 7'b0000000,
        variant        = 7'b0100000,
        extension      = 7'b0000001
    } funct7_t;

    typedef enum logic [2:0] {
        alu_op_add     = 3'b000,
        alu_op_sll     = 3'b001,
        alu_op_sra     = 3'b010,
        alu_op_sub     = 3'b011,
        alu_op_xor     = 3'b100,
        alu_op_srl     = 3'b101,
        alu_op_or      = 3'b110,
        alu_op_and     = 3'b111
    } alu_ops;

    typedef union packed {
        logic [31:0] word;

        struct packed {
            logic [11:0] i_imm;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  rd;
            rv32i_opcode opcode;
        } i_type;

        struct packed {
            logic [6:0]  funct7;
            logic [4:0]  rs2;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  rd;
            rv32i_opcode opcode;
        } r_type;

        struct packed {
            logic [11:5] imm_s_top;
            logic [4:0]  rs2;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  imm_s_bot;
            rv32i_opcode opcode;
        } s_type;

        struct packed {
         // Fill this out to get branches running!
            logic [11:5] imm_b_top_11_5;
            logic [4:0] rs2;
            logic [4:0] rs1;
            logic [2:0] funct3;
            logic [4:0] imm_b_bot_4_0;
            rv32i_opcode opcode;
        } b_type; 

        struct packed {
            logic [31:12] imm;
            logic [4:0]   rd;
            rv32i_opcode  opcode;
        } j_type;

    } instr_t;

    typedef struct packed {
        logic                                   valid;
        logic   [RAT_PS_WIDTH_TOP - 1:0]            ps1;
        logic                                   ps1_ready;

        logic   [RAT_PS_WIDTH_TOP - 1:0]            ps2;
        logic                                   ps2_ready;     

        logic   [RAT_PS_WIDTH_TOP - 1:0]            pd;
        logic   [4:0]                           rd; 

        logic   [$clog2( ROB_DEPTH_TOP ) - 1: 0]    rob_idx;

        logic   [31:0]                          imm;
        logic   [2:0]                           aluop;                       
        alu_m1_sel_t                            alu_m1_sel;
        alu_m2_sel_t                            alu_m2_sel;

        logic   [31:0]                          inst;
        logic   [2:0]                           cmpop;
        logic   [31:0]                          pc;

        // Signals needed for RVFI
        logic   [31:0]                          pc_next;
        logic   [4:0]                           rs1_s;
        logic   [4:0]                           rs2_s;

        int                                     alu_count;
    } alu_rs_data_t;

    typedef struct packed {
        logic                                   valid;
        logic   [RAT_PS_WIDTH_TOP - 1:0]            ps1;
        logic                                   ps1_ready;

        logic   [RAT_PS_WIDTH_TOP - 1:0]            ps2;
        logic                                   ps2_ready;     

        logic   [RAT_PS_WIDTH_TOP - 1:0]            pd;
        logic   [4:0]                           rd; 

        logic   [$clog2( ROB_DEPTH_TOP ) - 1: 0]    rob_idx;


        logic   [31:0]                          inst;


        // Signals needed for RVFI
        logic   [31:0]                          pc;
        logic   [31:0]                          pc_next;
        logic   [4:0]                           rs1_s;
        logic   [4:0]                           rs2_s;
        int                                     mul_count;

    } mul_rs_data_t;

    typedef struct packed {
        logic                                   valid;
        logic   [RAT_PS_WIDTH_TOP - 1:0]            ps1;
        logic                                   ps1_ready;

        logic   [RAT_PS_WIDTH_TOP - 1:0]            ps2;
        logic                                   ps2_ready;     

        logic   [RAT_PS_WIDTH_TOP - 1:0]            pd;
        logic   [4:0]                           rd; 

        logic   [$clog2( ROB_DEPTH_TOP ) - 1: 0]    rob_idx;


        logic   [31:0]                          inst;


        // Signals needed for RVFI
        logic   [31:0]                          pc;
        logic   [31:0]                          pc_next;
        logic   [4:0]                           rs1_s;
        logic   [4:0]                           rs2_s;
        int                                     div_count;

    } div_rs_data_t;


    typedef struct packed {
        logic                                       valid;
        logic   [RAT_PS_WIDTH_TOP - 1:0]            ps1;
        logic                                       ps1_ready;

        logic   [RAT_PS_WIDTH_TOP - 1:0]            ps2;
        logic                                       ps2_ready;     

        logic   [RAT_PS_WIDTH_TOP - 1:0]            pd;
        logic   [4:0]                               rd; 

        logic   [$clog2( ROB_DEPTH_TOP ) - 1: 0]    rob_idx;


        logic   [31:0]                              inst;
        logic   [2:0]                               aluop; 
        logic   [31:0]                              imm;
                      

        // Signals needed for RVFI
        logic   [31:0]                              pc;
        logic   [31:0]                              pc_next;
        logic   [4:0]                               rs1_s;
        logic   [4:0]                               rs2_s;

        logic   [MEM_RS_DEPTH_TOP - 1:0]            store_count;

        logic   [31:0]                              ps1_v;
        logic   [31:0]                              ps2_v;
        logic   [31:0]                              mem_addr;
        logic   [3:0]                               mem_rmask;
        logic                                       load_data_valid;
        logic   [31:0]                              load_data_rdata;
        int                                         ld_count;


    } mem_rs_data_t;

    typedef struct packed {
        logic                                       valid;
        logic   [RAT_PS_WIDTH_TOP - 1:0]            ps1;
        logic                                       ps1_ready;

        logic   [RAT_PS_WIDTH_TOP - 1:0]            ps2;
        logic                                       ps2_ready;     

        logic   [RAT_PS_WIDTH_TOP - 1:0]            pd;
        logic   [4:0]                               rd; 

        alu_m1_sel_t                            alu_m1_sel;
        alu_m2_sel_t                            alu_m2_sel;

        logic   [$clog2( ROB_DEPTH_TOP ) - 1: 0]    rob_idx;


        logic   [31:0]                              inst;
        logic   [2:0]                               aluop; 
        logic   [31:0]                              imm;
                      

        // Signals needed for RVFI
        logic   [31:0]                              pc;
        logic   [31:0]                              pc_next;
        logic   [4:0]                               rs1_s;
        logic   [4:0]                               rs2_s;

        logic   [2:0]                               cmpop;

        // branch predictor signals
        logic   [31:0]                              btb_addr;
        logic   [1:0]                               br_prediction;
        logic                                       btb_valid_out;
        logic                                       predictor_valid_out;
        logic   [7:0]                               predictor_index;

    } br_rs_data_t;

    typedef struct packed {
        logic   alu_rs_full;
        logic   mul_rs_full;
        logic   div_rs_full;
        logic   mem_rs_full;
        logic   br_rs_full;
        logic   ld_rs_full;
    } rs_full_t;

    typedef struct packed {
        logic   alu_rs_select;  
        logic   mul_rs_select;  
        logic   div_rs_select;  
        logic   mem_rs_select; 
        logic   br_rs_select;   
    } rs_select_t;

    typedef enum logic [2:0] {
        alu     = 3'b000,
        mul     = 3'b001,
        div     = 3'b010,
        mem     = 3'b011,
        br      = 3'b100
    } rs_t;

    typedef struct packed {
        logic               valid;
        logic   [63:0]      order;
        logic   [31:0]      inst;
        logic   [4:0]       rs1_addr;
        logic   [4:0]       rs2_addr;
        logic   [31:0]      rs1_v;
        logic   [31:0]      rs2_v;
        logic   [4:0]       rd_addr;
        logic   [31:0]      rd_wdata;
        logic   [31:0]      pc_rdata;
        logic   [31:0]      pc_wdata;
        // ADD MEM AND FRD VALUES WHEN IMPLEMENTED
        logic   [31:0]      mem_addr;
        logic   [3:0]       mem_rmask;
        logic   [3:0]       mem_wmask;
        logic   [31:0]      mem_rdata;
        logic   [31:0]      mem_wdata;

        logic               jump;
    } rvfi_t;


    typedef enum logic [1:0] {
        IDLE = 2'b00,       // Waiting for a new request
        INIT = 2'b01,      // Initialize the divider
        WAITING = 2'b10    // Wait for the divider to complete
    } state_t;

endpackage
