module icache 
import cache_types::*;
(
    input   logic           clk,
    input   logic           rst,

    // cpu side signals, ufp -> upward facing port
    input   logic   [31:0]  ufp_addr,
    input   logic   [3:0]   ufp_rmask,
    input   logic   [3:0]   ufp_wmask,
    output  logic   [31:0]  ufp_rdata,
    input   logic   [31:0]  ufp_wdata,
    output  logic           ufp_resp,

    // memory side signals, dfp -> downward facing port
    output  logic   [31:0]  dfp_addr,
    output  logic           dfp_read,
    output  logic           dfp_write,
    input   logic   [255:0] dfp_rdata,
    output  logic   [255:0] dfp_wdata,
    input   logic           dfp_resp
);
            shadow_reg_t    shadow_reg, shadow_reg_next;

            // sram signals
            // csb, web active low
            logic           sram_csb;
            logic           sram_web[4];
            logic   [31:0]  sram_addr;
            logic   [3:0]   sram_rmask;
            logic   [31:0]  sram_wmask;
            logic   [255:0] sram_wdata;
            logic           sram_valid;

            // Global signals
            logic           hit, hit_reg;
            logic           dirty;
            // One hot encoded signal representing which way should be written to
            logic   [3:0]   write, write_reg;
            logic           write_back, write_back_reg;

            // Hold output of sram arrays
            logic   [255:0] data_out[4];
            logic   [23:0]  tag_out[4];
            logic           valid_out[4];

            // Signals to register dfp values
            logic           dfp_resp_next;

            // LRU signals
            logic           lru_web1;
            logic   [2:0]   lru_din1;
            logic   [2:0]   lru_dout0, lru_dout1, invert_lru_dout;
            logic   [1:0]   write_way, write_way_next;

            int unsigned    icache_hit_hk;
            int unsigned    icache_miss_hk;

    generate for (genvar i = 0; i < 4; i++) begin : arrays
        mp_cache_data_array data_array (
            .clk0       ( clk ),
            .csb0       ( sram_csb ),
            .web0       ( sram_web[i] ),
            .wmask0     ( sram_wmask ),
            .addr0      ( sram_addr[8:5] ),
            .din0       ( sram_wdata ),
            .dout0      ( data_out[i] )
        );
        mp_cache_tag_array tag_array (
            .clk0       ( clk ),
            .csb0       ( sram_csb ),
            .web0       ( sram_web[i] ),
            .addr0      ( sram_addr[8:5] ),
            .din0       ( { dirty, sram_addr[31:9] } ),
            .dout0      ( tag_out[i] )
        );
        valid_array valid_array (
            .clk0       ( clk ),
            .rst0       ( rst ),
            .csb0       ( sram_csb ),
            .web0       ( sram_web[i] ),
            .addr0      ( sram_addr[8:5] ),
            .din0       ( sram_valid ),
            .dout0      ( valid_out[i] )
        );
    end endgenerate

    lru_array lru_array (
        .clk0       ( clk ),
        .rst0       ( rst ),
        .csb0       ( sram_csb ),
        .web0       ( '1 ),
        .addr0      ( sram_addr[8:5] ),
        .din0       ( '0 ),
        .dout0      ( lru_dout0 ),
        .csb1       ( '0 ),
        .web1       ( lru_web1 ),
        .addr1      ( shadow_reg.addr[8:5] ),
        .din1       ( lru_din1 ),
        .dout1      ( lru_dout1 )
    );


    int miss_wait_cycles;

    // Create our shadow register to store values that go into sram
    always_ff @( posedge clk ) begin
        if ( rst ) begin
            shadow_reg <= '0;
            dfp_resp_next <= '0;
            write_reg <= '0;
            write_back_reg <= '0;
            miss_wait_cycles <= '0;
        end 
        else begin
            shadow_reg <= shadow_reg_next;
            dfp_resp_next <= dfp_resp;
            write_reg <= write;
            write_back_reg <= write_back;
        end

        if ( ufp_resp ) begin
            icache_hit_hk <= icache_hit_hk + 1;
        end
        if ( dfp_resp ) begin
            icache_miss_hk <= icache_miss_hk + 1;
        end

        if ( dfp_read || dfp_write ) begin
            miss_wait_cycles <= miss_wait_cycles + 1;
        end

        
    end

    always_comb begin
        if ( !rst ) begin
            dirty = '0;

            sram_csb    = '0;
            sram_valid  = '1;

            // 1) Stall mux
            if ( ( !hit && ( shadow_reg.rmask != '0 || shadow_reg.wmask != '0 ) ) ) begin
                // if there is a stall, pull sram values from shadow reg
                shadow_reg_next.addr = shadow_reg.addr;
                shadow_reg_next.rmask = shadow_reg.rmask;
                shadow_reg_next.wmask = shadow_reg.wmask;
                shadow_reg_next.wdata = shadow_reg.wdata;
            end
            else begin
                shadow_reg_next.addr = ufp_addr;
                shadow_reg_next.rmask = ufp_rmask;
                shadow_reg_next.wmask = ufp_wmask;
                shadow_reg_next.wdata = ufp_wdata;
            end

            // Iterate through each way
            for ( int way = 0; way < 4; way++ ) begin

                // If no write, write_back, or dfp_resp, pass in default signals
                sram_addr = shadow_reg_next.addr;
                sram_rmask = shadow_reg_next.rmask;
                sram_wmask = '0;
                sram_wdata = '0;
                sram_web[way] = '1;

                if ( write_back ) begin
                    sram_valid = '0;
                    if ( way == integer'( write_way ) ) begin
                        sram_web[way] = !dfp_resp;
                    end
                end
                // 2) Write control mux
                else if ( write != '0 ) begin
                    // Write is raised after a write hit, set write enable for the correct way
                    sram_web[way] = '1;
                    if ( write[way] && shadow_reg.wmask != '0 ) begin
                        sram_web[way] = '0;
                    end
                    dirty = '1;

                    // On a write, allow register to be updated, but recycle inputs into sram
                    sram_addr = shadow_reg.addr;
                    sram_rmask = shadow_reg.rmask;
                    sram_wmask = {28'b0, shadow_reg.wmask} << ( shadow_reg.addr[4:2] * 4 );
                    sram_wdata = {224'b0, shadow_reg.wdata} << ( shadow_reg.addr[4:2] * 32 );
                end
                else if ( dfp_resp ) begin

                    sram_web[way] = '1;
                    if ( way == integer'( write_way ) && !write_back_reg ) begin
                        sram_web[way] = '0;
                    end

                    // On a miss, set wdata and wmask to replace the line
                    sram_addr = shadow_reg.addr;
                    sram_wmask = '1;
                    sram_rmask= '1;
                    sram_wdata = dfp_rdata;
                end 
            end
        end
        else begin
            shadow_reg_next = '0;
            sram_valid = '0;
            dirty = '0;
            sram_addr = '0;
            sram_wmask = '0;
            sram_rmask= '0;
            sram_wdata = '0;

            // Leave csb and web low so data can be marked as invalid
            sram_csb = '0;
            for ( int i = 0; i < 4; i++ ) begin
                sram_web[i] = '0;
            end
        end
    end

    always_comb begin
        // Set default signals
        hit = '0;
        ufp_resp = '0;
        ufp_rdata = '0;

        dfp_read = '0;
        dfp_write = '0;
        dfp_wdata = '0;
        dfp_addr = '0;

        lru_web1 = '1;
        lru_din1 = '0;

        write = '0;
        write_back = '0;
        write_way = '0;
        invert_lru_dout = '0;

        for ( int way = 0; way < 4; way++ ) begin
            // If tags match and valid is high, have cache hit
            if ( ( shadow_reg.addr[31:9] == tag_out[way][22:0] ) && valid_out[way] == '1 && write_reg == '0 ) begin

                if ( shadow_reg.rmask != '0 || shadow_reg.wmask != '0 ) begin
                    // Calculate new LRU based on read value
                    unique case ( unsigned'( way ) )
                                // din1 = X00
                        32'd0:   lru_din1 = ( lru_dout0 & 3'b100 );
                                // din1 = X10
                        32'd1:   lru_din1 = ( ( lru_dout0 | 3'b010 ) & 3'b110 );  
                                // din1 = 0X1
                        32'd2:   lru_din1 = ( ( lru_dout0 | 3'b001 ) & 3'b011 );
                                // din1 = 1X1
                        32'd3:   lru_din1 = ( lru_dout0 | 3'b101 );
                        default: lru_din1 = 'x;
                    endcase

                    // Initiate write to LRU with calculated din1
                    lru_web1 = '0;
                end

                // For read hits, set rdata
                if ( shadow_reg.rmask != '0 ) begin
                    ufp_resp = '1;
                    hit = '1;

                    // Loop through each byte of rmask
                    for ( int j = 0; j < 4; j++ ) begin
                        if ( shadow_reg.rmask[j] ) begin
                            // If rmask bit is high, copy byte at data_out[offset * 8 + j * 8]
                            ufp_rdata[( j << 3 ) +: 8] = data_out[way][( integer'( shadow_reg.addr[4:2] * 32 ) ) + ( j << 3 ) +: 8];
                        end
                    end
                end
                // For write hits, set write signal so value can be written to cache
                else if ( shadow_reg.wmask != '0 ) begin
                    write[way] = '1;
                    ufp_resp = '1;
                    hit = '1;
                end
            end
        end

        // Handle the miss case, set dfp values and stall
        // Handle dirty miss case, perform read if writeback success
        if ( ( !hit && ( shadow_reg.rmask != '0 || shadow_reg.wmask != '0 ) ) ) begin

            // Trace through LRU to calculate write-way
            invert_lru_dout = ~lru_dout0;
            
            unique case ( invert_lru_dout[0] )
                            // Select AB
                1'b0:         write_way = { 1'b0, invert_lru_dout[1] };
                            // Select CD
                1'b1:         write_way = { 1'b1, invert_lru_dout[2] };
                default:    write_way = 'x;
            endcase

            // If the line being evicted is dirty, need to initiate write-back
            if ( ( tag_out[write_way][23] == '1 && valid_out[write_way] == '1 ) && write_reg == '0 ) begin
                // For write-back, use address corresponding to tag out from sram
                write_back = '1;
                if ( dfp_resp_next != 1'b1 ) begin
                    dfp_addr = { tag_out[write_way][22:0], shadow_reg.addr[8:5], 5'b00000 };  
                    dfp_read = '0;
                    dfp_write = '1;
                    dfp_wdata = data_out[write_way];
                end
                else begin
                    dfp_addr = { shadow_reg.addr[31:5], 5'b00000 };
                    dfp_read = '1;
                    dfp_write = '0;
                    dfp_wdata = '0;
                end
            end 
            else if ( dfp_resp_next != 1'b1 && write_reg == '0 ) begin
                dfp_addr = { shadow_reg.addr[31:5], 5'b00000 };
                dfp_read = '1;
                dfp_write = '0;
                dfp_wdata = '0;
            end 
        end
    end

endmodule

