module enemy_up_example (
	input logic vga_clk,
	input logic [9:0] DrawX, DrawY,
	input logic blank,
	input logic [11:0] enemy_X, enemy_Y, enemy_S,
	output logic [3:0] red, green, blue,
	output logic enemyflag
);

logic [9:0] rom_address;
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

assign rom_address = (DrawX-enemy_X)+(DrawY-enemy_Y)*32;

always_ff @ (posedge vga_clk) begin
	if( ((DrawX - enemy_X) <= enemy_S) && ((DrawY - enemy_Y) <= enemy_S-1) && (pink_flag == 1'b0) ) begin
        // if not pink draw palette red, otherwise draw background
        enemyflag <= 1'b1;
        red <= palette_red;
		green <= palette_green;
		blue <= palette_blue;
    end
    else if (blank) begin
        red <= 4'h0;
		green <= 4'h0;
	    blue <= 4'h0;
		enemyflag <= 1'b0;
		end
end

enemy_up_rom enemy_up_rom (
	.clka   (negedge_vga_clk),
	.addra (rom_address),
	.douta       (rom_q)
);

enemy_up_palette enemy_up_palette (
	.index (rom_q),
	.red   (palette_red),
	.green (palette_green),
	.blue  (palette_blue)
);

endmodule
