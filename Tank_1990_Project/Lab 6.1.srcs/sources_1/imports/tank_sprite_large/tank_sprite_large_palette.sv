module tank_sprite_large_palette (
	input logic [1:0] index,
	output logic [3:0] red, green, blue
);

localparam [0:3][11:0] palette = {
	{4'hF, 4'hF, 4'hF},
	{4'h6, 4'h7, 4'h0},
	{4'hE, 4'hA, 4'h1},
	{4'hE, 4'hE, 4'h9}
};

assign {red, green, blue} = palette[index];

endmodule
