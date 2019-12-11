`timescale 1ns / 1ps
module ICE_IR500_DRV_CORE 
(
	CURREN,
	IRLEDEN,
	IRPWM,
	IRLEDEN2,
	IRPWM2, 
	IRLED1,
	IRLED2
) ;

	input IRLEDEN;
	input IRPWM;
	input CURREN;
	input IRLEDEN2; 
	input IRPWM2; 
	output IRLED1;
	output IRLED2;

parameter IR500_CURRENT = "0b000000000000";
parameter CURRENT_MODE = "0b0";

reg [95:0] IR_CUR;
reg [7:0] CUR_MOD;
reg [11:0] ir_current;
reg cur_mode;
integer i,j;
supply0 GND;
supply1 VCC;
initial 
	begin
		IR_CUR= IR500_CURRENT;	
		CUR_MOD = CURRENT_MODE;
		i=$sscanf(IR_CUR, "%b",ir_current);
		j=$sscanf(CUR_MOD, "%b",cur_mode);
	end


bolt_ir_barcode inst (
		.barcode_en(IRLEDEN2), 
        .barcode_pwm(IRPWM2),
		.cbit_barcode_en(1'b1), 
		.cbit_ir500(1'b1),
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
		.barcode_pad(IRLED2),
		.ir_pad(IRLED1),
		.i200uref(),
        .cbit_barcode(ir_current[3:0]),
        .cbit_ir(ir_current[11:4])
);  

endmodule
