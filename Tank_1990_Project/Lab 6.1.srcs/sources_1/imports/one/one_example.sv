module one_example (
	input logic vga_clk,
	input logic [9:0] DrawX, DrawY,
	input logic blank,
	input logic [1:0] enemy1_counter, enemy2_counter, enemy3_counter,
	output logic [3:0] red, green, blue,
	output logic one_flag
);

logic [11:0] rom_address;
logic [1:0] rom_q;

logic [3:0] palette_red, palette_green, palette_blue;

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
assign rom_address = (DrawX%64)+(DrawY%64)*64;

always_ff @ (posedge vga_clk) begin
	if(DrawX<=640 && DrawX>=576 && DrawY<=192 && DrawY>=128 && pink_flag == 1'b0) begin
	   if((enemy1_counter == 2'b00 && enemy2_counter == 2'b00 && enemy3_counter != 2'b00) || (enemy1_counter != 2'b00 && enemy2_counter == 2'b00 && enemy3_counter == 2'b00) || (enemy1_counter == 2'b00 && enemy2_counter != 2'b00 && enemy3_counter == 2'b00))  begin
	   one_flag <= 1'b1;
	   red <= palette_red;
	   green <= palette_green;
	   blue <= palette_blue;
	   end
	end
	else if(blank) begin
	   one_flag <= 1'b0;
	   red <= 4'h0;
	   green <= 4'h0;
	   blue <= 4'h0;
	end
end

one_rom one_rom (
	.clka   (negedge_vga_clk),
	.addra (rom_address),
	.douta       (rom_q)
);

one_palette one_palette (
	.index (rom_q),
	.red   (palette_red),
	.green (palette_green),
	.blue  (palette_blue)
);

endmodule
