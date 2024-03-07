module gameover_screen_example (
	input logic vga_clk,
	input logic [9:0] DrawX, DrawY,
	input logic blank, Reset,
	input logic [1:0] p1counter1, p1counter2, p1counter3,
	input logic [7:0] keycode,
	output logic [3:0] red, green, blue,
	output logic gameover_screen_flag
);

logic [16:0] rom_address;
logic [2:0] rom_q;

logic [3:0] palette_red, palette_green, palette_blue;

logic negedge_vga_clk;

// read from ROM on negedge, set pixel on posedge
assign negedge_vga_clk = ~vga_clk;

// address into the rom = (x*xDim)/640 + ((y*yDim)/480) * xDim
// this will stretch out the sprite across the entire screen
assign rom_address = ((DrawX * 320) / 640) + (((DrawY * 240) / 480) * 320);

always_ff @ (posedge vga_clk or posedge Reset) begin
	if(Reset) begin
	   gameover_screen_flag <= 1'b0;
	end
	
	else if (p1counter1 != 2'b11 || p1counter2 != 2'b11 || p1counter3 != 2'b11) begin
	    gameover_screen_flag <= 1'b1;
	    red <= palette_red;
		green <= palette_green;
		blue <= palette_blue;
	end
	   
	else if (blank) begin
	    gameover_screen_flag <= 1'b0;
		
	end
end

gameover_screen_rom gameover_screen_rom (
	.clka   (negedge_vga_clk),
	.addra (rom_address),
	.douta       (rom_q)
);

gameover_screen_palette gameover_screen_palette (
	.index (rom_q),
	.red   (palette_red),
	.green (palette_green),
	.blue  (palette_blue)
);

endmodule
