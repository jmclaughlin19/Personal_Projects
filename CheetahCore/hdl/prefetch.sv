module prefetch
(
   input   logic                clk,
   input   logic                rst,
   // input   logic                jump_commit,
   //to cache
   output  logic   [31:0]                    ufp_addr,
   output   logic   [3:0]                    ufp_rmask,
   output   logic   [3:0]                    ufp_wmask,
   input   logic   [31:0]                    ufp_rdata,
   output   logic   [31:0]                   ufp_wdata,
   input  logic                              ufp_resp,


   //from execute
   input  logic   [31:0]                      dmem_addr,
   input  logic   [3:0]                       dmem_rmask,
   input  logic   [31:0]                      dmem_wdata,
   input  logic   [3:0]                       dmem_wmask,
   output logic                               dmem_resp,
   output logic   [31:0]                      dmem_rdata,


   //from bmem to know if bmem request was sent
   input   logic   [31:0]                     bmem_addr,
   input   logic                              bmem_read
);


localparam int           THRESHOLD = 3;


logic   [31:0]           last_dmem_sent_addr;
logic                    miss_last_next;
logic                    miss_last;
logic                    prefetch_sent_next;
logic                    prefetch_sent;
logic                    miss_execute;
logic                    miss_execute_next;


logic   [31:0]                      dmem_addr_reg;
logic   [3:0]                       dmem_rmask_reg;
logic   [31:0]                      dmem_wdata_reg;
logic   [3:0]                       dmem_wmask_reg;


// logic for strid
logic   [31:0]                      last_missed_addr;
logic   [31:0]                      last_missed_addr_next;


logic   [31:0]                      current_stride;
logic   [31:0]                      prev_stride;
logic   [31:0]                      prev_stride_next;


int                                 consistency_counter;
int                                 consistency_counter_next;
  
always_ff @(posedge clk) begin
   if (rst) begin
       last_dmem_sent_addr <= '0;
       miss_last <= '0;
       prefetch_sent <= '0;
       miss_execute <= '0;
       dmem_addr_reg <= '0;
       dmem_rmask_reg <= '0;
       dmem_wmask_reg <= '0;
       dmem_wdata_reg <= '0;
       last_missed_addr <= '0;
       prev_stride <= '0;
       consistency_counter <= '0;
   end
   else if (dmem_rmask != '0 || dmem_wmask != '0) begin
       last_dmem_sent_addr <= dmem_addr;
       miss_last <= '0;
       if (miss_execute_next) begin
           // store all data from execute
           dmem_addr_reg <= dmem_addr;
           dmem_rmask_reg <= dmem_rmask;
           dmem_wmask_reg <= dmem_wmask;
           dmem_wdata_reg <= dmem_wdata;
       end
       miss_execute <= miss_execute_next;
       prefetch_sent <= prefetch_sent_next;
   end
   else begin
       miss_last <= miss_last_next;
       miss_execute <= miss_execute_next;
       prefetch_sent <= prefetch_sent_next;
   end


   if (!rst) begin
       last_missed_addr <= last_missed_addr_next;
   end
  
   prev_stride <= prev_stride_next;
   consistency_counter <= consistency_counter_next;
end


always_comb begin
   current_stride = '0;
   dmem_rdata = '0;
   dmem_resp = '0;
   // find if we missed last prefetch
   if (rst) begin
       miss_last_next = '0;
       miss_execute_next = '0;
       prefetch_sent_next = '0;
       last_missed_addr_next = '0;
       prev_stride_next ='0;
       consistency_counter_next = '0;
   end
   else begin
       miss_last_next = miss_last;
       miss_execute_next = miss_execute;
       prefetch_sent_next = prefetch_sent;
       last_missed_addr_next = last_missed_addr;
       prev_stride_next = prev_stride;
       consistency_counter_next = consistency_counter;
   end
   if ( bmem_read && bmem_addr[31:5] == last_dmem_sent_addr[31:5] ) begin
       miss_last_next = '1;
       if (last_missed_addr_next != '0) begin
           current_stride = bmem_addr - last_missed_addr;
           prev_stride_next = current_stride;
           if (current_stride == prev_stride) begin
               consistency_counter_next = consistency_counter + 1;
           end
           else begin
               consistency_counter_next = '0;
           end
       end
       last_missed_addr_next = bmem_addr;
   end
  
   // sent prefetch and got back from cache
   if (prefetch_sent && ufp_resp) begin
       prefetch_sent_next = '0;
   end


   // if we missed last and we have a resp from cache and we do not have memory request from execute prefetch
   if ( miss_last_next && ufp_resp && dmem_rmask == '0 && dmem_wmask == '0 ) begin
       // send out prefecth based on miss last addr
       if (consistency_counter_next >= THRESHOLD) begin
           ufp_addr = last_dmem_sent_addr + current_stride;
           ufp_rmask = '1;
           ufp_wmask = '0;
           ufp_wdata = '0;
           prefetch_sent_next = '1;
           consistency_counter_next = '0;
       end
       else begin
           ufp_addr = '0;
           ufp_rmask = '0;
           ufp_wmask = '0;
           ufp_wdata = '0;
       end
       if (!prefetch_sent) begin
           dmem_rdata = ufp_rdata;
           dmem_resp = ufp_resp;
       end
       miss_last_next = '0;
   end
   // add case to handle holding execute value if we have an outstanding prefetch and get an execute request
   else if (prefetch_sent) begin
       if (dmem_rmask != '0 || dmem_wmask != '0) begin
           miss_execute_next = '1;
       end
       ufp_addr = '0;
       ufp_rmask = '0;
       ufp_wmask = '0;
       ufp_wdata = '0;
   end
   else begin
       // send out output from execute like normal
       if (miss_execute) begin
           ufp_addr = dmem_addr_reg;
           ufp_rmask = dmem_rmask_reg;
           ufp_wmask = dmem_wmask_reg;
           ufp_wdata = dmem_wdata_reg;
           miss_execute_next = '0;
       end
       else begin
           ufp_addr = dmem_addr;
           ufp_rmask = dmem_rmask;
           ufp_wmask = dmem_wmask;
           ufp_wdata = dmem_wdata;
       end
       dmem_rdata = ufp_rdata;
       dmem_resp = ufp_resp;
   end
  
  
end


endmodule : prefetch