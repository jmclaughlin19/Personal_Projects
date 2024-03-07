`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/03/2023 05:00:48 PM
// Design Name: 
// Module Name: enemy1_move
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


module enemy_move(
    input logic Reset, frame_clk, vga_clk,
	input logic [7:0] keycode, keycode2,
	input logic enemystopL, enemystopR, enemystopU, enemystopD,
	input logic [1:0] enemy_counter,
	input logic start_screen_flag,
    output logic [11:0]  enemy_X, enemy_Y, enemy_S,
    output logic [1:0] direction_flag,
    output logic enemy_bullet_init
    );
    
    logic [11:0] enemy_X_Motion, enemy_Y_Motion;
    logic [31:0] seconds, cur_seconds, cur_seconds2;
    logic rand1, rand2, rand3, rand4, seed_init;
    logic [1:0] randmover;
    logic BOUNCE;
    parameter [11:0] enemy_X_Center=96;  // Center position on the X axis 160 ORIGINALLY 
    parameter [11:0] enemy_Y_Center=96;  // Center position on the Y axis 128 ORIGINALLY
    parameter [11:0] enemy_X_Min=32;       // Leftmost point on the X axis
    parameter [11:0] enemy_X_Max=575;     // Rightmost point on the X axis
    parameter [11:0] enemy_Y_Min=3;       // Topmost point on the Y axis
    parameter [11:0] enemy_Y_Max=415;     // Bottommost point on the Y axis
    parameter [11:0] enemy_X_Step=1;      // Step size on the X axis
    parameter [11:0] enemy_Y_Step=1;      // Step size on the Y axis
    
    assign enemy_S = 32;
    
    always_ff @ (posedge frame_clk or posedge Reset) //make sure the frame clock is instantiated correctly
    begin: Move_Ball
        if (Reset)  // asynchronous Reset
        begin 
            enemy_Y_Motion <= 10'd0; //Ball_Y_Step;
			enemy_X_Motion <= 10'd0; //Ball_X_Step;
			enemy_Y <= enemy_Y_Center;
			enemy_X <= enemy_X_Center;
			direction_flag <= 2'b11;
			cur_seconds <= 32'd0;
			cur_seconds2 <= 32'd0;
			seed_init <= 1'b1;
        end
           
        else if ( start_screen_flag == 1'b0)
        begin 
                if (enemy_counter != 2'b00)  begin
                seed_init <= 1'b0;
                
                if(((seconds == cur_seconds+1))) begin
                    cur_seconds <= seconds;
                    randmover <= {rand1, rand2};    
                    
                end
                
                
                
				 if ( (enemy_Y + enemy_S) >= enemy_Y_Max )begin  // Ball is at the bottom edge, BOUNCE!
					  enemy_Y_Motion <= (~ (enemy_Y_Step) + 1'b1);
					 
					  end
					  
				 else if ( (enemy_Y - enemy_S) <= enemy_Y_Min ) begin  // Ball is at the top edge, BOUNCE!
					  enemy_Y_Motion <= enemy_Y_Step;
					 
					  end
				  else if ( (enemy_X + enemy_S) >= enemy_X_Max )begin  // Ball is at the Right edge, BOUNCE!
					  enemy_X_Motion <= (~ (enemy_X_Step) + 1'b1);
					 
					  end
				 else if ( (enemy_X - enemy_S) <= enemy_X_Min ) begin // Ball is at the Left edge, BOUNCE!
					  enemy_X_Motion <= enemy_X_Step;
					 
					  end
				 else 
					  enemy_Y_Motion <= enemy_Y_Motion;  // Ball is somewhere in the middle, don't bounce, just keep moving
					  
				 //modify to control ball motion with the keycode
				 if (((randmover == 2'b00))&& (enemystopU == 1'b0) && (seconds >= cur_seconds2 +8))
				    begin
				    direction_flag <= 2'b00;
                     enemy_Y_Motion <= -10'd2;
                     enemy_X_Motion <= 10'd0;
                     if ( (enemy_Y + enemy_S) >= enemy_Y_Max )  // Ball is at the bottom edge, BOUNCE!
					  enemy_Y_Motion <= (~ (enemy_Y_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_Y - enemy_S) <= enemy_Y_Min )  // Ball is at the top edge, BOUNCE!
					  enemy_Y_Motion <= enemy_Y_Step;
					  
				  else if ( (enemy_X + enemy_S) >= enemy_X_Max )  // Ball is at the Right edge, BOUNCE!
					  enemy_X_Motion <= (~ (enemy_X_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_X - enemy_S) <= enemy_X_Min )  // Ball is at the Left edge, BOUNCE!
					  enemy_X_Motion <= enemy_X_Step;
					  
                    end
                 
                 else if (((randmover == 2'b10)) && (enemystopL == 1'b0)&& (seconds >= cur_seconds2 +5))
				    begin
				    direction_flag <= 2'b10;
                     enemy_Y_Motion <= 10'd0;
                     enemy_X_Motion <= -10'd2;
                     if ( (enemy_Y + enemy_S) >= enemy_Y_Max )  // Ball is at the bottom edge, BOUNCE!
					  enemy_Y_Motion <= (~ (enemy_Y_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_Y - enemy_S) <= enemy_Y_Min )  // Ball is at the top edge, BOUNCE!
					  enemy_Y_Motion <= enemy_Y_Step;
					  
				  else if ( (enemy_X + enemy_S) >= enemy_X_Max )  // Ball is at the Right edge, BOUNCE!
					  enemy_X_Motion <= (~ (enemy_X_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_X - enemy_S) <= enemy_X_Min )  // Ball is at the Left edge, BOUNCE!
					  enemy_X_Motion <= enemy_X_Step;
					  
                    end
                    
                  else if (((randmover == 2'b01)) && (enemystopR == 1'b0)&& (seconds >= cur_seconds2 +5))
				    begin
				    direction_flag <= 2'b01;
                     enemy_Y_Motion <= 10'd0;
                     enemy_X_Motion <= 10'd2;
                     if ( (enemy_Y + enemy_S) >= enemy_Y_Max )  // Ball is at the bottom edge, BOUNCE!
					  enemy_Y_Motion <= (~ (enemy_Y_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_Y - enemy_S) <= enemy_Y_Min )  // Ball is at the top edge, BOUNCE!
					  enemy_Y_Motion <= enemy_Y_Step;
					  
				  else if ( (enemy_X + enemy_S) >= enemy_X_Max )  // Ball is at the Right edge, BOUNCE!
					  enemy_X_Motion <= (~ (enemy_X_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_X - enemy_S) <= enemy_X_Min )  // Ball is at the Left edge, BOUNCE!
					  enemy_X_Motion <= enemy_X_Step;
					  
                    end  
                    
                 else if (((randmover == 2'b11)) && (enemystopD == 1'b0)&& (seconds >= cur_seconds2 +5))
				    begin
				    direction_flag <= 2'b11;
                     enemy_Y_Motion <= 10'd2;
                     enemy_X_Motion <= 10'd0;
                     if ( (enemy_Y + enemy_S) >= enemy_Y_Max )  // Ball is at the bottom edge, BOUNCE!
					  enemy_Y_Motion <= (~ (enemy_Y_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_Y - enemy_S) <= enemy_Y_Min )  // Ball is at the top edge, BOUNCE!
					  enemy_Y_Motion <= enemy_Y_Step;
					  
				  else if ( (enemy_X + enemy_S) >= enemy_X_Max )  // Ball is at the Right edge, BOUNCE!
					  enemy_X_Motion <= (~ (enemy_X_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_X - enemy_S) <= enemy_X_Min )  // Ball is at the Left edge, BOUNCE!
					  enemy_X_Motion <= enemy_X_Step;
					  
                    end
                    
                    
                    
                 if (((randmover == 2'b00)) && (enemystopU == 1'b1)&& (seconds >= cur_seconds2 +5)) begin
                     enemy_Y_Motion <= 10'd0;
                     enemy_X_Motion <= 10'd0;
                 
                 end 
                 
                 if (((randmover == 2'b10)) && (enemystopL == 1'b1)&& (seconds >= cur_seconds2 +5)) begin
                     enemy_Y_Motion <= 10'd0;
                     enemy_X_Motion <= 10'd0;
                 
                 end
                 
                 if (((randmover == 2'b01)) && (enemystopR == 1'b1)&& (seconds >= cur_seconds2 +5)) begin
                     enemy_Y_Motion <= 10'd0;
                     enemy_X_Motion <= 10'd0;
                     
                 end
                    
                    
                 if (((randmover == 2'b11)) && (enemystopD == 1'b1)&& (seconds >= cur_seconds2 +5)) begin
                     enemy_Y_Motion <= 10'd0;
                     enemy_X_Motion <= 10'd0;
                
                 end   
                 
                 if((rand3 == 1'b1) && (seconds == cur_seconds+1) && (seconds >= cur_seconds2 +5)) begin
                    enemy_bullet_init = 1'b1;
                 end   
                 else begin
                    enemy_bullet_init = 1'b0;
                 end
                    
//				 if ((keycode != 8'h1A) && (keycode != 8'h07) && (keycode != 8'h04) && (keycode != 8'h16) )
//			         begin
//                     enemy_Y_Motion <= 10'd0;
//                     enemy_X_Motion <= 10'd0;
//			         end   
			         
				 enemy_Y <= (enemy_Y + enemy_Y_Motion);  // Update ball position
				 enemy_X <= (enemy_X + enemy_X_Motion);
				 end
				 else begin
		       enemy_Y_Motion <= 10'd0; 
			 enemy_X_Motion <= 10'd0; 
			 enemy_Y <= 12'b0;
			 enemy_X <= 12'b0;
		      end
		end  
		
		
		
    end

    
    
singlesecond_counter timer(
.frame_clk(vga_clk), .Reset(Reset), .start_screen_flag(start_screen_flag), .seconds(seconds)
);

LFSR randvalue1(  
   .i_Clk(frame_clk),
   .i_Enable(1'b1),
   .i_Seed_DV(seed_init),
   .i_Seed_Data(16'hABCD),
   .o_LFSR_Data(rand1),
   .o_LFSR_Done()
);

LFSR randvalue2(  
   .i_Clk(frame_clk),
   .i_Enable(1'b1),
   .i_Seed_DV(seed_init),
   .i_Seed_Data(16'h1234),
   .o_LFSR_Data(rand2),
   .o_LFSR_Done()
);


LFSR randvalue3(  
   .i_Clk(frame_clk),
   .i_Enable(1'b1),
   .i_Seed_DV(seed_init),
   .i_Seed_Data(16'h5678),
   .o_LFSR_Data(rand3),
   .o_LFSR_Done()
);





    
//Randbit first( .Clk(frame_clk), .Reset(Reset),
//       .e(rand1)  
//    );
       
//Randbit2 second( .Clk(frame_clk), .Reset(Reset),
//       .d(rand2)  
//    );
       
//Randbit3 third( .Clk(frame_clk), .Reset(Reset),
//       .d(rand3)  
//    );
       
//Randbit4 fourth( .Clk(frame_clk), .Reset(Reset),
//       .e(rand4)  
//    );
    
endmodule


module singlesecond_counter(input frame_clk, input Reset, input logic start_screen_flag, output logic [31:0] seconds);
    logic [31:0] count = 0;
    always @(posedge frame_clk or posedge Reset) begin
        if (Reset)begin
            seconds <= 0;
        end
        else if (start_screen_flag == 1'b0) begin
            if (count == 12500000 - 1) begin
             count <= 0;
             seconds <= seconds + 1;
         end 
         else begin
               count <= count + 1;
        end
        end
    end
endmodule



// We referenced this module online as per our project proposal https://nandland.com/lfsr-linear-feedback-shift-register/
module LFSR 
  (
   input i_Clk,
   input i_Enable,
 
   // Optional Seed Value
   input i_Seed_DV,
   input [15:0] i_Seed_Data,
 
   output [15:0] o_LFSR_Data,
   output o_LFSR_Done
   );
 
  reg [16:1] r_LFSR = 0;
  reg              r_XNOR;
 
 
  // Purpose: Load up LFSR with Seed if Data Valid (DV) pulse is detected.
  // Othewise just run LFSR when enabled.
  always @(posedge i_Clk)
    begin
      if (i_Enable == 1'b1)
        begin
          if (i_Seed_DV == 1'b1)
            r_LFSR <= i_Seed_Data;
          else
            r_LFSR <= {r_LFSR[15:1], r_XNOR};
        end
    end
 
  // Create Feedback Polynomials.  Based on Application Note:
  // http://www.xilinx.com/support/documentation/application_notes/xapp052.pdf
  always @(*)
    begin
          r_XNOR = r_LFSR[16] ^~ r_LFSR[15] ^~ r_LFSR[13] ^~ r_LFSR[4];
    end // always @ (*)
 
 
  assign o_LFSR_Data = r_LFSR[1];
 
  // Conditional Assignment (?)
  assign o_LFSR_Done = (r_LFSR[16:1] == i_Seed_Data) ? 1'b1 : 1'b0;
 
endmodule // LFSR
 








///////////////////////////////////////////////////////////










module enemy2_move(
    input logic Reset, frame_clk, vga_clk,
	input logic [7:0] keycode, keycode2,
	input logic enemystopL, enemystopR, enemystopU, enemystopD, 
	input logic start_screen_flag,

	input logic [1:0] enemy_counter,
                            output logic [11:0]  enemy_X, enemy_Y, enemy_S,
    output logic [1:0] direction_flag,
    output logic enemy_bullet_init
    );
    
    logic [11:0] enemy_X_Motion, enemy_Y_Motion;
    logic [31:0] seconds, cur_seconds, cur_seconds2;
    logic rand1, rand2, rand3, rand4, seed_init;
    logic [1:0] randmover;
    logic BOUNCE;
    parameter [11:0] enemy_X_Center=512;  // Center position on the X axis 160 ORIGINALLY 
    parameter [11:0] enemy_Y_Center=64;  // Center position on the Y axis 128 ORIGINALLY
    parameter [11:0] enemy_X_Min=32;       // Leftmost point on the X axis
    parameter [11:0] enemy_X_Max=575;     // Rightmost point on the X axis
    parameter [11:0] enemy_Y_Min=3;       // Topmost point on the Y axis
    parameter [11:0] enemy_Y_Max=415;     // Bottommost point on the Y axis
    parameter [11:0] enemy_X_Step=1;      // Step size on the X axis
    parameter [11:0] enemy_Y_Step=1;      // Step size on the Y axis
    
    assign enemy_S = 32;
    
    always_ff @ (posedge frame_clk or posedge Reset) //make sure the frame clock is instantiated correctly
    begin: Move_Ball
        if (Reset)  // asynchronous Reset
        begin 
            enemy_Y_Motion <= 10'd0; //Ball_Y_Step;
			enemy_X_Motion <= 10'd0; //Ball_X_Step;
			enemy_Y <= enemy_Y_Center;
			enemy_X <= enemy_X_Center;
			direction_flag <= 2'b10;
			cur_seconds <= 32'd0;
			cur_seconds2 <= 32'd0;
			seed_init <= 1'b1;
        end
           
        else if (start_screen_flag == 1'b0)
        begin 
                if (enemy_counter != 2'b00)  begin
                seed_init <= 1'b0;
                
                if(((seconds == cur_seconds+1))) begin
                    cur_seconds <= seconds;
                    randmover <= {rand1, rand2};    
                    
                end
                
                
                
				 if ( (enemy_Y + enemy_S) >= enemy_Y_Max )begin  // Ball is at the bottom edge, BOUNCE!
					  enemy_Y_Motion <= (~ (enemy_Y_Step) + 1'b1);
					 
					  end
					  
				 else if ( (enemy_Y - enemy_S) <= enemy_Y_Min ) begin  // Ball is at the top edge, BOUNCE!
					  enemy_Y_Motion <= enemy_Y_Step;
					 
					  end
				  else if ( (enemy_X + enemy_S) >= enemy_X_Max )begin  // Ball is at the Right edge, BOUNCE!
					  enemy_X_Motion <= (~ (enemy_X_Step) + 1'b1);
					 
					  end
				 else if ( (enemy_X - enemy_S) <= enemy_X_Min ) begin // Ball is at the Left edge, BOUNCE!
					  enemy_X_Motion <= enemy_X_Step;
					 
					  end
				 else 
					  enemy_Y_Motion <= enemy_Y_Motion;  // Ball is somewhere in the middle, don't bounce, just keep moving
					  
				 //modify to control ball motion with the keycode
				 if (((randmover == 2'b00))&& (enemystopU == 1'b0) && (seconds >= cur_seconds2 +5))
				    begin
				    direction_flag <= 2'b00;
                     enemy_Y_Motion <= -10'd2;
                     enemy_X_Motion <= 10'd0;
                     if ( (enemy_Y + enemy_S) >= enemy_Y_Max )  // Ball is at the bottom edge, BOUNCE!
					  enemy_Y_Motion <= (~ (enemy_Y_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_Y - enemy_S) <= enemy_Y_Min )  // Ball is at the top edge, BOUNCE!
					  enemy_Y_Motion <= enemy_Y_Step;
					  
				  else if ( (enemy_X + enemy_S) >= enemy_X_Max )  // Ball is at the Right edge, BOUNCE!
					  enemy_X_Motion <= (~ (enemy_X_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_X - enemy_S) <= enemy_X_Min )  // Ball is at the Left edge, BOUNCE!
					  enemy_X_Motion <= enemy_X_Step;
					  
                    end
                 
                 else if (((randmover == 2'b10)) && (enemystopL == 1'b0)&& (seconds >= cur_seconds2 +5))
				    begin
				    direction_flag <= 2'b10;
                     enemy_Y_Motion <= 10'd0;
                     enemy_X_Motion <= -10'd2;
                     if ( (enemy_Y + enemy_S) >= enemy_Y_Max )  // Ball is at the bottom edge, BOUNCE!
					  enemy_Y_Motion <= (~ (enemy_Y_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_Y - enemy_S) <= enemy_Y_Min )  // Ball is at the top edge, BOUNCE!
					  enemy_Y_Motion <= enemy_Y_Step;
					  
				  else if ( (enemy_X + enemy_S) >= enemy_X_Max )  // Ball is at the Right edge, BOUNCE!
					  enemy_X_Motion <= (~ (enemy_X_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_X - enemy_S) <= enemy_X_Min )  // Ball is at the Left edge, BOUNCE!
					  enemy_X_Motion <= enemy_X_Step;
					  
                    end
                    
                  else if (((randmover == 2'b01)) && (enemystopR == 1'b0)&& (seconds >= cur_seconds2 +5))
				    begin
				    direction_flag <= 2'b01;
                     enemy_Y_Motion <= 10'd0;
                     enemy_X_Motion <= 10'd2;
                     if ( (enemy_Y + enemy_S) >= enemy_Y_Max )  // Ball is at the bottom edge, BOUNCE!
					  enemy_Y_Motion <= (~ (enemy_Y_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_Y - enemy_S) <= enemy_Y_Min )  // Ball is at the top edge, BOUNCE!
					  enemy_Y_Motion <= enemy_Y_Step;
					  
				  else if ( (enemy_X + enemy_S) >= enemy_X_Max )  // Ball is at the Right edge, BOUNCE!
					  enemy_X_Motion <= (~ (enemy_X_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_X - enemy_S) <= enemy_X_Min )  // Ball is at the Left edge, BOUNCE!
					  enemy_X_Motion <= enemy_X_Step;
					  
                    end  
                    
                 else if (((randmover == 2'b11)) && (enemystopD == 1'b0)&& (seconds >= cur_seconds2 +5))
				    begin
				    direction_flag <= 2'b11;
                     enemy_Y_Motion <= 10'd2;
                     enemy_X_Motion <= 10'd0;
                     if ( (enemy_Y + enemy_S) >= enemy_Y_Max )  // Ball is at the bottom edge, BOUNCE!
					  enemy_Y_Motion <= (~ (enemy_Y_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_Y - enemy_S) <= enemy_Y_Min )  // Ball is at the top edge, BOUNCE!
					  enemy_Y_Motion <= enemy_Y_Step;
					  
				  else if ( (enemy_X + enemy_S) >= enemy_X_Max )  // Ball is at the Right edge, BOUNCE!
					  enemy_X_Motion <= (~ (enemy_X_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_X - enemy_S) <= enemy_X_Min )  // Ball is at the Left edge, BOUNCE!
					  enemy_X_Motion <= enemy_X_Step;
					  
                    end
                    
                    
                    
                 if (((randmover == 2'b00)) && (enemystopU == 1'b1)&& (seconds >= cur_seconds2 +5)) begin
                     enemy_Y_Motion <= 10'd0;
                     enemy_X_Motion <= 10'd0;
                 
                 end 
                 
                 if (((randmover == 2'b10)) && (enemystopL == 1'b1)&& (seconds >= cur_seconds2 +5)) begin
                     enemy_Y_Motion <= 10'd0;
                     enemy_X_Motion <= 10'd0;
                 
                 end
                 
                 if (((randmover == 2'b01)) && (enemystopR == 1'b1)&& (seconds >= cur_seconds2 +5)) begin
                     enemy_Y_Motion <= 10'd0;
                     enemy_X_Motion <= 10'd0;
                     
                 end
                    
                    
                 if (((randmover == 2'b11)) && (enemystopD == 1'b1)&& (seconds >= cur_seconds2 +5)) begin
                     enemy_Y_Motion <= 10'd0;
                     enemy_X_Motion <= 10'd0;
                
                 end   
                 
                 if((rand3 == 1'b1) && (seconds == cur_seconds+1) && (seconds >= cur_seconds2 +5)) begin
                    enemy_bullet_init = 1'b1;
                 end   
                 else begin
                    enemy_bullet_init = 1'b0;
                 end
                    
//				 if ((keycode != 8'h1A) && (keycode != 8'h07) && (keycode != 8'h04) && (keycode != 8'h16) )
//			         begin
//                     enemy_Y_Motion <= 10'd0;
//                     enemy_X_Motion <= 10'd0;
//			         end   
			         
				 enemy_Y <= (enemy_Y + enemy_Y_Motion);  // Update ball position
				 enemy_X <= (enemy_X + enemy_X_Motion);
				 
				end 
				else begin
		    enemy_Y_Motion <= 10'd0; 
			enemy_X_Motion <= 10'd0; 
			enemy_Y <= 12'b0;
			enemy_X <= 12'b0;
		  end
		end  
		
		
		
    end

    
    
singlesecond_counter2 timer(
.frame_clk(vga_clk), .Reset(Reset), .start_screen_flag(start_screen_flag), .seconds(seconds)
);

LFSR2 randvalue1(  
   .i_Clk(frame_clk),
   .i_Enable(1'b1),
   .i_Seed_DV(seed_init),
   .i_Seed_Data(16'hACBD),
   .o_LFSR_Data(rand1),
   .o_LFSR_Done()
);

LFSR2 randvalue2(  
   .i_Clk(frame_clk),
   .i_Enable(1'b1),
   .i_Seed_DV(seed_init),
   .i_Seed_Data(16'h1594),
   .o_LFSR_Data(rand2),
   .o_LFSR_Done()
);


LFSR2 randvalue3(  
   .i_Clk(frame_clk),
   .i_Enable(1'b1),
   .i_Seed_DV(seed_init),
   .i_Seed_Data(16'h5098),
   .o_LFSR_Data(rand3),
   .o_LFSR_Done()
);





    
//Randbit first( .Clk(frame_clk), .Reset(Reset),
//       .e(rand1)  
//    );
       
//Randbit2 second( .Clk(frame_clk), .Reset(Reset),
//       .d(rand2)  
//    );
       
//Randbit3 third( .Clk(frame_clk), .Reset(Reset),
//       .d(rand3)  
//    );
       
//Randbit4 fourth( .Clk(frame_clk), .Reset(Reset),
//       .e(rand4)  
//    );
    
endmodule


module singlesecond_counter2(input frame_clk, input Reset, input start_screen_flag, output logic [31:0] seconds);
    logic [31:0] count = 0;
    always @(posedge frame_clk or posedge Reset) begin
        if (Reset)begin
            seconds <= 0;
        end
        else if (start_screen_flag == 1'b0) begin
            if (count == 12500000 - 1) begin
             count <= 0;
             seconds <= seconds + 1;
         end 
         else begin
               count <= count + 1;
        end
        end
    end
endmodule



// We referenced this module online as per our project proposal https://nandland.com/lfsr-linear-feedback-shift-register/
module LFSR2 
  (
   input i_Clk,
   input i_Enable,
 
   // Optional Seed Value
   input i_Seed_DV,
   input [15:0] i_Seed_Data,
 
   output [15:0] o_LFSR_Data,
   output o_LFSR_Done
   );
 
  reg [16:1] r_LFSR = 0;
  reg              r_XNOR;
 
 
  // Purpose: Load up LFSR with Seed if Data Valid (DV) pulse is detected.
  // Othewise just run LFSR when enabled.
  always @(posedge i_Clk)
    begin
      if (i_Enable == 1'b1)
        begin
          if (i_Seed_DV == 1'b1)
            r_LFSR <= i_Seed_Data;
          else
            r_LFSR <= {r_LFSR[15:1], r_XNOR};
        end
    end
 
  // Create Feedback Polynomials.  Based on Application Note:
  // http://www.xilinx.com/support/documentation/application_notes/xapp052.pdf
  always @(*)
    begin
          r_XNOR = r_LFSR[16] ^~ r_LFSR[15] ^~ r_LFSR[13] ^~ r_LFSR[4];
    end // always @ (*)
 
 
  assign o_LFSR_Data = r_LFSR[1];
 
  // Conditional Assignment (?)
  assign o_LFSR_Done = (r_LFSR[16:1] == i_Seed_Data) ? 1'b1 : 1'b0;
 
endmodule // LFSR
 









//module Randbit(
//    input logic Clk, Reset,
//    output logic e
//);
//    logic a, b, c, d;
//    assign a = b^e;
    
//    always_ff @(posedge Clk or posedge Reset) begin
//        if(Reset) begin
//        b <= 1'b1;
//        c <= 1'b0;
//        d <= 1'b0;
//        e <= 1'b0;
//        end
        
//        else begin
//        b <= a;
//        c <= b;
//        d <= c;
//        e <= d;
//        end
//    end
     
//endmodule




     






//module Randbit(
//    input logic Clk, Reset,
//    output logic e
//);
//    logic a, b, c, d;
//    assign a = b^e;
    
//    always_ff @(posedge Clk or posedge Reset) begin
//        if(Reset) begin
//        b <= 1'b1;
//        c <= 1'b0;
//        d <= 1'b0;
//        e <= 1'b0;
//        end
        
//        else begin
//        b <= a;
//        c <= b;
//        d <= c;
//        e <= d;
//        end
//    end
     
//endmodule




module enemy3_move(
    input logic Reset, frame_clk, vga_clk,
	input logic [7:0] keycode, keycode2,
	input logic enemystopL, enemystopR, enemystopU, enemystopD,
	input logic [1:0] enemy_counter,
                            output logic [11:0]  enemy_X, enemy_Y, enemy_S,
	input logic start_screen_flag,
    output logic [1:0] direction_flag,
    output logic enemy_bullet_init
    );
    
    logic [11:0] enemy_X_Motion, enemy_Y_Motion;
    logic [31:0] seconds, cur_seconds, cur_seconds2;
    logic rand1, rand2, rand3, rand4, seed_init;
    logic [1:0] randmover;
    logic BOUNCE;
    parameter [11:0] enemy_X_Center=96;  // Center position on the X axis 160 ORIGINALLY 
    parameter [11:0] enemy_Y_Center=352;  // Center position on the Y axis 128 ORIGINALLY
    parameter [11:0] enemy_X_Min=32;       // Leftmost point on the X axis
    parameter [11:0] enemy_X_Max=575;     // Rightmost point on the X axis
    parameter [11:0] enemy_Y_Min=3;       // Topmost point on the Y axis
    parameter [11:0] enemy_Y_Max=415;     // Bottommost point on the Y axis
    parameter [11:0] enemy_X_Step=1;      // Step size on the X axis
    parameter [11:0] enemy_Y_Step=1;      // Step size on the Y axis
    
    assign enemy_S = 32;
    
    always_ff @ (posedge frame_clk or posedge Reset) //make sure the frame clock is instantiated correctly
    begin: Move_Ball
        if (Reset)  // asynchronous Reset
        begin 
            enemy_Y_Motion <= 10'd0; //Ball_Y_Step;
			enemy_X_Motion <= 10'd0; //Ball_X_Step;
			enemy_Y <= enemy_Y_Center;
			enemy_X <= enemy_X_Center;
			direction_flag <= 2'b01;
			cur_seconds <= 32'd0;
			cur_seconds2 <= 32'd0;
			seed_init <= 1'b1;
        end
           
        
       else if(start_screen_flag == 2'b00) 
        begin 
                if ( enemy_counter != 2'b00)begin
                seed_init <= 1'b0;
                
                if(((seconds == cur_seconds+1))) begin
                    cur_seconds <= seconds;
                    randmover <= {rand1, rand2};    
                    
                end
                
                
                
				 if ( (enemy_Y + enemy_S) >= enemy_Y_Max )begin  // Ball is at the bottom edge, BOUNCE!
					  enemy_Y_Motion <= (~ (enemy_Y_Step) + 1'b1);
					 
					  end
					  
				 else if ( (enemy_Y - enemy_S) <= enemy_Y_Min ) begin  // Ball is at the top edge, BOUNCE!
					  enemy_Y_Motion <= enemy_Y_Step;
					 
					  end
				  else if ( (enemy_X + enemy_S) >= enemy_X_Max )begin  // Ball is at the Right edge, BOUNCE!
					  enemy_X_Motion <= (~ (enemy_X_Step) + 1'b1);
					 
					  end
				 else if ( (enemy_X - enemy_S) <= enemy_X_Min ) begin // Ball is at the Left edge, BOUNCE!
					  enemy_X_Motion <= enemy_X_Step;
					 
					  end
				 else 
					  enemy_Y_Motion <= enemy_Y_Motion;  // Ball is somewhere in the middle, don't bounce, just keep moving
					  
				 //modify to control ball motion with the keycode
				 if (((randmover == 2'b00))&& (enemystopU == 1'b0) && (seconds >= cur_seconds2 +5))
				    begin
				    direction_flag <= 2'b00;
                     enemy_Y_Motion <= -10'd2;
                     enemy_X_Motion <= 10'd0;
                     if ( (enemy_Y + enemy_S) >= enemy_Y_Max )  // Ball is at the bottom edge, BOUNCE!
					  enemy_Y_Motion <= (~ (enemy_Y_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_Y - enemy_S) <= enemy_Y_Min )  // Ball is at the top edge, BOUNCE!
					  enemy_Y_Motion <= enemy_Y_Step;
					  
				  else if ( (enemy_X + enemy_S) >= enemy_X_Max )  // Ball is at the Right edge, BOUNCE!
					  enemy_X_Motion <= (~ (enemy_X_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_X - enemy_S) <= enemy_X_Min )  // Ball is at the Left edge, BOUNCE!
					  enemy_X_Motion <= enemy_X_Step;
					  
                    end
                 
                 else if (((randmover == 2'b10)) && (enemystopL == 1'b0)&& (seconds >= cur_seconds2 +5))
				    begin
				    direction_flag <= 2'b10;
                     enemy_Y_Motion <= 10'd0;
                     enemy_X_Motion <= -10'd2;
                     if ( (enemy_Y + enemy_S) >= enemy_Y_Max )  // Ball is at the bottom edge, BOUNCE!
					  enemy_Y_Motion <= (~ (enemy_Y_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_Y - enemy_S) <= enemy_Y_Min )  // Ball is at the top edge, BOUNCE!
					  enemy_Y_Motion <= enemy_Y_Step;
					  
				  else if ( (enemy_X + enemy_S) >= enemy_X_Max )  // Ball is at the Right edge, BOUNCE!
					  enemy_X_Motion <= (~ (enemy_X_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_X - enemy_S) <= enemy_X_Min )  // Ball is at the Left edge, BOUNCE!
					  enemy_X_Motion <= enemy_X_Step;
					  
                    end
                    
                  else if (((randmover == 2'b01)) && (enemystopR == 1'b0)&& (seconds >= cur_seconds2 +5))
				    begin
				    direction_flag <= 2'b01;
                     enemy_Y_Motion <= 10'd0;
                     enemy_X_Motion <= 10'd2;
                     if ( (enemy_Y + enemy_S) >= enemy_Y_Max )  // Ball is at the bottom edge, BOUNCE!
					  enemy_Y_Motion <= (~ (enemy_Y_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_Y - enemy_S) <= enemy_Y_Min )  // Ball is at the top edge, BOUNCE!
					  enemy_Y_Motion <= enemy_Y_Step;
					  
				  else if ( (enemy_X + enemy_S) >= enemy_X_Max )  // Ball is at the Right edge, BOUNCE!
					  enemy_X_Motion <= (~ (enemy_X_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_X - enemy_S) <= enemy_X_Min )  // Ball is at the Left edge, BOUNCE!
					  enemy_X_Motion <= enemy_X_Step;
					  
                    end  
                    
                 else if (((randmover == 2'b11)) && (enemystopD == 1'b0)&& (seconds >= cur_seconds2 +5))
				    begin
				    direction_flag <= 2'b11;
                     enemy_Y_Motion <= 10'd2;
                     enemy_X_Motion <= 10'd0;
                     if ( (enemy_Y + enemy_S) >= enemy_Y_Max )  // Ball is at the bottom edge, BOUNCE!
					  enemy_Y_Motion <= (~ (enemy_Y_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_Y - enemy_S) <= enemy_Y_Min )  // Ball is at the top edge, BOUNCE!
					  enemy_Y_Motion <= enemy_Y_Step;
					  
				  else if ( (enemy_X + enemy_S) >= enemy_X_Max )  // Ball is at the Right edge, BOUNCE!
					  enemy_X_Motion <= (~ (enemy_X_Step) + 1'b1);  // 2's complement.
					  
				 else if ( (enemy_X - enemy_S) <= enemy_X_Min )  // Ball is at the Left edge, BOUNCE!
					  enemy_X_Motion <= enemy_X_Step;
					  
                    end
                    
                    
                    
                 if (((randmover == 2'b00)) && (enemystopU == 1'b1)&& (seconds >= cur_seconds2 +5)) begin
                     enemy_Y_Motion <= 10'd0;
                     enemy_X_Motion <= 10'd0;
                 
                 end 
                 
                 if (((randmover == 2'b10)) && (enemystopL == 1'b1)&& (seconds >= cur_seconds2 +5)) begin
                     enemy_Y_Motion <= 10'd0;
                     enemy_X_Motion <= 10'd0;
                 
                 end
                 
                 if (((randmover == 2'b01)) && (enemystopR == 1'b1)&& (seconds >= cur_seconds2 +5)) begin
                     enemy_Y_Motion <= 10'd0;
                     enemy_X_Motion <= 10'd0;
                     
                 end
                    
                    
                 if (((randmover == 2'b11)) && (enemystopD == 1'b1)&& (seconds >= cur_seconds2 +5)) begin
                     enemy_Y_Motion <= 10'd0;
                     enemy_X_Motion <= 10'd0;
                
                 end   
                 
                 if((rand3 == 1'b1) && (seconds == cur_seconds+1) && (seconds >= cur_seconds2 +5)) begin
                    enemy_bullet_init = 1'b1;
                 end   
                 else begin
                    enemy_bullet_init = 1'b0;
                 end
                    
//				 if ((keycode != 8'h1A) && (keycode != 8'h07) && (keycode != 8'h04) && (keycode != 8'h16) )
//			         begin
//                     enemy_Y_Motion <= 10'd0;
//                     enemy_X_Motion <= 10'd0;
//			         end   
			         
				 enemy_Y <= (enemy_Y + enemy_Y_Motion);  // Update ball position
				 enemy_X <= (enemy_X + enemy_X_Motion);
		end		 
		else begin
		    enemy_Y_Motion <= 10'd0; 
			enemy_X_Motion <= 10'd0; 
			enemy_Y <= 12'b0;
			enemy_X <= 12'b0;
		end
	 
		end  
		
				
    end

    
    
singlesecond_counter3 timer(
.frame_clk(vga_clk), .Reset(Reset), .start_screen_flag(start_screen_flag), .seconds(seconds)
);

LFSR3 randvalue1(  
   .i_Clk(frame_clk),
   .i_Enable(1'b1),
   .i_Seed_DV(seed_init),
   .i_Seed_Data(16'hAAAD),
   .o_LFSR_Data(rand1),
   .o_LFSR_Done()
);

LFSR3 randvalue2(  
   .i_Clk(frame_clk),
   .i_Enable(1'b1),
   .i_Seed_DV(seed_init),
   .i_Seed_Data(16'h1444),
   .o_LFSR_Data(rand2),
   .o_LFSR_Done()
);


LFSR3 randvalue3(  
   .i_Clk(frame_clk),
   .i_Enable(1'b1),
   .i_Seed_DV(seed_init),
   .i_Seed_Data(16'h8978),
   .o_LFSR_Data(rand3),
   .o_LFSR_Done()
);





    
endmodule


module singlesecond_counter3(input frame_clk, input Reset, input logic start_screen_flag, output logic [31:0] seconds);
    logic [31:0] count = 0;
    always @(posedge frame_clk or posedge Reset) begin
        if (Reset)begin
            seconds <= 0;
        end
        else if (start_screen_flag == 1'b0) begin 
        if (count == 12500000 - 1) begin
            count <= 0;
            seconds <= seconds + 1;
       	 end 
        else begin
            count <= count + 1;
        end
	end
    end
endmodule



// We referenced this module online as per our project proposal https://nandland.com/lfsr-linear-feedback-shift-register/
module LFSR3
  (
   input i_Clk,
   input i_Enable,
 
   // Optional Seed Value
   input i_Seed_DV,
   input [15:0] i_Seed_Data,
 
   output [15:0] o_LFSR_Data,
   output o_LFSR_Done
   );
 
  reg [16:1] r_LFSR = 0;
  reg              r_XNOR;
 
 
  // Purpose: Load up LFSR with Seed if Data Valid (DV) pulse is detected.
  // Othewise just run LFSR when enabled.
  always @(posedge i_Clk)
    begin
      if (i_Enable == 1'b1)
        begin
          if (i_Seed_DV == 1'b1)
            r_LFSR <= i_Seed_Data;
          else
            r_LFSR <= {r_LFSR[15:1], r_XNOR};
        end
    end
 
  // Create Feedback Polynomials.  Based on Application Note:
  // http://www.xilinx.com/support/documentation/application_notes/xapp052.pdf
  always @(*)
    begin
          r_XNOR = r_LFSR[16] ^~ r_LFSR[15] ^~ r_LFSR[13] ^~ r_LFSR[4];
    end // always @ (*)
 
 
  assign o_LFSR_Data = r_LFSR[1];
 
  // Conditional Assignment (?)
  assign o_LFSR_Done = (r_LFSR[16:1] == i_Seed_Data) ? 1'b1 : 1'b0;
 
endmodule // LFSR
 









//module Randbit(
//    input logic Clk, Reset,
//    output logic e
//);
//    logic a, b, c, d;
//    assign a = b^e;
    
//    always_ff @(posedge Clk or posedge Reset) begin
//        if(Reset) begin
//        b <= 1'b1;
//        c <= 1'b0;
//        d <= 1'b0;
//        e <= 1'b0;
//        end
        
//        else begin
//        b <= a;
//        c <= b;
//        d <= c;
//        e <= d;
//        end
//    end
     
//endmodule




     




     

