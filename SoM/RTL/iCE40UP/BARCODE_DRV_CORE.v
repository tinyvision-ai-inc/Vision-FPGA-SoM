`timescale 1ns / 1ps
module BARCODE_DRV_CORE   (
	CURREN,
	BARCODEEN,
	BARCODEPWM,
	BARCODE
);

	input BARCODEEN,	CURREN, 	BARCODEPWM; 
	output 	BARCODE; 

parameter BARCODE_CURRENT = "0b0000";
parameter CURRENT_MODE = "0b0";

reg [31:0] BARC_CUR;
reg [7:0] CUR_MOD;
reg [3:0] barc_current;
reg cur_mode;
integer i,j;
supply0 GND;
supply1 VCC;
initial 
	begin
		CUR_MOD = CURRENT_MODE;
		BARC_CUR= BARCODE_CURRENT;	
		i=$sscanf(BARC_CUR, "%b",barc_current);
		j=$sscanf(CUR_MOD, "%b",cur_mode);
	end


bolt_ir_barcode inst (
		.barcode_en(BARCODEEN), 
        .barcode_pwm(BARCODEPWM),
		.cbit_barcode_en(1'b1), 
		.cbit_ir500(1'b1),
		.cbit_ir_en(),
		.cbit_ir_half_cur(cur_mode),
		.cbit_rgb_en(), 
		.drivergnd(GND),
		.icc40u(~CURREN),
		.ir_pwm(),
		.irled_en(),
		.poc(1'b0),  
		.rgbled_en(),
		.vccio(VCC),
		.barcode_pad(BARCODE),
		.ir_pad(),
		.i200uref(),  
        .cbit_barcode(barc_current),
        .cbit_ir()
);  
endmodule
