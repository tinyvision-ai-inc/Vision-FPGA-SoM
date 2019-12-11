`timescale 1ns / 1ps
module IR400_DRV_CORE   (
	CURREN,
	IRLEDEN,
	IRPWM,
	IRLED
);

	input CURREN,IRLEDEN,IRPWM;
	output 	IRLED; 

parameter IR400_CURRENT = "0b00000000";
parameter CURRENT_MODE = "0b0";

reg [63:0] IR_CUR;
reg [7:0] CUR_MOD;
reg [7:0] ir_current;
reg cur_mode;
integer i,j;
supply0 GND;
supply1 VCC;
initial 
	begin
		IR_CUR= IR400_CURRENT;	
		CUR_MOD = CURRENT_MODE;
		i=$sscanf(IR_CUR, "%b",ir_current);
		j=$sscanf(CUR_MOD, "%b",cur_mode);
	end


bolt_ir_barcode inst (
		.barcode_en(), 
        .barcode_pwm(),
		.cbit_barcode_en(),
		.cbit_ir500(),
		.cbit_ir_en(1'b1),
		.cbit_ir_half_cur(cur_mode),
		.cbit_rgb_en(),
		.drivergnd(GND),
		.icc40u(~CURREN),
		.ir_pwm(IRPWM),
		.irled_en(IRLEDEN),
		.poc(1'b0),
		.rgbled_en(),
		.vccio(VCC),
		.barcode_pad(),
		.ir_pad(IRLED),
		.i200uref(),
        .cbit_barcode(),
        .cbit_ir(ir_current)
);  

endmodule
