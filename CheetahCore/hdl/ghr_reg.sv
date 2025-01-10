module ghr_reg #(
    parameter WIDTH = 8 
)(
    input logic clk,       
    input logic rst,       
    input logic shift_en,  
    input logic din,       
    output logic [WIDTH-1:0] dout 
);

    always_ff @(posedge clk) begin
        if (rst) begin
            dout <= {WIDTH{1'b0}}; 
        end else if (shift_en) begin
            dout <= {dout[WIDTH-2:0], din}; 
        end
    end

endmodule: ghr_reg
