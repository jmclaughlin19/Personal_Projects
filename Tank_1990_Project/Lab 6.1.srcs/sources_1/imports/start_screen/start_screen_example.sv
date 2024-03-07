module start_screen_example (
	input logic vga_clk,
	input logic [9:0] DrawX, DrawY,
	input logic blank, Reset,
	input logic [7:0] keycode,
	output logic [3:0] red, green, blue,
	output logic start_screen_flag
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
    
    if(Reset)begin
            start_screen_flag <= 1'b1;
         end
    else if((keycode == 8'h28) )
         begin 
               start_screen_flag <= 1'b0;
		end
	else if(blank) begin
		red <= palette_red;
		green <= palette_green;
		blue <= palette_blue;
	end
	

end

start_screen_rom start_screen_rom (
	.clka   (negedge_vga_clk),
	.addra (rom_address),
	.douta       (rom_q)
);

start_screen_palette start_screen_palette (
	.index (rom_q),
	.red   (palette_red),
	.green (palette_green),
	.blue  (palette_blue)
);

endmodule
