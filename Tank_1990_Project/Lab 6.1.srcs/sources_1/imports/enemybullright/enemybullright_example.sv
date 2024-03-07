module enemybullright_example (
	input logic vga_clk,
	input logic [9:0] DrawX, DrawY,
	input logic blank,
	input logic [11:0] bull_X, bull_Y, 
	output logic [3:0] red, green, blue,
	output logic bullflagright
);

logic [6:0] rom_address;
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
assign rom_address = (DrawX-bull_X)+(DrawY-bull_Y)*16;

always_ff @ (posedge vga_clk) begin
	if(((DrawX- bull_X) <=16) && ((DrawY - bull_Y) <= 7) && (pink_flag == 1'b0)) begin
	   bullflagright <= 1'b1;
	   red <= palette_red;
	   green <= palette_green;
	   blue <= palette_blue;
	end
	else if(blank) begin
	   bullflagright <= 1'b0;
	   red <= 4'h0;
	   green <= 4'h0;
	   blue <= 4'h0;
	end
end

enemybullright_rom enemybullright_rom (
	.clka   (negedge_vga_clk),
	.addra (rom_address),
	.douta       (rom_q)
);

enemybullright_palette enemybullright_palette (
	.index (rom_q),
	.red   (palette_red),
	.green (palette_green),
	.blue  (palette_blue)
);

endmodule
