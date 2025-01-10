module cacheline_adapter
(
    input   logic               clk,
    input   logic               rst,

    // Received from bmem to verify response
    input   logic   [63:0]      bmem_rdata,
    input   logic               bmem_rvalid,

    // Request, format for bmem received from cache
    input   logic   [255:0]     write_data,
    input   logic               write_enable,   
    input   logic               read_enable,
    input   logic   [31:0]      addr,

    // Outputs to cache
    output  logic   [255:0]     data_out,

    // Valid output to cache
    output  logic               valid_out,

    output  logic   [63:0]      bmem_wdata,
    output  logic               bmem_write,

    // bmem read to request a read to bmem
    output  logic               bmem_read, 

    // Used for bmem read and write correlated address
    output  logic   [31:0]      bmem_addr,
    input   logic               bmem_ready
);

            logic   [1:0]       burst_counter;
            logic   [255:0]     full_line, full_line_reg;
            logic               read_enable_reg;

always_ff @(posedge clk) begin
    if ( rst ) begin
        burst_counter <= 2'b00;
        full_line_reg <= '0;
    end 
    // Update burst counter if writing or reading
    else if ( write_enable ) begin
        burst_counter <= burst_counter + 1'b1;
        full_line_reg <= full_line;
    end 
    else if ( bmem_rvalid ) begin 
        burst_counter <= burst_counter + 1'b1;
        full_line_reg <= full_line;
    end 

    // Raise read_enable_reg for one cycle after read_enable
    if ( read_enable && !valid_out ) begin
        read_enable_reg <= read_enable;
    end
    else begin
        read_enable_reg <= '0;
    end
end

always_comb begin
    data_out = '0;
    valid_out = '0;
    bmem_write = '0;
    bmem_read = '0;
    bmem_addr = '0;

    // Recycle full_line to maintain old values
    full_line = full_line_reg;
    bmem_wdata = '0;

    if ( write_enable && bmem_ready) begin
        bmem_wdata = write_data[burst_counter * 64 +: 64];
        bmem_write = 1'b1;
        bmem_addr = addr;
    end 
    else if ( bmem_rvalid ) begin 
        full_line[burst_counter * 64 +: 64] = bmem_rdata;
    end 
    else begin
        full_line = '0;
    end

    // When burst counter == 3, packet is complete, initiate write/read
    if ( burst_counter == 2'b11 ) begin
        if ( read_enable ) begin
            data_out = full_line;
            valid_out = '1;
        end 
        else if ( write_enable ) begin
            data_out = 'x;
            valid_out = '1;
        end
    end

    // Force read_enable_reg = bmem_read high for only one cycle to adhere to bmem spec
    if ( !read_enable_reg && read_enable && bmem_ready ) begin
        bmem_read = read_enable;
        bmem_addr = addr;
    end
end

endmodule : cacheline_adapter


