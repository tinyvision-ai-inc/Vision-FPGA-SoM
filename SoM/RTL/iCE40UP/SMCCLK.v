`timescale 1 ns / 1 ps
module SMCCLK ( CLK );
output CLK ;

reg CLK ;

always
 begin
	 CLK = 0;
	 forever #25 CLK = ~CLK;
 end
 
endmodule
