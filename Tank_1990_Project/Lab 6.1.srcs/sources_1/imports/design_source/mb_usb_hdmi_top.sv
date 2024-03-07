`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Zuofu Cheng
// 
// Create Date: 12/11/2022 10:48:49 AM
// Design Name: 
// Module Name: mb_usb_hdmi_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// Top level for mb_lwusb test project, copy mb wrapper here from Verilog and modify
// to SV
// Dependencies: microblaze block design
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mb_usb_hdmi_top(
    input logic Clk,
    input logic reset_rtl_0,
    
    //USB signals
    input logic [0:0] gpio_usb_int_tri_i,
    output logic gpio_usb_rst_tri_o,
    input logic usb_spi_miso,
    output logic usb_spi_mosi,
    output logic usb_spi_sclk,
    output logic usb_spi_ss,
    
    //UART
    input logic uart_rtl_0_rxd,
    output logic uart_rtl_0_txd,
    
    //HDMI
    output logic hdmi_tmds_clk_n,
    output logic hdmi_tmds_clk_p,
    output logic [2:0]hdmi_tmds_data_n,
    output logic [2:0]hdmi_tmds_data_p,
        
    //HEX displays
    output logic [7:0] hex_segA,
    output logic [3:0] hex_gridA,
    output logic [7:0] hex_segB,
    output logic [3:0] hex_gridB
    );
    
    logic [31:0] keycode0_gpio, keycode1_gpio;
    logic clk_25MHz, clk_125MHz, clk, clk_100MHz;
    logic locked;
    logic [9:0] drawX, drawY, ballxsig, ballysig, ballsizesig;
    
    logic [31:0] cur_seconds, seconds;
    logic hsync, vsync, vde;
    logic [3:0] red, green, blue;
    logic reset_ah;
    
    assign reset_ah = reset_rtl_0;
    
    
    //Keycode HEX drivers
    HexDriver HexA (
        .clk(Clk),
        .reset(reset_ah),
        .in({keycode0_gpio[31:28], keycode0_gpio[27:24], keycode0_gpio[23:20], keycode0_gpio[19:16]}),
        .hex_seg(hex_segA),
        .hex_grid(hex_gridA)
    );
    
    HexDriver HexB (
        .clk(Clk),
        .reset(reset_ah),
        .in({keycode0_gpio[15:12], keycode0_gpio[11:8], keycode0_gpio[7:4], keycode0_gpio[3:0]}),
        .hex_seg(hex_segB),
        .hex_grid(hex_gridB)
    );
    
    mb_block mb_block_i(
        .clk_100MHz(Clk),
        .gpio_usb_int_tri_i(gpio_usb_int_tri_i),
        .gpio_usb_keycode_0_tri_o(keycode0_gpio),
        .gpio_usb_keycode_1_tri_o(keycode1_gpio),
        .gpio_usb_rst_tri_o(gpio_usb_rst_tri_o),
        .reset_rtl_0(~reset_ah), //Block designs expect active low reset, all other modules are active high
        .uart_rtl_0_rxd(uart_rtl_0_rxd),
        .uart_rtl_0_txd(uart_rtl_0_txd),
        .usb_spi_miso(usb_spi_miso),
        .usb_spi_mosi(usb_spi_mosi),
        .usb_spi_sclk(usb_spi_sclk),
        .usb_spi_ss(usb_spi_ss)
    );
        
    //clock wizard configured with a 1x and 5x clock for HDMI
    clk_wiz_0 clk_wiz (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .reset(reset_ah),
        .locked(locked),
        .clk_in1(Clk)
    );
    
    //VGA Sync signal generator
    vga_controller vga (
        .pixel_clk(clk_25MHz),
        .reset(reset_ah),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );    

    //Real Digital VGA to HDMI converter
    hdmi_tx_0 vga_to_hdmi (
        //Clocking and Reset
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        //Reset is active LOW
        .rst(reset_ah),
        //Color and Sync Signals
        .red(red),
        .green(green),
        .blue(blue),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde),
        
        //aux Data (unused)
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),
        
        //Differential outputs
        .TMDS_CLK_P(hdmi_tmds_clk_p),          
        .TMDS_CLK_N(hdmi_tmds_clk_n),          
        .TMDS_DATA_P(hdmi_tmds_data_p),         
        .TMDS_DATA_N(hdmi_tmds_data_n)          
    );

    
    //Ball Module
//    ball ball_instance(
//        .Reset(reset_ah),
//        .frame_clk(vsync),                    //Figure out what this should be so that the ball will move
//        .keycode(keycode0_gpio[7:0]),    //Notice: only one keycode connected to ball by default
//        .BallX(ballxsig),
//        .BallY(ballysig),
//        .BallS(ballsizesig)
//    );
    
//    //Color Mapper Module   
//    color_mapper color_instance(
//        .BallX(ballxsig),
//        .BallY(ballysig),
//        .DrawX(drawX),
//        .DrawY(drawY),
//        .Ball_size(ballsizesig),
//        .Red(red),
//        .Green(green),
//        .Blue(blue)
//    );

    
    // Motion logic here
    
     logic start_screen_flag, victory_screen_flag, gameover_screen_flag;
     logic [1:0] p1counter1, p1counter2, p1counter3;
    
    logic [11:0] p1xsig, p1ysig, p1sizesig;
    logic [1:0] p1_direction_flag;
    logic bullet_init;
    p1_move p1_motion_contr(
        .Reset(reset_ah),
        .frame_clk(vsync), 
        .vga_clk(clk_25MHz),
        .keycode(keycode0_gpio[7:0]),
        .keycode2(keycode0_gpio[15:8]),
        .start_screen_flag(start_screen_flag),
        .p1_X(p1xsig),
        .p1_Y(p1ysig),
        .p1_S(p1sizesig),
        .direction_flag(p1_direction_flag),
        .bullet_init(bullet_init),
        .gameover_screen_flag(gameover_screen_flag),
        // These things below are inputs
        .p1stopL(p1stopL),
        .p1stopR(p1stopR),
        .p1stopU(p1stopU),
        .p1stopD(p1stopD)
        );
    logic [11:0] bullxsig, bullysig;
    logic [1:0] bull_direction_flag;
    logic bull_live, bullmovelive;
    logic bullet_initializer;
    logic bullhit, bullhit1, bullhit2, bullhit3, bullhit4, bullhit5, bullhit6, bullhit7, bullhit8, bullhit9,
          bullhit10, bullhit11, bullhit12, bullhit13, bullhit14, bullhit15, bullhit16, bullhit17, bullhit18, bullhit19, bullhit20,
          bullhit21, bullhit22, bullhit23, bullhit24, bullhit25, bullhit26, bullhit27, bullhit28, bullhit29, bullhit30,bullhit31, 
          bullhit32, bullhit33, bullhit34, bullhit35 , bullhit36 , bullhit37, bullhit38, bullhit39, bullhit40, bullhit41, bullhit42
           , bullhit43, p1enemy1hit, p1enemy2hit, p1enemy3hit;
    assign bullhit = bullhit1 & bullhit2 & bullhit3 & bullhit4 & bullhit5 & bullhit6 & bullhit7 
                    & bullhit8 & bullhit9 & bullhit10& bullhit11 & bullhit12 & bullhit13 & bullhit14 & bullhit15 & bullhit16 
                    & bullhit17 & bullhit18 & bullhit19 & bullhit20 & bullhit21 & bullhit22 & bullhit23 & bullhit24 & bullhit25
                    & bullhit26 & bullhit27 & bullhit28 & bullhit29 & bullhit30 & bullhit31 & bullhit32 & bullhit33 & bullhit34
                    & bullhit35 & bullhit36 & bullhit37 & bullhit38 & bullhit39 & bullhit40 & bullhit41  & bullhit42  & bullhit43
                    & p1enemy1hit & p1enemy2hit & p1enemy3hit;
    bullmove bullmover1(
        .frame_clk(vsync),
        .Reset(reset_ah),
    
       .p1_X(p1xsig), .p1_Y(p1ysig), 
         .direction_flag(p1_direction_flag),
        .bullet_init(bullet_initializer),
        .bull_hit(bullhit),
    
         .bull_X(bullxsig), .bull_Y(bullysig), 
        .bull_direction_out(bull_direction_flag),
        .bull_live(bull_live)
    );
    assign bullet_initializer = (bullet_init &&( ~bull_live) );
    
    
    
    
    
    
    
    
 
    
    
    
    
    
    
  //  BEGIN ENEMY1 TEST LOGIC DEFINITIONS
    
    
    
      logic [1:0] enemy1_direction_flag;
    
    
    logic enemy1stopL, enemy1stopR, enemy1stopU, enemy1stopD, enemy1stopL1, enemy1stopR1, enemy1stopU1, enemy1stopD1,  enemy1stopL2, enemy1stopR2, enemy1stopU2, enemy1stopD2;
    logic enemy1stopL3, enemy1stopR3, enemy1stopU3, enemy1stopD3, enemy1stopL4, enemy1stopR4, enemy1stopU4, enemy1stopD4,  enemy1stopL5, enemy1stopR5, enemy1stopU5, enemy1stopD5;
    logic enemy1stopL6, enemy1stopR6, enemy1stopU6, enemy1stopD6, enemy1stopL7, enemy1stopR7, enemy1stopU7, enemy1stopD7,  enemy1stopL8, enemy1stopR8, enemy1stopU8, enemy1stopD8;
    logic enemy1stopL9, enemy1stopR9, enemy1stopU9, enemy1stopD9, enemy1stopL10, enemy1stopR10, enemy1stopU10, enemy1stopD10,  enemy1stopL11, enemy1stopR11, enemy1stopU11, enemy1stopD11;
    logic enemy1stopL12, enemy1stopR12, enemy1stopU12, enemy1stopD12, enemy1stopL13, enemy1stopR13, enemy1stopU13, enemy1stopD13,  enemy1stopL14, enemy1stopR14, enemy1stopU14, enemy1stopD14;
    logic enemy1stopL15, enemy1stopR15, enemy1stopU15, enemy1stopD15, enemy1stopL16, enemy1stopR16, enemy1stopU16, enemy1stopD16,  enemy1stopL17, enemy1stopR17, enemy1stopU17, enemy1stopD17;
    logic enemy1stopL18, enemy1stopR18, enemy1stopU18, enemy1stopD18, enemy1stopL19, enemy1stopR19, enemy1stopU19, enemy1stopD19, enemy1stopL20, enemy1stopR20, enemy1stopU20, enemy1stopD20;
    logic enemy1stopL21, enemy1stopR21, enemy1stopU21, enemy1stopD21, enemy1stopL22, enemy1stopR22, enemy1stopU22, enemy1stopD22, enemy1stopL23, enemy1stopR23, enemy1stopU23, enemy1stopD23;
    logic enemy1stopL24, enemy1stopR24, enemy1stopU24, enemy1stopD24, enemy1stopL25, enemy1stopR25, enemy1stopU25, enemy1stopD25, enemy1stopL26, enemy1stopR26, enemy1stopU26, enemy1stopD26;
    logic enemy1stopL27, enemy1stopR27, enemy1stopU27, enemy1stopD27, enemy1stopL28, enemy1stopR28, enemy1stopU28, enemy1stopD28, enemy1stopL29, enemy1stopR29, enemy1stopU29, enemy1stopD29;
    logic enemy1stopL31, enemy1stopR31, enemy1stopU31, enemy1stopD31, enemy1stopL32, enemy1stopR32, enemy1stopU32, enemy1stopD32, enemy1stopL33, enemy1stopR33, enemy1stopU33, enemy1stopD33;
    logic enemy1stopL30, enemy1stopR30, enemy1stopU30, enemy1stopD30, enemy1stopL34, enemy1stopR34, enemy1stopU34, enemy1stopD34, enemy1stopL35, enemy1stopR35, enemy1stopU35, enemy1stopD35;
    logic enemy1stopL36, enemy1stopR36, enemy1stopU36, enemy1stopD36 , enemy1stopL37, enemy1stopR37, enemy1stopU37, enemy1stopD37 , enemy1stopL38, enemy1stopR38, enemy1stopU38, enemy1stopD38;
    logic enemy1stopL39, enemy1stopR39, enemy1stopU39, enemy1stopD39 , enemy1stopL40, enemy1stopR40, enemy1stopU40, enemy1stopD40 , enemy1stopL41, enemy1stopR41, enemy1stopU41, enemy1stopD41;
    logic enemy1stopL42, enemy1stopR42, enemy1stopU42, enemy1stopD42,enemy1stopL43, enemy1stopR43, enemy1stopU43, enemy1stopD43;
    assign enemy1stopL = enemy1stopL1 | enemy1stopL2 | enemy1stopL3 | enemy1stopL4 |enemy1stopL5| enemy1stopL6 | enemy1stopL7 |enemy1stopL8 | enemy1stopL9 | enemy1stopL10 |enemy1stopL11
                     |enemy1stopL12 |enemy1stopL13 |enemy1stopL14 |enemy1stopL15 |enemy1stopL16 |enemy1stopL17 |enemy1stopL18 |enemy1stopL19 |enemy1stopL20 
                     |enemy1stopL21 |enemy1stopL22 |enemy1stopL23 |enemy1stopL24 |enemy1stopL25 |enemy1stopL26 | enemy1stopL27 | enemy1stopL28 | enemy1stopL29 | enemy1stopL30
                     |enemy1stopL31 |enemy1stopL32 |enemy1stopL33  |enemy1stopL34 |enemy1stopL35 |enemy1stopL36 |enemy1stopL37|enemy1stopL38
                     |enemy1stopL39 |enemy1stopL40 |enemy1stopL41 |enemy1stopL42 |enemy1stopL43;
    assign enemy1stopR = enemy1stopR1 | enemy1stopR2 | enemy1stopR3 | enemy1stopR4 |enemy1stopR5| enemy1stopR6 | enemy1stopR7 |enemy1stopR8 | enemy1stopR9 | enemy1stopR10 |enemy1stopR11
                     |enemy1stopR12 |enemy1stopR13 |enemy1stopR14 |enemy1stopR15 |enemy1stopR16 |enemy1stopR17 |enemy1stopR18 |enemy1stopR19 |enemy1stopR20
                     |enemy1stopR21 |enemy1stopR22 |enemy1stopR23 |enemy1stopR24 |enemy1stopR25|enemy1stopR26 | enemy1stopR27 | enemy1stopR28 | enemy1stopR29 | enemy1stopR30
                     |enemy1stopR31 |enemy1stopR32 |enemy1stopR33 |enemy1stopR34 |enemy1stopR35 |enemy1stopR36 |enemy1stopR37|enemy1stopR38
                     |enemy1stopR39 |enemy1stopR40 |enemy1stopR41|enemy1stopR42 |enemy1stopR43;
    assign enemy1stopU = enemy1stopU1 | enemy1stopU2 | enemy1stopU3 | enemy1stopU4 |enemy1stopU5| enemy1stopU6 | enemy1stopU7 |enemy1stopU8 | enemy1stopU9 | enemy1stopU10 |enemy1stopU11
                    |enemy1stopU12 |enemy1stopU13 |enemy1stopU14 |enemy1stopU15 |enemy1stopU16 |enemy1stopU17 |enemy1stopU18 |enemy1stopU19 |enemy1stopU20
                     |enemy1stopU21 |enemy1stopU22 |enemy1stopU23 |enemy1stopU24 |enemy1stopU25|enemy1stopU26 | enemy1stopU27 | enemy1stopU28 | enemy1stopU29 | enemy1stopU30
                     |enemy1stopU31 |enemy1stopU32 |enemy1stopU33 |enemy1stopU34 |enemy1stopU35 |enemy1stopU36 |enemy1stopU37|enemy1stopU38
                     |enemy1stopU39 |enemy1stopU40 |enemy1stopU41|enemy1stopU42 |enemy1stopU43;
    assign enemy1stopD = enemy1stopD1 | enemy1stopD2 | enemy1stopD3 | enemy1stopD4 |enemy1stopD5| enemy1stopD6 | enemy1stopD7 |enemy1stopD8 | enemy1stopD9 | enemy1stopD10 |enemy1stopD11
                    |enemy1stopD12 |enemy1stopD13 |enemy1stopD14 |enemy1stopD15 |enemy1stopD16 |enemy1stopD17 |enemy1stopD18 |enemy1stopD19 |enemy1stopD20
                    |enemy1stopD21 |enemy1stopD22 |enemy1stopD23 |enemy1stopD24 | enemy1stopD25|enemy1stopD26 | enemy1stopD27 | enemy1stopD28 | enemy1stopD29 | enemy1stopD30
                     |enemy1stopD31 |enemy1stopD32 |enemy1stopD33 |enemy1stopD34 |enemy1stopD35 |enemy1stopD36 |enemy1stopD37|enemy1stopD38
                      |enemy1stopD39 |enemy1stopD40 |enemy1stopD41|enemy1stopD42 |enemy1stopD43;

    
    
    
    
    logic enemy1bullhit, enemy1bullhit1, enemy1bullhit2, enemy1bullhit3, enemy1bullhit4, enemy1bullhit5, enemy1bullhit6, enemy1bullhit7, enemy1bullhit8, enemy1bullhit9,
          enemy1bullhit10, enemy1bullhit11, enemy1bullhit12, enemy1bullhit13, enemy1bullhit14, enemy1bullhit15, enemy1bullhit16, enemy1bullhit17, enemy1bullhit18, enemy1bullhit19, enemy1bullhit20,
          enemy1bullhit21, enemy1bullhit22, enemy1bullhit23, enemy1bullhit24, enemy1bullhit25, enemy1bullhit26, enemy1bullhit27, enemy1bullhit28, enemy1bullhit29, enemy1bullhit30,enemy1bullhit31, 
          enemy1bullhit32, enemy1bullhit33, enemy1bullhit34, enemy1bullhit35 , enemy1bullhit36 , enemy1bullhit37, enemy1bullhit38, enemy1bullhit39, enemy1bullhit40, enemy1bullhit41, enemy1bullhit42 
          , enemy1bullhit43, enemy1p1hit;
    assign enemy1bullhit = enemy1bullhit1 & enemy1bullhit2 & enemy1bullhit3 & enemy1bullhit4 & enemy1bullhit5 & enemy1bullhit6 & enemy1bullhit7 
                    & enemy1bullhit8 & enemy1bullhit9 & enemy1bullhit10& enemy1bullhit11 & enemy1bullhit12 & enemy1bullhit13 & enemy1bullhit14 & enemy1bullhit15 & enemy1bullhit16 
                    & enemy1bullhit17 & enemy1bullhit18 & enemy1bullhit19 & enemy1bullhit20 & enemy1bullhit21 & enemy1bullhit22 & enemy1bullhit23 & enemy1bullhit24 & enemy1bullhit25
                    & enemy1bullhit26 & enemy1bullhit27 & enemy1bullhit28 & enemy1bullhit29 & enemy1bullhit30 & enemy1bullhit31 & enemy1bullhit32 & enemy1bullhit33 & enemy1bullhit34
                    & enemy1bullhit35 & enemy1bullhit36 & enemy1bullhit37 & enemy1bullhit38 & enemy1bullhit39 & enemy1bullhit40 & enemy1bullhit41  & enemy1bullhit42  & enemy1bullhit43
                    & enemy1p1hit;

    

  // Declare 43 logic variables named enemy1brick#active
  logic enemy1brick1active;
  logic enemy1brick2active;
  logic enemy1brick3active;
  logic enemy1brick4active;
  logic enemy1brick5active;
  logic enemy1brick6active;
  logic enemy1brick7active;
  logic enemy1brick8active;
  logic enemy1brick9active;
  logic enemy1brick10active;
  logic enemy1brick11active;
  logic enemy1brick12active;
  logic enemy1brick13active;
  logic enemy1brick14active;
  logic enemy1brick15active;
  logic enemy1brick16active;
  logic enemy1brick17active;
  logic enemy1brick18active;
  logic enemy1brick19active;
  logic enemy1brick20active;
  logic enemy1brick21active;
  logic enemy1brick22active;
  logic enemy1brick23active;
  logic enemy1brick24active;
  logic enemy1brick25active;
  logic enemy1brick26active;
  logic enemy1brick27active;
  logic enemy1brick28active;
  logic enemy1brick29active;
  logic enemy1brick30active;
  logic enemy1brick31active;
  logic enemy1brick32active;
  logic enemy1brick33active;
  logic enemy1brick34active;
  logic enemy1brick35active;
  logic enemy1brick36active;
  logic enemy1brick37active;
  logic enemy1brick38active;
  logic enemy1brick39active;
  logic enemy1brick40active;
  logic enemy1brick41active;
  logic enemy1brick42active;
  logic enemy1brick43active;

  logic p1brick1active;
  logic p1brick2active;
  logic p1brick3active;
  logic p1brick4active;
  logic p1brick5active;
  logic p1brick6active;
  logic p1brick7active;
  logic p1brick8active;
  logic p1brick9active;
  logic p1brick10active;
  logic p1brick11active;
  logic p1brick12active;
  logic p1brick13active;
  logic p1brick14active;
  logic p1brick15active;
  logic p1brick16active;
  logic p1brick17active;
  logic p1brick18active;
  logic p1brick19active;
  logic p1brick20active;
  logic p1brick21active;
  logic p1brick22active;
  logic p1brick23active;
  logic p1brick24active;
  logic p1brick25active;
  logic p1brick26active;
  logic p1brick27active;
  logic p1brick28active;
  logic p1brick29active;
  logic p1brick30active;
  logic p1brick31active;
  logic p1brick32active;
  logic p1brick33active;
  logic p1brick34active;
  logic p1brick35active;
  logic p1brick36active;
  logic p1brick37active;
  logic p1brick38active;
  logic p1brick39active;
  logic p1brick40active;
  logic p1brick41active;
  logic p1brick42active;
  logic p1brick43active;

  
    
    
    
    
    
    
    logic enemy2brick1active;
  logic enemy2brick2active;
  logic enemy2brick3active;
  logic enemy2brick4active;
  logic enemy2brick5active;
  logic enemy2brick6active;
  logic enemy2brick7active;
  logic enemy2brick8active;
  logic enemy2brick9active;
  logic enemy2brick10active;
  logic enemy2brick11active;
  logic enemy2brick12active;
  logic enemy2brick13active;
  logic enemy2brick14active;
  logic enemy2brick15active;
  logic enemy2brick16active;
  logic enemy2brick17active;
  logic enemy2brick18active;
  logic enemy2brick19active;
  logic enemy2brick20active;
  logic enemy2brick21active;
  logic enemy2brick22active;
  logic enemy2brick23active;
  logic enemy2brick24active;
  logic enemy2brick25active;
  logic enemy2brick26active;
  logic enemy2brick27active; 
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
   
    
    // END ENEMY1 LOGIC DEFINITIONS LOGIC
    
    
    
    logic [11:0] enemy1xsig, enemy1ysig, enemy1sizesig;
  
    logic [1:0] enemy1_counter;
    logic enemy_bullet_init;
    enemy_move enemy_motion_contr(
        .Reset(reset_ah),
        .frame_clk(vsync),
        .vga_clk(clk_25MHz),
        .keycode(keycode0_gpio[7:0]),
        .keycode2(keycode0_gpio[15:8]),
        .start_screen_flag(start_screen_flag),
        .enemystopL(enemy1stopL), 
        .enemystopR(enemy1stopR),
        .enemystopU(enemy1stopU),
        .enemystopD(enemy1stopD),
        .enemy_counter(enemy1_counter),
        .enemy_X(enemy1xsig),
        .enemy_Y(enemy1ysig),
        .enemy_S(enemy1sizesig),
        .direction_flag(enemy1_direction_flag),
        .enemy_bullet_init(enemy_bullet_init)
    
    );
    
    logic [11:0] enemy1bullxsig, enemy1bullysig;
    logic [1:0] enemy1_bull_direction_flag;
    logic enemy1_bull_live, enemy1bullmovelive;
    logic enemy1_bullet_initializer;
    bullmove enemybullmover1(
        .frame_clk(vsync),
        .Reset(reset_ah),
    
       .p1_X(enemy1xsig), .p1_Y(enemy1ysig), 
         .direction_flag(enemy1_direction_flag),
        .bullet_init(enemy1_bullet_initializer),
        .bull_hit(enemy1bullhit),
    
         .bull_X(enemy1bullxsig), .bull_Y(enemy1bullysig), 
        .bull_direction_out(enemy1_bull_direction_flag),
        .bull_live(enemy1_bull_live)
    );
    assign enemy1_bullet_initializer = (enemy_bullet_init &&( ~enemy1_bull_live));
    
    
    

    
    
    
    
    
    
    
    // Instantiations of sprites begin here



    logic p1_up_flag;
    logic [3:0] p1_up_red, p1_up_green, p1_up_blue;
    p1_up_final_example p1_up_final(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.red(p1_up_red), .green(p1_up_green), .blue(p1_up_blue),
	.tankflag(p1_up_flag),
	    .p1_X(p1xsig),
        .p1_Y(p1ysig),
        .p1_S(p1sizesig)
      );  
      
    logic p1_right_flag;
    logic [3:0] p1_right_red, p1_right_green, p1_right_blue;
    p1_right_example p1_right(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.red(p1_right_red), .green(p1_right_green), .blue(p1_right_blue),
	.tankflag(p1_right_flag),
	    .p1_X(p1xsig),
        .p1_Y(p1ysig),
        .p1_S(p1sizesig)
      );  
      
     logic p1_down_flag;
    logic [3:0] p1_down_red, p1_down_green, p1_down_blue;
    p1_down_example p1_down(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.red(p1_down_red), .green(p1_down_green), .blue(p1_down_blue),
	.tankflag(p1_down_flag),
	    .p1_X(p1xsig),
        .p1_Y(p1ysig),
        .p1_S(p1sizesig)
      );   
      
      logic p1_left_flag;
    logic [3:0] p1_left_red, p1_left_green, p1_left_blue;
    p1_left_example p1_left(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.red(p1_left_red), .green(p1_left_green), .blue(p1_left_blue),
	.tankflag(p1_left_flag),
	    .p1_X(p1xsig),
        .p1_Y(p1ysig),
        .p1_S(p1sizesig)
      );  
      
    logic brick1flag, brick1active;
    logic [3:0] brick1_red, brick1_green, brick1_blue;
    brick_example brick1(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(160), .maxx(191), .miny(288), .maxy(319),
	.red(brick1_red), .green(brick1_green), .blue(brick1_blue),
	.brickflag(brick1flag)
     );   
     
     logic brick2flag, brick2active;
    logic [3:0] brick2_red, brick2_green, brick2_blue;
    brick_example brick2(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(449), .maxx(479), .miny(320), .maxy(352),
	.red(brick2_red), .green(brick2_green), .blue(brick2_blue),
	.brickflag(brick2flag)
     );   
     
    logic brick3flag, brick3active;
    logic [3:0] brick3_red, brick3_green, brick3_blue;
    brick_example brick3(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(449), .maxx(479), .miny(352), .maxy(384),
	.red(brick3_red), .green(brick3_green), .blue(brick3_blue),
	.brickflag(brick3flag)
     ); 
     
     logic brick4flag, brick4active;
    logic [3:0] brick4_red, brick4_green, brick4_blue;
    brick_example brick4(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(449), .maxx(479), .miny(384), .maxy(416),
	.red(brick4_red), .green(brick4_green), .blue(brick4_blue),
	.brickflag(brick4flag)
     );     
     logic brick5flag, brick5active;
    logic [3:0] brick5_red, brick5_green, brick5_blue;
    brick_example brick5(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(449), .maxx(479), .miny(224), .maxy(256),
	.red(brick5_red), .green(brick5_green), .blue(brick5_blue),
	.brickflag(brick5flag)
     );    
     logic brick6flag, brick6active;
    logic [3:0] brick6_red, brick6_green, brick6_blue;
    brick_example brick6(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(449), .maxx(479), .miny(192), .maxy(224),
	.red(brick6_red), .green(brick6_green), .blue(brick6_blue),
	.brickflag(brick6flag)
     );    
     logic brick7flag, brick7active;
    logic [3:0] brick7_red, brick7_green, brick7_blue;
    brick_example brick7(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(160), .maxx(191), .miny(256), .maxy(288),
	.red(brick7_red), .green(brick7_green), .blue(brick7_blue),
	.brickflag(brick7flag)
     );  
     logic brick8flag, brick8active;
    logic [3:0] brick8_red, brick8_green, brick8_blue;
    brick_example brick8(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(192), .maxx(223), .miny(224), .maxy(256),
	.red(brick8_red), .green(brick8_green), .blue(brick8_blue),
	.brickflag(brick8flag)
     );  
     logic brick9flag, brick9active;
    logic [3:0] brick9_red, brick9_green, brick9_blue;
    brick_example brick9(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(224), .maxx(255), .miny(224), .maxy(256),
	.red(brick9_red), .green(brick9_green), .blue(brick9_blue),
	.brickflag(brick9flag)
     );  
     logic brick10flag, brick10active;
    logic [3:0] brick10_red, brick10_green, brick10_blue;
    brick_example brick10(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(256), .maxx(287), .miny(224), .maxy(256),
	.red(brick10_red), .green(brick10_green), .blue(brick10_blue),
	.brickflag(brick10flag)
     );  
     
     logic brick11flag, brick11active;
    logic [3:0] brick11_red, brick11_green, brick11_blue;
    brick_example brick11(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(63), .maxx(95), .miny(224), .maxy(256),
	.red(brick11_red), .green(brick11_green), .blue(brick11_blue),
	.brickflag(brick11flag)
     );  
     
     logic brick12flag, brick12active;
    logic [3:0] brick12_red, brick12_green, brick12_blue;
    brick_example brick12(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(95), .maxx(127), .miny(224), .maxy(256),
	.red(brick12_red), .green(brick12_green), .blue(brick12_blue),
	.brickflag(brick12flag)
     );  
     
     logic brick13flag, brick13active;
    logic [3:0] brick13_red, brick13_green, brick13_blue;
    brick_example brick13(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(127), .maxx(159), .miny(224), .maxy(256),
	.red(brick13_red), .green(brick13_green), .blue(brick13_blue),
	.brickflag(brick13flag)
     );  
     
     logic brick14flag, brick14active;
    logic [3:0] brick14_red, brick14_green, brick14_blue;
    brick_example brick14(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(288), .maxx(320), .miny(32), .maxy(64),
	.red(brick14_red), .green(brick14_green), .blue(brick14_blue),
	.brickflag(brick14flag)
     );  
     
     logic brick15flag, brick15active;
    logic [3:0] brick15_red, brick15_green, brick15_blue;
    brick_example brick15(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(288), .maxx(320), .miny(64), .maxy(96),
	.red(brick15_red), .green(brick15_green), .blue(brick15_blue),
	.brickflag(brick15flag)
     );  
     
      logic brick16flag, brick16active;
    logic [3:0] brick16_red, brick16_green, brick16_blue;
    brick_example brick16(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(288), .maxx(320), .miny(128), .maxy(160),
	.red(brick16_red), .green(brick16_green), .blue(brick16_blue),
	.brickflag(brick16flag)
     );  
     
     logic brick17flag, brick17active;
    logic [3:0] brick17_red, brick17_green, brick17_blue;
    brick_example brick17(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(288), .maxx(320), .miny(160), .maxy(192),
	.red(brick17_red), .green(brick17_green), .blue(brick17_blue),
	.brickflag(brick17flag)
     );  
     
     logic brick18flag, brick18active;
    logic [3:0] brick18_red, brick18_green, brick18_blue;
    brick_example brick18(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(320), .maxx(352), .miny(128), .maxy(160),
	.red(brick18_red), .green(brick18_green), .blue(brick18_blue),
	.brickflag(brick18flag)
     );  
     
     logic brick19flag, brick19active;
    logic [3:0] brick19_red, brick19_green, brick19_blue;
    brick_example brick19(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(352), .maxx(384), .miny(128), .maxy(160),
	.red(brick19_red), .green(brick19_green), .blue(brick19_blue),
	.brickflag(brick19flag)
     );  
     
     
     logic brick20flag, brick20active;
    logic [3:0] brick20_red, brick20_green, brick20_blue;
    brick_example brick20(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(352), .maxx(384), .miny(96), .maxy(128),
	.red(brick20_red), .green(brick20_green), .blue(brick20_blue),
	.brickflag(brick20flag)
     );  
     
     logic brick21flag, brick21active;
    logic [3:0] brick21_red, brick21_green, brick21_blue;
    brick_example brick21(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(352), .maxx(384), .miny(160), .maxy(192),
	.red(brick21_red), .green(brick21_green), .blue(brick21_blue),
	.brickflag(brick21flag)
     ); 
     
     logic brick22flag, brick22active;
    logic [3:0] brick22_red, brick22_green, brick22_blue;
    brick_example brick22(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(384), .maxx(416), .miny(160), .maxy(192),
	.red(brick22_red), .green(brick22_green), .blue(brick22_blue),
	.brickflag(brick22flag)
     );  
     
     logic brick23flag, brick23active;
    logic [3:0] brick23_red, brick23_green, brick23_blue;
    brick_example brick23(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(160), .maxx(192), .miny(96), .maxy(128),
	.red(brick23_red), .green(brick23_green), .blue(brick23_blue),
	.brickflag(brick23flag)
     );  
     
     logic brick24flag, brick24active;
    logic [3:0] brick24_red, brick24_green, brick24_blue;
    brick_example brick24(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(192), .maxx(224), .miny(96), .maxy(128),
	.red(brick24_red), .green(brick24_green), .blue(brick24_blue),
	.brickflag(brick24flag)
     );  
     
     logic brick25flag, brick25active;
    logic [3:0] brick25_red, brick25_green, brick25_blue;
    brick_example brick25(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(192), .maxx(224), .miny(32), .maxy(64),
	.red(brick25_red), .green(brick25_green), .blue(brick25_blue),
	.brickflag(brick25flag)
     );
     
     logic brick26flag, brick26active;
    logic [3:0] brick26_red, brick26_green, brick26_blue;
    brick_example brick26(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(512), .maxx(544), .miny(256), .maxy(288),
	.red(brick26_red), .green(brick26_green), .blue(brick26_blue),
	.brickflag(brick26flag)
     ); 
     
     logic brick27flag, brick27active;
    logic [3:0] brick27_red, brick27_green, brick27_blue;
    brick_example brick27(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(544), .maxx(576), .miny(256), .maxy(288),
	.red(brick27_red), .green(brick27_green), .blue(brick27_blue),
	.brickflag(brick27flag)
     );   
     
     
     logic steel1flag;
    logic [3:0] steel1_red, steel1_green, steel1_blue;
    steel_example steel1(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(449), .maxx(479), .miny(288), .maxy(319),
	.red(steel1_red), .green(steel1_green), .blue(steel1_blue),
	.steelflag(steel1flag)
     );  
      logic steel2flag;
    logic [3:0] steel2_red, steel2_green, steel2_blue;
    steel_example steel2(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(320), .maxx(352), .miny(288), .maxy(319),
	.red(steel2_red), .green(steel2_green), .blue(steel2_blue),
	.steelflag(steel2flag)
     );   
       logic steel3flag;
    logic [3:0] steel3_red, steel3_green, steel3_blue;
    steel_example steel3(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(288), .maxx(320), .miny(288), .maxy(319),
	.red(steel3_red), .green(steel3_green), .blue(steel3_blue),
	.steelflag(steel3flag)
     );   
       logic steel4flag;
    logic [3:0] steel4_red, steel4_green, steel4_blue;
    steel_example steel4(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(352), .maxx(384), .miny(288), .maxy(319),
	.red(steel4_red), .green(steel4_green), .blue(steel4_blue),
	.steelflag(steel4flag)
     );   
       logic steel5flag;
    logic [3:0] steel5_red, steel5_green, steel5_blue;
    steel_example steel5(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(449), .maxx(479), .miny(256), .maxy(288),
	.red(steel5_red), .green(steel5_green), .blue(steel5_blue),
	.steelflag(steel5flag)
     );
       logic steel6flag;
    logic [3:0] steel6_red, steel6_green, steel6_blue;
    steel_example steel6(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(160), .maxx(191), .miny(224), .maxy(256),
	.red(steel6_red), .green(steel6_green), .blue(steel6_blue),
	.steelflag(steel6flag)
     );      
     
     logic steel7flag;
    logic [3:0] steel7_red, steel7_green, steel7_blue;
    steel_example steel7(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(160), .maxx(191), .miny(192), .maxy(224),
	.red(steel7_red), .green(steel7_green), .blue(steel7_blue),
	.steelflag(steel7flag)
     );      
     
     logic steel8flag;
    logic [3:0] steel8_red, steel8_green, steel8_blue;
    steel_example steel8(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(288), .maxx(320), .miny(96), .maxy(128),
	.red(steel8_red), .green(steel8_green), .blue(steel8_blue),
	.steelflag(steel8flag)
     );    
     
     logic steel9flag;
    logic [3:0] steel9_red, steel9_green, steel9_blue;
    steel_example steel9(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(192), .maxx(224), .miny(64), .maxy(96),
	.red(steel9_red), .green(steel9_green), .blue(steel9_blue),
	.steelflag(steel9flag)
     );      
     
     logic steel10flag;
    logic [3:0] steel10_red, steel10_green, steel10_blue;
    steel_example steel10(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(160), .maxx(192), .miny(384), .maxy(416),
	.red(steel10_red), .green(steel10_green), .blue(steel10_blue),
	.steelflag(steel10flag)
     );    
     logic steel11flag;
    logic [3:0] steel11_red, steel11_green, steel11_blue;
    steel_example steel11(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(192), .maxx(224), .miny(384), .maxy(416),
	.red(steel11_red), .green(steel11_green), .blue(steel11_blue),
	.steelflag(steel11flag)
     );    
     logic steel12flag;
    logic [3:0] steel12_red, steel12_green, steel12_blue;
    steel_example steel12(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(224), .maxx(256), .miny(384), .maxy(416),
	.red(steel12_red), .green(steel12_green), .blue(steel12_blue),
	.steelflag(steel12flag)
     );    
     logic steel13flag;
    logic [3:0] steel13_red, steel13_green, steel13_blue;
    steel_example steel13(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(192), .maxx(224), .miny(352), .maxy(384),
	.red(steel13_red), .green(steel13_green), .blue(steel13_blue),
	.steelflag(steel13flag)
     );    
     
     logic steel14flag;
    logic [3:0] steel14_red, steel14_green, steel14_blue;
    steel_example steel14(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(480), .maxx(512), .miny(128), .maxy(160),
	.red(steel14_red), .green(steel14_green), .blue(steel14_blue),
	.steelflag(steel14flag)
     );    
     
     logic steel15flag;
    logic [3:0] steel15_red, steel15_green, steel15_blue;
    steel_example steel15(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(512), .maxx(544), .miny(128), .maxy(160),
	.red(steel15_red), .green(steel15_green), .blue(steel15_blue),
	.steelflag(steel15flag)
     );    
     
     logic steel16flag;
    logic [3:0] steel16_red, steel16_green, steel16_blue;
    steel_example steel16(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.minx(544), .maxx(576), .miny(128), .maxy(160),
	.red(steel16_red), .green(steel16_green), .blue(steel16_blue),
	.steelflag(steel16flag)
     );    
     
     
     logic enemy_down_flag;
    logic [3:0] enemy_down_red, enemy_down_green, enemy_down_blue;
    enemy_down_example enemy_down(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.red(enemy_down_red), .green(enemy_down_green), .blue(enemy_down_blue),
	.enemyflag(enemy_down_flag),
	.enemy_X(enemy1xsig),
        .enemy_Y(enemy1ysig),
        .enemy_S(enemy1sizesig)
     );   
      
     logic enemy_left_flag;
    logic [3:0] enemy_left_red, enemy_left_green, enemy_left_blue;
    enemy_left_example enemy_left(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.red(enemy_left_red), .green(enemy_left_green), .blue(enemy_left_blue),
	.enemyflag(enemy_left_flag),
	.enemy_X(enemy1xsig),
        .enemy_Y(enemy1ysig),
        .enemy_S(enemy1sizesig)
     );    
     
     logic enemy_right_flag;
    logic [3:0] enemy_right_red, enemy_right_green, enemy_right_blue;
    enemy_right_example enemy_right(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.red(enemy_right_red), .green(enemy_right_green), .blue(enemy_right_blue),
	.enemyflag(enemy_right_flag),
	.enemy_X(enemy1xsig),
        .enemy_Y(enemy1ysig),
        .enemy_S(enemy1sizesig)
     );    
     
      logic enemy_up_flag;
    logic [3:0] enemy_up_red, enemy_up_green, enemy_up_blue;
    enemy_up_example enemy_up(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.red(enemy_up_red), .green(enemy_up_green), .blue(enemy_up_blue),
	.enemyflag(enemy_up_flag),
	.enemy_X(enemy1xsig),
        .enemy_Y(enemy1ysig),
        .enemy_S(enemy1sizesig)
     );    
     

       
     logic bullflagright;
    logic [3:0] p1bullright_red, p1bullright_green, p1bullright_blue;
    p1bullright_example p1bullright(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.bull_X(bullxsig), .bull_Y(bullysig), 
	.red(p1bullright_red), .green(p1bullright_green), .blue(p1bullright_blue),
	.bullflagright(bullflagright)
     );   
     
     logic bullflagdown;
    logic [3:0] p1bulldown_red, p1bulldown_green, p1bulldown_blue;
    p1bulldown_example p1bulldown(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.bull_X(bullxsig), .bull_Y(bullysig), 
	.red(p1bulldown_red), .green(p1bulldown_green), .blue(p1bulldown_blue),
	.bullflagdown(bullflagdown)
     );   
     
     logic bullflagleft;
    logic [3:0] p1bullleft_red, p1bullleft_green, p1bullleft_blue;
    p1bullleft_example p1bullleft(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.bull_X(bullxsig), .bull_Y(bullysig), 
	.red(p1bullleft_red), .green(p1bullleft_green), .blue(p1bullleft_blue),
	.bullflagleft(bullflagleft)
     );   
     
     logic bullflagup;
    logic [3:0] p1bullup_red, p1bullup_green, p1bullup_blue;
    p1bullup_example p1bullup(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.bull_X(bullxsig), .bull_Y(bullysig), 
	.red(p1bullup_red), .green(p1bullup_green), .blue(p1bullup_blue),
	.bullflagup(bullflagup)
     );   

     logic bull_live1, explosion, bull_live2; // dont think we use 1 and 2 too scared to delete
     
     logic explode_flag;
     logic [3:0] explode_red, explode_green, explode_blue;
     explode_example explosion_sprite(
     .vga_clk(clk_25MHz),
     .DrawX(drawX), .DrawY(drawY),
     .blank(vde),
     .bull_X(bullxsig), .bull_Y(bullysig),
     .red(explode_red), .green(explode_green), .blue(explode_blue),
     .bull_live(bull_live),
     .explode_flag(explode_flag),
     .explosion(explosion)
     );
     
     
     logic enemy1explosion, enemy1explode_flag;
     logic [3:0] enemy1explode_red, enemy1explode_green, enemy1explode_blue;
     explode_example enemy1explosion_sprite(
     .vga_clk(clk_25MHz),
     .DrawX(drawX), .DrawY(drawY),
     .blank(vde),
     .bull_X(enemy1bullxsig), .bull_Y(enemy1bullysig),
     .red(enemy1explode_red), .green(enemy1explode_green), .blue(enemy1explode_blue),
     .bull_live(enemy1_bull_live),
     .explode_flag(enemy1explode_flag),
     .explosion(enemy1explosion)
     );
     
     
 logic enemy3brick1active;
  logic enemy3brick2active;
  logic enemy3brick3active;
  logic enemy3brick4active;
  logic enemy3brick5active;
  logic enemy3brick6active;
  logic enemy3brick7active;
  logic enemy3brick8active;
  logic enemy3brick9active;
  logic enemy3brick10active;
  logic enemy3brick11active;
  logic enemy3brick12active;
  logic enemy3brick13active;
  logic enemy3brick14active;
  logic enemy3brick15active;
  logic enemy3brick16active;
  logic enemy3brick17active;
  logic enemy3brick18active;
  logic enemy3brick19active;
  logic enemy3brick20active;
  logic enemy3brick21active;
  logic enemy3brick22active;
  logic enemy3brick23active;
  logic enemy3brick24active;
  logic enemy3brick25active;
  logic enemy3brick26active;
  logic enemy3brick27active;
  

   
    logic enemy3bullhit, enemy3bullhit1, enemy3bullhit2, enemy3bullhit3, enemy3bullhit4, enemy3bullhit5, enemy3bullhit6, enemy3bullhit7, enemy3bullhit8, enemy3bullhit9,
          enemy3bullhit10, enemy3bullhit11, enemy3bullhit12, enemy3bullhit13, enemy3bullhit14, enemy3bullhit15, enemy3bullhit16, enemy3bullhit17, enemy3bullhit18, enemy3bullhit19, enemy3bullhit20,
          enemy3bullhit21, enemy3bullhit22, enemy3bullhit23, enemy3bullhit24, enemy3bullhit25, enemy3bullhit26, enemy3bullhit27, enemy3bullhit28, enemy3bullhit29, enemy3bullhit30,enemy3bullhit31, 
          enemy3bullhit32, enemy3bullhit33, enemy3bullhit34, enemy3bullhit35 , enemy3bullhit36 , enemy3bullhit37, enemy3bullhit38, enemy3bullhit39, enemy3bullhit40, enemy3bullhit41, enemy3bullhit42 
          , enemy3bullhit43, enemy3p1hit;
    assign enemy3bullhit = enemy3bullhit1 & enemy3bullhit2 & enemy3bullhit3 & enemy3bullhit4 & enemy3bullhit5 & enemy3bullhit6 & enemy3bullhit7 
                    & enemy3bullhit8 & enemy3bullhit9 & enemy3bullhit10& enemy3bullhit11 & enemy3bullhit12 & enemy3bullhit13 & enemy3bullhit14 & enemy3bullhit15 & enemy3bullhit16 
                    & enemy3bullhit17 & enemy3bullhit18 & enemy3bullhit19 & enemy3bullhit20 & enemy3bullhit21 & enemy3bullhit22 & enemy3bullhit23 & enemy3bullhit24 & enemy3bullhit25
                    & enemy3bullhit26 & enemy3bullhit27 & enemy3bullhit28 & enemy3bullhit29 & enemy3bullhit30 & enemy3bullhit31 & enemy3bullhit32 & enemy3bullhit33 & enemy3bullhit34
                    & enemy3bullhit35 & enemy3bullhit36 & enemy3bullhit37 & enemy3bullhit38 & enemy3bullhit39 & enemy3bullhit40 & enemy3bullhit41  & enemy3bullhit42  & enemy3bullhit43
                    & enemy3p1hit;





      logic [1:0] enemy3_direction_flag;
    
    
    logic enemy3stopL, enemy3stopR, enemy3stopU, enemy3stopD, enemy3stopL1, enemy3stopR1, enemy3stopU1, enemy3stopD1,  enemy3stopL2, enemy3stopR2, enemy3stopU2, enemy3stopD2;
    logic enemy3stopL3, enemy3stopR3, enemy3stopU3, enemy3stopD3, enemy3stopL4, enemy3stopR4, enemy3stopU4, enemy3stopD4,  enemy3stopL5, enemy3stopR5, enemy3stopU5, enemy3stopD5;
    logic enemy3stopL6, enemy3stopR6, enemy3stopU6, enemy3stopD6, enemy3stopL7, enemy3stopR7, enemy3stopU7, enemy3stopD7,  enemy3stopL8, enemy3stopR8, enemy3stopU8, enemy3stopD8;
    logic enemy3stopL9, enemy3stopR9, enemy3stopU9, enemy3stopD9, enemy3stopL10, enemy3stopR10, enemy3stopU10, enemy3stopD10,  enemy3stopL11, enemy3stopR11, enemy3stopU11, enemy3stopD11;
    logic enemy3stopL12, enemy3stopR12, enemy3stopU12, enemy3stopD12, enemy3stopL13, enemy3stopR13, enemy3stopU13, enemy3stopD13,  enemy3stopL14, enemy3stopR14, enemy3stopU14, enemy3stopD14;
    logic enemy3stopL15, enemy3stopR15, enemy3stopU15, enemy3stopD15, enemy3stopL16, enemy3stopR16, enemy3stopU16, enemy3stopD16,  enemy3stopL17, enemy3stopR17, enemy3stopU17, enemy3stopD17;
    logic enemy3stopL18, enemy3stopR18, enemy3stopU18, enemy3stopD18, enemy3stopL19, enemy3stopR19, enemy3stopU19, enemy3stopD19, enemy3stopL20, enemy3stopR20, enemy3stopU20, enemy3stopD20;
    logic enemy3stopL21, enemy3stopR21, enemy3stopU21, enemy3stopD21, enemy3stopL22, enemy3stopR22, enemy3stopU22, enemy3stopD22, enemy3stopL23, enemy3stopR23, enemy3stopU23, enemy3stopD23;
    logic enemy3stopL24, enemy3stopR24, enemy3stopU24, enemy3stopD24, enemy3stopL25, enemy3stopR25, enemy3stopU25, enemy3stopD25, enemy3stopL26, enemy3stopR26, enemy3stopU26, enemy3stopD26;
    logic enemy3stopL27, enemy3stopR27, enemy3stopU27, enemy3stopD27, enemy3stopL28, enemy3stopR28, enemy3stopU28, enemy3stopD28, enemy3stopL29, enemy3stopR29, enemy3stopU29, enemy3stopD29;
    logic enemy3stopL31, enemy3stopR31, enemy3stopU31, enemy3stopD31, enemy3stopL32, enemy3stopR32, enemy3stopU32, enemy3stopD32, enemy3stopL33, enemy3stopR33, enemy3stopU33, enemy3stopD33;
    logic enemy3stopL30, enemy3stopR30, enemy3stopU30, enemy3stopD30, enemy3stopL34, enemy3stopR34, enemy3stopU34, enemy3stopD34, enemy3stopL35, enemy3stopR35, enemy3stopU35, enemy3stopD35;
    logic enemy3stopL36, enemy3stopR36, enemy3stopU36, enemy3stopD36 , enemy3stopL37, enemy3stopR37, enemy3stopU37, enemy3stopD37 , enemy3stopL38, enemy3stopR38, enemy3stopU38, enemy3stopD38;
    logic enemy3stopL39, enemy3stopR39, enemy3stopU39, enemy3stopD39 , enemy3stopL40, enemy3stopR40, enemy3stopU40, enemy3stopD40 , enemy3stopL41, enemy3stopR41, enemy3stopU41, enemy3stopD41;
    logic enemy3stopL42, enemy3stopR42, enemy3stopU42, enemy3stopD42,enemy3stopL43, enemy3stopR43, enemy3stopU43, enemy3stopD43;
    assign enemy3stopL = enemy3stopL1 | enemy3stopL2 | enemy3stopL3 | enemy3stopL4 |enemy3stopL5| enemy3stopL6 | enemy3stopL7 |enemy3stopL8 | enemy3stopL9 | enemy3stopL10 |enemy3stopL11
                     |enemy3stopL12 |enemy3stopL13 |enemy3stopL14 |enemy3stopL15 |enemy3stopL16 |enemy3stopL17 |enemy3stopL18 |enemy3stopL19 |enemy3stopL20 
                     |enemy3stopL21 |enemy3stopL22 |enemy3stopL23 |enemy3stopL24 |enemy3stopL25 |enemy3stopL26 | enemy3stopL27 | enemy3stopL28 | enemy3stopL29 | enemy3stopL30
                     |enemy3stopL31 |enemy3stopL32 |enemy3stopL33  |enemy3stopL34 |enemy3stopL35 |enemy3stopL36 |enemy3stopL37|enemy3stopL38
                     |enemy3stopL39 |enemy3stopL40 |enemy3stopL41 |enemy3stopL42 |enemy3stopL43;
    assign enemy3stopR = enemy3stopR1 | enemy3stopR2 | enemy3stopR3 | enemy3stopR4 |enemy3stopR5| enemy3stopR6 | enemy3stopR7 |enemy3stopR8 | enemy3stopR9 | enemy3stopR10 |enemy3stopR11
                     |enemy3stopR12 |enemy3stopR13 |enemy3stopR14 |enemy3stopR15 |enemy3stopR16 |enemy3stopR17 |enemy3stopR18 |enemy3stopR19 |enemy3stopR20
                     |enemy3stopR21 |enemy3stopR22 |enemy3stopR23 |enemy3stopR24 |enemy3stopR25|enemy3stopR26 | enemy3stopR27 | enemy3stopR28 | enemy3stopR29 | enemy3stopR30
                     |enemy3stopR31 |enemy3stopR32 |enemy3stopR33 |enemy3stopR34 |enemy3stopR35 |enemy3stopR36 |enemy3stopR37|enemy3stopR38
                     |enemy3stopR39 |enemy3stopR40 |enemy3stopR41|enemy3stopR42 |enemy3stopR43;
    assign enemy3stopU = enemy3stopU1 | enemy3stopU2 | enemy3stopU3 | enemy3stopU4 |enemy3stopU5| enemy3stopU6 | enemy3stopU7 |enemy3stopU8 | enemy3stopU9 | enemy3stopU10 |enemy3stopU11
                    |enemy3stopU12 |enemy3stopU13 |enemy3stopU14 |enemy3stopU15 |enemy3stopU16 |enemy3stopU17 |enemy3stopU18 |enemy3stopU19 |enemy3stopU20
                     |enemy3stopU21 |enemy3stopU22 |enemy3stopU23 |enemy3stopU24 |enemy3stopU25|enemy3stopU26 | enemy3stopU27 | enemy3stopU28 | enemy3stopU29 | enemy3stopU30
                     |enemy3stopU31 |enemy3stopU32 |enemy3stopU33 |enemy3stopU34 |enemy3stopU35 |enemy3stopU36 |enemy3stopU37|enemy3stopU38
                     |enemy3stopU39 |enemy3stopU40 |enemy3stopU41|enemy3stopU42 |enemy3stopU43;
    assign enemy3stopD = enemy3stopD1 | enemy3stopD2 | enemy3stopD3 | enemy3stopD4 |enemy3stopD5| enemy3stopD6 | enemy3stopD7 |enemy3stopD8 | enemy3stopD9 | enemy3stopD10 |enemy3stopD11
                    |enemy3stopD12 |enemy3stopD13 |enemy3stopD14 |enemy3stopD15 |enemy3stopD16 |enemy3stopD17 |enemy3stopD18 |enemy3stopD19 |enemy3stopD20
                    |enemy3stopD21 |enemy3stopD22 |enemy3stopD23 |enemy3stopD24 | enemy3stopD25|enemy3stopD26 | enemy3stopD27 | enemy3stopD28 | enemy3stopD29 | enemy3stopD30
                     |enemy3stopD31 |enemy3stopD32 |enemy3stopD33 |enemy3stopD34 |enemy3stopD35 |enemy3stopD36 |enemy3stopD37|enemy3stopD38
                      |enemy3stopD39 |enemy3stopD40 |enemy3stopD41|enemy3stopD42 |enemy3stopD43;





 
    logic [11:0] enemy3xsig, enemy3ysig, enemy3sizesig;
  
    logic [1:0] enemy3_counter;
    logic enemy3_bullet_init;
    enemy3_move enemy3_motion_contr(
        .Reset(reset_ah),
        .frame_clk(vsync),
        .vga_clk(clk_25MHz),
        .keycode(keycode0_gpio[7:0]),
        .keycode2(keycode0_gpio[15:8]),
        .enemystopL(enemy3stopL), 
        .enemystopR(enemy3stopR),
        .enemystopU(enemy3stopU),
        .enemystopD(enemy3stopD),
        .start_screen_flag(start_screen_flag),
        .enemy_counter(enemy3_counter),
        .enemy_X(enemy3xsig),
        .enemy_Y(enemy3ysig),
        .enemy_S(enemy3sizesig),
        .direction_flag(enemy3_direction_flag),
        .enemy_bullet_init(enemy3_bullet_init)
    
    );
    
    logic [11:0] enemy3bullxsig, enemy3bullysig;
    logic [1:0] enemy3_bull_direction_flag;
    logic enemy3_bull_live, enemy3bullmovelive;
    logic enemy3_bullet_initializer;
    logic enemy3bullhit;
    bullmove enemybullmover3(
        .frame_clk(vsync),
        .Reset(reset_ah),
    
       .p1_X(enemy3xsig), .p1_Y(enemy3ysig), 
         .direction_flag(enemy3_direction_flag),
        .bullet_init(enemy3_bullet_initializer),
        .bull_hit(enemy3bullhit),
    
         .bull_X(enemy3bullxsig), .bull_Y(enemy3bullysig), 
        .bull_direction_out(enemy3_bull_direction_flag),
        .bull_live(enemy3_bull_live)
    );
    assign enemy3_bullet_initializer = (enemy3_bullet_init &&( ~enemy3_bull_live));
    
    


    
    


    
     logic enemy3_down_flag;
    logic [3:0] enemy3_down_red, enemy3_down_green, enemy3_down_blue;
    enemy_down_example enemy3_down(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.red(enemy3_down_red), .green(enemy3_down_green), .blue(enemy3_down_blue),
	.enemyflag(enemy3_down_flag),
	.enemy_X( enemy3xsig),
        .enemy_Y( enemy3ysig),
        .enemy_S( enemy3sizesig)
     );   
      
     logic enemy3_left_flag;
    logic [3:0] enemy3_left_red, enemy3_left_green, enemy3_left_blue;
    enemy_left_example enemy3_left(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.red(enemy3_left_red), .green(enemy3_left_green), .blue(enemy3_left_blue),
	.enemyflag(enemy3_left_flag),
	.enemy_X( enemy3xsig),
        .enemy_Y( enemy3ysig),
        .enemy_S( enemy3sizesig)
     );    
     
     logic enemy3_right_flag;
    logic [3:0] enemy3_right_red, enemy3_right_green, enemy3_right_blue;
    enemy_right_example enemy3_right(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.red(enemy3_right_red), .green(enemy3_right_green), .blue(enemy3_right_blue),
	.enemyflag(enemy3_right_flag),
	.enemy_X( enemy3xsig),
        .enemy_Y( enemy3ysig),
        .enemy_S( enemy3sizesig)
     );    
     
      logic enemy3_up_flag;
    logic [3:0] enemy3_up_red, enemy3_up_green, enemy3_up_blue;
    enemy_up_example enemy3_up(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.red(enemy3_up_red), .green(enemy3_up_green), .blue(enemy3_up_blue),
	.enemyflag(enemy3_up_flag),
	.enemy_X( enemy3xsig),
        .enemy_Y( enemy3ysig),
        .enemy_S( enemy3sizesig)
     );    



     Collision enemy3collide(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(160), .brick1_Y(288),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick1active),
     
     .player1_left_stop(enemy3stopL1), .player1_right_stop(enemy3stopR1), 
     .player1_up_stop(enemy3stopU1), .player1_down_stop(enemy3stopD1)
          ); 
     
     Collision enemy3collide2(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(449), .brick1_Y(320),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick2active),
     
     .player1_left_stop(enemy3stopL6), .player1_right_stop(enemy3stopR6), 
     .player1_up_stop(enemy3stopU6), .player1_down_stop(enemy3stopD6)
          ); 
          
     Collision enemy3collide3(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(449), .brick1_Y(352),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick3active),
     
     .player1_left_stop(enemy3stopL7), .player1_right_stop(enemy3stopR7), 
     .player1_up_stop(enemy3stopU7), .player1_down_stop(enemy3stopD7)
          ); 
     
     Collision enemy3collide4(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(449), .brick1_Y(384),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick4active),
     
     .player1_left_stop(enemy3stopL8), .player1_right_stop(enemy3stopR8), 
     .player1_up_stop(enemy3stopU8), .player1_down_stop(enemy3stopD8)
          ); 
    Collision enemy3collide5(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(449), .brick1_Y(224),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick5active),
     
     .player1_left_stop(enemy3stopL10), .player1_right_stop(enemy3stopR10), 
     .player1_up_stop(enemy3stopU10), .player1_down_stop(enemy3stopD10)
          ); 
          
          Collision enemy3collide6(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(449), .brick1_Y(192),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick6active),
     
     .player1_left_stop(enemy3stopL11), .player1_right_stop(enemy3stopR11), 
     .player1_up_stop(enemy3stopU11), .player1_down_stop(enemy3stopD11)
          );
          
      Collision enemy3collide7(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(160), .brick1_Y(256),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick7active),
     
     .player1_left_stop(enemy3stopL12), .player1_right_stop(enemy3stopR12), 
     .player1_up_stop(enemy3stopU12), .player1_down_stop(enemy3stopD12)
          ); 
          
      Collision enemy3collide8(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(192), .brick1_Y(224),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick8active),
     
     .player1_left_stop(enemy3stopL14), .player1_right_stop(enemy3stopR14), 
     .player1_up_stop(enemy3stopU14), .player1_down_stop(enemy3stopD14)
          );  
     Collision enemy3collide9(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(224), .brick1_Y(224),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick9active),
     
     .player1_left_stop(enemy3stopL15), .player1_right_stop(enemy3stopR15), 
     .player1_up_stop(enemy3stopU15), .player1_down_stop(enemy3stopD15)
          );
     Collision enemy3collide10(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(256), .brick1_Y(224),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick10active),
     
     .player1_left_stop(enemy3stopL16), .player1_right_stop(enemy3stopR16), 
     .player1_up_stop(enemy3stopU16), .player1_down_stop(enemy3stopD16)
          );    
          
     Collision enemy3collide11(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(63), .brick1_Y(224),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick11active),
     
     .player1_left_stop(enemy3stopL17), .player1_right_stop(enemy3stopR17), 
     .player1_up_stop(enemy3stopU17), .player1_down_stop(enemy3stopD17)
          );        
     
      Collision enemy3collide12(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(95), .brick1_Y(224),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick12active),
     
     .player1_left_stop(enemy3stopL18), .player1_right_stop(enemy3stopR18), 
     .player1_up_stop(enemy3stopU18), .player1_down_stop(enemy3stopD18)
          );    
          
     Collision enemy3collide13(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(127), .brick1_Y(224),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick13active),
     
     .player1_left_stop(enemy3stopL19), .player1_right_stop(enemy3stopR19), 
     .player1_up_stop(enemy3stopU19), .player1_down_stop(enemy3stopD19)
          );     
          
     Collision enemy3collide14(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(288), .brick1_Y(32),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick14active),
     
     .player1_left_stop(enemy3stopL21), .player1_right_stop(enemy3stopR21), 
     .player1_up_stop(enemy3stopU21), .player1_down_stop(enemy3stopD21)
          );    
          
     Collision enemy3collide15(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(288), .brick1_Y(64),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick15active),
     
     .player1_left_stop(enemy3stopL22), .player1_right_stop(enemy3stopR22), 
     .player1_up_stop(enemy3stopU22), .player1_down_stop(enemy3stopD22)
          );       
          
      Collision enemy3collide16(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(288), .brick1_Y(128),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick16active),
     
     .player1_left_stop(enemy3stopL23), .player1_right_stop(enemy3stopR23), 
     .player1_up_stop(enemy3stopU23), .player1_down_stop(enemy3stopD23)
          );      
          
      Collision enemy3collide17(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(288), .brick1_Y(160),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick17active),
     
     .player1_left_stop(enemy3stopL24), .player1_right_stop(enemy3stopR24), 
     .player1_up_stop(enemy3stopU24), .player1_down_stop(enemy3stopD24)
          ); 
          
          
     Collision enemy3collide18(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(320), .brick1_Y(128),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick18active),
     
     .player1_left_stop(enemy3stopL26), .player1_right_stop(enemy3stopR26), 
     .player1_up_stop(enemy3stopU26), .player1_down_stop(enemy3stopD26)
          );                
    Collision enemy3collide19(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(352), .brick1_Y(128),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick19active),
     
     .player1_left_stop(enemy3stopL27), .player1_right_stop(enemy3stopR27), 
     .player1_up_stop(enemy3stopU27), .player1_down_stop(enemy3stopD27)
          );   
     
     Collision enemy3collide20(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(352), .brick1_Y(96),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick20active),
     
     .player1_left_stop(enemy3stopL28), .player1_right_stop(enemy3stopR28), 
     .player1_up_stop(enemy3stopU28), .player1_down_stop(enemy3stopD28)
          );       
     Collision enemy3collide21(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(352), .brick1_Y(160),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick21active),
     
     .player1_left_stop(enemy3stopL29), .player1_right_stop(enemy3stopR29), 
     .player1_up_stop(enemy3stopU29), .player1_down_stop(enemy3stopD29)
          ); 
          
     Collision enemy3collide22(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(384), .brick1_Y(160),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick22active),
     
     .player1_left_stop(enemy3stopL30), .player1_right_stop(enemy3stopR30), 
     .player1_up_stop(enemy3stopU30), .player1_down_stop(enemy3stopD30)
          ); 
          
     Collision enemy3collide23(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(160), .brick1_Y(96),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick23active),
     
     .player1_left_stop(enemy3stopL31), .player1_right_stop(enemy3stopR31), 
     .player1_up_stop(enemy3stopU31), .player1_down_stop(enemy3stopD31)
          ); 
          
      Collision enemy3collide24(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(192), .brick1_Y(96),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick24active),
     
     .player1_left_stop(enemy3stopL32), .player1_right_stop(enemy3stopR32), 
     .player1_up_stop(enemy3stopU32), .player1_down_stop(enemy3stopD32)
          ); 
          
     Collision enemy3collide25(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(192), .brick1_Y(32),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick25active),
     
     .player1_left_stop(enemy3stopL33), .player1_right_stop(enemy3stopR33), 
     .player1_up_stop(enemy3stopU33), .player1_down_stop(enemy3stopD33)
          );
          
      Collision enemy3collide26(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(512), .brick1_Y(256),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick26active),
     
     .player1_left_stop(enemy3stopL42), .player1_right_stop(enemy3stopR42), 
     .player1_up_stop(enemy3stopU42), .player1_down_stop(enemy3stopD42)
          );
          
      Collision enemy3collide27(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(544), .brick1_Y(256),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick27active),
     
     .player1_left_stop(enemy3stopL43), .player1_right_stop(enemy3stopR43), 
     .player1_up_stop(enemy3stopU43), .player1_down_stop(enemy3stopD43)
          ); 
                          
    Collision steel1enemy3collide(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(449), .brick1_Y(288),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     
     .player1_left_stop(enemy3stopL2), .player1_right_stop(enemy3stopR2), 
     .player1_up_stop(enemy3stopU2), .player1_down_stop(enemy3stopD2)
          ); 
          
      Collision steel2enemy3collide(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(320), .brick1_Y(288),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     
     .player1_left_stop(enemy3stopL3), .player1_right_stop(enemy3stopR3), 
     .player1_up_stop(enemy3stopU3), .player1_down_stop(enemy3stopD3)
          ); 
     Collision steel3enemy3collide(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(288), .brick1_Y(288),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     
     .player1_left_stop(enemy3stopL4), .player1_right_stop(enemy3stopR4), 
     .player1_up_stop(enemy3stopU4), .player1_down_stop(enemy3stopD4)
          ); 
     
     Collision steel4enemy3collide(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(352), .brick1_Y(288),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     
     .player1_left_stop(enemy3stopL5), .player1_right_stop(enemy3stopR5), 
     .player1_up_stop(enemy3stopU5), .player1_down_stop(enemy3stopD5)
          ); 
     
     Collision steel5enemy3collide(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(449), .brick1_Y(256),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     
     .player1_left_stop(enemy3stopL9), .player1_right_stop(enemy3stopR9), 
     .player1_up_stop(enemy3stopU9), .player1_down_stop(enemy3stopD9)
          ); 
     
     Collision steel6enemy3collide(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(160), .brick1_Y(224),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
    
     .player1_left_stop(enemy3stopL13), .player1_right_stop(enemy3stopR13), 
     .player1_up_stop(enemy3stopU13), .player1_down_stop(enemy3stopD13)
          ); 
     
     Collision steel7enemy3collide(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(160), .brick1_Y(192),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy3stopL20), .player1_right_stop(enemy3stopR20), 
     .player1_up_stop(enemy3stopU20), .player1_down_stop(enemy3stopD20)
          ); 
          
     Collision steel8enemy3collide(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(288), .brick1_Y(96),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy3stopL25), .player1_right_stop(enemy3stopR25), 
     .player1_up_stop(enemy3stopU25), .player1_down_stop(enemy3stopD25)
          ); 
          
     Collision steel9enemy3collide(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(192), .brick1_Y(64),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy3stopL34), .player1_right_stop(enemy3stopR34), 
     .player1_up_stop(enemy3stopU34), .player1_down_stop(enemy3stopD34)
          ); 
     
     Collision steel10enemy3collide(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(160), .brick1_Y(384),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy3stopL35), .player1_right_stop(enemy3stopR35), 
     .player1_up_stop(enemy3stopU35), .player1_down_stop(enemy3stopD35)
          ); 
     
     Collision steel11enemy3collide(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(192), .brick1_Y(384),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy3stopL36), .player1_right_stop(enemy3stopR36), 
     .player1_up_stop(enemy3stopU36), .player1_down_stop(enemy3stopD36)
          ); 
     
     Collision steel12enemy3collide(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(224), .brick1_Y(384),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy3stopL37), .player1_right_stop(enemy3stopR37), 
     .player1_up_stop(enemy3stopU37), .player1_down_stop(enemy3stopD37)
          );
     Collision steel13enemy3collide(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(192), .brick1_Y(352),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy3stopL38), .player1_right_stop(enemy3stopR38), 
     .player1_up_stop(enemy3stopU38), .player1_down_stop(enemy3stopD38)
          );
          
     Collision steel14enemy3collide(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(480), .brick1_Y(128),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy3stopL39), .player1_right_stop(enemy3stopR39), 
     .player1_up_stop(enemy3stopU39), .player1_down_stop(enemy3stopD39)
          );
          
     Collision steel15enemy3collide(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(512), .brick1_Y(128),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy3stopL40), .player1_right_stop(enemy3stopR40), 
     .player1_up_stop(enemy3stopU40), .player1_down_stop(enemy3stopD40)
          );
          
     Collision steel16enemy3collide(
     .player1_X(enemy3xsig), .player1_Y(enemy3ysig),
     .brick1_X(544), .brick1_Y(128),
     .p1_direction_flag(enemy3_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy3stopL41), .player1_right_stop(enemy3stopR41), 
     .player1_up_stop(enemy3stopU41), .player1_down_stop(enemy3stopD41)
          );





























     bullcollidebrick enemy3bullbrick1(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(160),
    .obj_Y(288),
    .frame_clk(vsync), .extbrickactive(p1brick1active) , .extbrickactive2(enemy1brick1active),
    .extbrickactive3(enemy2brick1active),
    .bull_hit(enemy3bullhit1),
    .brickactive(enemy3brick1active)
     );
     
     bullcollidebrick enemy3bullbrick2(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(449),
    .obj_Y(320),
    .frame_clk(vsync), .extbrickactive(p1brick2active), .extbrickactive2(enemy1brick2active),
    .extbrickactive3(enemy2brick2active),
    .bull_hit(enemy3bullhit6),
    .brickactive(enemy3brick2active)
     );
     
     bullcollidebrick enemy3bullbrick3(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(449),
    .obj_Y(352),
    .frame_clk(vsync), .extbrickactive(p1brick3active), .extbrickactive2(enemy1brick3active),
    .extbrickactive3(enemy2brick3active),
    .bull_hit(enemy3bullhit7),
    .brickactive(enemy3brick3active)
     );
     
     bullcollidebrick enemy3bullbrick4(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(449),
    .obj_Y(384),
    .frame_clk(vsync), .extbrickactive(p1brick4active), .extbrickactive2(enemy1brick4active),
    .extbrickactive3(enemy2brick4active),
    .bull_hit(enemy3bullhit8),
    .brickactive(enemy3brick4active)
     );
     
     bullcollidebrick enemy3bullbrick5(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(449),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(p1brick5active),.extbrickactive2(enemy1brick5active),
    .extbrickactive3(enemy2brick5active),
    .bull_hit(enemy3bullhit10),
    .brickactive(enemy3brick5active)
     );
     
     bullcollidebrick enemy3bullbrick6(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(449),
    .obj_Y(192),
    .frame_clk(vsync), .extbrickactive(p1brick6active), .extbrickactive2(enemy1brick6active),
    .extbrickactive3(enemy2brick6active),
    .bull_hit(enemy3bullhit11),
    .brickactive(enemy3brick6active)
     );
     bullcollidebrick enemy3bullbrick7(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(160),
    .obj_Y(256),
    .frame_clk(vsync), .extbrickactive(p1brick7active), .extbrickactive2(enemy1brick7active),
    .extbrickactive3(enemy2brick7active),
    .bull_hit(enemy3bullhit12),
    .brickactive(enemy3brick7active)
     );
     bullcollidebrick enemy3bullbrick8(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(192),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(p1brick8active), .extbrickactive2(enemy1brick8active),
    .extbrickactive3(enemy2brick8active),
    .bull_hit(enemy3bullhit14),
    .brickactive(enemy3brick8active)
     );
     
     bullcollidebrick enemy3bullbrick9(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(224),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(p1brick9active), .extbrickactive2(enemy1brick9active),
    .extbrickactive3(enemy2brick9active),
    .bull_hit(enemy3bullhit15),
    .brickactive(enemy3brick9active)
     );
     
     bullcollidebrick enemy3bullbrick10(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(256),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(p1brick10active), .extbrickactive2(enemy1brick10active),
    .extbrickactive3(enemy2brick10active),
    .bull_hit(enemy3bullhit16),
    .brickactive(enemy3brick10active)
     );
     
     bullcollidebrick enemy3bullbrick11(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(63),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(p1brick11active), .extbrickactive2(enemy1brick11active),
    .extbrickactive3(enemy2brick11active),
    .bull_hit(enemy3bullhit17),
    .brickactive(enemy3brick11active)
     );
     
     bullcollidebrick enemy3bullbrick12(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(95),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(p1brick12active), .extbrickactive2(enemy1brick12active),
    .extbrickactive3(enemy2brick12active),
    .bull_hit(enemy3bullhit18),
    .brickactive(enemy3brick12active)
     );
     
     bullcollidebrick enemy3bullbrick13(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(127),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(p1brick13active), .extbrickactive2(enemy1brick13active),
    .extbrickactive3(enemy2brick13active),
    .bull_hit(enemy3bullhit19),
    .brickactive(enemy3brick13active)
     );
     
      bullcollidebrick enemy3bullbrick14(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(288),
    .obj_Y(32),
    .frame_clk(vsync), .extbrickactive(p1brick14active), .extbrickactive2(enemy1brick14active),
    .extbrickactive3(enemy2brick14active),
    .bull_hit(enemy3bullhit21),
    .brickactive(enemy3brick14active)
     );
     
      bullcollidebrick enemy3bullbrick15(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(288),
    .obj_Y(64),
    .frame_clk(vsync), .extbrickactive(p1brick15active), .extbrickactive2(enemy1brick15active),
    .extbrickactive3(enemy2brick15active),
    .bull_hit(enemy3bullhit22),
    .brickactive(enemy3brick15active)
     );
     
     bullcollidebrick enemy3bullbrick16(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(288),
    .obj_Y(128),
    .frame_clk(vsync), .extbrickactive(p1brick16active), .extbrickactive2(enemy1brick16active),
    .extbrickactive3(enemy2brick16active),
    .bull_hit(enemy3bullhit23),
    .brickactive(enemy3brick16active)
     );
     
     bullcollidebrick enemy3bullbrick17(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(288),
    .obj_Y(160),
    .frame_clk(vsync), .extbrickactive(p1brick17active), .extbrickactive2(enemy1brick17active),
    .extbrickactive3(enemy2brick17active),
    .bull_hit(enemy3bullhit24),
    .brickactive(enemy3brick17active)
     );
     
     bullcollidebrick enemy3bullbrick18(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(320),
    .obj_Y(128),
    .frame_clk(vsync), .extbrickactive(p1brick18active), .extbrickactive2(enemy1brick18active),
    .extbrickactive3(enemy2brick18active),
    .bull_hit(enemy3bullhit26),
    .brickactive(enemy3brick18active)
     );
     
     bullcollidebrick enemy3bullbrick19(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(352),
    .obj_Y(128),
    .frame_clk(vsync), .extbrickactive(p1brick19active), .extbrickactive2(enemy1brick19active),
    .extbrickactive3(enemy2brick19active),
    .bull_hit(enemy3bullhit27),
    .brickactive(enemy3brick19active)
     );
     
     bullcollidebrick enemy3bullbrick20(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(352),
    .obj_Y(96),
    .frame_clk(vsync), .extbrickactive(p1brick20active), .extbrickactive2(enemy1brick20active),
    .extbrickactive3(enemy2brick20active),
    .bull_hit(enemy3bullhit28),
    .brickactive(enemy3brick20active)
     );
     
     bullcollidebrick enemy3bullbrick21(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(352),
    .obj_Y(160),
    .frame_clk(vsync), .extbrickactive(p1brick21active), .extbrickactive2(enemy1brick21active),
    .extbrickactive3(enemy2brick21active),
    .bull_hit(enemy3bullhit29),
    .brickactive(enemy3brick21active)
     );
     
     bullcollidebrick enemy3bullbrick22(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(384),
    .obj_Y(160),
    .frame_clk(vsync), .extbrickactive(p1brick22active), .extbrickactive2(enemy1brick22active),
    .extbrickactive3(enemy2brick22active),
    .bull_hit(enemy3bullhit30),
    .brickactive(enemy3brick22active)
     );
     
     bullcollidebrick enemy3bullbrick23(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(160),
    .obj_Y(96),
    .frame_clk(vsync), .extbrickactive(p1brick23active), .extbrickactive2(enemy1brick23active),
    .extbrickactive3(enemy2brick23active),
    .bull_hit(enemy3bullhit31),
    .brickactive(enemy3brick23active)
     );
     
      bullcollidebrick enemy3bullbrick24(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(192),
    .obj_Y(96),
    .frame_clk(vsync), .extbrickactive(p1brick24active), .extbrickactive2(enemy1brick24active),
    .extbrickactive3(enemy2brick24active),
    .bull_hit(enemy3bullhit32),
    .brickactive(enemy3brick24active)
     );
     
      bullcollidebrick enemy3bullbrick25(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(192),
    .obj_Y(32),
    .frame_clk(vsync), .extbrickactive(p1brick25active),.extbrickactive2(enemy1brick25active),
     .extbrickactive3(enemy2brick25active),
    .bull_hit(enemy3bullhit33),
    .brickactive(enemy3brick25active)
     );
     
     bullcollidebrick enemy3bullbrick26(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(512),
    .obj_Y(256),
    .frame_clk(vsync), .extbrickactive(p1brick26active), .extbrickactive2(enemy1brick26active),
    .extbrickactive3(enemy2brick26active),
    .bull_hit(enemy3bullhit42),
    .brickactive(enemy3brick26active)
     );
     
     bullcollidebrick enemy3bullbrick27(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(544),
    .obj_Y(256),
    .frame_clk(vsync), .extbrickactive(p1brick27active), .extbrickactive2(enemy1brick27active),
    .extbrickactive3(enemy2brick27active),
    .bull_hit(enemy3bullhit43),
    .brickactive(enemy3brick27active)
     );
     

     
     bullcollidesteel enemy3bullsteel1(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(449),
    .obj_Y(288),
    .frame_clk(vsync),
    
    .bull_hit(enemy3bullhit2)
     );
      
      bullcollidesteel enemy3bullsteel2(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(320),
    .obj_Y(288),
    .frame_clk(vsync),
    
    .bull_hit(enemy3bullhit3)
     );
     
      bullcollidesteel enemy3bullsteel3(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(288),
    .obj_Y(288),
    .frame_clk(vsync),
    
    .bull_hit(enemy3bullhit4)
     );
     
      bullcollidesteel enemy3bullsteel4(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(352),
    .obj_Y(288),
    .frame_clk(vsync),
    
    .bull_hit(enemy3bullhit5)
     ); 
     bullcollidesteel enemy3bullsteel5(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(449),
    .obj_Y(256),
    .frame_clk(vsync),
    
    .bull_hit(enemy3bullhit9)
     ); 
     
     
    bullcollidesteel enemy3bullsteel6(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(160),
    .obj_Y(224),
    .frame_clk(vsync),
    
    .bull_hit(enemy3bullhit13)
     );   
     
     bullcollidesteel enemy3bullsteel7(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(160),
    .obj_Y(192),
    .frame_clk(vsync),
    
    .bull_hit(enemy3bullhit20)
     );   
     
     bullcollidesteel enemy3bullsteel8(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(288),
    .obj_Y(96),
    .frame_clk(vsync),
    
    .bull_hit(enemy3bullhit25)
     );   
     
      bullcollidesteel enemy3bullsteel9(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(192),
    .obj_Y(64),
    .frame_clk(vsync),
    
    .bull_hit(enemy3bullhit34)
     );   
     
     bullcollidesteel enemy3bullsteel10(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(160),
    .obj_Y(384),
    .frame_clk(vsync),
    
    .bull_hit(enemy3bullhit35)
     );
     
     bullcollidesteel enemy3bullsteel11(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(192),
    .obj_Y(384),
    .frame_clk(vsync),
    
    .bull_hit(enemy3bullhit36)
     );
     
     bullcollidesteel enemy3bullsteel12(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(224),
    .obj_Y(384),
    .frame_clk(vsync),
    
    .bull_hit(enemy3bullhit37)
     );
     
     bullcollidesteel enemy3bullsteel13(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(192),
    .obj_Y(352),
    .frame_clk(vsync),
    
    .bull_hit(enemy3bullhit38)
     );
     
      bullcollidesteel enemy3bullsteel14(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(480),
    .obj_Y(128),
    .frame_clk(vsync),
    
    .bull_hit(enemy3bullhit39)
     );
     
      bullcollidesteel enemy3bullsteel15(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(512),
    .obj_Y(128),
    .frame_clk(vsync),
    
    .bull_hit(enemy3bullhit40)
     );
     
     bullcollidesteel enemy3bullsteel16(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(544),
    .obj_Y(128),
    .frame_clk(vsync),
    
    .bull_hit(enemy3bullhit41)
     );
      
     logic enemy3bullflagright;
    logic [3:0] enemy3bullright_red, enemy3bullright_green, enemy3bullright_blue;
    enemybullright_example enemy3bullright(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.bull_X(enemy3bullxsig), .bull_Y(enemy3bullysig), 
	.red(enemy3bullright_red), .green(enemy3bullright_green), .blue(enemy3bullright_blue),
	.bullflagright(enemy3bullflagright)
     );   
     
     logic enemy3bullflagdown;
    logic [3:0] enemy3bulldown_red, enemy3bulldown_green, enemy3bulldown_blue;
    enemybulldown_example enemy3bulldown(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.bull_X(enemy3bullxsig), .bull_Y(enemy3bullysig), 
	.red(enemy3bulldown_red), .green(enemy3bulldown_green), .blue(enemy3bulldown_blue),
	.bullflagdown(enemy3bullflagdown)
     );   
     
     logic enemy3bullflagleft;
    logic [3:0] enemy3bullleft_red, enemy3bullleft_green, enemy3bullleft_blue;
    enemybullleft_example enemy3bullleft(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.bull_X(enemy3bullxsig), .bull_Y(enemy3bullysig), 
	.red(enemy3bullleft_red), .green(enemy3bullleft_green), .blue(enemy3bullleft_blue),
	.bullflagleft(enemy3bullflagleft)
     );   
     
     logic enemy3bullflagup;
    logic [3:0] enemy3bullup_red, enemy3bullup_green, enemy3bullup_blue;
    enemybullup_example enemy3bullup(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.bull_X(enemy3bullxsig), .bull_Y(enemy3bullysig), 
	.red(enemy3bullup_red), .green(enemy3bullup_green), .blue(enemy3bullup_blue),
	.bullflagup(enemy3bullflagup)
     );   



bullcollidetank enemy3hitp1(
     .bull_X(enemy3bullxsig),
    .bull_Y(enemy3bullysig),
    .obj_X(p1xsig),
    .obj_Y(p1ysig),
    .frame_clk(vsync), 
    .Reset(reset_ah),
    .bull_live(enemy3_bull_live),
        
    .bull_hit(enemy3p1hit),
    .enemy_counter(p1counter3)
     ); 

 bullcollidetank p1hitenemy3(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(enemy3xsig),
    .obj_Y(enemy3ysig),
    .frame_clk(vsync), 
    .Reset(reset_ah),
    .bull_live(bull_live),
    
    .bull_hit(p1enemy3hit),
    .enemy_counter(enemy3_counter)
     ); 


   logic enemy3explosion, enemy3explode_flag;
     logic [3:0] enemy3explode_red, enemy3explode_green, enemy3explode_blue;
     explode_example enemy3explosion_sprite(
     .vga_clk(clk_25MHz),
     .DrawX(drawX), .DrawY(drawY),
     .blank(vde),
     .bull_X(enemy3bullxsig), .bull_Y(enemy3bullysig),
     .red(enemy3explode_red), .green(enemy3explode_green), .blue(enemy3explode_blue),
     .bull_live(enemy3_bull_live),
     .explode_flag(enemy3explode_flag),
     .explosion(enemy3explosion)
     );
     



     
     
  


assign brick1active = enemy3brick1active & enemy1brick1active & enemy2brick1active & p1brick1active;
assign brick2active = enemy3brick2active & enemy1brick2active & enemy2brick2active & p1brick2active;
assign brick3active = enemy3brick3active & enemy1brick3active & enemy2brick3active & p1brick3active;
assign brick4active = enemy3brick4active & enemy1brick4active & enemy2brick4active & p1brick4active;
assign brick5active = enemy3brick5active & enemy1brick5active & enemy2brick5active & p1brick5active;
assign brick6active = enemy3brick6active & enemy1brick6active & enemy2brick6active & p1brick6active;
assign brick7active = enemy3brick7active & enemy1brick7active & enemy2brick7active & p1brick7active;
assign brick8active = enemy3brick8active & enemy1brick8active & enemy2brick8active & p1brick8active;
assign brick9active = enemy3brick9active & enemy1brick9active & enemy2brick9active & p1brick9active;
assign brick10active = enemy3brick10active & enemy1brick10active & enemy2brick10active & p1brick10active;
assign brick11active = enemy3brick11active & enemy1brick11active & enemy2brick11active & p1brick11active;
assign brick12active = enemy3brick12active & enemy1brick12active & enemy2brick12active & p1brick12active;
assign brick13active = enemy3brick13active & enemy1brick13active & enemy2brick13active & p1brick13active;
assign brick14active = enemy3brick14active & enemy1brick14active & enemy2brick14active & p1brick14active;
assign brick15active = enemy3brick15active & enemy1brick15active & enemy2brick15active & p1brick15active;
assign brick16active = enemy3brick16active & enemy1brick16active & enemy2brick16active & p1brick16active;
assign brick17active = enemy3brick17active & enemy1brick17active & enemy2brick17active & p1brick17active;
assign brick18active = enemy3brick18active & enemy1brick18active & enemy2brick18active & p1brick18active;
assign brick19active = enemy3brick19active & enemy1brick19active & enemy2brick19active & p1brick19active;
assign brick20active = enemy3brick20active & enemy1brick20active & enemy2brick20active & p1brick20active;
assign brick21active = enemy3brick21active & enemy1brick21active & enemy2brick21active & p1brick21active;
assign brick22active = enemy3brick22active & enemy1brick22active & enemy2brick22active & p1brick22active;
assign brick23active = enemy3brick23active & enemy1brick23active & enemy2brick23active & p1brick23active;
assign brick24active = enemy3brick24active & enemy1brick24active & enemy2brick24active & p1brick24active;
assign brick25active = enemy3brick25active & enemy1brick25active & enemy2brick25active & p1brick25active;
assign brick26active = enemy3brick26active & enemy1brick26active & enemy2brick26active & p1brick26active;
assign brick27active = enemy3brick27active & enemy1brick27active & enemy2brick27active & p1brick27active;


    logic enemy2bullhit, enemy2bullhit1, enemy2bullhit2, enemy2bullhit3, enemy2bullhit4, enemy2bullhit5, enemy2bullhit6, enemy2bullhit7, enemy2bullhit8, enemy2bullhit9,
          enemy2bullhit10, enemy2bullhit11, enemy2bullhit12, enemy2bullhit13, enemy2bullhit14, enemy2bullhit15, enemy2bullhit16, enemy2bullhit17, enemy2bullhit18, enemy2bullhit19, enemy2bullhit20,
          enemy2bullhit21, enemy2bullhit22, enemy2bullhit23, enemy2bullhit24, enemy2bullhit25, enemy2bullhit26, enemy2bullhit27, enemy2bullhit28, enemy2bullhit29, enemy2bullhit30,enemy2bullhit31, 
          enemy2bullhit32, enemy2bullhit33, enemy2bullhit34, enemy2bullhit35 , enemy2bullhit36 , enemy2bullhit37, enemy2bullhit38, enemy2bullhit39, enemy2bullhit40, enemy2bullhit41, enemy2bullhit42 
          , enemy2bullhit43, enemy2p1hit;
    assign enemy2bullhit = enemy2bullhit1 & enemy2bullhit2 & enemy2bullhit3 & enemy2bullhit4 & enemy2bullhit5 & enemy2bullhit6 & enemy2bullhit7 
                    & enemy2bullhit8 & enemy2bullhit9 & enemy2bullhit10& enemy2bullhit11 & enemy2bullhit12 & enemy2bullhit13 & enemy2bullhit14 & enemy2bullhit15 & enemy2bullhit16 
                    & enemy2bullhit17 & enemy2bullhit18 & enemy2bullhit19 & enemy2bullhit20 & enemy2bullhit21 & enemy2bullhit22 & enemy2bullhit23 & enemy2bullhit24 & enemy2bullhit25
                    & enemy2bullhit26 & enemy2bullhit27 & enemy2bullhit28 & enemy2bullhit29 & enemy2bullhit30 & enemy2bullhit31 & enemy2bullhit32 & enemy2bullhit33 & enemy2bullhit34
                    & enemy2bullhit35 & enemy2bullhit36 & enemy2bullhit37 & enemy2bullhit38 & enemy2bullhit39 & enemy2bullhit40 & enemy2bullhit41  & enemy2bullhit42  & enemy2bullhit43
                    & enemy2p1hit;


      logic [1:0] enemy2_direction_flag;
    
    
    logic enemy2stopL, enemy2stopR, enemy2stopU, enemy2stopD, enemy2stopL1, enemy2stopR1, enemy2stopU1, enemy2stopD1,  enemy2stopL2, enemy2stopR2, enemy2stopU2, enemy2stopD2;
    logic enemy2stopL3, enemy2stopR3, enemy2stopU3, enemy2stopD3, enemy2stopL4, enemy2stopR4, enemy2stopU4, enemy2stopD4,  enemy2stopL5, enemy2stopR5, enemy2stopU5, enemy2stopD5;
    logic enemy2stopL6, enemy2stopR6, enemy2stopU6, enemy2stopD6, enemy2stopL7, enemy2stopR7, enemy2stopU7, enemy2stopD7,  enemy2stopL8, enemy2stopR8, enemy2stopU8, enemy2stopD8;
    logic enemy2stopL9, enemy2stopR9, enemy2stopU9, enemy2stopD9, enemy2stopL10, enemy2stopR10, enemy2stopU10, enemy2stopD10,  enemy2stopL11, enemy2stopR11, enemy2stopU11, enemy2stopD11;
    logic enemy2stopL12, enemy2stopR12, enemy2stopU12, enemy2stopD12, enemy2stopL13, enemy2stopR13, enemy2stopU13, enemy2stopD13,  enemy2stopL14, enemy2stopR14, enemy2stopU14, enemy2stopD14;
    logic enemy2stopL15, enemy2stopR15, enemy2stopU15, enemy2stopD15, enemy2stopL16, enemy2stopR16, enemy2stopU16, enemy2stopD16,  enemy2stopL17, enemy2stopR17, enemy2stopU17, enemy2stopD17;
    logic enemy2stopL18, enemy2stopR18, enemy2stopU18, enemy2stopD18, enemy2stopL19, enemy2stopR19, enemy2stopU19, enemy2stopD19, enemy2stopL20, enemy2stopR20, enemy2stopU20, enemy2stopD20;
    logic enemy2stopL21, enemy2stopR21, enemy2stopU21, enemy2stopD21, enemy2stopL22, enemy2stopR22, enemy2stopU22, enemy2stopD22, enemy2stopL23, enemy2stopR23, enemy2stopU23, enemy2stopD23;
    logic enemy2stopL24, enemy2stopR24, enemy2stopU24, enemy2stopD24, enemy2stopL25, enemy2stopR25, enemy2stopU25, enemy2stopD25, enemy2stopL26, enemy2stopR26, enemy2stopU26, enemy2stopD26;
    logic enemy2stopL27, enemy2stopR27, enemy2stopU27, enemy2stopD27, enemy2stopL28, enemy2stopR28, enemy2stopU28, enemy2stopD28, enemy2stopL29, enemy2stopR29, enemy2stopU29, enemy2stopD29;
    logic enemy2stopL31, enemy2stopR31, enemy2stopU31, enemy2stopD31, enemy2stopL32, enemy2stopR32, enemy2stopU32, enemy2stopD32, enemy2stopL33, enemy2stopR33, enemy2stopU33, enemy2stopD33;
    logic enemy2stopL30, enemy2stopR30, enemy2stopU30, enemy2stopD30, enemy2stopL34, enemy2stopR34, enemy2stopU34, enemy2stopD34, enemy2stopL35, enemy2stopR35, enemy2stopU35, enemy2stopD35;
    logic enemy2stopL36, enemy2stopR36, enemy2stopU36, enemy2stopD36 , enemy2stopL37, enemy2stopR37, enemy2stopU37, enemy2stopD37 , enemy2stopL38, enemy2stopR38, enemy2stopU38, enemy2stopD38;
    logic enemy2stopL39, enemy2stopR39, enemy2stopU39, enemy2stopD39 , enemy2stopL40, enemy2stopR40, enemy2stopU40, enemy2stopD40 , enemy2stopL41, enemy2stopR41, enemy2stopU41, enemy2stopD41;
    logic enemy2stopL42, enemy2stopR42, enemy2stopU42, enemy2stopD42,enemy2stopL43, enemy2stopR43, enemy2stopU43, enemy2stopD43;
    assign enemy2stopL = enemy2stopL1 | enemy2stopL2 | enemy2stopL3 | enemy2stopL4 |enemy2stopL5| enemy2stopL6 | enemy2stopL7 |enemy2stopL8 | enemy2stopL9 | enemy2stopL10 |enemy2stopL11
                     |enemy2stopL12 |enemy2stopL13 |enemy2stopL14 |enemy2stopL15 |enemy2stopL16 |enemy2stopL17 |enemy2stopL18 |enemy2stopL19 |enemy2stopL20 
                     |enemy2stopL21 |enemy2stopL22 |enemy2stopL23 |enemy2stopL24 |enemy2stopL25 |enemy2stopL26 | enemy2stopL27 | enemy2stopL28 | enemy2stopL29 | enemy2stopL30
                     |enemy2stopL31 |enemy2stopL32 |enemy2stopL33  |enemy2stopL34 |enemy2stopL35 |enemy2stopL36 |enemy2stopL37|enemy2stopL38
                     |enemy2stopL39 |enemy2stopL40 |enemy2stopL41 |enemy2stopL42 |enemy2stopL43;
    assign enemy2stopR = enemy2stopR1 | enemy2stopR2 | enemy2stopR3 | enemy2stopR4 |enemy2stopR5| enemy2stopR6 | enemy2stopR7 |enemy2stopR8 | enemy2stopR9 | enemy2stopR10 |enemy2stopR11
                     |enemy2stopR12 |enemy2stopR13 |enemy2stopR14 |enemy2stopR15 |enemy2stopR16 |enemy2stopR17 |enemy2stopR18 |enemy2stopR19 |enemy2stopR20
                     |enemy2stopR21 |enemy2stopR22 |enemy2stopR23 |enemy2stopR24 |enemy2stopR25|enemy2stopR26 | enemy2stopR27 | enemy2stopR28 | enemy2stopR29 | enemy2stopR30
                     |enemy2stopR31 |enemy2stopR32 |enemy2stopR33 |enemy2stopR34 |enemy2stopR35 |enemy2stopR36 |enemy2stopR37|enemy2stopR38
                     |enemy2stopR39 |enemy2stopR40 |enemy2stopR41|enemy2stopR42 |enemy2stopR43;
    assign enemy2stopU = enemy2stopU1 | enemy2stopU2 | enemy2stopU3 | enemy2stopU4 |enemy2stopU5| enemy2stopU6 | enemy2stopU7 |enemy2stopU8 | enemy2stopU9 | enemy2stopU10 |enemy2stopU11
                    |enemy2stopU12 |enemy2stopU13 |enemy2stopU14 |enemy2stopU15 |enemy2stopU16 |enemy2stopU17 |enemy2stopU18 |enemy2stopU19 |enemy2stopU20
                     |enemy2stopU21 |enemy2stopU22 |enemy2stopU23 |enemy2stopU24 |enemy2stopU25|enemy2stopU26 | enemy2stopU27 | enemy2stopU28 | enemy2stopU29 | enemy2stopU30
                     |enemy2stopU31 |enemy2stopU32 |enemy2stopU33 |enemy2stopU34 |enemy2stopU35 |enemy2stopU36 |enemy2stopU37|enemy2stopU38
                     |enemy2stopU39 |enemy2stopU40 |enemy2stopU41|enemy2stopU42 |enemy2stopU43;
    assign enemy2stopD = enemy2stopD1 | enemy2stopD2 | enemy2stopD3 | enemy2stopD4 |enemy2stopD5| enemy2stopD6 | enemy2stopD7 |enemy2stopD8 | enemy2stopD9 | enemy2stopD10 |enemy2stopD11
                    |enemy2stopD12 |enemy2stopD13 |enemy2stopD14 |enemy2stopD15 |enemy2stopD16 |enemy2stopD17 |enemy2stopD18 |enemy2stopD19 |enemy2stopD20
                    |enemy2stopD21 |enemy2stopD22 |enemy2stopD23 |enemy2stopD24 | enemy2stopD25|enemy2stopD26 | enemy2stopD27 | enemy2stopD28 | enemy2stopD29 | enemy2stopD30
                     |enemy2stopD31 |enemy2stopD32 |enemy2stopD33 |enemy2stopD34 |enemy2stopD35 |enemy2stopD36 |enemy2stopD37|enemy2stopD38
                      |enemy2stopD39 |enemy2stopD40 |enemy2stopD41|enemy2stopD42 |enemy2stopD43;



    logic [11:0] enemy2xsig, enemy2ysig, enemy2sizesig;
  
    logic [1:0] enemy2_counter;
    logic enemy2_bullet_init;
    enemy2_move enemy2_motion_contr(
        .Reset(reset_ah),
        .frame_clk(vsync),
        .vga_clk(clk_25MHz),
        .keycode(keycode0_gpio[7:0]),
        .keycode2(keycode0_gpio[15:8]),
        .enemystopL(enemy2stopL), 
        .enemystopR(enemy2stopR),
        .enemystopU(enemy2stopU),
        .enemystopD(enemy2stopD),
        .start_screen_flag(start_screen_flag),
        .enemy_counter(enemy2_counter),
        .enemy_X(enemy2xsig),
        .enemy_Y(enemy2ysig),
        .enemy_S(enemy2sizesig),
        .direction_flag(enemy2_direction_flag),
        .enemy_bullet_init(enemy2_bullet_init)
    
    );
    
    logic [11:0] enemy2bullxsig, enemy2bullysig;
    logic [1:0] enemy2_bull_direction_flag;
    logic enemy2_bull_live, enemy2bullmovelive;
    logic enemy2_bullet_initializer;
    bullmove enemybullmover2(
        .frame_clk(vsync),
        .Reset(reset_ah),
    
       .p1_X(enemy2xsig), .p1_Y(enemy2ysig), 
         .direction_flag(enemy2_direction_flag),
        .bullet_init(enemy2_bullet_initializer),
        .bull_hit(enemy2bullhit),
    
         .bull_X(enemy2bullxsig), .bull_Y(enemy2bullysig), 
        .bull_direction_out(enemy2_bull_direction_flag),
        .bull_live(enemy2_bull_live)
    );
    assign enemy2_bullet_initializer = (enemy2_bullet_init &&( ~enemy2_bull_live));
    
    


     logic enemy2_down_flag;
    logic [3:0] enemy2_down_red, enemy2_down_green, enemy2_down_blue;
    enemy_down_example enemy2_down(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.red(enemy2_down_red), .green(enemy2_down_green), .blue(enemy2_down_blue),
	.enemyflag(enemy2_down_flag),
	.enemy_X( enemy2xsig),
        .enemy_Y( enemy2ysig),
        .enemy_S( enemy2sizesig)
     );   
      
     logic enemy2_left_flag;
    logic [3:0] enemy2_left_red, enemy2_left_green, enemy2_left_blue;
    enemy_left_example enemy2_left(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.red(enemy2_left_red), .green(enemy2_left_green), .blue(enemy2_left_blue),
	.enemyflag(enemy2_left_flag),
	.enemy_X( enemy2xsig),
        .enemy_Y( enemy2ysig),
        .enemy_S( enemy2sizesig)
     );    
     
     logic enemy2_right_flag;
    logic [3:0] enemy2_right_red, enemy2_right_green, enemy2_right_blue;
    enemy_right_example enemy2_right(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.red(enemy2_right_red), .green(enemy2_right_green), .blue(enemy2_right_blue),
	.enemyflag(enemy2_right_flag),
	.enemy_X( enemy2xsig),
        .enemy_Y( enemy2ysig),
        .enemy_S( enemy2sizesig)
     );    
     
      logic enemy2_up_flag;
    logic [3:0] enemy2_up_red, enemy2_up_green, enemy2_up_blue;
    enemy_up_example enemy2_up(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.red(enemy2_up_red), .green(enemy2_up_green), .blue(enemy2_up_blue),
	.enemyflag(enemy2_up_flag),
	.enemy_X( enemy2xsig),
        .enemy_Y( enemy2ysig),
        .enemy_S( enemy2sizesig)
     );    


     Collision enemy2collide(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(160), .brick1_Y(288),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick1active),
     
     .player1_left_stop(enemy2stopL1), .player1_right_stop(enemy2stopR1), 
     .player1_up_stop(enemy2stopU1), .player1_down_stop(enemy2stopD1)
          ); 
     
     Collision enemy2collide2(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(449), .brick1_Y(320),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick2active),
     
     .player1_left_stop(enemy2stopL6), .player1_right_stop(enemy2stopR6), 
     .player1_up_stop(enemy2stopU6), .player1_down_stop(enemy2stopD6)
          ); 
          
     Collision enemy2collide3(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(449), .brick1_Y(352),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick3active),
     
     .player1_left_stop(enemy2stopL7), .player1_right_stop(enemy2stopR7), 
     .player1_up_stop(enemy2stopU7), .player1_down_stop(enemy2stopD7)
          ); 
     
     Collision enemy2collide4(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(449), .brick1_Y(384),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick4active),
     
     .player1_left_stop(enemy2stopL8), .player1_right_stop(enemy2stopR8), 
     .player1_up_stop(enemy2stopU8), .player1_down_stop(enemy2stopD8)
          ); 
    Collision enemy2collide5(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(449), .brick1_Y(224),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick5active),
     
     .player1_left_stop(enemy2stopL10), .player1_right_stop(enemy2stopR10), 
     .player1_up_stop(enemy2stopU10), .player1_down_stop(enemy2stopD10)
          ); 
          
          Collision enemy2collide6(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(449), .brick1_Y(192),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick6active),
     
     .player1_left_stop(enemy2stopL11), .player1_right_stop(enemy2stopR11), 
     .player1_up_stop(enemy2stopU11), .player1_down_stop(enemy2stopD11)
          );
          
      Collision enemy2collide7(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(160), .brick1_Y(256),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick7active),
     
     .player1_left_stop(enemy2stopL12), .player1_right_stop(enemy2stopR12), 
     .player1_up_stop(enemy2stopU12), .player1_down_stop(enemy2stopD12)
          ); 
          
      Collision enemy2collide8(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(192), .brick1_Y(224),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick8active),
     
     .player1_left_stop(enemy2stopL14), .player1_right_stop(enemy2stopR14), 
     .player1_up_stop(enemy2stopU14), .player1_down_stop(enemy2stopD14)
          );  
     Collision enemy2collide9(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(224), .brick1_Y(224),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick9active),
     
     .player1_left_stop(enemy2stopL15), .player1_right_stop(enemy2stopR15), 
     .player1_up_stop(enemy2stopU15), .player1_down_stop(enemy2stopD15)
          );
     Collision enemy2collide10(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(256), .brick1_Y(224),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick10active),
     
     .player1_left_stop(enemy2stopL16), .player1_right_stop(enemy2stopR16), 
     .player1_up_stop(enemy2stopU16), .player1_down_stop(enemy2stopD16)
          );    
          
     Collision enemy2collide11(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(63), .brick1_Y(224),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick11active),
     
     .player1_left_stop(enemy2stopL17), .player1_right_stop(enemy2stopR17), 
     .player1_up_stop(enemy2stopU17), .player1_down_stop(enemy2stopD17)
          );        
     
      Collision enemy2collide12(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(95), .brick1_Y(224),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick12active),
     
     .player1_left_stop(enemy2stopL18), .player1_right_stop(enemy2stopR18), 
     .player1_up_stop(enemy2stopU18), .player1_down_stop(enemy2stopD18)
          );    
          
     Collision enemy2collide13(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(127), .brick1_Y(224),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick13active),
     
     .player1_left_stop(enemy2stopL19), .player1_right_stop(enemy2stopR19), 
     .player1_up_stop(enemy2stopU19), .player1_down_stop(enemy2stopD19)
          );     
          
     Collision enemy2collide14(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(288), .brick1_Y(32),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick14active),
     
     .player1_left_stop(enemy2stopL21), .player1_right_stop(enemy2stopR21), 
     .player1_up_stop(enemy2stopU21), .player1_down_stop(enemy2stopD21)
          );    
          
     Collision enemy2collide15(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(288), .brick1_Y(64),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick15active),
     
     .player1_left_stop(enemy2stopL22), .player1_right_stop(enemy2stopR22), 
     .player1_up_stop(enemy2stopU22), .player1_down_stop(enemy2stopD22)
          );       
          
      Collision enemy2collide16(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(288), .brick1_Y(128),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick16active),
     
     .player1_left_stop(enemy2stopL23), .player1_right_stop(enemy2stopR23), 
     .player1_up_stop(enemy2stopU23), .player1_down_stop(enemy2stopD23)
          );      
          
      Collision enemy2collide17(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(288), .brick1_Y(160),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick17active),
     
     .player1_left_stop(enemy2stopL24), .player1_right_stop(enemy2stopR24), 
     .player1_up_stop(enemy2stopU24), .player1_down_stop(enemy2stopD24)
          ); 
          
          
     Collision enemy2collide18(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(320), .brick1_Y(128),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick18active),
     
     .player1_left_stop(enemy2stopL26), .player1_right_stop(enemy2stopR26), 
     .player1_up_stop(enemy2stopU26), .player1_down_stop(enemy2stopD26)
          );                
    Collision enemy2collide19(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(352), .brick1_Y(128),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick19active),
     
     .player1_left_stop(enemy2stopL27), .player1_right_stop(enemy2stopR27), 
     .player1_up_stop(enemy2stopU27), .player1_down_stop(enemy2stopD27)
          );   
     
     Collision enemy2collide20(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(352), .brick1_Y(96),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick20active),
     
     .player1_left_stop(enemy2stopL28), .player1_right_stop(enemy2stopR28), 
     .player1_up_stop(enemy2stopU28), .player1_down_stop(enemy2stopD28)
          );       
     Collision enemy2collide21(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(352), .brick1_Y(160),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick21active),
     
     .player1_left_stop(enemy2stopL29), .player1_right_stop(enemy2stopR29), 
     .player1_up_stop(enemy2stopU29), .player1_down_stop(enemy2stopD29)
          ); 
          
     Collision enemy2collide22(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(384), .brick1_Y(160),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick22active),
     
     .player1_left_stop(enemy2stopL30), .player1_right_stop(enemy2stopR30), 
     .player1_up_stop(enemy2stopU30), .player1_down_stop(enemy2stopD30)
          ); 
          
     Collision enemy2collide23(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(160), .brick1_Y(96),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick23active),
     
     .player1_left_stop(enemy2stopL31), .player1_right_stop(enemy2stopR31), 
     .player1_up_stop(enemy2stopU31), .player1_down_stop(enemy2stopD31)
          ); 
          
      Collision enemy2collide24(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(192), .brick1_Y(96),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick24active),
     
     .player1_left_stop(enemy2stopL32), .player1_right_stop(enemy2stopR32), 
     .player1_up_stop(enemy2stopU32), .player1_down_stop(enemy2stopD32)
          ); 
          
     Collision enemy2collide25(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(192), .brick1_Y(32),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick25active),
     
     .player1_left_stop(enemy2stopL33), .player1_right_stop(enemy2stopR33), 
     .player1_up_stop(enemy2stopU33), .player1_down_stop(enemy2stopD33)
          );
          
      Collision enemy2collide26(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(512), .brick1_Y(256),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick26active),
     
     .player1_left_stop(enemy2stopL42), .player1_right_stop(enemy2stopR42), 
     .player1_up_stop(enemy2stopU42), .player1_down_stop(enemy2stopD42)
          );
          
      Collision enemy2collide27(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(544), .brick1_Y(256),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick27active),
     
     .player1_left_stop(enemy2stopL43), .player1_right_stop(enemy2stopR43), 
     .player1_up_stop(enemy2stopU43), .player1_down_stop(enemy2stopD43)
          ); 
                          
    Collision steel1enemy2collide(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(449), .brick1_Y(288),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     
     .player1_left_stop(enemy2stopL2), .player1_right_stop(enemy2stopR2), 
     .player1_up_stop(enemy2stopU2), .player1_down_stop(enemy2stopD2)
          ); 
          
      Collision steel2enemy2collide(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(320), .brick1_Y(288),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     
     .player1_left_stop(enemy2stopL3), .player1_right_stop(enemy2stopR3), 
     .player1_up_stop(enemy2stopU3), .player1_down_stop(enemy2stopD3)
          ); 
     Collision steel3enemy2collide(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(288), .brick1_Y(288),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     
     .player1_left_stop(enemy2stopL4), .player1_right_stop(enemy2stopR4), 
     .player1_up_stop(enemy2stopU4), .player1_down_stop(enemy2stopD4)
          ); 
     
     Collision steel4enemy2collide(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(352), .brick1_Y(288),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     
     .player1_left_stop(enemy2stopL5), .player1_right_stop(enemy2stopR5), 
     .player1_up_stop(enemy2stopU5), .player1_down_stop(enemy2stopD5)
          ); 
     
     Collision steel5enemy2collide(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(449), .brick1_Y(256),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     
     .player1_left_stop(enemy2stopL9), .player1_right_stop(enemy2stopR9), 
     .player1_up_stop(enemy2stopU9), .player1_down_stop(enemy2stopD9)
          ); 
     
     Collision steel6enemy2collide(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(160), .brick1_Y(224),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
    
     .player1_left_stop(enemy2stopL13), .player1_right_stop(enemy2stopR13), 
     .player1_up_stop(enemy2stopU13), .player1_down_stop(enemy2stopD13)
          ); 
     
     Collision steel7enemy2collide(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(160), .brick1_Y(192),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy2stopL20), .player1_right_stop(enemy2stopR20), 
     .player1_up_stop(enemy2stopU20), .player1_down_stop(enemy2stopD20)
          ); 
          
     Collision steel8enemy2collide(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(288), .brick1_Y(96),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy2stopL25), .player1_right_stop(enemy2stopR25), 
     .player1_up_stop(enemy2stopU25), .player1_down_stop(enemy2stopD25)
          ); 
          
     Collision steel9enemy2collide(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(192), .brick1_Y(64),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy2stopL34), .player1_right_stop(enemy2stopR34), 
     .player1_up_stop(enemy2stopU34), .player1_down_stop(enemy2stopD34)
          ); 
     
     Collision steel10enemy2collide(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(160), .brick1_Y(384),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy2stopL35), .player1_right_stop(enemy2stopR35), 
     .player1_up_stop(enemy2stopU35), .player1_down_stop(enemy2stopD35)
          ); 
     
     Collision steel11enemy2collide(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(192), .brick1_Y(384),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy2stopL36), .player1_right_stop(enemy2stopR36), 
     .player1_up_stop(enemy2stopU36), .player1_down_stop(enemy2stopD36)
          ); 
     
     Collision steel12enemy2collide(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(224), .brick1_Y(384),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy2stopL37), .player1_right_stop(enemy2stopR37), 
     .player1_up_stop(enemy2stopU37), .player1_down_stop(enemy2stopD37)
          );
     Collision steel13enemy2collide(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(192), .brick1_Y(352),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy2stopL38), .player1_right_stop(enemy2stopR38), 
     .player1_up_stop(enemy2stopU38), .player1_down_stop(enemy2stopD38)
          );
          
     Collision steel14enemy2collide(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(480), .brick1_Y(128),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy2stopL39), .player1_right_stop(enemy2stopR39), 
     .player1_up_stop(enemy2stopU39), .player1_down_stop(enemy2stopD39)
          );
          
     Collision steel15enemy2collide(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(512), .brick1_Y(128),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy2stopL40), .player1_right_stop(enemy2stopR40), 
     .player1_up_stop(enemy2stopU40), .player1_down_stop(enemy2stopD40)
          );
          
     Collision steel16enemy2collide(
     .player1_X(enemy2xsig), .player1_Y(enemy2ysig),
     .brick1_X(544), .brick1_Y(128),
     .p1_direction_flag(enemy2_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy2stopL41), .player1_right_stop(enemy2stopR41), 
     .player1_up_stop(enemy2stopU41), .player1_down_stop(enemy2stopD41)
          );


     bullcollidebrick enemy2bullbrick1(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(160),
    .obj_Y(288),
    .frame_clk(vsync), .extbrickactive(p1brick1active) , .extbrickactive2(enemy1brick1active),
    .extbrickactive3(enemy3brick1active),

    .bull_hit(enemy2bullhit1),
    .brickactive(enemy2brick1active)
     );
     
     bullcollidebrick enemy2bullbrick2(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(449),
    .obj_Y(320),
    .frame_clk(vsync), .extbrickactive(p1brick2active), .extbrickactive2(enemy1brick2active),
    .extbrickactive3(enemy3brick2active),

    .bull_hit(enemy2bullhit6),
    .brickactive(enemy2brick2active)
     );
     
     bullcollidebrick enemy2bullbrick3(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(449),
    .obj_Y(352),
    .frame_clk(vsync), .extbrickactive(p1brick3active), .extbrickactive2(enemy1brick3active),
    .extbrickactive3(enemy3brick3active),

    .bull_hit(enemy2bullhit7),
    .brickactive(enemy2brick3active)
     );
     
     bullcollidebrick enemy2bullbrick4(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(449),
    .obj_Y(384),
    .frame_clk(vsync), .extbrickactive(p1brick4active), .extbrickactive2(enemy1brick4active),
.extbrickactive3(enemy3brick4active),

    
    .bull_hit(enemy2bullhit8),
    .brickactive(enemy2brick4active)
     );
     
     bullcollidebrick enemy2bullbrick5(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(449),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(p1brick5active),.extbrickactive2(enemy1brick5active),
.extbrickactive3(enemy3brick5active),

    
    .bull_hit(enemy2bullhit10),
    .brickactive(enemy2brick5active)
     );
     
     bullcollidebrick enemy2bullbrick6(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(449),
    .obj_Y(192),
    .frame_clk(vsync), .extbrickactive(p1brick6active), .extbrickactive2(enemy1brick6active),
    .extbrickactive3(enemy3brick6active),

    .bull_hit(enemy2bullhit11),
    .brickactive(enemy2brick6active)
     );
     bullcollidebrick enemy2bullbrick7(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(160),
    .obj_Y(256),
    .frame_clk(vsync), .extbrickactive(p1brick7active), .extbrickactive2(enemy1brick7active),
    .extbrickactive3(enemy3brick7active),

    .bull_hit(enemy2bullhit12),
    .brickactive(enemy2brick7active)
     );
     bullcollidebrick enemy2bullbrick8(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(192),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(p1brick8active), .extbrickactive2(enemy1brick8active),
    .extbrickactive3(enemy3brick8active),

    .bull_hit(enemy2bullhit14),
    .brickactive(enemy2brick8active)
     );
     
     bullcollidebrick enemy2bullbrick9(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(224),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(p1brick9active), .extbrickactive2(enemy1brick9active),
    .extbrickactive3(enemy3brick9active),

    .bull_hit(enemy2bullhit15),
    .brickactive(enemy2brick9active)
     );
     
     bullcollidebrick enemy2bullbrick10(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(256),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(p1brick10active), .extbrickactive2(enemy1brick10active),
    .extbrickactive3(enemy3brick10active),

    .bull_hit(enemy2bullhit16),
    .brickactive(enemy2brick10active)
     );
     
     bullcollidebrick enemy2bullbrick11(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(63),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(p1brick11active), .extbrickactive2(enemy1brick11active),
    .extbrickactive3(enemy3brick11active),

    .bull_hit(enemy2bullhit17),
    .brickactive(enemy2brick11active)
     );
     
     bullcollidebrick enemy2bullbrick12(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(95),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(p1brick12active), .extbrickactive2(enemy1brick12active),
    .extbrickactive3(enemy3brick12active),

    .bull_hit(enemy2bullhit18),
    .brickactive(enemy2brick12active)
     );
     
     bullcollidebrick enemy2bullbrick13(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(127),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(p1brick13active), .extbrickactive2(enemy1brick13active),
    .extbrickactive3(enemy3brick13active),

    .bull_hit(enemy2bullhit19),
    .brickactive(enemy2brick13active)
     );
     
      bullcollidebrick enemy2bullbrick14(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(288),
    .obj_Y(32),
    .frame_clk(vsync), .extbrickactive(p1brick14active), .extbrickactive2(enemy1brick14active),
    .extbrickactive3(enemy3brick14active),

    .bull_hit(enemy2bullhit21),
    .brickactive(enemy2brick14active)
     );
     
      bullcollidebrick enemy2bullbrick15(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(288),
    .obj_Y(64),
    .frame_clk(vsync), .extbrickactive(p1brick15active), .extbrickactive2(enemy1brick15active), .extbrickactive3(enemy3brick15active),

    
    .bull_hit(enemy2bullhit22),
    .brickactive(enemy2brick15active)
     );
     
     bullcollidebrick enemy2bullbrick16(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(288),
    .obj_Y(128),
    .frame_clk(vsync), .extbrickactive(p1brick16active), .extbrickactive2(enemy1brick16active),
    .extbrickactive3(enemy3brick16active),

    .bull_hit(enemy2bullhit23),
    .brickactive(enemy2brick16active)
     );
     
     bullcollidebrick enemy2bullbrick17(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(288),
    .obj_Y(160),
    .frame_clk(vsync), .extbrickactive(p1brick17active), .extbrickactive2(enemy1brick17active),
    .extbrickactive3(enemy3brick17active),

    .bull_hit(enemy2bullhit24),
    .brickactive(enemy2brick17active)
     );
     
     bullcollidebrick enemy2bullbrick18(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(320),
    .obj_Y(128),
    .frame_clk(vsync), .extbrickactive(p1brick18active), .extbrickactive2(enemy1brick18active),
    .extbrickactive3(enemy3brick18active),

    .bull_hit(enemy2bullhit26),
    .brickactive(enemy2brick18active)
     );
     
     bullcollidebrick enemy2bullbrick19(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(352),
    .obj_Y(128),
    .frame_clk(vsync), .extbrickactive(p1brick19active), .extbrickactive2(enemy1brick19active),
    .extbrickactive3(enemy3brick19active),

    .bull_hit(enemy2bullhit27),
    .brickactive(enemy2brick19active)
     );
     
     bullcollidebrick enemy2bullbrick20(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(352),
    .obj_Y(96),
    .frame_clk(vsync), .extbrickactive(p1brick20active), .extbrickactive2(enemy1brick20active),
    .extbrickactive3(enemy3brick20active),

    .bull_hit(enemy2bullhit28),
    .brickactive(enemy2brick20active)
     );
     
     bullcollidebrick enemy2bullbrick21(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(352),
    .obj_Y(160),
    .frame_clk(vsync), .extbrickactive(p1brick21active), .extbrickactive2(enemy1brick21active),
    .extbrickactive3(enemy3brick21active),

    .bull_hit(enemy2bullhit29),
    .brickactive(enemy2brick21active)
     );
     
     bullcollidebrick enemy2bullbrick22(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(384),
    .obj_Y(160),
    .frame_clk(vsync), .extbrickactive(p1brick22active), .extbrickactive2(enemy1brick22active),
    .extbrickactive3(enemy3brick22active),

    .bull_hit(enemy2bullhit30),
    .brickactive(enemy2brick22active)
     );
     
     bullcollidebrick enemy2bullbrick23(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(160),
    .obj_Y(96),
    .frame_clk(vsync), .extbrickactive(p1brick23active), .extbrickactive2(enemy1brick23active),
    .extbrickactive3(enemy3brick23active),

    .bull_hit(enemy2bullhit31),
    .brickactive(enemy2brick23active)
     );
     
      bullcollidebrick enemy2bullbrick24(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(192),
    .obj_Y(96),
    .frame_clk(vsync), .extbrickactive(p1brick24active), .extbrickactive2(enemy1brick24active),
    .extbrickactive3(enemy3brick24active),

    .bull_hit(enemy2bullhit32),
    .brickactive(enemy2brick24active)
     );
     
      bullcollidebrick enemy2bullbrick25(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(192),
    .obj_Y(32),
    .frame_clk(vsync), .extbrickactive(p1brick25active),.extbrickactive2(enemy1brick25active),
     .extbrickactive3(enemy3brick25active),

    .bull_hit(enemy2bullhit33),
    .brickactive(enemy2brick25active)
     );
     
     bullcollidebrick enemy2bullbrick26(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(512),
    .obj_Y(256),
    .frame_clk(vsync), .extbrickactive(p1brick26active), .extbrickactive2(enemy1brick26active),
.extbrickactive3(enemy3brick26active),

    
    .bull_hit(enemy2bullhit42),
    .brickactive(enemy2brick26active)
     );
     
     bullcollidebrick enemy2bullbrick27(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(544),
    .obj_Y(256),
    .frame_clk(vsync), .extbrickactive(p1brick27active), .extbrickactive2(enemy1brick27active),
    .extbrickactive3(enemy3brick27active),

    .bull_hit(enemy2bullhit43),
    .brickactive(enemy2brick27active)
     );

     

     
     bullcollidesteel enemy2bullsteel1(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(449),
    .obj_Y(288),
    .frame_clk(vsync),
    
    .bull_hit(enemy2bullhit2)
     );
      
      bullcollidesteel enemy2bullsteel2(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(320),
    .obj_Y(288),
    .frame_clk(vsync),
    
    .bull_hit(enemy2bullhit3)
     );
     
      bullcollidesteel enemy2bullsteel3(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(288),
    .obj_Y(288),
    .frame_clk(vsync),
    
    .bull_hit(enemy2bullhit4)
     );
     
      bullcollidesteel enemy2bullsteel4(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(352),
    .obj_Y(288),
    .frame_clk(vsync),
    
    .bull_hit(enemy2bullhit5)
     ); 
     bullcollidesteel enemy2bullsteel5(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(449),
    .obj_Y(256),
    .frame_clk(vsync),
    
    .bull_hit(enemy2bullhit9)
     ); 
     
     
    bullcollidesteel enemy2bullsteel6(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(160),
    .obj_Y(224),
    .frame_clk(vsync),
    
    .bull_hit(enemy2bullhit13)
     );   
     
     bullcollidesteel enemy2bullsteel7(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(160),
    .obj_Y(192),
    .frame_clk(vsync),
    
    .bull_hit(enemy2bullhit20)
     );   
     
     bullcollidesteel enemy2bullsteel8(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(288),
    .obj_Y(96),
    .frame_clk(vsync),
    
    .bull_hit(enemy2bullhit25)
     );   
     
      bullcollidesteel enemy2bullsteel9(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(192),
    .obj_Y(64),
    .frame_clk(vsync),
    
    .bull_hit(enemy2bullhit34)
     );   
     
     bullcollidesteel enemy2bullsteel10(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(160),
    .obj_Y(384),
    .frame_clk(vsync),
    
    .bull_hit(enemy2bullhit35)
     );
     
     bullcollidesteel enemy2bullsteel11(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(192),
    .obj_Y(384),
    .frame_clk(vsync),
    
    .bull_hit(enemy2bullhit36)
     );
     
     bullcollidesteel enemy2bullsteel12(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(224),
    .obj_Y(384),
    .frame_clk(vsync),
    
    .bull_hit(enemy2bullhit37)
     );
     
     bullcollidesteel enemy2bullsteel13(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(192),
    .obj_Y(352),
    .frame_clk(vsync),
    
    .bull_hit(enemy2bullhit38)
     );
     
      bullcollidesteel enemy2bullsteel14(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(480),
    .obj_Y(128),
    .frame_clk(vsync),
    
    .bull_hit(enemy2bullhit39)
     );
     
      bullcollidesteel enemy2bullsteel15(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(512),
    .obj_Y(128),
    .frame_clk(vsync),
    
    .bull_hit(enemy2bullhit40)
     );
     
     bullcollidesteel enemy2bullsteel16(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(544),
    .obj_Y(128),
    .frame_clk(vsync),
    
    .bull_hit(enemy2bullhit41)
     );

 
     logic enemy2bullflagright;
    logic [3:0] enemy2bullright_red, enemy2bullright_green, enemy2bullright_blue;
    enemybullright_example enemy2bullright(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.bull_X(enemy2bullxsig), .bull_Y(enemy2bullysig), 
	.red(enemy2bullright_red), .green(enemy2bullright_green), .blue(enemy2bullright_blue),
	.bullflagright(enemy2bullflagright)
     );   
     
     logic enemy2bullflagdown;
    logic [3:0] enemy2bulldown_red, enemy2bulldown_green, enemy2bulldown_blue;
    enemybulldown_example enemy2bulldown(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.bull_X(enemy2bullxsig), .bull_Y(enemy2bullysig), 
	.red(enemy2bulldown_red), .green(enemy2bulldown_green), .blue(enemy2bulldown_blue),
	.bullflagdown(enemy2bullflagdown)
     );   
     
     logic enemy2bullflagleft;
    logic [3:0] enemy2bullleft_red, enemy2bullleft_green, enemy2bullleft_blue;
    enemybullleft_example enemy2bullleft(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.bull_X(enemy2bullxsig), .bull_Y(enemy2bullysig), 
	.red(enemy2bullleft_red), .green(enemy2bullleft_green), .blue(enemy2bullleft_blue),
	.bullflagleft(enemy2bullflagleft)
     );   
     
     logic enemy2bullflagup;
    logic [3:0] enemy2bullup_red, enemy2bullup_green, enemy2bullup_blue;
    enemybullup_example enemy2bullup(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.bull_X(enemy2bullxsig), .bull_Y(enemy2bullysig), 
	.red(enemy2bullup_red), .green(enemy2bullup_green), .blue(enemy2bullup_blue),
	.bullflagup(enemy2bullflagup)
     );   

bullcollidetank enemy2hitp1(
     .bull_X(enemy2bullxsig),
    .bull_Y(enemy2bullysig),
    .obj_X(p1xsig),
    .obj_Y(p1ysig),
    .frame_clk(vsync), 
    .Reset(reset_ah),
    .bull_live(enemy2_bull_live),
        
    .bull_hit(enemy2p1hit),
    .enemy_counter(p1counter2)
     ); 

 bullcollidetank p1hitenemy2(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(enemy2xsig),
    .obj_Y(enemy2ysig),
    .frame_clk(vsync), 
    .Reset(reset_ah),
    .bull_live(bull_live),
    
    .bull_hit(p1enemy2hit),
    .enemy_counter(enemy2_counter)
     ); 

   logic enemy2explosion, enemy2explode_flag;
     logic [3:0] enemy2explode_red, enemy2explode_green, enemy2explode_blue;
     explode_example enemy2explosion_sprite(
     .vga_clk(clk_25MHz),
     .DrawX(drawX), .DrawY(drawY),
     .blank(vde),
     .bull_X(enemy2bullxsig), .bull_Y(enemy2bullysig),
     .red(enemy2explode_red), .green(enemy2explode_green), .blue(enemy2explode_blue),
     .bull_live(enemy2_bull_live),
     .explode_flag(enemy2explode_flag),
     .explosion(enemy2explosion)
     );


     
     
     
     
     
     
     // ENEMY1 COLLISION LOGIC
     
     
     
     
     
     
     Collision enemy1collide(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(160), .brick1_Y(288),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick1active),
     
     .player1_left_stop(enemy1stopL1), .player1_right_stop(enemy1stopR1), 
     .player1_up_stop(enemy1stopU1), .player1_down_stop(enemy1stopD1)
          ); 
     
     Collision enemy1collide2(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(449), .brick1_Y(320),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick2active),
     
     .player1_left_stop(enemy1stopL6), .player1_right_stop(enemy1stopR6), 
     .player1_up_stop(enemy1stopU6), .player1_down_stop(enemy1stopD6)
          ); 
          
     Collision enemy1collide3(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(449), .brick1_Y(352),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick3active),
     
     .player1_left_stop(enemy1stopL7), .player1_right_stop(enemy1stopR7), 
     .player1_up_stop(enemy1stopU7), .player1_down_stop(enemy1stopD7)
          ); 
     
     Collision enemy1collide4(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(449), .brick1_Y(384),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick4active),
     
     .player1_left_stop(enemy1stopL8), .player1_right_stop(enemy1stopR8), 
     .player1_up_stop(enemy1stopU8), .player1_down_stop(enemy1stopD8)
          ); 
    Collision enemy1collide5(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(449), .brick1_Y(224),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick5active),
     
     .player1_left_stop(enemy1stopL10), .player1_right_stop(enemy1stopR10), 
     .player1_up_stop(enemy1stopU10), .player1_down_stop(enemy1stopD10)
          ); 
          
          Collision enemy1collide6(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(449), .brick1_Y(192),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick6active),
     
     .player1_left_stop(enemy1stopL11), .player1_right_stop(enemy1stopR11), 
     .player1_up_stop(enemy1stopU11), .player1_down_stop(enemy1stopD11)
          );
          
      Collision enemy1collide7(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(160), .brick1_Y(256),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick7active),
     
     .player1_left_stop(enemy1stopL12), .player1_right_stop(enemy1stopR12), 
     .player1_up_stop(enemy1stopU12), .player1_down_stop(enemy1stopD12)
          ); 
          
      Collision enemy1collide8(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(192), .brick1_Y(224),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick8active),
     
     .player1_left_stop(enemy1stopL14), .player1_right_stop(enemy1stopR14), 
     .player1_up_stop(enemy1stopU14), .player1_down_stop(enemy1stopD14)
          );  
     Collision enemy1collide9(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(224), .brick1_Y(224),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick9active),
     
     .player1_left_stop(enemy1stopL15), .player1_right_stop(enemy1stopR15), 
     .player1_up_stop(enemy1stopU15), .player1_down_stop(enemy1stopD15)
          );
     Collision enemy1collide10(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(256), .brick1_Y(224),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick10active),
     
     .player1_left_stop(enemy1stopL16), .player1_right_stop(enemy1stopR16), 
     .player1_up_stop(enemy1stopU16), .player1_down_stop(enemy1stopD16)
          );    
          
     Collision enemy1collide11(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(63), .brick1_Y(224),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick11active),
     
     .player1_left_stop(enemy1stopL17), .player1_right_stop(enemy1stopR17), 
     .player1_up_stop(enemy1stopU17), .player1_down_stop(enemy1stopD17)
          );        
     
      Collision enemy1collide12(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(95), .brick1_Y(224),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick12active),
     
     .player1_left_stop(enemy1stopL18), .player1_right_stop(enemy1stopR18), 
     .player1_up_stop(enemy1stopU18), .player1_down_stop(enemy1stopD18)
          );    
          
     Collision enemy1collide13(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(127), .brick1_Y(224),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick13active),
     
     .player1_left_stop(enemy1stopL19), .player1_right_stop(enemy1stopR19), 
     .player1_up_stop(enemy1stopU19), .player1_down_stop(enemy1stopD19)
          );     
          
     Collision enemy1collide14(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(288), .brick1_Y(32),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick14active),
     
     .player1_left_stop(enemy1stopL21), .player1_right_stop(enemy1stopR21), 
     .player1_up_stop(enemy1stopU21), .player1_down_stop(enemy1stopD21)
          );    
          
     Collision enemy1collide15(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(288), .brick1_Y(64),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick15active),
     
     .player1_left_stop(enemy1stopL22), .player1_right_stop(enemy1stopR22), 
     .player1_up_stop(enemy1stopU22), .player1_down_stop(enemy1stopD22)
          );       
          
      Collision enemy1collide16(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(288), .brick1_Y(128),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick16active),
     
     .player1_left_stop(enemy1stopL23), .player1_right_stop(enemy1stopR23), 
     .player1_up_stop(enemy1stopU23), .player1_down_stop(enemy1stopD23)
          );      
          
      Collision enemy1collide17(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(288), .brick1_Y(160),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick17active),
     
     .player1_left_stop(enemy1stopL24), .player1_right_stop(enemy1stopR24), 
     .player1_up_stop(enemy1stopU24), .player1_down_stop(enemy1stopD24)
          ); 
          
          
     Collision enemy1collide18(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(320), .brick1_Y(128),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick18active),
     
     .player1_left_stop(enemy1stopL26), .player1_right_stop(enemy1stopR26), 
     .player1_up_stop(enemy1stopU26), .player1_down_stop(enemy1stopD26)
          );                
    Collision enemy1collide19(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(352), .brick1_Y(128),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick19active),
     
     .player1_left_stop(enemy1stopL27), .player1_right_stop(enemy1stopR27), 
     .player1_up_stop(enemy1stopU27), .player1_down_stop(enemy1stopD27)
          );   
     
     Collision enemy1collide20(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(352), .brick1_Y(96),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick20active),
     
     .player1_left_stop(enemy1stopL28), .player1_right_stop(enemy1stopR28), 
     .player1_up_stop(enemy1stopU28), .player1_down_stop(enemy1stopD28)
          );       
     Collision enemy1collide21(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(352), .brick1_Y(160),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick21active),
     
     .player1_left_stop(enemy1stopL29), .player1_right_stop(enemy1stopR29), 
     .player1_up_stop(enemy1stopU29), .player1_down_stop(enemy1stopD29)
          ); 
          
     Collision enemy1collide22(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(384), .brick1_Y(160),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick22active),
     
     .player1_left_stop(enemy1stopL30), .player1_right_stop(enemy1stopR30), 
     .player1_up_stop(enemy1stopU30), .player1_down_stop(enemy1stopD30)
          ); 
          
     Collision enemy1collide23(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(160), .brick1_Y(96),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick23active),
     
     .player1_left_stop(enemy1stopL31), .player1_right_stop(enemy1stopR31), 
     .player1_up_stop(enemy1stopU31), .player1_down_stop(enemy1stopD31)
          ); 
          
      Collision enemy1collide24(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(192), .brick1_Y(96),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick24active),
     
     .player1_left_stop(enemy1stopL32), .player1_right_stop(enemy1stopR32), 
     .player1_up_stop(enemy1stopU32), .player1_down_stop(enemy1stopD32)
          ); 
          
     Collision enemy1collide25(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(192), .brick1_Y(32),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick25active),
     
     .player1_left_stop(enemy1stopL33), .player1_right_stop(enemy1stopR33), 
     .player1_up_stop(enemy1stopU33), .player1_down_stop(enemy1stopD33)
          );
          
      Collision enemy1collide26(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(512), .brick1_Y(256),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick26active),
     
     .player1_left_stop(enemy1stopL42), .player1_right_stop(enemy1stopR42), 
     .player1_up_stop(enemy1stopU42), .player1_down_stop(enemy1stopD42)
          );
          
      Collision enemy1collide27(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(544), .brick1_Y(256),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick27active),
     
     .player1_left_stop(enemy1stopL43), .player1_right_stop(enemy1stopR43), 
     .player1_up_stop(enemy1stopU43), .player1_down_stop(enemy1stopD43)
          ); 
                          
    Collision steel1enemy1collide(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(449), .brick1_Y(288),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     
     .player1_left_stop(enemy1stopL2), .player1_right_stop(enemy1stopR2), 
     .player1_up_stop(enemy1stopU2), .player1_down_stop(enemy1stopD2)
          ); 
          
      Collision steel2enemy1collide(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(320), .brick1_Y(288),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     
     .player1_left_stop(enemy1stopL3), .player1_right_stop(enemy1stopR3), 
     .player1_up_stop(enemy1stopU3), .player1_down_stop(enemy1stopD3)
          ); 
     Collision steel3enemy1collide(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(288), .brick1_Y(288),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     
     .player1_left_stop(enemy1stopL4), .player1_right_stop(enemy1stopR4), 
     .player1_up_stop(enemy1stopU4), .player1_down_stop(enemy1stopD4)
          ); 
     
     Collision steel4enemy1collide(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(352), .brick1_Y(288),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     
     .player1_left_stop(enemy1stopL5), .player1_right_stop(enemy1stopR5), 
     .player1_up_stop(enemy1stopU5), .player1_down_stop(enemy1stopD5)
          ); 
     
     Collision steel5enemy1collide(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(449), .brick1_Y(256),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     
     .player1_left_stop(enemy1stopL9), .player1_right_stop(enemy1stopR9), 
     .player1_up_stop(enemy1stopU9), .player1_down_stop(enemy1stopD9)
          ); 
     
     Collision steel6enemy1collide(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(160), .brick1_Y(224),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
    
     .player1_left_stop(enemy1stopL13), .player1_right_stop(enemy1stopR13), 
     .player1_up_stop(enemy1stopU13), .player1_down_stop(enemy1stopD13)
          ); 
     
     Collision steel7enemy1collide(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(160), .brick1_Y(192),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy1stopL20), .player1_right_stop(enemy1stopR20), 
     .player1_up_stop(enemy1stopU20), .player1_down_stop(enemy1stopD20)
          ); 
          
     Collision steel8enemy1collide(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(288), .brick1_Y(96),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy1stopL25), .player1_right_stop(enemy1stopR25), 
     .player1_up_stop(enemy1stopU25), .player1_down_stop(enemy1stopD25)
          ); 
          
     Collision steel9enemy1collide(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(192), .brick1_Y(64),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy1stopL34), .player1_right_stop(enemy1stopR34), 
     .player1_up_stop(enemy1stopU34), .player1_down_stop(enemy1stopD34)
          ); 
     
     Collision steel10enemy1collide(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(160), .brick1_Y(384),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy1stopL35), .player1_right_stop(enemy1stopR35), 
     .player1_up_stop(enemy1stopU35), .player1_down_stop(enemy1stopD35)
          ); 
     
     Collision steel11enemy1collide(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(192), .brick1_Y(384),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy1stopL36), .player1_right_stop(enemy1stopR36), 
     .player1_up_stop(enemy1stopU36), .player1_down_stop(enemy1stopD36)
          ); 
     
     Collision steel12enemy1collide(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(224), .brick1_Y(384),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy1stopL37), .player1_right_stop(enemy1stopR37), 
     .player1_up_stop(enemy1stopU37), .player1_down_stop(enemy1stopD37)
          );
     Collision steel13enemy1collide(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(192), .brick1_Y(352),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy1stopL38), .player1_right_stop(enemy1stopR38), 
     .player1_up_stop(enemy1stopU38), .player1_down_stop(enemy1stopD38)
          );
          
     Collision steel14enemy1collide(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(480), .brick1_Y(128),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy1stopL39), .player1_right_stop(enemy1stopR39), 
     .player1_up_stop(enemy1stopU39), .player1_down_stop(enemy1stopD39)
          );
          
     Collision steel15enemy1collide(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(512), .brick1_Y(128),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy1stopL40), .player1_right_stop(enemy1stopR40), 
     .player1_up_stop(enemy1stopU40), .player1_down_stop(enemy1stopD40)
          );
          
     Collision steel16enemy1collide(
     .player1_X(enemy1xsig), .player1_Y(enemy1ysig),
     .brick1_X(544), .brick1_Y(128),
     .p1_direction_flag(enemy1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(enemy1stopL41), .player1_right_stop(enemy1stopR41), 
     .player1_up_stop(enemy1stopU41), .player1_down_stop(enemy1stopD41)
          );
    
     bullcollidetank p1hitenemy1(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(enemy1xsig),
    .obj_Y(enemy1ysig),
    .frame_clk(vsync), 
    .Reset(reset_ah),
    .bull_live(bull_live),
    
    .bull_hit(p1enemy1hit),
    .enemy_counter(enemy1_counter)
     ); 
     
     bullcollidetank enemy1hitp1(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(p1xsig),
    .obj_Y(p1ysig),
    .frame_clk(vsync), 
    .Reset(reset_ah),
    .bull_live(enemy1_bull_live),
        
    .bull_hit(enemy1p1hit),
    .enemy_counter(p1counter1)
     ); 
   
     bullcollidebrick enemy1bullbrick1(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(160),
    .obj_Y(288),
    .frame_clk(vsync), .extbrickactive(p1brick1active), .extbrickactive2(enemy2brick1active),
   .extbrickactive3(enemy3brick1active),
    
    .bull_hit(enemy1bullhit1),
    .brickactive(enemy1brick1active)
     );
     
     bullcollidebrick enemy1bullbrick2(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(449),
    .obj_Y(320),
    .frame_clk(vsync), .extbrickactive(p1brick2active),.extbrickactive2(enemy2brick2active),
    .extbrickactive3(enemy3brick2active),
    .bull_hit(enemy1bullhit6),
    .brickactive(enemy1brick2active)
     );
     
     bullcollidebrick enemy1bullbrick3(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(449),
    .obj_Y(352),
    .frame_clk(vsync), .extbrickactive(p1brick3active), .extbrickactive2(enemy2brick3active),
    .extbrickactive3(enemy3brick3active),
    .bull_hit(enemy1bullhit7),
    .brickactive(enemy1brick3active)
     );
     
     bullcollidebrick enemy1bullbrick4(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(449),
    .obj_Y(384),
    .frame_clk(vsync), .extbrickactive(p1brick4active), .extbrickactive2(enemy2brick4active),
    .extbrickactive3(enemy3brick4active),
    .bull_hit(enemy1bullhit8),
    .brickactive(enemy1brick4active)
     );
     
     bullcollidebrick enemy1bullbrick5(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(449),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(p1brick5active),.extbrickactive2(enemy2brick5active),
    .extbrickactive3(enemy3brick5active),
    .bull_hit(enemy1bullhit10),
    .brickactive(enemy1brick5active)
     );
     
     bullcollidebrick enemy1bullbrick6(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(449),
    .obj_Y(192),
    .frame_clk(vsync), .extbrickactive(p1brick6active), .extbrickactive2(enemy2brick6active),
    .extbrickactive3(enemy3brick6active),
    .bull_hit(enemy1bullhit11),
    .brickactive(enemy1brick6active)
     );
     bullcollidebrick enemy1bullbrick7(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(160),
    .obj_Y(256),
    .frame_clk(vsync), .extbrickactive(p1brick7active),.extbrickactive2(enemy2brick7active),
    .extbrickactive3(enemy3brick7active),
    .bull_hit(enemy1bullhit12),
    .brickactive(enemy1brick7active)
     );
     bullcollidebrick enemy1bullbrick8(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(192),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(p1brick8active), .extbrickactive2(enemy2brick8active),
    .extbrickactive3(enemy3brick8active),
    .bull_hit(enemy1bullhit14),
    .brickactive(enemy1brick8active)
     );
     
     bullcollidebrick enemy1bullbrick9(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(224),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(p1brick9active), .extbrickactive2(enemy2brick9active),
    .extbrickactive3(enemy3brick9active),
    .bull_hit(enemy1bullhit15),
    .brickactive(enemy1brick9active)
     );
     
     bullcollidebrick enemy1bullbrick10(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(256),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(p1brick10active), .extbrickactive2(enemy2brick10active),
    .extbrickactive3(enemy3brick10active),
    .bull_hit(enemy1bullhit16),
    .brickactive(enemy1brick10active)
     );
     
     bullcollidebrick enemy1bullbrick11(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(63),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(p1brick11active), .extbrickactive2(enemy2brick11active),
    .extbrickactive3(enemy3brick11active),
    .bull_hit(enemy1bullhit17),
    .brickactive(enemy1brick11active)
     );
     
     bullcollidebrick enemy1bullbrick12(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(95),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(p1brick12active),.extbrickactive2(enemy2brick12active),
    .extbrickactive3(enemy3brick12active),
    .bull_hit(enemy1bullhit18),
    .brickactive(enemy1brick12active)
     );
     
     bullcollidebrick enemy1bullbrick13(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(127),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(p1brick13active), .extbrickactive2(enemy2brick13active),
    .extbrickactive3(enemy3brick13active),
    .bull_hit(enemy1bullhit19),
    .brickactive(enemy1brick13active)
     );
     
      bullcollidebrick enemy1bullbrick14(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(288),
    .obj_Y(32),
    .frame_clk(vsync), .extbrickactive(p1brick14active), .extbrickactive2(enemy2brick14active),
    .extbrickactive3(enemy3brick14active),
    .bull_hit(enemy1bullhit21),
    .brickactive(enemy1brick14active)
     );
     
      bullcollidebrick enemy1bullbrick15(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(288),
    .obj_Y(64),
    .frame_clk(vsync), .extbrickactive(p1brick15active), .extbrickactive2(enemy2brick15active),
    .extbrickactive3(enemy3brick15active),
    .bull_hit(enemy1bullhit22),
    .brickactive(enemy1brick15active)
     );
     
     bullcollidebrick enemy1bullbrick16(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(288),
    .obj_Y(128),
    .frame_clk(vsync), .extbrickactive(p1brick16active), .extbrickactive2(enemy2brick16active),
    .extbrickactive3(enemy3brick16active),
    .bull_hit(enemy1bullhit23),
    .brickactive(enemy1brick16active)
     );
     
     bullcollidebrick enemy1bullbrick17(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(288),
    .obj_Y(160),
    .frame_clk(vsync), .extbrickactive(p1brick17active), .extbrickactive2(enemy2brick17active),
    .extbrickactive3(enemy3brick17active),
    .bull_hit(enemy1bullhit24),
    .brickactive(enemy1brick17active)
     );
     
     bullcollidebrick enemy1bullbrick18(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(320),
    .obj_Y(128),
    .frame_clk(vsync), .extbrickactive(p1brick18active), .extbrickactive2(enemy2brick18active),
    .extbrickactive3(enemy3brick18active),
    .bull_hit(enemy1bullhit26),
    .brickactive(enemy1brick18active)
     );
     
     bullcollidebrick enemy1bullbrick19(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(352),
    .obj_Y(128),
    .frame_clk(vsync), .extbrickactive(p1brick19active), .extbrickactive2(enemy2brick19active),
    .extbrickactive3(enemy3brick19active),
    .bull_hit(enemy1bullhit27),
    .brickactive(enemy1brick19active)
     );
     
     bullcollidebrick enemy1bullbrick20(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(352),
    .obj_Y(96),
    .frame_clk(vsync), .extbrickactive(p1brick20active),.extbrickactive2(enemy2brick20active),
    .extbrickactive3(enemy3brick20active),
    .bull_hit(enemy1bullhit28),
    .brickactive(enemy1brick20active)
     );
     
     bullcollidebrick enemy1bullbrick21(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(352),
    .obj_Y(160),
    .frame_clk(vsync), .extbrickactive(p1brick21active),.extbrickactive2(enemy2brick21active),
    .extbrickactive3(enemy3brick21active),
    .bull_hit(enemy1bullhit29),
    .brickactive(enemy1brick21active)
     );
     
     bullcollidebrick enemy1bullbrick22(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(384),
    .obj_Y(160),
    .frame_clk(vsync), .extbrickactive(p1brick22active),.extbrickactive2(enemy2brick22active),
    .extbrickactive3(enemy3brick22active),
    .bull_hit(enemy1bullhit30),
    .brickactive(enemy1brick22active)
     );
     
     bullcollidebrick enemy1bullbrick23(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(160),
    .obj_Y(96),
    .frame_clk(vsync), .extbrickactive(p1brick23active),.extbrickactive2(enemy2brick23active),
    .extbrickactive3(enemy3brick23active),
    .bull_hit(enemy1bullhit31),
    .brickactive(enemy1brick23active)
     );
     
      bullcollidebrick enemy1bullbrick24(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(192),
    .obj_Y(96),
    .frame_clk(vsync), .extbrickactive(p1brick24active),.extbrickactive2(enemy2brick24active),
    .extbrickactive3(enemy3brick24active),
    .bull_hit(enemy1bullhit32),
    .brickactive(enemy1brick24active)
     );
     
      bullcollidebrick enemy1bullbrick25(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(192),
    .obj_Y(32),
    .frame_clk(vsync), .extbrickactive(p1brick25active),.extbrickactive2(enemy2brick25active),
    .extbrickactive3(enemy3brick25active),
    .bull_hit(enemy1bullhit33),
    .brickactive(enemy1brick25active)
     );
     
     bullcollidebrick enemy1bullbrick26(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(512),
    .obj_Y(256),
    .frame_clk(vsync), .extbrickactive(p1brick26active),.extbrickactive2(enemy2brick26active),
    .extbrickactive3(enemy3brick26active),
    .bull_hit(enemy1bullhit42),
    .brickactive(enemy1brick26active)
     );
     
     bullcollidebrick enemy1bullbrick27(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(544),
    .obj_Y(256),
    .frame_clk(vsync), .extbrickactive(p1brick27active),.extbrickactive2(enemy2brick27active),
    .extbrickactive3(enemy3brick27active),
    .bull_hit(enemy1bullhit43),
    .brickactive(enemy1brick27active)
     );
     




     
     bullcollidesteel enemy1bullsteel1(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(449),
    .obj_Y(288),
    .frame_clk(vsync),
    
    .bull_hit(enemy1bullhit2)
     );
      
      bullcollidesteel enemy1bullsteel2(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(320),
    .obj_Y(288),
    .frame_clk(vsync),
    
    .bull_hit(enemy1bullhit3)
     );
     
      bullcollidesteel enemy1bullsteel3(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(288),
    .obj_Y(288),
    .frame_clk(vsync),
    
    .bull_hit(enemy1bullhit4)
     );
     
      bullcollidesteel enemy1bullsteel4(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(352),
    .obj_Y(288),
    .frame_clk(vsync),
    
    .bull_hit(enemy1bullhit5)
     ); 
     bullcollidesteel enemy1bullsteel5(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(449),
    .obj_Y(256),
    .frame_clk(vsync),
    
    .bull_hit(enemy1bullhit9)
     ); 
     
     
    bullcollidesteel enemy1bullsteel6(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(160),
    .obj_Y(224),
    .frame_clk(vsync),
    
    .bull_hit(enemy1bullhit13)
     );   
     
     bullcollidesteel enemy1bullsteel7(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(160),
    .obj_Y(192),
    .frame_clk(vsync),
    
    .bull_hit(enemy1bullhit20)
     );   
     
     bullcollidesteel enemy1bullsteel8(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(288),
    .obj_Y(96),
    .frame_clk(vsync),
    
    .bull_hit(enemy1bullhit25)
     );   
     
      bullcollidesteel enemy1bullsteel9(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(192),
    .obj_Y(64),
    .frame_clk(vsync),
    
    .bull_hit(enemy1bullhit34)
     );   
     
     bullcollidesteel enemy1bullsteel10(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(160),
    .obj_Y(384),
    .frame_clk(vsync),
    
    .bull_hit(enemy1bullhit35)
     );
     
     bullcollidesteel enemy1bullsteel11(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(192),
    .obj_Y(384),
    .frame_clk(vsync),
    
    .bull_hit(enemy1bullhit36)
     );
     
     bullcollidesteel enemy1bullsteel12(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(224),
    .obj_Y(384),
    .frame_clk(vsync),
    
    .bull_hit(enemy1bullhit37)
     );
     
     bullcollidesteel enemy1bullsteel13(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(192),
    .obj_Y(352),
    .frame_clk(vsync),
    
    .bull_hit(enemy1bullhit38)
     );
     
      bullcollidesteel enemy1bullsteel14(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(480),
    .obj_Y(128),
    .frame_clk(vsync),
    
    .bull_hit(enemy1bullhit39)
     );
     
      bullcollidesteel enemy1bullsteel15(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(512),
    .obj_Y(128),
    .frame_clk(vsync),
    
    .bull_hit(enemy1bullhit40)
     );
     
     bullcollidesteel enemy1bullsteel16(
     .bull_X(enemy1bullxsig),
    .bull_Y(enemy1bullysig),
    .obj_X(544),
    .obj_Y(128),
    .frame_clk(vsync),
    
    .bull_hit(enemy1bullhit41)
     );

     
     
     
     
     
     
     
     // END ENEMY1 COLLISION LOGIC
     
     
     
     
     
      
//  Instantiate collision modules
    logic p1stopL, p1stopR, p1stopU, p1stopD, p1stopL1, p1stopR1, p1stopU1, p1stopD1,  p1stopL2, p1stopR2, p1stopU2, p1stopD2;
    logic p1stopL3, p1stopR3, p1stopU3, p1stopD3, p1stopL4, p1stopR4, p1stopU4, p1stopD4,  p1stopL5, p1stopR5, p1stopU5, p1stopD5;
    logic p1stopL6, p1stopR6, p1stopU6, p1stopD6, p1stopL7, p1stopR7, p1stopU7, p1stopD7,  p1stopL8, p1stopR8, p1stopU8, p1stopD8;
    logic p1stopL9, p1stopR9, p1stopU9, p1stopD9, p1stopL10, p1stopR10, p1stopU10, p1stopD10,  p1stopL11, p1stopR11, p1stopU11, p1stopD11;
    logic p1stopL12, p1stopR12, p1stopU12, p1stopD12, p1stopL13, p1stopR13, p1stopU13, p1stopD13,  p1stopL14, p1stopR14, p1stopU14, p1stopD14;
    logic p1stopL15, p1stopR15, p1stopU15, p1stopD15, p1stopL16, p1stopR16, p1stopU16, p1stopD16,  p1stopL17, p1stopR17, p1stopU17, p1stopD17;
    logic p1stopL18, p1stopR18, p1stopU18, p1stopD18, p1stopL19, p1stopR19, p1stopU19, p1stopD19, p1stopL20, p1stopR20, p1stopU20, p1stopD20;
    logic p1stopL21, p1stopR21, p1stopU21, p1stopD21, p1stopL22, p1stopR22, p1stopU22, p1stopD22, p1stopL23, p1stopR23, p1stopU23, p1stopD23;
    logic p1stopL24, p1stopR24, p1stopU24, p1stopD24, p1stopL25, p1stopR25, p1stopU25, p1stopD25, p1stopL26, p1stopR26, p1stopU26, p1stopD26;
    logic p1stopL27, p1stopR27, p1stopU27, p1stopD27, p1stopL28, p1stopR28, p1stopU28, p1stopD28, p1stopL29, p1stopR29, p1stopU29, p1stopD29;
    logic p1stopL31, p1stopR31, p1stopU31, p1stopD31, p1stopL32, p1stopR32, p1stopU32, p1stopD32, p1stopL33, p1stopR33, p1stopU33, p1stopD33;
    logic p1stopL30, p1stopR30, p1stopU30, p1stopD30, p1stopL34, p1stopR34, p1stopU34, p1stopD34, p1stopL35, p1stopR35, p1stopU35, p1stopD35;
    logic p1stopL36, p1stopR36, p1stopU36, p1stopD36 , p1stopL37, p1stopR37, p1stopU37, p1stopD37 , p1stopL38, p1stopR38, p1stopU38, p1stopD38;
    logic p1stopL39, p1stopR39, p1stopU39, p1stopD39 , p1stopL40, p1stopR40, p1stopU40, p1stopD40 , p1stopL41, p1stopR41, p1stopU41, p1stopD41;
    logic p1stopL42, p1stopR42, p1stopU42, p1stopD42,p1stopL43, p1stopR43, p1stopU43, p1stopD43;
    assign p1stopL = p1stopL1 | p1stopL2 | p1stopL3 | p1stopL4 |p1stopL5| p1stopL6 | p1stopL7 |p1stopL8 | p1stopL9 | p1stopL10 |p1stopL11
                     |p1stopL12 |p1stopL13 |p1stopL14 |p1stopL15 |p1stopL16 |p1stopL17 |p1stopL18 |p1stopL19 |p1stopL20 
                     |p1stopL21 |p1stopL22 |p1stopL23 |p1stopL24 |p1stopL25 |p1stopL26 | p1stopL27 | p1stopL28 | p1stopL29 | p1stopL30
                     |p1stopL31 |p1stopL32 |p1stopL33  |p1stopL34 |p1stopL35 |p1stopL36 |p1stopL37|p1stopL38
                     |p1stopL39 |p1stopL40 |p1stopL41 |p1stopL42 |p1stopL43;
    assign p1stopR = p1stopR1 | p1stopR2 | p1stopR3 | p1stopR4 |p1stopR5| p1stopR6 | p1stopR7 |p1stopR8 | p1stopR9 | p1stopR10 |p1stopR11
                     |p1stopR12 |p1stopR13 |p1stopR14 |p1stopR15 |p1stopR16 |p1stopR17 |p1stopR18 |p1stopR19 |p1stopR20
                     |p1stopR21 |p1stopR22 |p1stopR23 |p1stopR24 |p1stopR25|p1stopR26 | p1stopR27 | p1stopR28 | p1stopR29 | p1stopR30
                     |p1stopR31 |p1stopR32 |p1stopR33 |p1stopR34 |p1stopR35 |p1stopR36 |p1stopR37|p1stopR38
                     |p1stopR39 |p1stopR40 |p1stopR41|p1stopR42 |p1stopR43;
    assign p1stopU = p1stopU1 | p1stopU2 | p1stopU3 | p1stopU4 |p1stopU5| p1stopU6 | p1stopU7 |p1stopU8 | p1stopU9 | p1stopU10 |p1stopU11
                    |p1stopU12 |p1stopU13 |p1stopU14 |p1stopU15 |p1stopU16 |p1stopU17 |p1stopU18 |p1stopU19 |p1stopU20
                     |p1stopU21 |p1stopU22 |p1stopU23 |p1stopU24 |p1stopU25|p1stopU26 | p1stopU27 | p1stopU28 | p1stopU29 | p1stopU30
                     |p1stopU31 |p1stopU32 |p1stopU33 |p1stopU34 |p1stopU35 |p1stopU36 |p1stopU37|p1stopU38
                     |p1stopU39 |p1stopU40 |p1stopU41|p1stopU42 |p1stopU43;
    assign p1stopD = p1stopD1 | p1stopD2 | p1stopD3 | p1stopD4 |p1stopD5| p1stopD6 | p1stopD7 |p1stopD8 | p1stopD9 | p1stopD10 |p1stopD11
                    |p1stopD12 |p1stopD13 |p1stopD14 |p1stopD15 |p1stopD16 |p1stopD17 |p1stopD18 |p1stopD19 |p1stopD20
                    |p1stopD21 |p1stopD22 |p1stopD23 |p1stopD24 | p1stopD25|p1stopD26 | p1stopD27 | p1stopD28 | p1stopD29 | p1stopD30
                     |p1stopD31 |p1stopD32 |p1stopD33 |p1stopD34 |p1stopD35 |p1stopD36 |p1stopD37|p1stopD38
                      |p1stopD39 |p1stopD40 |p1stopD41|p1stopD42 |p1stopD43;
    
   
    Collision collide(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(160), .brick1_Y(288),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick1active),
     
     .player1_left_stop(p1stopL1), .player1_right_stop(p1stopR1), 
     .player1_up_stop(p1stopU1), .player1_down_stop(p1stopD1)
          ); 
     
     Collision collide2(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(449), .brick1_Y(320),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick2active),
     
     .player1_left_stop(p1stopL6), .player1_right_stop(p1stopR6), 
     .player1_up_stop(p1stopU6), .player1_down_stop(p1stopD6)
          ); 
          
     Collision collide3(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(449), .brick1_Y(352),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick3active),
     
     .player1_left_stop(p1stopL7), .player1_right_stop(p1stopR7), 
     .player1_up_stop(p1stopU7), .player1_down_stop(p1stopD7)
          ); 
     
     Collision collide4(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(449), .brick1_Y(384),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick4active),
     
     .player1_left_stop(p1stopL8), .player1_right_stop(p1stopR8), 
     .player1_up_stop(p1stopU8), .player1_down_stop(p1stopD8)
          ); 
    Collision collide5(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(449), .brick1_Y(224),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick5active),
     
     .player1_left_stop(p1stopL10), .player1_right_stop(p1stopR10), 
     .player1_up_stop(p1stopU10), .player1_down_stop(p1stopD10)
          ); 
          
          Collision collide6(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(449), .brick1_Y(192),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick6active),
     
     .player1_left_stop(p1stopL11), .player1_right_stop(p1stopR11), 
     .player1_up_stop(p1stopU11), .player1_down_stop(p1stopD11)
          );
          
      Collision collide7(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(160), .brick1_Y(256),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick7active),
     
     .player1_left_stop(p1stopL12), .player1_right_stop(p1stopR12), 
     .player1_up_stop(p1stopU12), .player1_down_stop(p1stopD12)
          ); 
          
      Collision collide8(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(192), .brick1_Y(224),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick8active),
     
     .player1_left_stop(p1stopL14), .player1_right_stop(p1stopR14), 
     .player1_up_stop(p1stopU14), .player1_down_stop(p1stopD14)
          );  
     Collision collide9(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(224), .brick1_Y(224),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick9active),
     
     .player1_left_stop(p1stopL15), .player1_right_stop(p1stopR15), 
     .player1_up_stop(p1stopU15), .player1_down_stop(p1stopD15)
          );
     Collision collide10(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(256), .brick1_Y(224),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick10active),
     
     .player1_left_stop(p1stopL16), .player1_right_stop(p1stopR16), 
     .player1_up_stop(p1stopU16), .player1_down_stop(p1stopD16)
          );    
          
     Collision collide11(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(63), .brick1_Y(224),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick11active),
     
     .player1_left_stop(p1stopL17), .player1_right_stop(p1stopR17), 
     .player1_up_stop(p1stopU17), .player1_down_stop(p1stopD17)
          );        
     
      Collision collide12(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(95), .brick1_Y(224),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick12active),
     
     .player1_left_stop(p1stopL18), .player1_right_stop(p1stopR18), 
     .player1_up_stop(p1stopU18), .player1_down_stop(p1stopD18)
          );    
          
     Collision collide13(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(127), .brick1_Y(224),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick13active),
     
     .player1_left_stop(p1stopL19), .player1_right_stop(p1stopR19), 
     .player1_up_stop(p1stopU19), .player1_down_stop(p1stopD19)
          );     
          
     Collision collide14(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(288), .brick1_Y(32),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick14active),
     
     .player1_left_stop(p1stopL21), .player1_right_stop(p1stopR21), 
     .player1_up_stop(p1stopU21), .player1_down_stop(p1stopD21)
          );    
          
     Collision collide15(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(288), .brick1_Y(64),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick15active),
     
     .player1_left_stop(p1stopL22), .player1_right_stop(p1stopR22), 
     .player1_up_stop(p1stopU22), .player1_down_stop(p1stopD22)
          );       
          
      Collision collide16(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(288), .brick1_Y(128),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick16active),
     
     .player1_left_stop(p1stopL23), .player1_right_stop(p1stopR23), 
     .player1_up_stop(p1stopU23), .player1_down_stop(p1stopD23)
          );      
          
      Collision collide17(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(288), .brick1_Y(160),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick17active),
     
     .player1_left_stop(p1stopL24), .player1_right_stop(p1stopR24), 
     .player1_up_stop(p1stopU24), .player1_down_stop(p1stopD24)
          ); 
          
          
     Collision collide18(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(320), .brick1_Y(128),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick18active),
     
     .player1_left_stop(p1stopL26), .player1_right_stop(p1stopR26), 
     .player1_up_stop(p1stopU26), .player1_down_stop(p1stopD26)
          );                
    Collision collide19(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(352), .brick1_Y(128),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick19active),
     
     .player1_left_stop(p1stopL27), .player1_right_stop(p1stopR27), 
     .player1_up_stop(p1stopU27), .player1_down_stop(p1stopD27)
          );   
     
     Collision collide20(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(352), .brick1_Y(96),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick20active),
     
     .player1_left_stop(p1stopL28), .player1_right_stop(p1stopR28), 
     .player1_up_stop(p1stopU28), .player1_down_stop(p1stopD28)
          );       
     Collision collide21(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(352), .brick1_Y(160),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick21active),
     
     .player1_left_stop(p1stopL29), .player1_right_stop(p1stopR29), 
     .player1_up_stop(p1stopU29), .player1_down_stop(p1stopD29)
          ); 
          
     Collision collide22(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(384), .brick1_Y(160),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick22active),
     
     .player1_left_stop(p1stopL30), .player1_right_stop(p1stopR30), 
     .player1_up_stop(p1stopU30), .player1_down_stop(p1stopD30)
          ); 
          
     Collision collide23(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(160), .brick1_Y(96),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick23active),
     
     .player1_left_stop(p1stopL31), .player1_right_stop(p1stopR31), 
     .player1_up_stop(p1stopU31), .player1_down_stop(p1stopD31)
          ); 
          
      Collision collide24(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(192), .brick1_Y(96),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick24active),
     
     .player1_left_stop(p1stopL32), .player1_right_stop(p1stopR32), 
     .player1_up_stop(p1stopU32), .player1_down_stop(p1stopD32)
          ); 
          
     Collision collide25(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(192), .brick1_Y(32),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick25active),
     
     .player1_left_stop(p1stopL33), .player1_right_stop(p1stopR33), 
     .player1_up_stop(p1stopU33), .player1_down_stop(p1stopD33)
          );
          
      Collision collide26(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(512), .brick1_Y(256),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick26active),
     
     .player1_left_stop(p1stopL42), .player1_right_stop(p1stopR42), 
     .player1_up_stop(p1stopU42), .player1_down_stop(p1stopD42)
          );
          
      Collision collide27(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(544), .brick1_Y(256),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(brick27active),
     
     .player1_left_stop(p1stopL43), .player1_right_stop(p1stopR43), 
     .player1_up_stop(p1stopU43), .player1_down_stop(p1stopD43)
          ); 
                          
    Collision steel1collide(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(449), .brick1_Y(288),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     
     .player1_left_stop(p1stopL2), .player1_right_stop(p1stopR2), 
     .player1_up_stop(p1stopU2), .player1_down_stop(p1stopD2)
          ); 
          
      Collision steel2collide(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(320), .brick1_Y(288),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     
     .player1_left_stop(p1stopL3), .player1_right_stop(p1stopR3), 
     .player1_up_stop(p1stopU3), .player1_down_stop(p1stopD3)
          ); 
     Collision steel3collide(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(288), .brick1_Y(288),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     
     .player1_left_stop(p1stopL4), .player1_right_stop(p1stopR4), 
     .player1_up_stop(p1stopU4), .player1_down_stop(p1stopD4)
          ); 
     
     Collision steel4collide(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(352), .brick1_Y(288),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     
     .player1_left_stop(p1stopL5), .player1_right_stop(p1stopR5), 
     .player1_up_stop(p1stopU5), .player1_down_stop(p1stopD5)
          ); 
     
     Collision steel5collide(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(449), .brick1_Y(256),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     
     .player1_left_stop(p1stopL9), .player1_right_stop(p1stopR9), 
     .player1_up_stop(p1stopU9), .player1_down_stop(p1stopD9)
          ); 
     
     Collision steel6collide(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(160), .brick1_Y(224),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
    
     .player1_left_stop(p1stopL13), .player1_right_stop(p1stopR13), 
     .player1_up_stop(p1stopU13), .player1_down_stop(p1stopD13)
          ); 
     
     Collision steel7collide(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(160), .brick1_Y(192),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(p1stopL20), .player1_right_stop(p1stopR20), 
     .player1_up_stop(p1stopU20), .player1_down_stop(p1stopD20)
          ); 
          
     Collision steel8collide(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(288), .brick1_Y(96),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(p1stopL25), .player1_right_stop(p1stopR25), 
     .player1_up_stop(p1stopU25), .player1_down_stop(p1stopD25)
          ); 
          
     Collision steel9collide(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(192), .brick1_Y(64),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(p1stopL34), .player1_right_stop(p1stopR34), 
     .player1_up_stop(p1stopU34), .player1_down_stop(p1stopD34)
          ); 
     
     Collision steel10collide(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(160), .brick1_Y(384),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(p1stopL35), .player1_right_stop(p1stopR35), 
     .player1_up_stop(p1stopU35), .player1_down_stop(p1stopD35)
          ); 
     
     Collision steel11collide(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(192), .brick1_Y(384),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(p1stopL36), .player1_right_stop(p1stopR36), 
     .player1_up_stop(p1stopU36), .player1_down_stop(p1stopD36)
          ); 
     
     Collision steel12collide(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(224), .brick1_Y(384),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(p1stopL37), .player1_right_stop(p1stopR37), 
     .player1_up_stop(p1stopU37), .player1_down_stop(p1stopD37)
          );
     Collision steel13collide(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(192), .brick1_Y(352),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(p1stopL38), .player1_right_stop(p1stopR38), 
     .player1_up_stop(p1stopU38), .player1_down_stop(p1stopD38)
          );
          
     Collision steel14collide(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(480), .brick1_Y(128),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(p1stopL39), .player1_right_stop(p1stopR39), 
     .player1_up_stop(p1stopU39), .player1_down_stop(p1stopD39)
          );
          
     Collision steel15collide(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(512), .brick1_Y(128),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(p1stopL40), .player1_right_stop(p1stopR40), 
     .player1_up_stop(p1stopU40), .player1_down_stop(p1stopD40)
          );
          
     Collision steel16collide(
     .player1_X(p1xsig), .player1_Y(p1ysig),
     .brick1_X(544), .brick1_Y(128),
     .p1_direction_flag(p1_direction_flag),
     .frame_clk(vsync),
     .brickactive(1'b1),
     
     .player1_left_stop(p1stopL41), .player1_right_stop(p1stopR41), 
     .player1_up_stop(p1stopU41), .player1_down_stop(p1stopD41)
          );
          
     bullcollidebrick bullbrick1(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(160),
    .obj_Y(288),
    .frame_clk(vsync), .extbrickactive(enemy1brick1active),.extbrickactive2(enemy2brick1active),
    .extbrickactive3(enemy3brick1active),

    .bull_hit(bullhit1),
    .brickactive(p1brick1active)
     );
     
     bullcollidebrick bullbrick2(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(449),
    .obj_Y(320),
    .frame_clk(vsync), .extbrickactive(enemy1brick2active),.extbrickactive2(enemy2brick2active),
    .extbrickactive3(enemy3brick2active),
    .bull_hit(bullhit6),
    .brickactive(p1brick2active)
     );
     
     bullcollidebrick bullbrick3(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(449),
    .obj_Y(352),
    .frame_clk(vsync), .extbrickactive(enemy1brick3active),.extbrickactive2(enemy2brick3active),
    .extbrickactive3(enemy3brick3active),
    .bull_hit(bullhit7),
    .brickactive(p1brick3active)
     );
     
     bullcollidebrick bullbrick4(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(449),
    .obj_Y(384),
    .frame_clk(vsync), .extbrickactive(enemy1brick4active),.extbrickactive2(enemy2brick4active),
    .extbrickactive3(enemy3brick4active),
    .bull_hit(bullhit8),
    .brickactive(p1brick4active)
     );
     
     bullcollidebrick bullbrick5(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(449),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(enemy1brick5active),.extbrickactive2(enemy2brick5active),
    .extbrickactive3(enemy3brick5active),
    .bull_hit(bullhit10),
    .brickactive(p1brick5active)
     );
     
     bullcollidebrick bullbrick6(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(449),
    .obj_Y(192),
    .frame_clk(vsync), .extbrickactive(enemy1brick6active),.extbrickactive2(enemy2brick6active),
    .extbrickactive3(enemy3brick6active),
    .bull_hit(bullhit11),
    .brickactive(p1brick6active)
     );
     bullcollidebrick bullbrick7(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(160),
    .obj_Y(256),
    .frame_clk(vsync), .extbrickactive(enemy1brick7active),.extbrickactive2(enemy2brick7active),
    .extbrickactive3(enemy3brick7active),
    .bull_hit(bullhit12),
    .brickactive(p1brick7active)
     );
     bullcollidebrick bullbrick8(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(192),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(enemy1brick8active),.extbrickactive2(enemy2brick8active),
    .extbrickactive3(enemy3brick8active),
    .bull_hit(bullhit14),
    .brickactive(p1brick8active)
     );
     
     bullcollidebrick bullbrick9(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(224),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(enemy1brick9active),.extbrickactive2(enemy2brick9active),
    .extbrickactive3(enemy3brick9active),
    .bull_hit(bullhit15),
    .brickactive(p1brick9active)
     );
     
     bullcollidebrick bullbrick10(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(256),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(enemy1brick10active),
     .extbrickactive2(enemy2brick10active),
    .extbrickactive3(enemy3brick10active),
    .bull_hit(bullhit16),
    .brickactive(p1brick10active)
     );
     
     bullcollidebrick bullbrick11(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(63),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(enemy1brick11active),
    .extbrickactive2(enemy2brick11active),
     .extbrickactive3(enemy3brick11active),
    .bull_hit(bullhit17),
    .brickactive(p1brick11active)
     );
     
     bullcollidebrick bullbrick12(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(95),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(enemy1brick12active),
    .extbrickactive2(enemy2brick12active),
.extbrickactive3(enemy3brick12active),
    .bull_hit(bullhit18),
    .brickactive(p1brick12active)
     );
     
     bullcollidebrick bullbrick13(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(127),
    .obj_Y(224),
    .frame_clk(vsync), .extbrickactive(enemy1brick13active),
    .extbrickactive2(enemy2brick13active),
.extbrickactive3(enemy3brick13active),
    .bull_hit(bullhit19),
    .brickactive(p1brick13active)
     );
     
      bullcollidebrick bullbrick14(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(288),
    .obj_Y(32),
    .frame_clk(vsync), .extbrickactive(enemy1brick14active),
    .extbrickactive2(enemy2brick14active),
.extbrickactive3(enemy3brick14active),
    .bull_hit(bullhit21),
    .brickactive(p1brick14active)
     );
     
      bullcollidebrick bullbrick15(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(288),
    .obj_Y(64),
    .frame_clk(vsync), .extbrickactive(enemy1brick15active),
    .extbrickactive2(enemy2brick15active),
.extbrickactive3(enemy3brick15active),
    .bull_hit(bullhit22),
    .brickactive(p1brick15active)
     );
     
     bullcollidebrick bullbrick16(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(288),
    .obj_Y(128),
    .frame_clk(vsync), .extbrickactive(enemy1brick16active),
    .extbrickactive2(enemy2brick16active),
.extbrickactive3(enemy3brick16active),
    .bull_hit(bullhit23),
    .brickactive(p1brick16active)
     );
     
     bullcollidebrick bullbrick17(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(288),
    .obj_Y(160),
    .frame_clk(vsync), .extbrickactive(enemy1brick17active),
    .extbrickactive2(enemy2brick17active),
.extbrickactive3(enemy3brick17active),
    .bull_hit(bullhit24),
    .brickactive(p1brick17active)
     );
     
     bullcollidebrick bullbrick18(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(320),
    .obj_Y(128),
    .frame_clk(vsync), .extbrickactive(enemy1brick18active),
    .extbrickactive2(enemy2brick18active),
.extbrickactive3(enemy3brick18active),
    .bull_hit(bullhit26),
    .brickactive(p1brick18active)
     );
     
     bullcollidebrick bullbrick19(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(352),
    .obj_Y(128),
    .frame_clk(vsync), .extbrickactive(enemy1brick19active),
    .extbrickactive2(enemy2brick19active),
.extbrickactive3(enemy3brick19active),
    .bull_hit(bullhit27),
    .brickactive(p1brick19active)
     );
     
     bullcollidebrick bullbrick20(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(352),
    .obj_Y(96),
    .frame_clk(vsync), .extbrickactive(enemy1brick20active),
    .extbrickactive2(enemy2brick20active),
.extbrickactive3(enemy3brick20active),
    .bull_hit(bullhit28),
    .brickactive(p1brick20active)
     );
     
     bullcollidebrick bullbrick21(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(352),
    .obj_Y(160),
    .frame_clk(vsync), .extbrickactive(enemy1brick21active),
    .extbrickactive2(enemy2brick21active),
.extbrickactive3(enemy3brick21active),
    .bull_hit(bullhit29),
    .brickactive(p1brick21active)
     );
     
     bullcollidebrick bullbrick22(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(384),
    .obj_Y(160),
    .frame_clk(vsync), .extbrickactive(enemy1brick22active),
    .extbrickactive2(enemy2brick22active),
.extbrickactive3(enemy3brick22active),
    .bull_hit(bullhit30),
    .brickactive(p1brick22active)
     );
     
     bullcollidebrick bullbrick23(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(160),
    .obj_Y(96),
    .frame_clk(vsync), .extbrickactive(enemy1brick23active),
    .extbrickactive2(enemy2brick23active),
.extbrickactive3(enemy3brick23active),
    .bull_hit(bullhit31),
    .brickactive(p1brick23active)
     );
     
      bullcollidebrick bullbrick24(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(192),
    .obj_Y(96),
    .frame_clk(vsync), .extbrickactive(enemy1brick24active),
    .extbrickactive2(enemy2brick24active),
.extbrickactive3(enemy3brick24active),
    .bull_hit(bullhit32),
    .brickactive(p1brick24active)
     );
     
      bullcollidebrick bullbrick25(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(192),
    .obj_Y(32),
    .frame_clk(vsync), .extbrickactive(enemy1brick25active),
    .extbrickactive2(enemy2brick25active),
.extbrickactive3(enemy3brick25active),
    .bull_hit(bullhit33),
    .brickactive(p1brick25active)
     );
     
     bullcollidebrick bullbrick26(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(512),
    .obj_Y(256),
    .frame_clk(vsync), .extbrickactive(enemy1brick26active),
    .extbrickactive2(enemy2brick26active),
.extbrickactive3(enemy3brick26active),
    .bull_hit(bullhit42),
    .brickactive(p1brick26active)
     );
     
     bullcollidebrick bullbrick27(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(544),
    .obj_Y(256),
    .frame_clk(vsync), .extbrickactive(enemy1brick27active),
    .extbrickactive2(enemy2brick27active),
.extbrickactive3(enemy3brick27active),
    .bull_hit(bullhit43),
    .brickactive(p1brick27active)
     );







     
     
     bullcollidesteel bullsteel1(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(449),
    .obj_Y(288),
    .frame_clk(vsync),
    
    .bull_hit(bullhit2)
     );
      
      bullcollidesteel bullsteel2(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(320),
    .obj_Y(288),
    .frame_clk(vsync),
    
    .bull_hit(bullhit3)
     );
     
      bullcollidesteel bullsteel3(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(288),
    .obj_Y(288),
    .frame_clk(vsync),
    
    .bull_hit(bullhit4)
     );
     
      bullcollidesteel bullsteel4(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(352),
    .obj_Y(288),
    .frame_clk(vsync),
    
    .bull_hit(bullhit5)
     ); 
     bullcollidesteel bullsteel5(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(449),
    .obj_Y(256),
    .frame_clk(vsync),
    
    .bull_hit(bullhit9)
     ); 
     
     
    bullcollidesteel bullsteel6(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(160),
    .obj_Y(224),
    .frame_clk(vsync),
    
    .bull_hit(bullhit13)
     );   
     
     bullcollidesteel bullsteel7(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(160),
    .obj_Y(192),
    .frame_clk(vsync),
    
    .bull_hit(bullhit20)
     );   
     
     bullcollidesteel bullsteel8(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(288),
    .obj_Y(96),
    .frame_clk(vsync),
    
    .bull_hit(bullhit25)
     );   
     
      bullcollidesteel bullsteel9(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(192),
    .obj_Y(64),
    .frame_clk(vsync),
    
    .bull_hit(bullhit34)
     );   
     
     bullcollidesteel bullsteel10(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(160),
    .obj_Y(384),
    .frame_clk(vsync),
    
    .bull_hit(bullhit35)
     );
     
     bullcollidesteel bullsteel11(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(192),
    .obj_Y(384),
    .frame_clk(vsync),
    
    .bull_hit(bullhit36)
     );
     
     bullcollidesteel bullsteel12(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(224),
    .obj_Y(384),
    .frame_clk(vsync),
    
    .bull_hit(bullhit37)
     );
     
     bullcollidesteel bullsteel13(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(192),
    .obj_Y(352),
    .frame_clk(vsync),
    
    .bull_hit(bullhit38)
     );
     
      bullcollidesteel bullsteel14(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(480),
    .obj_Y(128),
    .frame_clk(vsync),
    
    .bull_hit(bullhit39)
     );
     
      bullcollidesteel bullsteel15(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(512),
    .obj_Y(128),
    .frame_clk(vsync),
    
    .bull_hit(bullhit40)
     );
     
     bullcollidesteel bullsteel16(
     .bull_X(bullxsig),
    .bull_Y(bullysig),
    .obj_X(544),
    .obj_Y(128),
    .frame_clk(vsync),
    
    .bull_hit(bullhit41)
     );
     
     
     
     
   
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     logic enemy1bullflagright;
    logic [3:0] enemy1bullright_red, enemy1bullright_green, enemy1bullright_blue;
    enemybullright_example enemy1bullright(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.bull_X(enemy1bullxsig), .bull_Y(enemy1bullysig), 
	.red(enemy1bullright_red), .green(enemy1bullright_green), .blue(enemy1bullright_blue),
	.bullflagright(enemy1bullflagright)
     );   
     
     logic enemy11bullflagdown;
    logic [3:0] enemy1bulldown_red, enemy1bulldown_green, enemy1bulldown_blue;
    enemybulldown_example enemy1bulldown(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.bull_X(enemy1bullxsig), .bull_Y(enemy1bullysig), 
	.red(enemy1bulldown_red), .green(enemy1bulldown_green), .blue(enemy1bulldown_blue),
	.bullflagdown(enemy1bullflagdown)
     );   
     
     logic enemy1bullflagleft;
    logic [3:0] enemy1bullleft_red, enemy1bullleft_green, enemy1bullleft_blue;
    enemybullleft_example enemy1bullleft(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.bull_X(enemy1bullxsig), .bull_Y(enemy1bullysig), 
	.red(enemy1bullleft_red), .green(enemy1bullleft_green), .blue(enemy1bullleft_blue),
	.bullflagleft(enemy1bullflagleft)
     );   
     
     logic enemy1bullflagup;
    logic [3:0] enemy1bullup_red, enemy1bullup_green, enemy1bullup_blue;
    enemybullup_example enemy1bullup(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.bull_X(enemy1bullxsig), .bull_Y(enemy1bullysig), 
	.red(enemy1bullup_red), .green(enemy1bullup_green), .blue(enemy1bullup_blue),
	.bullflagup(enemy1bullflagup)
     );   
     
    logic [3:0] start_screen_red, start_screen_green, start_screen_blue;
    start_screen_example start_screen(
     .vga_clk(clk_25MHz), .Reset(reset_ah),
	.DrawX(drawX), .DrawY(drawY),
	.keycode(keycode0_gpio[7:0]),
	.blank(vde),
	.red(start_screen_red), .green(start_screen_green), .blue(start_screen_blue),
	.start_screen_flag(start_screen_flag)
     );   
     
     logic [3:0] victory_screen_red, victory_screen_green, victory_screen_blue;
    victory_screen_example victory_screen(
     .vga_clk(clk_25MHz), .Reset(reset_ah),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.enemy1_counter(enemy1_counter),
	.enemy2_counter(enemy2_counter),
	.enemy3_counter(enemy3_counter),
	.red(victory_screen_red), .green(victory_screen_green), .blue(victory_screen_blue),
	.victory_screen_flag(victory_screen_flag)
     );   
     
     logic [3:0] gameover_screen_red, gameover_screen_green, gameover_screen_blue;
    gameover_screen_example gameover_screen(
     .vga_clk(clk_25MHz), .Reset(reset_ah),
	.DrawX(drawX), .DrawY(drawY),
	.keycode(keycode0_gpio[7:0]),
	.p1counter1(p1counter1), .p1counter2(p1counter2), .p1counter3(p1counter3),
	.blank(vde),
	.red(gameover_screen_red), .green(gameover_screen_green), .blue(gameover_screen_blue),
	.gameover_screen_flag(gameover_screen_flag)
     );   
     
     
     logic enemies_remaining_flag;
    logic [3:0] enemies_remaining_red, enemies_remaining_green, enemies_remaining_blue;
    Enemies_remaining_example enemies_remaining(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.red(enemies_remaining_red), .green(enemies_remaining_green), .blue(enemies_remaining_blue),
	.enemies_remaining_flag(enemies_remaining_flag)
     );   
     
      logic one_flag;
    logic [3:0] one_red, one_green, one_blue;
    one_example one(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.enemy1_counter(enemy1_counter), .enemy2_counter(enemy2_counter), .enemy3_counter(enemy3_counter),
	.red(one_red), .green(one_green), .blue(one_blue),
	.one_flag(one_flag)
     );   
     
      logic two_flag;
    logic [3:0] two_red, two_green, two_blue;
    two_example two(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.enemy1_counter(enemy1_counter), .enemy2_counter(enemy2_counter), .enemy3_counter(enemy3_counter),
	.red(two_red), .green(two_green), .blue(two_blue),
	.two_flag(two_flag)
     );   
     
      logic three_flag;
    logic [3:0] three_red, three_green, three_blue;
    three_example three(
     .vga_clk(clk_25MHz),
	.DrawX(drawX), .DrawY(drawY),
	.blank(vde),
	.enemy1_counter(enemy1_counter), .enemy2_counter(enemy2_counter), .enemy3_counter(enemy3_counter),
	.red(three_red), .green(three_green), .blue(three_blue),
	.three_flag(three_flag)
     );   
      
 // Begin coloring/drawing logic     
      
      
 always_ff @(posedge clk_25MHz) begin
	// && direction flag == 1
	//&& (explosion == 1'b1)
	
	 if(start_screen_flag == 1'b1 )begin
	   red <= start_screen_red;
		green <= start_screen_green;
		blue <= start_screen_blue;
	 end
	 
     else if(victory_screen_flag == 1'b1)begin
        red <= victory_screen_red;
		green <= victory_screen_green;
		blue <= victory_screen_blue;
     end
     
     else if(gameover_screen_flag == 1'b1)begin
        red <= gameover_screen_red;
		green <= gameover_screen_green;
		blue <= gameover_screen_blue;
     end
     else if(enemies_remaining_flag == 1'b1)begin
        red <= enemies_remaining_red;
		green <= enemies_remaining_green;
		blue <= enemies_remaining_blue;
     end
     
     else if(one_flag == 1'b1)begin
        red <= one_red;
		green <= one_green;
		blue <= one_blue;
     end
     
     else if(two_flag == 1'b1)begin
        red <= two_red;
		green <= two_green;
		blue <= two_blue;
     end
     
     else if(three_flag == 1'b1)begin
        red <= three_red;
		green <= three_green;
		blue <= three_blue;
     end

	 else if((explode_flag == 1'b1) && (explosion == 1'b1) )begin
	    red <= explode_red;
		green <= explode_green;
		blue <= explode_blue;
	end
	else if((enemy1explode_flag == 1'b1) && (enemy1explosion == 1'b1) )begin
	    red <= enemy1explode_red;
		green <= enemy1explode_green;
		blue <= enemy1explode_blue;
	end
	else if((enemy2explode_flag == 1'b1) && (enemy2explosion == 1'b1) )begin
	    red <= enemy2explode_red;
		green <= enemy2explode_green;
		blue <= enemy2explode_blue;
	end
	else if((enemy3explode_flag == 1'b1) && (enemy3explosion == 1'b1) )begin
	    red <= enemy3explode_red;
		green <= enemy3explode_green;
		blue <= enemy3explode_blue;
	end

	
	 else if((p1_up_flag == 1'b1) && (p1_direction_flag == 2'b00))begin
	    red <= p1_up_red;
		green <= p1_up_green;
		blue <= p1_up_blue;
	end
	 else if ((p1_down_flag == 1'b1) && (p1_direction_flag == 2'b11))begin
	    red <= p1_down_red;
		green <= p1_down_green;
		blue <= p1_down_blue;
		end
	else if ((p1_right_flag == 1'b1) && (p1_direction_flag == 2'b01))begin
	    red <= p1_right_red;
		green <= p1_right_green;
		blue <= p1_right_blue;
		end
    else if ((p1_left_flag == 1'b1) && (p1_direction_flag == 2'b10))begin
	    red <= p1_left_red;
		green <= p1_left_green;
		blue <= p1_left_blue;
		end
    else if (enemy_down_flag == 1'b1 && enemy1_direction_flag == 2'b11 && enemy1_counter != 2'b00) begin
        red <= enemy_down_red;
		green <= enemy_down_green;
		blue <= enemy_down_blue;
        end
    else if (enemy_left_flag == 1'b1 && enemy1_direction_flag == 2'b10 && enemy1_counter != 2'b00) begin
        red <= enemy_left_red;
		green <= enemy_left_green;
		blue <= enemy_left_blue;
        end
    else if (enemy_right_flag == 1'b1 && enemy1_direction_flag == 2'b01 && enemy1_counter != 2'b00) begin
        red <= enemy_right_red;
		green <= enemy_right_green;
		blue <= enemy_right_blue;
        end
    else if (enemy_up_flag == 1'b1 && enemy1_direction_flag == 2'b00 && enemy1_counter != 2'b00) begin
        red <= enemy_up_red;
		green <= enemy_up_green;
		blue <= enemy_up_blue;
        end
        
        
        
    else if (enemy2_down_flag == 1'b1 && enemy2_direction_flag == 2'b11 && enemy2_counter != 2'b00) begin
        red <= enemy2_down_red;
		green <= enemy2_down_green;
		blue <= enemy2_down_blue;
        end
    else if (enemy2_left_flag == 1'b1 && enemy2_direction_flag == 2'b10 && enemy2_counter != 2'b00) begin
        red <= enemy2_left_red;
		green <= enemy2_left_green;
		blue <= enemy2_left_blue;
        end
    else if (enemy2_right_flag == 1'b1 && enemy2_direction_flag == 2'b01 && enemy2_counter != 2'b00) begin
        red <= enemy2_right_red;
		green <= enemy2_right_green;
		blue <= enemy2_right_blue;
        end
    else if (enemy2_up_flag == 1'b1 && enemy2_direction_flag == 2'b00 && enemy2_counter != 2'b00) begin
        red <= enemy2_up_red;
		green <= enemy2_up_green;
		blue <= enemy2_up_blue;
        end
     
    else if ((enemy2_bull_direction_flag ==2'b01) &&( enemy2bullflagright == 1'b1) && (enemy2_bull_live == 1'b1)) begin
        red <= enemy2bullright_red;
		green <= enemy2bullright_green;
		blue <= enemy2bullright_blue;
        end
    else if ((enemy2_bull_direction_flag ==2'b10) &&( enemy2bullflagleft == 1'b1) && (enemy2_bull_live == 1'b1)) begin
        red <= enemy2bullleft_red;
		green <= enemy2bullleft_green;
		blue <= enemy2bullleft_blue;
        end
    else if ((enemy2_bull_direction_flag ==2'b00) &&( enemy2bullflagup == 1'b1) && (enemy2_bull_live == 1'b1)) begin
        red <= enemy2bullup_red;
		green <= enemy2bullup_green;
		blue <= enemy2bullup_blue;
        end
    else if ((enemy2_bull_direction_flag ==2'b11) &&( enemy2bullflagdown == 1'b1) && (enemy2_bull_live == 1'b1)) begin
        red <= enemy2bulldown_red;
		green <= enemy2bulldown_green;
		blue <= enemy2bulldown_blue;
        end

    else if (enemy3_down_flag == 1'b1 && enemy3_direction_flag == 2'b11 && enemy3_counter != 2'b00) begin
        red <= enemy3_down_red;
		green <= enemy3_down_green;
		blue <= enemy3_down_blue;
        end
    else if (enemy3_left_flag == 1'b1 && enemy3_direction_flag == 2'b10 && enemy3_counter != 2'b00) begin
        red <= enemy3_left_red;
		green <= enemy3_left_green;
		blue <= enemy3_left_blue;
        end
    else if (enemy3_right_flag == 1'b1 && enemy3_direction_flag == 2'b01 && enemy3_counter != 2'b00) begin
        red <= enemy3_right_red;
		green <= enemy3_right_green;
		blue <= enemy3_right_blue;
        end
    else if (enemy3_up_flag == 1'b1 && enemy3_direction_flag == 2'b00 && enemy3_counter != 2'b00) begin
        red <= enemy3_up_red;
		green <= enemy3_up_green;
		blue <= enemy3_up_blue;
        end
     
    else if ((enemy3_bull_direction_flag ==2'b01) &&( enemy3bullflagright == 1'b1) && (enemy3_bull_live == 1'b1)) begin
        red <= enemy3bullright_red;
		green <= enemy3bullright_green;
		blue <= enemy3bullright_blue;
        end
    else if ((enemy3_bull_direction_flag ==2'b10) &&( enemy3bullflagleft == 1'b1) && (enemy3_bull_live == 1'b1)) begin
        red <= enemy3bullleft_red;
		green <= enemy3bullleft_green;
		blue <= enemy3bullleft_blue;
        end
    else if ((enemy3_bull_direction_flag ==2'b00) &&( enemy3bullflagup == 1'b1) && (enemy3_bull_live == 1'b1)) begin
        red <= enemy3bullup_red;
		green <= enemy3bullup_green;
		blue <= enemy3bullup_blue;
        end
    else if ((enemy3_bull_direction_flag ==2'b11) &&( enemy3bullflagdown == 1'b1) && (enemy3_bull_live == 1'b1)) begin
        red <= enemy3bulldown_red;
		green <= enemy3bulldown_green;
		blue <= enemy3bulldown_blue;
        end



    else if (brick1flag == 1'b1 && brick1active ==1'b1) begin
        red <= brick1_red;
		green <= brick1_green;
		blue <= brick1_blue;
        end
    else if (brick2flag == 1'b1 && brick2active ==1'b1) begin
        red <= brick2_red;
		green <= brick2_green;
		blue <= brick2_blue;
        end
    else if (brick3flag == 1'b1 && brick3active ==1'b1) begin
        red <= brick3_red;
		green <= brick3_green;
		blue <= brick3_blue;
        end
    else if (brick4flag == 1'b1 && brick4active ==1'b1) begin
        red <= brick4_red;
		green <= brick4_green;
		blue <= brick4_blue;
        end
    else if (brick5flag == 1'b1 && brick5active ==1'b1) begin
        red <= brick5_red;
		green <= brick5_green;
		blue <= brick5_blue;
        end
    else if (brick6flag == 1'b1 && brick6active ==1'b1) begin
        red <= brick6_red;
		green <= brick6_green;
		blue <= brick6_blue;
        end
    else if (brick7flag == 1'b1 && brick7active ==1'b1) begin
        red <= brick7_red;
		green <= brick7_green;
		blue <= brick7_blue;
        end
    else if (brick8flag == 1'b1 && brick8active ==1'b1) begin
        red <= brick8_red;
		green <= brick8_green;
		blue <= brick8_blue;
        end
    else if (brick9flag == 1'b1 && brick9active ==1'b1) begin
        red <= brick9_red;
		green <= brick9_green;
		blue <= brick9_blue;
        end
    else if (brick10flag == 1'b1 && brick10active ==1'b1) begin
        red <= brick10_red;
		green <= brick10_green;
		blue <= brick10_blue;
        end
    else if (brick11flag == 1'b1 && brick11active ==1'b1) begin
        red <= brick11_red;
		green <= brick11_green;
		blue <= brick11_blue;
        end  
    else if (brick12flag == 1'b1 && brick12active ==1'b1) begin
        red <= brick12_red;
		green <= brick12_green;
		blue <= brick12_blue;
        end   
    else if (brick13flag == 1'b1 && brick13active ==1'b1) begin
        red <= brick13_red;
		green <= brick13_green;
		blue <= brick13_blue;
        end     
    else if (brick14flag == 1'b1 && brick14active ==1'b1) begin
        red <= brick14_red;
		green <= brick14_green;
		blue <= brick14_blue;
        end   
    else if (brick15flag == 1'b1 && brick15active ==1'b1) begin
        red <= brick15_red;
		green <= brick15_green;
		blue <= brick15_blue;
        end    
    else if (brick16flag == 1'b1 && brick16active ==1'b1) begin
        red <= brick16_red;
		green <= brick16_green;
		blue <= brick16_blue;
        end  
    else if (brick17flag == 1'b1 && brick17active ==1'b1) begin
        red <= brick17_red;
		green <= brick17_green;
		blue <= brick17_blue;
        end 
   else if (brick18flag == 1'b1 && brick18active ==1'b1) begin
        red <= brick18_red;
		green <= brick18_green;
		blue <= brick18_blue;
        end             
    else if (brick19flag == 1'b1 && brick19active ==1'b1) begin
        red <= brick19_red;
		green <= brick19_green;
		blue <= brick19_blue;
        end 
    else if (brick20flag == 1'b1 && brick20active ==1'b1) begin
        red <= brick20_red;
		green <= brick20_green;
		blue <= brick20_blue;
        end
    else if (brick21flag == 1'b1 && brick21active ==1'b1) begin
        red <= brick21_red;
		green <= brick21_green;
		blue <= brick21_blue;
        end
    else if (brick22flag == 1'b1 && brick22active ==1'b1) begin
        red <= brick22_red;
		green <= brick22_green;
		blue <= brick22_blue;
        end
    else if (brick23flag == 1'b1 && brick23active ==1'b1) begin
        red <= brick23_red;
		green <= brick23_green;
		blue <= brick23_blue;
        end
    else if (brick24flag == 1'b1 && brick24active ==1'b1) begin
        red <= brick24_red;
		green <= brick24_green;
		blue <= brick24_blue;
        end
    else if (brick25flag == 1'b1 && brick25active ==1'b1) begin
        red <= brick25_red;
		green <= brick25_green;
		blue <= brick25_blue;
        end
    else if (brick26flag == 1'b1 && brick26active ==1'b1) begin
        red <= brick26_red;
		green <= brick26_green;
		blue <= brick26_blue;
        end
        
    else if (brick27flag == 1'b1 && brick27active ==1'b1) begin
        red <= brick27_red;
		green <= brick27_green;
		blue <= brick27_blue;
        end
        
   else if (steel1flag == 1'b1) begin
        red <= steel1_red;
		green <= steel1_green;
		blue <= steel1_blue;
        end
    else if (steel2flag == 1'b1) begin
        red <= steel2_red;
		green <= steel2_green;
		blue <= steel2_blue;
        end 
    else if (steel3flag == 1'b1) begin
        red <= steel3_red;
		green <= steel3_green;
		blue <= steel3_blue;
        end
    else if (steel4flag == 1'b1) begin
        red <= steel4_red;
		green <= steel4_green;
		blue <= steel4_blue;
        end
    else if (steel5flag == 1'b1) begin
        red <= steel5_red;
		green <= steel5_green;
		blue <= steel5_blue;
        end
   else if (steel6flag == 1'b1) begin
        red <= steel6_red;
		green <= steel6_green;
		blue <= steel6_blue;
        end
   else if (steel7flag == 1'b1) begin
        red <= steel7_red;
		green <= steel7_green;
		blue <= steel7_blue;
        end
    else if (steel8flag == 1'b1) begin
        red <= steel8_red;
		green <= steel8_green;
		blue <= steel8_blue;
        end
    else if (steel9flag == 1'b1) begin
        red <= steel9_red;
		green <= steel9_green;
		blue <= steel9_blue;
        end
    else if (steel10flag == 1'b1) begin
        red <= steel10_red;
		green <= steel10_green;
		blue <= steel10_blue;
        end
    else if (steel11flag == 1'b1) begin
        red <= steel11_red;
		green <= steel11_green;
		blue <= steel11_blue;
        end
    else if (steel12flag == 1'b1) begin
        red <= steel12_red;
		green <= steel12_green;
		blue <= steel12_blue;
        end
     else if (steel13flag == 1'b1) begin
        red <= steel13_red;
		green <= steel13_green;
		blue <= steel13_blue;
        end
    else if (steel14flag == 1'b1) begin
        red <= steel14_red;
		green <= steel14_green;
		blue <= steel14_blue;
        end
    else if (steel15flag == 1'b1) begin
        red <= steel15_red;
		green <= steel15_green;
		blue <= steel15_blue;
        end
    else if (steel16flag == 1'b1) begin
        red <= steel16_red;
		green <= steel16_green;
		blue <= steel16_blue;
        end
    
    else if ((bull_direction_flag ==2'b01) &&( bullflagright == 1'b1) && (bull_live == 1'b1)) begin
        red <= p1bullright_red;
		green <= p1bullright_green;
		blue <= p1bullright_blue;
        end
    else if ((bull_direction_flag ==2'b10) &&( bullflagleft == 1'b1) && (bull_live == 1'b1)) begin
        red <= p1bullleft_red;
		green <= p1bullleft_green;
		blue <= p1bullleft_blue;
        end
    else if ((bull_direction_flag ==2'b00) &&( bullflagup == 1'b1) && (bull_live == 1'b1)) begin
        red <= p1bullup_red;
		green <= p1bullup_green;
		blue <= p1bullup_blue;
        end
    else if ((bull_direction_flag ==2'b11) &&( bullflagdown == 1'b1) && (bull_live == 1'b1)) begin
        red <= p1bulldown_red;
		green <= p1bulldown_green;
		blue <= p1bulldown_blue;
        end
        
        
        
    else if ((enemy1_bull_direction_flag ==2'b01) &&( enemy1bullflagright == 1'b1) && (enemy1_bull_live == 1'b1)) begin
        red <= enemy1bullright_red;
		green <= enemy1bullright_green;
		blue <= enemy1bullright_blue;
        end
    else if ((enemy1_bull_direction_flag ==2'b10) &&( enemy1bullflagleft == 1'b1) && (enemy1_bull_live == 1'b1)) begin
        red <= enemy1bullleft_red;
		green <= enemy1bullleft_green;
		blue <= enemy1bullleft_blue;
        end
    else if ((enemy1_bull_direction_flag ==2'b00) &&( enemy1bullflagup == 1'b1) && (enemy1_bull_live == 1'b1)) begin
        red <= enemy1bullup_red;
		green <= enemy1bullup_green;
		blue <= enemy1bullup_blue;
        end
    else if ((enemy1_bull_direction_flag ==2'b11) &&( enemy1bullflagdown == 1'b1) && (enemy1_bull_live == 1'b1)) begin
        red <= enemy1bulldown_red;
		green <= enemy1bulldown_green;
		blue <= enemy1bulldown_blue;
        end
        
        
        
    else if ((drawX<=63 && drawX>=0) || (drawY<=31 && drawY>=0) || (drawX<=640 && drawX>=576) || (drawY>=416 && drawY<=479)) begin
        red <= 4'h7;
		green <= 4'h7;
		blue <= 4'h7;
		end
	else
	begin
	    red <= 4'h0;
		green <= 4'h0;
		blue <= 4'h0;
    end
    
    
end
 
endmodule


