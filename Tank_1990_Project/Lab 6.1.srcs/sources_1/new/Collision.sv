`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2023 10:25:43 PM
// Design Name: 
// Module Name: Collision
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


module Collision(
    input logic [11:0] player1_X,
    input logic [11:0] player1_Y,
    input logic [11:0] brick1_X,
    input logic [11:0] brick1_Y,
    input logic [1:0] p1_direction_flag,
    input logic frame_clk,
    input logic brickactive, // make sure this is passed in as 1 for steels
    
    output logic player1_left_stop,
    output logic player1_right_stop, 
    output logic player1_up_stop,
    output logic player1_down_stop
    );
    
    
  
    
    always_comb begin
    
    if((((player1_Y >= brick1_Y) && (player1_Y <= (brick1_Y + 30))) || (((player1_Y + 30) >= brick1_Y ) && ((player1_Y + 32) <= (brick1_Y + 32))))
		&& (brickactive == 1'b1) &&(((player1_X >= brick1_X) && (player1_X <= (brick1_X + 29))) || (((player1_X + 29) >= brick1_X ) && ((player1_X + 32) <= (brick1_X + 32)))))
		begin 
   
        //2
        if((player1_X + 32) <= brick1_X+6) begin  // Had as 3 originally with it working
			player1_left_stop = 1'b0;
			player1_right_stop = 1'b1;
			player1_up_stop = 1'b0;
			player1_down_stop = 1'b0;
		end
		else begin end
		//27
		if(player1_X >= (brick1_X + 26)) begin   // Had as 28 originally with it working
			player1_left_stop = 1'b1;
			player1_right_stop = 1'b0;
			player1_up_stop = 1'b0;
			player1_down_stop = 1'b0;
		end
		else begin end
		//28
		if(player1_Y >= (brick1_Y + 27)) begin  //Had as 29 originally with it working
			player1_left_stop = 1'b0;
			player1_right_stop = 1'b0;
			player1_up_stop = 1'b1;
			player1_down_stop = 1'b0;
		end
		else begin end
		//4
		if((player1_Y + 32) <= (brick1_Y+6)) begin  //Had as 3 originally with it working
			player1_left_stop = 1'b0;
			player1_right_stop = 1'b0;
			player1_up_stop = 1'b0;
			player1_down_stop = 1'b1;
		end
		else begin end
		
		end
		
	else begin
			player1_left_stop = 1'b0;
			player1_right_stop = 1'b0;
			player1_up_stop = 1'b0;
			player1_down_stop = 1'b0;
		end
        
    
        end
        

    
    
    
    

	
    
    
    
  
    
endmodule
