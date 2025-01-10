module fetch (
    input   logic               clk,
    input   logic               rst,

    // From cache
    input   logic               ufp_resp, 

    // From iqueue, if full cannot make another request
    input   logic               iqueue_full,

    // From CPU, cannot request unless bmem is ready

    // jump signal
    input   logic               jump_commit,
    // jump pc_next signal
    input   logic   [31:0]      jump_pc_next_commit,

    // branch prediction flags  
    input   logic               br_commit,
    input   logic   [31:0]      br_pc_next_commit,

    // To cache, initiate read request
    output  logic   [31:0]      pc,
    output  logic   [31:0]      pc_next,
    output  logic   [3:0]       ufp_rmask,

    output  logic               jump_commit_reg,
    output  logic               br_commit_reg
);
            logic               rst_reg;
            logic               ufp_resp_reg;
            logic               jump_commit_reg_next;
            logic   [31:0]      jump_pc_next_commit_reg;

            logic               br_commit_reg_next;
            logic   [31:0]      br_pc_next_commit_reg;
        

    always_ff @( posedge clk ) begin
        if ( rst ) begin
            pc <= 32'h1ECEB000;
            rst_reg <= '1;
            ufp_resp_reg <= '0;
            jump_commit_reg <= '0;
            jump_pc_next_commit_reg <= '0;

            br_commit_reg <= '0;
            br_pc_next_commit_reg <= '0;
        end
        else begin
            pc <= pc_next;
            rst_reg <= '0;
        end

        if ( iqueue_full && ufp_resp ) begin
            ufp_resp_reg <= '1;
        end
        else if ( !iqueue_full ) begin
            ufp_resp_reg <= '0;
        end

        if ( jump_commit && (ufp_resp || ufp_resp_reg) && !iqueue_full ) begin
            jump_commit_reg <= '0;
        end
        else if ( jump_commit ) begin
            jump_commit_reg <= jump_commit;
            br_commit_reg <= '0;
        end
        else begin
            jump_commit_reg <= jump_commit_reg_next;
            // jump_pc_next_commit_reg <= jump_pc_next_commit;
        end
        
        if ( jump_commit ) begin
            jump_pc_next_commit_reg <= jump_pc_next_commit;
        end
        else if ( (ufp_resp || ufp_resp_reg) && !iqueue_full && jump_commit_reg ) begin
            jump_pc_next_commit_reg <= '0;
        end
        // *************************************************************

        if ( br_commit && (ufp_resp || ufp_resp_reg) && !iqueue_full) begin
            br_commit_reg <= '0;
        end
        else if ( br_commit ) begin
            br_commit_reg <= br_commit;
        end
        else begin
            br_commit_reg <= br_commit_reg_next;
            // jump_pc_next_commit_reg <= jump_pc_next_commit;
        end
        
        if ( br_commit ) begin
            br_pc_next_commit_reg <= br_pc_next_commit;
        end
        else if ( br_commit_reg && (ufp_resp || ufp_resp_reg) && !iqueue_full) begin
            br_pc_next_commit_reg <= '0;
        end

    end

    always_comb begin
        pc_next = pc;
        ufp_rmask = '0;
        if ( rst ) begin
            jump_commit_reg_next = '0;
            br_commit_reg_next = '0;
        end 
        else begin
            jump_commit_reg_next = jump_commit_reg;
            br_commit_reg_next = br_commit_reg;
        end


        // 1 cycle after rst, initiate first read
        if ( rst_reg && !rst ) begin
            ufp_rmask = '1;
        end
        
        // Processing 1 request at a time for now
        // If we have a response, iqueue is not full, and bmem is ready, initiate read
        if ( ( ufp_resp_reg || ufp_resp ) && !iqueue_full) begin
            if ( jump_commit_reg || jump_commit ) begin
                if ( jump_commit ) begin
                    pc_next = jump_pc_next_commit;
                end
                else begin
                    pc_next = jump_pc_next_commit_reg;
                end
                ufp_rmask = '1;   
                jump_commit_reg_next = '0;
                br_commit_reg_next = '0;
            end
            else if ( br_commit_reg || br_commit ) begin
                if ( br_commit ) begin
                    pc_next = br_pc_next_commit;
                end
                else begin
                    pc_next = br_pc_next_commit_reg;
                end
                ufp_rmask = '1;
                br_commit_reg_next = '0;
            end
            else begin
                pc_next = pc + 4;
                ufp_rmask = '1;
            end
        end
    end


endmodule : fetch



