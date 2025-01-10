module cpu
import rv32i_types::*;
(
    input   logic                               clk,
    input   logic                               rst,

    output  logic   [31:0]                      bmem_addr,
    output  logic                               bmem_read,
    output  logic                               bmem_write,
    output  logic   [63:0]                      bmem_wdata,
    input   logic                               bmem_ready,

    input   logic   [31:0]                      bmem_raddr,
    input   logic   [63:0]                      bmem_rdata,
    input   logic                               bmem_rvalid
);              
            logic   [31:0]                      pc;
            logic   [3:0]                       ufp_rmask;
            logic   [3:0]                       ufp_wmask;
            logic   [31:0]                      ufp_wdata;
            logic   [31:0]                      ufp_rdata;
            logic                               ufp_resp;

            logic                               ufp_resp_reg;  

            // Queue signals
            logic    [139:0]                    iqueue_out;
            logic                               iqueue_empty;
            logic                               iqueue_full; 
            logic                               iqueue_out_valid;

            id_ex_stage_reg_t                   decode_rename_reg;

            logic   [31:0]                      pc_next;

            logic                               free_list_dequeue;
            logic                               free_list_empty;
            logic   [FREE_LIST_DATA_WIDTH_TOP-1: 0] free_list_pd;
            logic                               free_list_full;

            logic   [4:0]                       rat_rs1;
            logic   [FREE_LIST_DATA_WIDTH_TOP-1:0]  rat_ps1;
            logic                               rat_ps1_valid;
            logic   [4:0]                       rat_rs2;
            logic   [FREE_LIST_DATA_WIDTH_TOP-1:0]  rat_ps2;
            logic                               rat_ps2_valid;
            logic   [4:0]                       rename_dispatch_rd;
            logic   [FREE_LIST_DATA_WIDTH_TOP-1:0]  rename_dispatch_pd;
            logic                               rename_dispatch_regf_we;

            logic                               rob_enqueue;
            logic   [ROB_DATA_WIDTH_TOP-1:0]    rob_data_rename_dispatch;
            logic   [$clog2(ROB_DEPTH_TOP)-1:0] rob_idx_rename_dispatch;
            logic                               rob_empty;
            logic                               rob_full;
            logic                               rob_data_out_valid;
            logic   [ROB_DATA_WIDTH_TOP - 1:0]  rob_data_out;

            alu_rs_data_t                       alu_rs_data;
            alu_rs_data_t                       alu_unit_data;
            mul_rs_data_t                       mul_rs_data;
            mul_rs_data_t                       mul_unit_data;
            mem_rs_data_t                       mem_rs_data;
            mem_rs_data_t                       mem_unit_data;
            div_rs_data_t                       div_rs_data;
            div_rs_data_t                       div_unit_data; 
            br_rs_data_t                        br_rs_data;
            br_rs_data_t                        br_unit_data;

            logic   [RAT_PS_WIDTH_TOP - 1: 0]     ps1_out_alu;
            logic   [RAT_PS_WIDTH_TOP - 1: 0]     ps2_out_alu;
            logic   [RAT_PS_WIDTH_TOP - 1: 0]     ps1_out_mem;
            logic   [RAT_PS_WIDTH_TOP - 1: 0]     ps2_out_mem;
            logic   [RAT_PS_WIDTH_TOP - 1: 0]     ps1_out_div;
            logic   [RAT_PS_WIDTH_TOP - 1: 0]     ps2_out_div;
            logic   [RAT_PS_WIDTH_TOP - 1: 0]     ps1_out_mul;
            logic   [RAT_PS_WIDTH_TOP - 1: 0]     ps2_out_mul;
            logic   [RAT_PS_WIDTH_TOP - 1: 0]     ps1_out_br;
            logic   [RAT_PS_WIDTH_TOP - 1: 0]     ps2_out_br;

            logic                           rs_full_alu;
            logic                           rs_full_mul;
            logic                           rs_full_mem;
            logic                           rs_full_div;
            logic                           rs_full_br;
            logic                           rs_full_ld;

            logic   [31:0]                      pd_v_broadcast;
            logic   [4:0]                       rd_broadcast;
            logic   [RAT_PS_WIDTH_TOP - 1:0]        pd_broadcast;
            logic   [$clog2(ROB_DEPTH_TOP) - 1:0]   rob_idx_broadcast;
            logic   [$clog2(ROB_DEPTH_TOP) - 1:0]   rvfi_rob_idx_out;


            logic                               regf_we_reg;
            logic                               execute_valid_out;
            logic                               regf_we_broadcast;
            logic                               wakeup_broadcast;
            logic                               update_rat_broadcast;
            logic                               ready_to_commit_broadcast;

            logic   [RAT_PS_WIDTH_TOP - 1:0]    rrf_pd;
            logic                               free_list_enqueue;

            logic   [31:0]                      ps1_v[5], ps2_v[5];

            logic                           rs_select_alu;
            logic                           rs_select_mul;
            logic                           rs_select_mem;
            logic                           rs_select_div;
            logic                           rs_select_br;
            
            rvfi_t                              rvfi_ex;

            logic                               signed_flag;
            logic   [32:0]                      multiply_operand_a, multiply_operand_b;
            logic   [65:0]                      multiplier_output_66;
            // logic   [65:0]                      multiplier_output_66_mulhsu;
            logic                               multiplier_output_valid;

            logic   [1:0]                       mul_shift_reg;
            logic                               div_rem_sign_flag;
            logic   [32:0]                      div_rem_operand_a;
            logic   [32:0]                      div_rem_operand_b;
            logic                               complete_inst_signed;
            logic   [32:0]                      quotient_signed;
            logic   [32:0]                      remainder_signed;
            logic                               divide_by_0_signed;
            logic                               hold;
            logic                               start;


            state_t                             division_state;


            // mem insts
            logic   [31:0]                      dmem_addr;
            logic   [3:0]                       dmem_rmask;
            logic   [31:0]                      dmem_wdata;
            logic   [3:0]                       dmem_wmask;
            logic                               mem_inst_complete;
            logic   [31:0]                      dmem_rdata;
            logic   [$clog2(ROB_DEPTH_TOP)-1:0] rob_head_idx;

            logic                               jump_reg;
            logic                               jump_commit;

            logic   [31:0]                      jump_pc_next_reg;
            logic   [31:0]                      jump_pc_next_commit;

            // logic   [RAT_PS_WIDTH_TOP - 1:0]    rob_pds[ROB_DEPTH_TOP];
            int                                 rob_pd_count;

            logic   [RAT_PS_WIDTH_TOP - 1:0]    rrf[31:0];

            logic                               jump_commit_reg;

            logic                               mem_inst_sent_invalid_reg;

            logic   [3:0]                       rvfi_mem_rmask;
            logic   [3:0]                       rvfi_mem_wmask;
            logic                               funit_ready[5];

            logic   [31:0]                      ps1_v_mem;
            logic   [31:0]                      ps2_v_mem;

            // branch predictor signals

            logic   [7:0]                       ghr_reg_out;
            logic                               predictor_valid_out;
            logic                               btb_valid_out;
            logic   [31:0]                      btb_addr;
            logic   [1:0]                       br_prediction;
            logic                               br_commit;
            logic   [31:0]                      br_pc_next_commit;
            logic                               br_commit_reg;
            logic   [7:0]                       predictor_index, predictor_index_temp;

            logic   [1:0]                       br_prediction_temp;
            logic   [31:0]                      btb_addr_temp;
            logic                               btb_valid_out_temp;
            logic                               predictor_valid_out_temp;

            logic                               ghr_din;
            logic   [7:0]                       predictor_idx;
            logic   [4:0]                       btb_index;
            logic   [31:0]                      btb_addr_new;
            logic                               web_btb;
            logic                               ghr_shift_en;
            logic                               web_predictor;
            logic   [1:0]                       predictor_data_in;

            logic [7:0] ghr_reg_out_reg;

    assign predictor_index = ( iqueue_full ) ? '0 : pc_next[9:2] ^ ghr_reg_out;
    assign predictor_index_temp = ( iqueue_full ) ? '0 : pc[9:2] ^ ghr_reg_out_reg;
    
    // Temporary assigments for synth
    assign ufp_wmask = '0;
    assign ufp_wdata = '0;

    always_ff @( posedge clk ) begin
        if ( rst ) begin
            ufp_resp_reg <= '0;
            ghr_reg_out_reg <= '0;
        end
        else begin
            ufp_resp_reg <= ufp_resp;
            ghr_reg_out_reg <= ghr_reg_out;
        end
    end


    fetch fetch_inst (
        .rst            ( rst ),
        .clk            ( clk ),
        
        // From iqueue, cannot request if queue full
        .iqueue_full    ( iqueue_full ),
        // From cache, only processing one request at a time
        .ufp_resp       ( ufp_resp ),
        
        // To cache, initiate read request
        .pc             ( pc ),
        .pc_next        ( pc_next ),
        .ufp_rmask      ( ufp_rmask ),

        // jump flags
        .jump_commit    ( jump_commit ),
        .jump_pc_next_commit ( jump_pc_next_commit ),

        // branch prediction flags
        .br_commit              ( br_commit ),
        .br_pc_next_commit      ( br_pc_next_commit ),

        .jump_commit_reg     ( jump_commit_reg ),
        .br_commit_reg       ( br_commit_reg )
    );

    queue #( .DATA_WIDTH( QUEUE_DATA_WIDTH_TOP ), .DEPTH( QUEUE_DEPTH_TOP ) ) instruction_queue_inst ( 
        .clk            ( clk ),
        .rst            ( rst ), 

        // From cache, enqueue every time a response is received unless we want to discard the response for a jump
        .enqueue        ( ufp_resp && !jump_commit_reg && !br_commit_reg ),

        // From various modules, used to determine when dequeue is valid
        // .iqueue_empty don't need because it is set from an internal signal, empty reg
        .free_list_empty    ( free_list_empty ),
        
        .rs_full_alu        ( rs_full_alu ),
        .rs_full_mem        ( rs_full_mem ),
        .rs_full_div        ( rs_full_div ),
        .rs_full_mul        ( rs_full_mul ),
        .rs_full_br         ( rs_full_br ),
        .rs_full_ld         ( rs_full_ld ),
        .rob_full           ( rob_full ),

        // Right now, th    is stalls if any rs is full; eventually, should change to send specific inst types through if their rs is unblocked
        // .dequeue            ( !iqueue_empty && !free_list_empty && ( rs_full != '1 ) && !rob_full ), 
        // From fetch   
        .data_in            ( { predictor_index_temp, predictor_valid_out_temp, btb_valid_out_temp, br_prediction_temp, btb_addr_temp, pc, pc + 'd4, ufp_rdata} ),

        // To decode    
        .data_out           ( iqueue_out ),
        .full               ( iqueue_full ),
        .empty_reg          ( iqueue_empty ),
        .data_out_valid     ( iqueue_out_valid ),

        .jump_commit        ( jump_commit )
    );

    decode decode_inst (
        .clk                ( clk ),
        .rst                ( rst || jump_commit ),

        // From iqueue
        .inst               ( iqueue_out[31:0] ),
        .pc                 ( iqueue_out[95:64] ),
        .pc_next            ( iqueue_out[63:32] ),
        .btb_addr           ( iqueue_out[127:96] ),
        .br_prediction      ( iqueue_out[129:128] ),
        .btb_valid_out      ( iqueue_out[130] ),
        .predictor_valid_out ( iqueue_out[131] ),
        .predictor_index    ( iqueue_out[139:132] ),
        .iqueue_out_valid   ( iqueue_out_valid ),

        // To rename_dispatch, contains all relevant instruction info
        .decode_rename_reg  ( decode_rename_reg ),

        .jump_commit        ( jump_commit )
    );

    rename_dispatch #( .DATA_WIDTH( RENAME_DISPATCH_DATA_WIDTH_TOP ), .ROB_DATA_WIDTH( ROB_DATA_WIDTH_TOP ), .ROB_DEPTH( ROB_DEPTH_TOP ) ) rename_dispatch_inst
    (
        // From decode, contains relevant instruction info
        .decode_rename_reg  ( decode_rename_reg ),

        // From ROB, receive index mapped
        .rob_idx_in         ( rob_idx_rename_dispatch ),

        // From free list, receive dequeued data
        .free_list_pd       ( free_list_pd ),

        // From RAT, receive requested mappings
        .ps1                ( rat_ps1 ),
        .ps1_valid          ( rat_ps1_valid ),
        .ps2                ( rat_ps2 ),
        .ps2_valid          ( rat_ps2_valid ),

        .ps1_out_mem        ( ps1_out_mem ),
        .ps2_out_mem        ( ps2_out_mem ),

        // To free list, trigger dequeue
        .free_list_dequeue  ( free_list_dequeue ),
        // To RAT, request mappings
        .rs1                ( rat_rs1 ),
        .rs2                ( rat_rs2 ),
        // To RAT, update mapping for destination reg
        .rd                 ( rename_dispatch_rd ),
        .pd                 ( rename_dispatch_pd ),
        .regf_we            ( rename_dispatch_regf_we ),
        // To reservation stations, contains relevant meta data
        .alu_rs_data        ( alu_rs_data ),
        .mul_rs_data        ( mul_rs_data ),
        .div_rs_data        ( div_rs_data ),
        .mem_rs_data        ( mem_rs_data ),
        .br_rs_data         ( br_rs_data ),

        // To ROB, enqueue the mappings for dispatched instruction
        .enqueue            ( rob_enqueue ),
        .rob_data_out       ( rob_data_rename_dispatch ),
        .jump_commit        ( jump_commit )
    );

    // Data width must be able to hold depth max value
    freelist #( .DATA_WIDTH( FREE_LIST_DATA_WIDTH_TOP ), .DEPTH( FREE_LIST_DEPTH_TOP ), .ROB_DEPTH( ROB_DEPTH_TOP ) )  free_list_inst 
    (
        .clk            ( clk ),
        .rst            ( rst ),

        // From RRF
        .enqueue        ( free_list_enqueue ),
        .data_in        ( rrf_pd ),
        // From rename_dispatch
        .dequeue        ( free_list_dequeue ),

        // To rename_dispatch
        .data_out       ( free_list_pd ),
        // Unused for now since free_list full unimportant
        .full           ( free_list_full ),

        // If empty, stop dequeue from iqueue
        .empty_reg          ( free_list_empty ),

        .jump_commit        ( jump_commit ),
        // .rob_pds            ( rob_pds ),
        .rob_pd_count       ( rob_pd_count )
    );

    rat #( .NUM_REGS( RAT_NUM_REGS_TOP ), .PS_WIDTH( RAT_PS_WIDTH_TOP ) ) rat_inst
    (
        .clk            ( clk ),
        .rst            ( rst ),

        // From/to rename_dispatch, update rd mapping and return rs1 and rs2 mappings
        .rd             ( rename_dispatch_rd ),
        .pd             ( rename_dispatch_pd ),
        .regf_we        ( rename_dispatch_regf_we ),
        .rs1            ( rat_rs1 ),
        .ps1            ( rat_ps1 ),
        .ps1_valid      ( rat_ps1_valid ),
        .rs2            ( rat_rs2 ),
        .ps2            ( rat_ps2 ),
        .ps2_valid      ( rat_ps2_valid ),

        // From CDB, update rd -> pd mapping to valid on writeback
        .rd_cdb         ( rd_broadcast ),
        .pd_cdb         ( pd_broadcast ),
        .regf_we_cdb    ( update_rat_broadcast ),

        .jump_commit    ( jump_commit ),
        .rrf            ( rrf )
    );
    
    // Removed dequeue output since dequeue functionality is encapsulated inside rob itself
    rob #( .DATA_WIDTH( ROB_DATA_WIDTH_TOP), .DEPTH( ROB_DEPTH_TOP ), .PS_WIDTH( RAT_PS_WIDTH_TOP ) ) rob_inst 
    (
        .clk            ( clk ),
        .rst            ( rst ), 

        // From rename_dispatch, add new ROB element
        .enqueue        ( rob_enqueue ),
        .data_in        ( rob_data_rename_dispatch ),
        // From CDB, mark item at rob_idx ready to commit
        .ready_to_commit( ready_to_commit_broadcast ),
        .rob_idx_in     ( rob_idx_broadcast ),

        // To RRF, send data to retire instruction
        .data_out       ( rob_data_out ),
        .data_out_valid ( rob_data_out_valid ),
        // To rename_dispatch
        .rob_idx_out    ( rob_idx_rename_dispatch ),
        // ROB empty unused for now, can't think of its use
        .empty_reg      ( rob_empty ),
        // If ROB full, prevent dequeue from iqueue
        .full           ( rob_full ),
        .rvfi_rob_idx_out ( rvfi_rob_idx_out ),
        .head           ( rob_head_idx ),

        .jump_commit    ( jump_commit ),
        .rob_pd_count   ( rob_pd_count )
        // .rob_pds        ( rob_pds )
    );

    alu_rs #( .ALU_RS_DEPTH( ALU_RS_DEPTH_TOP ), .DATA_WIDTH( RS_DATA_WIDTH_TOP )) alu_rs_inst
    (
        .clk                ( clk ),
        .rst                ( rst ),
        .alu_rs_data        ( alu_rs_data ),
        // From CDB, update ready bits if wakeup received and pd_broadcast match
        .wakeup             ( wakeup_broadcast ),
        .pd_broadcast       ( pd_broadcast ),
        .alu_rs_data_out    ( alu_unit_data ),
        .funit_ready_alu    ( funit_ready[alu] ),
        .rs_full_alu        ( rs_full_alu ),
        .ps1_out_alu        ( ps1_out_alu ),
        .ps2_out_alu        ( ps2_out_alu ),
        .jump_commit        ( jump_commit ),
        .rs_select_alu      ( rs_select_alu )

    );

    mem_rs #( .MEM_RS_DEPTH( MEM_RS_DEPTH_TOP), .DATA_WIDTH( RS_DATA_WIDTH_TOP), .ROB_DEPTH( ROB_DEPTH_TOP) ) mem_rs_inst 
    (
        .clk                ( clk ),
        .rst                ( rst ),


        .mem_rs_data        ( mem_rs_data ),
        .wakeup             ( wakeup_broadcast ),
        .pd_broadcast       ( pd_broadcast ),

        .mem_rs_data_out    ( mem_unit_data ),

        .rs_select_mem      ( rs_select_mem ),
        .funit_ready_mem    ( funit_ready[mem] ),
        .rs_full_mem        ( rs_full_mem ),

        .mem_inst_complete  ( mem_inst_complete ),

        .rs_full_ld         ( rs_full_ld ),
        .rob_head_idx       ( rob_head_idx ),
        
        .jump_commit        ( jump_commit ),

        .mem_inst_sent_invalid_reg  ( mem_inst_sent_invalid_reg ),

        .ps1_v_mem          ( ps1_v[mem] ),
        .ps2_v_mem          ( ps2_v[mem] ),
        .pd_v_broadcast     ( pd_v_broadcast ),
        .dmem_addr          ( dmem_addr ),
        .dmem_wmask         ( dmem_wmask ),
        .dmem_wdata         ( dmem_wdata )

    );

    reservation_stations #( .ALU_RS_DEPTH( ALU_RS_DEPTH_TOP ), .MUL_RS_DEPTH( MUL_RS_DEPTH_TOP ), .DIV_RS_DEPTH( DIV_RS_DEPTH_TOP ), .MEM_RS_DEPTH( MEM_RS_DEPTH_TOP ), .BR_RS_DEPTH( BR_RS_DEPTH_TOP ), .DATA_WIDTH( RS_DATA_WIDTH_TOP ), .ROB_DEPTH( ROB_DEPTH_TOP ) ) reservation_stations_inst
    (
        .clk                ( clk ),
        .rst                ( rst ),

        // From rename_dispatch
        .mul_rs_data        ( mul_rs_data ),
        .div_rs_data        ( div_rs_data ),
        .br_rs_data         ( br_rs_data ),

        // From CDB, update ready bits if wakeup received and pd_broadcast match
        .wakeup             ( wakeup_broadcast ),
        .pd_broadcast       ( pd_broadcast ),

        
        // To execute
        .mul_rs_data_out    ( mul_unit_data ),
        .div_rs_data_out    ( div_unit_data ),
        .br_rs_data_out     ( br_unit_data ),
    
        .rs_select_mul      ( rs_select_mul ),
        .rs_select_div      ( rs_select_div ),
        .rs_select_br       ( rs_select_br ),

        .mul_shift_reg      ( mul_shift_reg ),

        .funit_ready        ( funit_ready ),

        // If reservation stations are full, prevent dequeue from iqueue
        
        
        .rs_full_div        ( rs_full_div ),
        .rs_full_mul        ( rs_full_mul ),
        .rs_full_br         ( rs_full_br ),



        
        
        .ps1_out_div        ( ps1_out_div ),
        .ps2_out_div        ( ps2_out_div ),
        .ps1_out_br        ( ps1_out_br ),
        .ps2_out_br        ( ps2_out_br ),
        .ps1_out_mul        ( ps1_out_mul ),
        .ps2_out_mul        ( ps2_out_mul ),


        .division_state     ( division_state ),

        .multiplier_output_valid ( multiplier_output_valid ),

        .rob_head_idx       ( rob_head_idx ),
        
        .jump_commit        ( jump_commit )

        
    );
    
    regfile #( .DATA_WIDTH( REG_DATA_WIDTH_TOP ), .NUM_REGS( RAT_NUM_REGS_TOP ) ) regfile_inst
    (
        .clk                ( clk ),
        .rst                ( rst ),

        // From CDB
        .regf_we            ( regf_we_broadcast ),
        .pd_v               ( pd_v_broadcast ),
        .pd_s               ( pd_broadcast ),

        // From reservation stations
        .ps1_out_alu        ( ps1_out_alu ),
        .ps2_out_alu        ( ps2_out_alu ),
        .ps1_out_mem        ( ps1_out_mem ),
        .ps2_out_mem        ( ps2_out_mem ),
        .ps1_out_div        ( ps1_out_div ),
        .ps2_out_div        ( ps2_out_div ),
        .ps1_out_br        ( ps1_out_br ),
        .ps2_out_br        ( ps2_out_br ),
        .ps1_out_mul        ( ps1_out_mul ),
        .ps2_out_mul        ( ps2_out_mul ),

        
        // To execution units
        .ps1_v              ( ps1_v ),
        .ps2_v              ( ps2_v )
    );

    logic jump;
    logic [31:0] jump_pc_next;

    execute #( .DATA_WIDTH( EXECUTE_DATA_WIDTH_TOP ), .ROB_DEPTH( ROB_DEPTH_TOP ) ) execute_inst
    (
        .clk                        ( clk ),
        .rst                        ( rst ),

        // From regfile     
        .ps1_v                      ( ps1_v ),
        .ps2_v                      ( ps2_v ),

        // From reservation stations
        .alu_unit_data              ( alu_unit_data ),
        .mul_unit_data              ( mul_unit_data ),
        .div_unit_data              ( div_unit_data ),
        .mem_unit_data              ( mem_unit_data ),
        .br_unit_data               ( br_unit_data ),

        .rs_select_alu      ( rs_select_alu ),
        .rs_select_mul      ( rs_select_mul ),
        .rs_select_mem      ( rs_select_mem ),
        .rs_select_div      ( rs_select_div ),
        .rs_select_br       ( rs_select_br ),

        // To CDB       
        .cdb_pd_v                   ( pd_v_broadcast ),
        .cdb_rd                     ( rd_broadcast ),
        .cdb_pd                     ( pd_broadcast ),
        .cdb_rob_idx                ( rob_idx_broadcast ),
        .funit_ready                ( funit_ready ),

        .mul_shift_reg              ( mul_shift_reg ),

        .cdb_valid_out              ( execute_valid_out ),
        .cdb_rvfi_ex                ( rvfi_ex ),
        .signed_flag                ( signed_flag ),
        .multiply_operand_a         ( multiply_operand_a ),
        .multiply_operand_b         ( multiply_operand_b ),
        // .multiplier_output_66_mulhsu       ( multiplier_output_66_mulhsu ),
        .multiplier_output_66       ( multiplier_output_66 ),
        .multiplier_output_valid    ( multiplier_output_valid ),

        .div_rem_sign_flag          ( div_rem_sign_flag ),
        .div_rem_operand_a          ( div_rem_operand_a ),
        .div_rem_operand_b          ( div_rem_operand_b ),
        .complete_inst_signed       ( complete_inst_signed ),
        // .complete_inst_unsigned     ( complete_inst_unsigned ),
        .divide_by_0_signed         ( divide_by_0_signed ),
        // .divide_by_0_unsigned       ( divide_by_0_unsigned ),
        .remainder_signed           ( remainder_signed ),
        // .remainder_unsigned         ( remainder_unsigned ),
        .quotient_signed            ( quotient_signed ),
        // .quotient_unsigned          ( quotient_unsigned ),
        .hold                       ( hold ),
        .start                      ( start ),

        .division_state             ( division_state ),

        .dmem_addr                  ( dmem_addr ),
        .dmem_rmask                 ( dmem_rmask ),
        .dmem_wdata                 ( dmem_wdata ),
        .dmem_wmask                 ( dmem_wmask ),

        // inputs
        .dmem_rdata                 ( dmem_rdata ),
        .dmem_resp                  ( mem_inst_complete ),
        .cdb_regf_we                ( regf_we_reg ),

        .jump                       ( jump ),
        .jump_reg                   ( jump_reg ),
        .jump_pc_next               ( jump_pc_next ),
        .jump_pc_next_reg           ( jump_pc_next_reg ),

        .jump_commit                ( jump_commit ),

        .mem_inst_sent_invalid_reg  ( mem_inst_sent_invalid_reg ),

        .rvfi_mem_rmask             ( rvfi_mem_rmask ),
        .rvfi_mem_wmask             ( rvfi_mem_wmask ),

        // branch predictor
        .ghr_din               ( ghr_din ),
        .predictor_idx         ( predictor_idx ),
        .btb_index             ( btb_index ),
        .btb_addr_new          ( btb_addr_new ),
        .web_btb               ( web_btb ),
        .ghr_shift_en          ( ghr_shift_en ),
        .web_predictor         ( web_predictor ),
        .predictor_data_in     ( predictor_data_in )
    );

    cdb #( .DATA_WIDTH( CDB_DATA_WIDTH_TOP ), .ROB_DEPTH( ROB_DEPTH_TOP ) ) cdb_inst
    (
        .clk                ( clk ),
        .rst                ( rst ),

        // Broadcast if execute says it is valid
        .valid_to_broadcast ( execute_valid_out ),
        .regf_we_reg         ( regf_we_reg ),

        // From execute
        .jump_reg           ( jump_reg ),
        .jump_pc_next_reg   ( jump_pc_next_reg ),

        // Broadcast signal to flush
        .jump_commit       ( jump_commit ),
        .jump_pc_next_commit ( jump_pc_next_commit ),

        // Broadcast signals
        .regf_we_cdb        ( regf_we_broadcast ),
        .wakeup             ( wakeup_broadcast ),
        .update_rat         ( update_rat_broadcast ),
        .ready_to_commit    ( ready_to_commit_broadcast )
    );

    rvfi_t          rrf_rvfi;
    rrf #( .ROB_DATA_WIDTH( ROB_DATA_WIDTH_TOP ), .PS_WIDTH( RAT_PS_WIDTH_TOP ) ) rrf_inst
    (
        .clk                ( clk ),
        .rst                ( rst ),

        // From ROB, update free list
        .rob_data_out       ( rob_data_out ),
        .rob_data_out_valid ( rob_data_out_valid ),

        // To free list, enqueue
        .rrf_pd             ( rrf_pd ),
        .free_list_enqueue  ( free_list_enqueue ),

        .rrf_rvfi           ( rrf_rvfi ),

        // To RAT, replace RAT on jump commit
        .rrf_out            ( rrf ),
        .jump_commit        ( jump_commit )
    );

    rvfi_array #( .ARR_DEPTH( ROB_DEPTH_TOP ) ) rvfi_array_inst 
    (
        .clk                ( clk ),
        .rst                ( rst ),
        .rvfi_ex            ( rvfi_ex ),
        .rob_idx_in         ( rob_idx_broadcast ),
        .rob_idx_out        ( rvfi_rob_idx_out ),
        .read_enable        ( rob_data_out_valid ),
        .rvfi_data          ( rrf_rvfi )
    );

    DW02_mult_3_stage_inst #( .A_WIDTH( 32 ), .B_WIDTH( 32 ) ) multiplier_inst
    (
        .inst_CLK           ( clk ),
        .inst_TC            ( signed_flag ),
        .inst_A             ( multiply_operand_a ),
        .inst_B             ( multiply_operand_b ),
        // .PRODUCT_inst_64    ( multiplier_output_66_mulhsu),
        .PRODUCT_inst_66    ( multiplier_output_66 )
    );

    // DW_div_seq_inst_unsigned divider_unsigned (
    //     .inst_clk           ( clk ),
    //     .inst_rst_n         ( !rst ),
    //     .inst_hold          ( hold ),
    //     .inst_start         ( start ),
    //     .inst_a             ( div_rem_operand_a ),
    //     .inst_b             ( div_rem_operand_b ),
    //     .complete_inst      ( complete_inst_unsigned ),
    //     .divide_by_0_inst   ( divide_by_0_unsigned ),
    //     .quotient_inst      ( quotient_unsigned ),
    //     .remainder_inst     ( remainder_unsigned )
    // );

    DW_div_seq_inst_signed divider_signed (
        .inst_clk           ( clk ),
        .inst_rst_n         ( !rst ),
        .inst_hold          ( hold ),
        .inst_start         ( start ),
        .inst_a             ( div_rem_operand_a ),
        .inst_b             ( div_rem_operand_b ),
        .complete_inst      ( complete_inst_signed ),
        .divide_by_0_inst   ( divide_by_0_signed ),
        .quotient_inst      ( quotient_signed ),
        .remainder_inst     ( remainder_signed )
    );


    // // Cacheline adapter logic signals
    // logic   [255:0]                     cacheline_adapter_data_out;
    // logic   [31:0]                      cacheline_adapter_addr_out;
    // logic                               cacheline_adapter_valid_out;
    // logic                               cacheline_adapter_write_enable;
    // logic   [255:0]                     cacheline_adapter_write_data;
    // logic   [31:0]                      cacheline_adapter_addr;
    // logic                               cacheline_adapter_read_enable;  

    // imem signals
    logic   [255:0]                     data_out_i;
    logic   [31:0]                      addr_out_i;
    logic                               valid_out_i;
    logic                               write_enable_i;
    logic   [255:0]                     write_data_i;
    logic   [31:0]                      addr_i;
    logic                               read_enable_i;   

    // imem signals
    logic   [255:0]                     data_out_m;
    logic   [31:0]                      addr_out_m;
    logic                               valid_out_m;
    logic                               write_enable_m;
    logic   [255:0]                     write_data_m;
    logic   [31:0]                      addr_m;
    logic                               read_enable_m;   

    // arb signals
    logic   [255:0]                     data_out;
    logic   [31:0]                      addr_out;
    logic                               valid_out;
    logic                               write_enable;
    logic   [255:0]                     write_data;
    logic   [31:0]                      addr;
    logic                               read_enable;  

    logic   [31:0]                      ufp_dmem_addr;
    logic   [3:0]                       ufp_dmem_rmask;
    logic   [31:0]                      ufp_dmem_wdata;
    logic   [3:0]                       ufp_dmem_wmask;
    logic                               ufp_dmem_resp;
    logic   [31:0]                      ufp_dmem_rdata;
    
    prefetch prefetch_inst 
    (
        .clk            ( clk ),
        .rst            ( rst ),
        // .jump_commit    ( jump_commit ),

        // to cache
        .ufp_addr       ( ufp_dmem_addr ),
        .ufp_rmask      ( ufp_dmem_rmask ),
        .ufp_wmask      ( ufp_dmem_wmask ),
        .ufp_rdata      ( ufp_dmem_rdata ),
        .ufp_wdata      ( ufp_dmem_wdata ),
        .ufp_resp       ( ufp_dmem_resp ),

        // execute conntion
        .dmem_addr       ( dmem_addr ),
        .dmem_rmask      ( dmem_rmask ),
        .dmem_wmask      ( dmem_wmask ),
        .dmem_rdata      ( dmem_rdata ),
        .dmem_wdata      ( dmem_wdata ),
        .dmem_resp       ( mem_inst_complete ),

        .bmem_addr     ( bmem_addr ),
        .bmem_read     ( bmem_read )

    );

    dcache dcache_inst (
        .clk            ( clk ),
        .rst            ( rst ),

        .ufp_addr       ( ufp_dmem_addr ),
        .ufp_rmask      ( ufp_dmem_rmask ),
        .ufp_wmask      ( ufp_dmem_wmask ),
        .ufp_rdata      ( ufp_dmem_rdata ),
        .ufp_wdata      ( ufp_dmem_wdata ),
        .ufp_resp       ( ufp_dmem_resp ),

        //send to cacheline addapter
        .dfp_addr       ( addr_m ),
        .dfp_read       ( read_enable_m ),
        .dfp_write      ( write_enable_m ),
        .dfp_wdata      ( write_data_m ),

        //returns from cacheline adapter
        .dfp_rdata      ( data_out_m ),
        .dfp_resp       ( valid_out_m )
    );

    arbiter arbiter (
        .clk                ( clk ),
        .rst                ( rst ),

        // into cacheline adapter from arbiter
        .write_data         ( write_data ),
        .write_enable       ( write_enable ),
        .read_enable        ( read_enable ),
        .addr               ( addr ),

        // output from cacheline adapter into arbiter
        .data_out           ( data_out ),
        .valid_out          ( valid_out ),
        
        // into arbiter from cache instruction
        .write_data_i       ( write_data_i ),
        .write_enable_i     ( write_enable_i ),
        .read_enable_i      ( read_enable_i ),
        .addr_i             ( addr_i ),

        // out of arbiter to cache instruction
        .data_out_i         ( data_out_i ),
        .addr_out_i         ( addr_out_i ),
        .valid_out_i        ( valid_out_i ),

        // into arbiter from cache mem
        .write_data_m       ( write_data_m ),
        .write_enable_m     ( write_enable_m ),
        .read_enable_m      ( read_enable_m ),
        .addr_m             ( addr_m ),

        // out of arbiter to cache mem
        .data_out_m         ( data_out_m ),
        .addr_out_m         ( addr_out_m ),
        .valid_out_m        ( valid_out_m )
    );


    icache icache_inst (
        .clk            ( clk ),
        .rst            ( rst ),

        // From fetch
        .ufp_addr       ( pc_next ),
        .ufp_rmask      ( ufp_rmask ),
        .ufp_wmask      ( ufp_wmask ),
        .ufp_rdata      ( ufp_rdata ),
        .ufp_wdata      ( ufp_wdata ),
        .ufp_resp       ( ufp_resp ),

        // To cacheline_adapter, will be formatted and passed to bmem
        .dfp_addr       ( addr_i ),
        .dfp_read       ( read_enable_i ),
        .dfp_write      ( write_enable_i ),
        .dfp_rdata      ( data_out_i ),
        // Cannot go straight in bc bmem_wdata wants 64 bytes and dfp wdata is 256 bits
        .dfp_wdata      ( write_data_i ),
        .dfp_resp       ( valid_out_i )
    );


    // logic      [31:0]           l2_addr_dfp;
    // logic                       l2_read_dfp;
    // logic                       l2_write_dfp;
    // logic       [255:0]         l2_rdata_dfp;
    // logic       [255:0]         l2_wdata_dfp;
    // logic                       l2_resp_dfp;

    // l2cache l2cache_inst (
    //     .clk            ( clk ),
    //     .rst            ( rst ),

    //     // From arbiter
    //     .ufp_addr       ( addr ),
    //     .ufp_rmask      ( {4{read_enable}} ),
    //     .ufp_wmask      ( {4{write_enable}} ),
    //     .ufp_rdata      ( data_out ),
    //     .ufp_wdata      ( write_data ),
    //     .ufp_resp       ( valid_out ),
        
    //     // To cacheline_adapter
    //     .dfp_addr       ( l2_addr_dfp ),
    //     .dfp_read       ( l2_read_dfp ),
    //     .dfp_write      ( l2_write_dfp ),
    //     .dfp_rdata      ( l2_rdata_dfp ),
    //     // Cannot go straight in bc bmem_wdata wants 64 bytes and dfp wdata is 256 bits
    //     .dfp_wdata      ( l2_wdata_dfp ),
    //     .dfp_resp       ( l2_resp_dfp )
    // );

    cacheline_adapter cacheline_adapter_inst (
        .clk            ( clk ),
        .rst            ( rst ),

        // From bmem, used to verify response
        .bmem_rdata     ( bmem_rdata ),
        .bmem_rvalid    ( bmem_rvalid ),
        // From l2, used to format bmem request
        .write_data     ( write_data ),
        .write_enable   ( write_enable ),
        .read_enable    ( read_enable ),
        .addr           ( addr ),

        // To ad
        .data_out       ( data_out ),
        .valid_out      ( valid_out ),
        // To bmem to initiate a request
        .bmem_addr      ( bmem_addr ),
        .bmem_read      ( bmem_read ),
        .bmem_wdata     ( bmem_wdata ),
        .bmem_write     ( bmem_write ),
        .bmem_ready     ( bmem_ready ) 
    );

    logic [31:0] trash;
    assign trash = bmem_raddr;




    // branch predictor instantiations

    


    ghr_reg #( .WIDTH( 8 )) ghr_register
    (
        .clk            ( clk ),
        .rst            ( rst ),
        .shift_en       ( ghr_shift_en ),
        .din            ( ghr_din ),

        .dout           ( ghr_reg_out )
    );


    logic [31:0]   btb_junk;

    btb btb_array 
    (
        .clk0           ( clk ),
        .csb0           ( '0 ),
        .web0           ( '1 ),                    // first port is for reading
        .addr0          ( pc_next[6:2] ),
        .din0           ( '0 ),
        .dout0          ( btb_addr ),

        .clk1           ( clk ),
        .csb1           ( '0 ),
        .web1           ( web_btb ),
        .addr1          ( btb_index ),                    // second port is for writing
        .din1           ( btb_addr_new ),
        .dout1          ( btb_junk )
    );

    logic [1:0]     predictor_junk;

    predictor_table predictor_history  
        (
            .clk0           ( clk ),
            .csb0           ( '0 ),
            .web0           ( '1 ),                    // first port is for reading
            .addr0          ( predictor_index ),
            .din0           ( '0 ),
            .dout0          ( br_prediction ),

            .clk1           ( clk ),
            .csb1           ( '0 ),
            .web1           ( web_predictor ),                    // second port is for writing
            .addr1          ( predictor_idx ),
            .din1           ( predictor_data_in ),
            .dout1          ( predictor_junk )
        );


    btb_predictor_valid_array #( .S_INDEX(5), .WIDTH(1) ) btb_valid 
    (
        .clk            ( clk ),
        .rst            ( rst ),
        .csb            ( '0 ),
        .web            ( web_btb ),                        // writing
        .waddr          ( btb_index ),
        .din            ( '1 ),

        .raddr          ( pc_next[6:2] ),                        // reading
        .dout           ( btb_valid_out )
    );

    btb_predictor_valid_array #( .S_INDEX(8), .WIDTH(1) ) predictor_valid 
    (
        .clk            ( clk ),
        .rst            ( rst ),
        .csb            ( '0 ),                     // writing
        .web            ( web_predictor ),
        .waddr          ( predictor_idx ),
        .din            ( '1 ),

        .raddr          ( predictor_index ),                        // reading
        .dout           ( predictor_valid_out )
    );



    always_comb begin
        br_commit = '0;
        br_pc_next_commit = '0;

        btb_addr_temp = '0;
        br_prediction_temp = 2'b01;
        btb_valid_out_temp = '0;
        predictor_valid_out_temp = '0;

        // // jimmy feels like needed jacob said no jacob wrong then said good edventaually 
        if(ufp_rdata[6:0] == op_b_br && predictor_valid_out) begin
            br_prediction_temp = br_prediction;
        end


        if (ufp_rdata[6:0] == op_b_br && predictor_valid_out && btb_valid_out) begin
            if (br_prediction[1] == 1'b1) begin
                br_commit = '1;
                br_pc_next_commit = btb_addr;

                btb_addr_temp = btb_addr;
                br_prediction_temp = br_prediction;
                btb_valid_out_temp = btb_valid_out;
                predictor_valid_out_temp = predictor_valid_out;
            end
            // br_prediction_temp = br_prediction;
        end
    end


endmodule : cpu


