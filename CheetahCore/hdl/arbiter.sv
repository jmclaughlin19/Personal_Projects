module arbiter (
    input logic                               clk,
    input logic                               rst,

    //from cacheline to arbiter
    input logic   [255:0]                      data_out,
    input logic                                valid_out,

    //into cacheline from arbiter
    output logic                               write_enable,
    output logic   [255:0]                     write_data,
    output logic   [31:0]                      addr,
    output logic                               read_enable,

    //out of arbiter into cache instruction
    output logic   [255:0]                     data_out_i,
    output logic   [31:0]                      addr_out_i,
    output logic                               valid_out_i,

    //in arbiter from cache instruction
    input logic                                write_enable_i,
    input logic   [255:0]                      write_data_i,
    input logic   [31:0]                       addr_i,
    input logic                                read_enable_i,

    //out of arbiter into cache mem
    output logic   [255:0]                     data_out_m,
    output logic   [31:0]                      addr_out_m,
    output logic                               valid_out_m,

    //into arbiter from cache mem
    input logic                                write_enable_m,
    input logic   [255:0]                      write_data_m,
    input logic   [31:0]                       addr_m,
    input logic                                read_enable_m
);

    logic m_bmem_sent;
    logic m_bmem_sent_next;
    logic i_bmem_sent;
    logic i_bmem_sent_next; 
    logic   [31:0]  i_addr_sent;
    logic   [31:0]  m_addr_sent;
    logic   [31:0]  i_addr_sent_next;
    logic   [31:0]  m_addr_sent_next;

    logic                               write_enable_reg;
    logic   [255:0]                     write_data_reg;
    logic   [31:0]                      addr_reg;
    logic                               read_enable_reg;

//according to cache if a dfp write or read is waiting always high so do not have to hold signals
always_ff @(posedge clk) begin
    if ( rst ) begin
        m_bmem_sent <= '0;
        i_bmem_sent <= '0;
        m_addr_sent <= '0;
        i_addr_sent <= '0;
        write_enable_reg <= '0;
        read_enable_reg <= '0;
        addr_reg <= '0;
        write_data_reg <= '0;
    end
    else begin
        m_bmem_sent <= m_bmem_sent_next;
        i_bmem_sent <= i_bmem_sent_next;
        m_addr_sent <= m_addr_sent_next;
        i_addr_sent <= i_addr_sent_next;
        write_enable_reg <= write_enable;
        read_enable_reg <= read_enable;
        addr_reg <= addr;
        write_data_reg <= write_data;
    end
end

always_comb begin
    m_bmem_sent_next = m_bmem_sent;
    i_bmem_sent_next = i_bmem_sent;
    m_addr_sent_next = m_addr_sent;
    i_addr_sent_next = i_addr_sent;
    data_out_i = '0;
    valid_out_i = '0;
    addr_out_i = '0;
    data_out_m = '0;
    valid_out_m = '0;
    addr_out_m = '0;
    write_enable = write_enable_reg;
    read_enable = read_enable_reg;
    write_data = write_data_reg;
    addr = addr_reg;

    if ( (write_enable_m || read_enable_m) && !i_bmem_sent && !m_bmem_sent) begin
        write_enable = write_enable_m;
        read_enable = read_enable_m;
        write_data = write_data_m;
        addr = addr_m;
        m_bmem_sent_next = '1;
        m_addr_sent_next = addr_m;
    end
    else if ( (write_enable_i || read_enable_i) && !m_bmem_sent && !i_bmem_sent) begin
        write_enable = write_enable_i;
        read_enable = read_enable_i;
        write_data = write_data_i;
        addr = addr_i;
        i_bmem_sent_next = '1;
        i_addr_sent_next = addr_i;
    end
    else if ( !i_bmem_sent && !m_bmem_sent ) begin
        write_enable = '0;
        read_enable = '0;
        write_data = '0;
        addr = '0;
    end

    if ( i_bmem_sent && valid_out ) begin
        data_out_i = data_out;
        valid_out_i = valid_out;
        addr_out_i = i_addr_sent;
        i_bmem_sent_next = '0;
        i_addr_sent_next = '0;
    end
    if ( m_bmem_sent && valid_out ) begin
        data_out_m = data_out;
        valid_out_m = valid_out;
        addr_out_m = m_addr_sent;
        m_bmem_sent_next = '0;
        m_addr_sent_next = '0;
    end

end
      


endmodule : arbiter

