`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/28/2023 09:41:56 PM
// Design Name: 
// Module Name: bullmove
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


module bullmove(
    input logic  frame_clk,
    input logic Reset,
    
    input logic [11:0]  p1_X, p1_Y, 
    input logic [1:0] direction_flag,
    input logic bullet_init,
    input logic bull_hit,
    
    output logic [11:0]  bull_X, bull_Y, 
    output logic [1:0] bull_direction_out,
    output logic bull_live
               
    );
    logic [11:0] bull_X_Motion, bull_Y_Motion, bull_X_Motionright, bull_Y_Motionright, bull_X_Motionleft, bull_Y_Motionleft, bull_X_Motionup, bull_Y_Motionup, bull_X_Motiondown, bull_Y_Motiondown;
     logic [11:0] initial_bull_X, initial_bull_Y, tmpx, tmpy, tmpxright, tmpyright, tmpxleft, tmpyleft, tmpxup, tmpyup, tmpxdown, tmpydown;
     logic [1:0] tmpflag;
     logic [1:0] bull_direction;
     always_comb begin
        bull_Y_Motionright = 10'd0;
        bull_X_Motionright = 10'd6;
        bull_Y_Motionleft = 10'd0;
        bull_X_Motionleft = -10'd6;
        bull_Y_Motionup = -10'd6;
        bull_X_Motionup = 10'd0;
        bull_Y_Motiondown = 10'd6;
        bull_X_Motiondown = 10'd0;
     
        initial_bull_X = p1_X;
        initial_bull_Y = p1_Y;
        
        
        tmpxright = initial_bull_X + 33;
        tmpyright = initial_bull_Y + 12;
        tmpxleft = initial_bull_X - 16;
        tmpyleft = initial_bull_Y + 12;
        tmpxup = initial_bull_X + 12;
        tmpyup = initial_bull_Y - 16;
        tmpxdown = initial_bull_X + 12;
        tmpydown = initial_bull_Y + 33;
     
     
     
     end
     
     
     
     
     
     always_ff @ (posedge frame_clk or posedge Reset) begin
    if(Reset)begin
            bull_Y_Motion <= 10'd0; //Ball_Y_Step;
			bull_X_Motion <= 10'd0; //Ball_X_Step;
			bull_Y <= 0;
			bull_X <= 0;
			bull_direction <= 2'b00;
			bull_live <= 1'b0;
    end
    
    else begin
    bull_direction <= direction_flag;
    if(bullet_init == 1'b1)
    begin
        bull_live <= 1'b1;
        if(bull_direction == 2'b01) begin
        bull_Y_Motion <= bull_Y_Motionright;
        bull_X_Motion <= bull_X_Motionright;
        bull_Y <= (tmpyright + bull_Y_Motionright);  // Update ball position
        bull_X <= (tmpxright + bull_X_Motionright);
        bull_direction_out <= bull_direction;
        end
        if(bull_direction == 2'b10) begin
        bull_Y <= (tmpyleft + bull_Y_Motionleft);  // Update ball position
        bull_X <= (tmpxleft + bull_X_Motionleft);
        bull_Y_Motion <= bull_Y_Motionleft;
        bull_X_Motion <= bull_X_Motionleft;
        bull_direction_out <= bull_direction;
        
        end
        if(bull_direction == 2'b00) begin
        bull_Y <= (tmpyup + bull_Y_Motionup);  // Update ball position
        bull_X <= (tmpxup + bull_X_Motionup);
        bull_Y_Motion <= bull_Y_Motionup;
        bull_X_Motion <= bull_X_Motionup;
        bull_direction_out <= bull_direction;
        end
        if(bull_direction == 2'b11) begin
        bull_Y <= (tmpydown + bull_Y_Motiondown);  // Update ball position
        bull_X <= (tmpxdown + bull_X_Motiondown);
        bull_Y_Motion <= bull_Y_Motiondown;
        bull_X_Motion <= bull_X_Motiondown;
        bull_direction_out <= bull_direction;
        end
        
        
        
    end
 
    else begin
     bull_Y <= (bull_Y + bull_Y_Motion);  // Update ball position
     bull_X <= (bull_X + bull_X_Motion);
     
     if(bull_X <= 64 || bull_X >= 559 || bull_Y <= 32 || bull_Y >= 399) begin
        bull_live <= 1'b0;
        bull_Y_Motion <= 12'd0;
        bull_X_Motion <= 12'd0;
        end
    end
    if(bull_hit == 1'b0) begin
        bull_live <= 1'b0;
        bull_Y_Motion <= 12'd0;
        bull_X_Motion <= 12'd0;
        end
    
    end
    
    
    
    
    
    
    
    end
   
    
    
    
endmodule
