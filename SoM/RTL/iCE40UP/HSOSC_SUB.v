`timescale 1 ns / 1 ps
module HSOSC_SUB (input ENACLKM, output CLKM);  

HSOSC_CORE_SUB inst(
	.ENACLKM(ENACLKM),
	.CLKM(CLKM));


endmodule
