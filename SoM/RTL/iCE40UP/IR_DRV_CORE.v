`timescale 1 ns / 1 ps
module IR_DRV_CORE (IRLED_EN,IR_PWM,IR_PU,IRLED);

input IRLED_EN,IR_PWM,IR_PU ;
output IRLED;	  

parameter IR_CURRENT = "0b0000000000";  
reg [9:0] ir_current;
reg [79:0]IR_CUR;
supply0 GND;
supply1 VCC;
integer i;
initial 
	begin 
	IR_CUR=IR_CURRENT;
	i=$sscanf(IR_CUR, "%b",ir_current);
	end
 
	thunder_ledio thunder_ledio(
		.IR_PAD(IRLED),
		.RGB0_PAD(),
		.RGB1_PAD(),
		.RGB2_PAD(),
		.cbit_ir(ir_current),
		.cbit_ir_en(1'b1),
		.cbit_rgb0(),
		.cbit_rgb1(),
		.cbit_rgb2(),
		.cbit_rgb_en(),
		.icc40u(IR_PU),
		.ir_pwm(IR_PWM),
		.irled_en(IRLED_EN),
		.poc(1'b0),
		.rgb0_pwm(),
		.rgb1_pwm(),
		.rgb2_pwm(),
		.rgbled_en(),
		.vccio(VCC),
		.vss_rgb(GND),
		.vssio_ir(GND));  
endmodule
