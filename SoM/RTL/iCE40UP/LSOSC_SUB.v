`timescale 1 ns / 1 ps
module LSOSC_SUB (input ENACLKK, output CLKK);

LSOSC_CORE_SUB inst(
	.ENACLKK(ENACLKK),
	.CLKK(CLKK));  


endmodule
