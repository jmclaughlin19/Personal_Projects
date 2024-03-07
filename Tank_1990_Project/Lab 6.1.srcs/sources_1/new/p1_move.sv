`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2023 07:33:06 PM
// Design Name: 
// Module Name: p1_move
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


module p1_move(input logic Reset, frame_clk, vga_clk,
			   input logic [7:0] keycode, keycode2,
			   input logic p1stopL, p1stopR, p1stopU, p1stopD,
			   input logic start_screen_flag,
			   input logic gameover_screen_flag,
               output logic [11:0]  p1_X, p1_Y, p1_S,
               output logic [1:0] direction_flag,
               output logic bullet_init
    );
    
    logic [11:0] p1_X_Motion, p1_Y_Motion;
    logic spacebar;
    parameter [11:0] p1_X_Center=320;  // Center position on the X axis
    parameter [11:0] p1_Y_Center=351;  // Center position on the Y axis 255 WAS THE ORIGINAL
    parameter [11:0] p1_X_Min=32;       // Leftmost point on the X axis
    parameter [11:0] p1_X_Max=575;     // Rightmost point on the X axis
    parameter [11:0] p1_Y_Min=3;       // Topmost point on the Y axis
    parameter [11:0] p1_Y_Max=415;     // Bottommost point on the Y axis
    parameter [11:0] p1_X_Step=1;      // Step size on the X axis
    parameter [11:0] p1_Y_Step=1;      // Step size on the Y axis
    
    assign p1_S = 32;
    
    always_ff @ (posedge frame_clk or posedge Reset) //make sure the frame clock is instantiated correctly
    begin: Move_Ball
        if (Reset)  // asynchronous Reset
        begin 
            p1_Y_Motion <= 10'd0; //Ball_Y_Step;
			p1_X_Motion <= 10'd0; //Ball_X_Step;
			p1_Y <= p1_Y_Center;
			p1_X <= p1_X_Center;
			direction_flag <= 2'b00;
			spacebar <= 1'b0;
        end
        
        else if (gameover_screen_flag == 1'b0 && start_screen_flag == 1'b1) begin
        end
           
        else if (gameover_screen_flag == 1'b0 && start_screen_flag == 1'b0)
        begin 
        
				 if ( (p1_Y + p1_S) >= p1_Y_Max )  // Ball is at the bottom edge, BOUNCE!
					  p1_Y_Motion <= (~ (p1_Y_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (p1_Y - p1_S) <= p1_Y_Min )  // Ball is at the top edge, BOUNCE!
					  p1_Y_Motion <= p1_Y_Step;
					  
				  else if ( (p1_X + p1_S) >= p1_X_Max )  // Ball is at the Right edge, BOUNCE!
					  p1_X_Motion <= (~ (p1_X_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (p1_X - p1_S) <= p1_X_Min )  // Ball is at the Left edge, BOUNCE!
					  p1_X_Motion <= p1_X_Step;
					  
				 else 
					  p1_Y_Motion <= p1_Y_Motion;  // Ball is somewhere in the middle, don't bounce, just keep moving
					  
				 //modify to control ball motion with the keycode
				 if (((keycode == 8'h1A))&& (p1stopU == 1'b0))
				    begin
				    direction_flag <= 2'b00;
                     p1_Y_Motion <= -10'd2;
                     p1_X_Motion <= 10'd0;
                     if ( (p1_Y + p1_S) >= p1_Y_Max )  // Ball is at the bottom edge, BOUNCE!
					  p1_Y_Motion <= (~ (p1_Y_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (p1_Y - p1_S) <= p1_Y_Min )  // Ball is at the top edge, BOUNCE!
					  p1_Y_Motion <= p1_Y_Step;
					  
				  else if ( (p1_X + p1_S) >= p1_X_Max )  // Ball is at the Right edge, BOUNCE!
					  p1_X_Motion <= (~ (p1_X_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (p1_X - p1_S) <= p1_X_Min )  // Ball is at the Left edge, BOUNCE!
					  p1_X_Motion <= p1_X_Step;
					  
                    end
                 
                 else if (((keycode == 8'h04)) && (p1stopL == 1'b0))
				    begin
				    direction_flag <= 2'b10;
                     p1_Y_Motion <= 10'd0;
                     p1_X_Motion <= -10'd2;
                     if ( (p1_Y + p1_S) >= p1_Y_Max )  // Ball is at the bottom edge, BOUNCE!
					  p1_Y_Motion <= (~ (p1_Y_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (p1_Y - p1_S) <= p1_Y_Min )  // Ball is at the top edge, BOUNCE!
					  p1_Y_Motion <= p1_Y_Step;
					  
				  else if ( (p1_X + p1_S) >= p1_X_Max )  // Ball is at the Right edge, BOUNCE!
					  p1_X_Motion <= (~ (p1_X_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (p1_X - p1_S) <= p1_X_Min )  // Ball is at the Left edge, BOUNCE!
					  p1_X_Motion <= p1_X_Step;
					  
                    end
                    
                  else if (((keycode == 8'h07)) && (p1stopR == 1'b0))
				    begin
				    direction_flag <= 2'b01;
                     p1_Y_Motion <= 10'd0;
                     p1_X_Motion <= 10'd2;
                     if ( (p1_Y + p1_S) >= p1_Y_Max )  // Ball is at the bottom edge, BOUNCE!
					  p1_Y_Motion <= (~ (p1_Y_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (p1_Y - p1_S) <= p1_Y_Min )  // Ball is at the top edge, BOUNCE!
					  p1_Y_Motion <= p1_Y_Step;
					  
				  else if ( (p1_X + p1_S) >= p1_X_Max )  // Ball is at the Right edge, BOUNCE!
					  p1_X_Motion <= (~ (p1_X_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (p1_X - p1_S) <= p1_X_Min )  // Ball is at the Left edge, BOUNCE!
					  p1_X_Motion <= p1_X_Step;
					  
                    end  
                    
                 else if (((keycode == 8'h16)) && (p1stopD == 1'b0))
				    begin
				    direction_flag <= 2'b11;
                     p1_Y_Motion <= 10'd2;
                     p1_X_Motion <= 10'd0;
                     if ( (p1_Y + p1_S) >= p1_Y_Max )  // Ball is at the bottom edge, BOUNCE!
					  p1_Y_Motion <= (~ (p1_Y_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (p1_Y - p1_S) <= p1_Y_Min )  // Ball is at the top edge, BOUNCE!
					  p1_Y_Motion <= p1_Y_Step;
					  
				  else if ( (p1_X + p1_S) >= p1_X_Max )  // Ball is at the Right edge, BOUNCE!
					  p1_X_Motion <= (~ (p1_X_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (p1_X - p1_S) <= p1_X_Min )  // Ball is at the Left edge, BOUNCE!
					  p1_X_Motion <= p1_X_Step;
					  
                    end
                    
                    
                    
                 if (((keycode == 8'h1A)) && (p1stopU == 1'b1)) begin
                     p1_Y_Motion <= 10'd0;
                     p1_X_Motion <= 10'd0;
                 
                 end 
                 
                 if (((keycode == 8'h04)) && (p1stopL == 1'b1)) begin
                     p1_Y_Motion <= 10'd0;
                     p1_X_Motion <= 10'd0;
                 
                 end
                 
                 if (((keycode == 8'h07)) && (p1stopR == 1'b1)) begin
                     p1_Y_Motion <= 10'd0;
                     p1_X_Motion <= 10'd0;
                     
                 end
                    
                    
                 if (((keycode == 8'h16)) && (p1stopD == 1'b1)) begin
                     p1_Y_Motion <= 10'd0;
                     p1_X_Motion <= 10'd0;
                
                 end   
                 
                 if(((keycode == 8'h2C) ||(keycode2 == 8'h2C)) && (spacebar ==0)) begin
                    bullet_init <= 1'b1;
                    spacebar <=1;
                 end
                 else if(((keycode == 8'h2C) ||(keycode2 == 8'h2C)) && (spacebar ==1)) begin
                    bullet_init <= 1'b0;
                 end   
                 else begin
                    spacebar <=0;
                    bullet_init <= 1'b0;
                 end
                    
				 if ((keycode != 8'h1A) && (keycode != 8'h07) && (keycode != 8'h04) && (keycode != 8'h16) )
			         begin
                     p1_Y_Motion <= 10'd0;
                     p1_X_Motion <= 10'd0;
			         end   
			         
				 p1_Y <= (p1_Y + p1_Y_Motion);  // Update ball position
				 p1_X <= (p1_X + p1_X_Motion);
				 
				 
		end  
		else begin
		p1_Y_Motion <= 10'd0; 
			 p1_X_Motion <= 10'd0; 
			 p1_Y <= 12'd448;
			 p1_X <= 12'd608;
		end
    end
    
    
 
    
    

endmodule

