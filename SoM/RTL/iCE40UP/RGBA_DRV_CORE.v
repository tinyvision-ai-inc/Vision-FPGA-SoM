`timescale        1ns/1ps
module RGBA_DRV_CORE 
(
	RGBLEDEN,
	CURREN,  
	RGB0PWM,
	RGB1PWM,
	RGB2PWM,
	RGB0,
	RGB1,
	RGB2
);
	input RGBLEDEN;
	input CURREN;
	input RGB0PWM;
	input RGB1PWM;
	input RGB2PWM;
	output RGB0;
	output RGB1;
	output RGB2;

parameter RGB0_CURRENT = 6'b000000;
parameter RGB1_CURRENT = 6'b000000;
parameter RGB2_CURRENT = 6'b000000;
parameter CURRENT_MODE = 0;
wire [2:0] rgb_pwm ={RGB2PWM,RGB1PWM,RGB0PWM};
reg [47:0] RGB_CUR0, RGB_CUR1, RGB_CUR2,CUR_MOD;
reg [5:0] rgb0_current,	 rgb1_current,rgb2_current;
reg cur_mode;
wire i200u_on = CURREN & RGBLEDEN ; 
integer i,j,k,l;
supply0 GND;
supply1 VCC;

`include "convertDeviceString.v"
initial 
	begin
		RGB_CUR0= RGB0_CURRENT;	
		RGB_CUR1= RGB1_CURRENT;
		RGB_CUR2= RGB2_CURRENT;	 
		//i=$sscanf(RGB_CUR0, "%b",rgb0_current);
		//j=$sscanf(RGB_CUR1, "%b",rgb1_current);
		//k=$sscanf(RGB_CUR2, "%b",rgb2_current);
		//l=$sscanf(CUR_MOD, "%b",cur_mode);

		rgb0_current = RGB0_CURRENT;
		rgb1_current = RGB1_CURRENT;
		rgb2_current = RGB2_CURRENT;

	end

//** Instantiate the  module **
rgb24max3     INST     (
                                       .cbit_rgb_en (1'b1),
                                       .cbit_rgb_half_cur (cur_mode),
                                       .i200uref (i200u_on),
                                       .poc (1'b0),
                                       .rgbled_en (RGBLEDEN),
                                       .rgb0 (RGB0),
                                       .rgb1 (RGB1),
                                       .rgb2 (RGB2),
                                       .vccio (VCC),
									   .rgb_pwm(rgb_pwm),
									   .cbit_rgb2(rgb2_current),
									   .cbit_rgb1(rgb1_current),
									   .cbit_rgb0(rgb0_current));


endmodule
