module explode_example (
	input logic vga_clk,
	input logic [9:0] DrawX, DrawY,
	input logic blank,
	input logic [11:0] bull_X, bull_Y, 
	input logic bull_live,
	output logic [3:0] red, green, blue,
	output logic explode_flag,
	output logic explosion
);

logic [9:0] rom_address;
logic [2:0] rom_q;

logic [3:0] palette_red, palette_green, palette_blue;

logic [31:0] seconds;
logic negedge_vga_clk;

// read from ROM on negedge, set pixel on posedge
assign negedge_vga_clk = ~vga_clk;

// address into the rom = (x*xDim)/640 + ((y*yDim)/480) * xDim
// this will stretch out the sprite across the entire screen





logic pink_flag;
always_comb begin
    if((palette_red ==4'hF) && (palette_green ==4'h0) && (palette_blue ==4'hF)) begin
    pink_flag = 1'b1;
    end
    else begin
    pink_flag = 1'b0;
    end
end
assign rom_address = (DrawX-bull_X+10)+(DrawY-bull_Y+6)*32;

//if(((DrawX- bull_X) <=32) && ((DrawY - bull_Y) <= 31) && (pink_flag == 1'b0)) b

logic explode_primer;
logic [31:0] cur_seconds;
logic [11:0] cur_bull_x, cur_bull_y;
always_ff @ (posedge vga_clk) begin

	if(((DrawX- bull_X+10) <=32) && ((DrawY - bull_Y+6) <= 31) && (pink_flag == 1'b0))  begin
	   explode_flag <= 1'b1;
	   red <= palette_red;
	   green <= palette_green;
	   blue <= palette_blue;
	end
	else if(blank) begin
	   explode_flag <= 1'b0;
	   red <= 4'h0;
	   green <= 4'h0;
	   blue <= 4'h0;
	end
	
	
end



always_ff @ (posedge vga_clk) begin
    if ((bull_X == 0))begin
	 explosion <= 1'b0;
	end
	if(bull_live == 1'b1)begin
	   explosion <= 1'b0;
	   explode_primer <= 1'b1;
	end
	else if(bull_live == 1'b0 && (explode_primer ==1'b1))
	begin
	       explosion <= 1'b1;
	       cur_seconds <= seconds;
	       explode_primer <= 1'b0;
	end

	if(seconds == (cur_seconds + 1)) 
	begin
	   explosion <= 1'b0;
	end

end




explode_rom explode_rom (
	.clka   (negedge_vga_clk),
	.addra (rom_address),
	.douta       (rom_q)
);

explode_palette explode_palette (
	.index (rom_q),
	.red   (palette_red),
	.green (palette_green),
	.blue  (palette_blue)
);

second_counter timer(
.frame_clk(vga_clk), .seconds(seconds)
);


endmodule



module second_counter(input frame_clk, output logic [31:0] seconds);
    logic [31:0] count = 0;
    always @(posedge frame_clk) begin
        if (count == 6000000 - 1) begin
            count <= 0;
            seconds <= seconds + 1;
        end 
        else begin
            count <= count + 1;
        end
    end
endmodule

