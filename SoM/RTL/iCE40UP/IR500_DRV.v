`timescale 1ps/1ps
module IR500_DRV   (
	IRLEDEN,
	IRPWM,
	CURREN,
	IRLED1,
	IRLED2
);

parameter IR500_CURRENT = "0b000000000000";
parameter CURRENT_MODE = "0b0";

	input IRLEDEN;
	input IRPWM;
	input CURREN;
	output IRLED1;
	output IRLED2;
endmodule
