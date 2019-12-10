`timescale 1ns / 1ps
module RGB_DRV_CORE (RGBLED_EN,RGB0_PWM, RGB1_PWM ,RGB2_PWM, RGB_PU, RGB0, RGB1, RGB2 );

input  RGBLED_EN,RGB0_PWM, RGB1_PWM ,RGB2_PWM, RGB_PU;
output   RGB0, RGB1, RGB2; 

parameter RGB0_CURRENT = "0b000000";
parameter RGB1_CURRENT = "0b000000";
parameter RGB2_CURRENT = "0b000000";	

reg [47:0] RGB_CUR0, RGB_CUR1, RGB_CUR2;
reg [5:0] rgb0_current,	 rgb1_current,rgb2_current;
integer i,j,k;
supply0 GND;
supply1 VCC;
initial 
	begin
		RGB_CUR0= RGB0_CURRENT;	
		RGB_CUR1= RGB1_CURRENT;
		RGB_CUR2= RGB2_CURRENT;	 
		i=$sscanf(RGB_CUR0, "%b",rgb0_current);
		j=$sscanf(RGB_CUR1, "%b",rgb1_current);
		k=$sscanf(RGB_CUR2, "%b",rgb2_current);
	end


thunder_ledio thunder_ledio (
		.IR_PAD(),
		.RGB0_PAD(RGB0),
		.RGB1_PAD(RGB1),
		.RGB2_PAD(RGB2),
		.cbit_ir(),
		.cbit_ir_en(),
		.cbit_rgb0(rgb0_current),
		.cbit_rgb1(rgb1_current),
		.cbit_rgb2(rgb2_current),
		.cbit_rgb_en(1'b1),	
		.icc40u(RGB_PU),	 
		.ir_pwm(),
		.irled_en(),
		.poc(1'b0),
		.rgb0_pwm(RGB0_PWM),
		.rgb1_pwm(RGB1_PWM),
		.rgb2_pwm(RGB2_PWM),
		.rgbled_en(RGBLED_EN),
		.vccio(VCC),
		.vss_rgb(GND),
		.vssio_ir(GND));  
endmodule
