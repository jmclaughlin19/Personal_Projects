`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/03/2023 03:34:01 PM
// Design Name: 
// Module Name: bullcollide
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module bullcollidebrick(
    input logic [11:0] bull_X,
    input logic [11:0] bull_Y,
    input logic [11:0] obj_X,
    input logic [11:0] obj_Y,
    input logic frame_clk,
    input logic extbrickactive,
    input logic extbrickactive2,
    input logic extbrickactive3,

    
    
    output logic bull_hit,
    output logic brickactive
    );
    
    
    
    always_ff @ (posedge frame_clk) begin
    if(bull_X == 0) begin
     brickactive = 1'b1; 
    end
    
    if((((bull_Y >= obj_Y) && (bull_Y <= (obj_Y + 32))) || (((bull_Y + 8) >= obj_Y ) && ((bull_Y + 8) <= (obj_Y + 32))))
		 && (brickactive == 1'b1) && (extbrickactive3 ==1'b1) &&  (extbrickactive2 == 1'b1) && (extbrickactive ==1'b1) && (((bull_X >= obj_X) && (bull_X <= (obj_X + 32))) || (((bull_X + 8) >= obj_X ) && ((bull_X + 8) <= (obj_X + 32)))))
        begin 
		bull_hit = 1'b0;
		brickactive = 1'b0;
		end
		
    else
    begin 
        bull_hit = 1'b1;
    end
    
		
    end
    
    
    
    
endmodule


module bullcollidesteel(
    input logic [11:0] bull_X,
    input logic [11:0] bull_Y,
    input logic [11:0] obj_X,
    input logic [11:0] obj_Y,
    input logic frame_clk,
    
    
    output logic bull_hit
    );
    
    
    
    always_ff @ (posedge frame_clk) begin
    
    if((((bull_Y >= obj_Y) && (bull_Y <= (obj_Y + 32))) || (((bull_Y + 8) >= obj_Y ) && ((bull_Y + 8) <= (obj_Y + 32))))
		  && (((bull_X >= obj_X) && (bull_X <= (obj_X + 32))) || (((bull_X + 8) >= obj_X ) && ((bull_X + 8) <= (obj_X + 32)))))
        begin 
		bull_hit = 1'b0;
		end
		
    else
    begin 
        bull_hit = 1'b1;
    end
    
		
    end
    
    
    
    
endmodule



module bullcollidetank(
    input logic [11:0] bull_X,
    input logic [11:0] bull_Y,
    input logic [11:0] obj_X,
    input logic [11:0] obj_Y,
    input logic frame_clk,
    input logic Reset,
    input logic bull_live,
    
    
    output logic bull_hit,
    output logic [1:0] enemy_counter
    );
    
    
    logic hitflag;
    
    
    always_ff @ (posedge frame_clk or posedge Reset) begin
    
    
    if(Reset)begin
        enemy_counter <= 2'b11;
    end
    
    
     else if((((bull_Y >= obj_Y) && (bull_Y <= (obj_Y + 32))) || (((bull_Y + 8) >= obj_Y ) && ((bull_Y + 8) <= (obj_Y + 32))))
		  && (((bull_X >= obj_X) && (bull_X <= (obj_X + 32))) || (((bull_X + 8) >= obj_X ) && ((bull_X + 8) <= (obj_X + 32)))) 
		  && !hitflag && bull_live)
        begin 
        hitflag <=1'b1;
		bull_hit <= 1'b0;
		enemy_counter <= enemy_counter - 2'b01;
		end
		
    else
    begin 
        hitflag <= (((bull_Y >= obj_Y) && (bull_Y <= (obj_Y + 32))) || (((bull_Y + 8) >= obj_Y ) && ((bull_Y + 8) <= (obj_Y + 32))))
		  && (((bull_X >= obj_X) && (bull_X <= (obj_X + 32))) || (((bull_X + 8) >= obj_X ) && ((bull_X + 8) <= (obj_X + 32))));
        bull_hit <= 1'b1;
    end
    
		
    end
    
    
    
    
endmodule



