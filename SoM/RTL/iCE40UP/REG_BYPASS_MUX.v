`timescale 1ns / 1ps
module REG_BYPASS_MUX(D, Q, ENA, CLK, RST, SELM);

parameter DATA_WIDTH = 16 ;

input  [DATA_WIDTH - 1 : 0] D ;
output [DATA_WIDTH - 1 : 0] Q ;
input  ENA ;
input  CLK ;
input  RST ;
input  SELM ;

reg    [DATA_WIDTH - 1 : 0] REG_INTERNAL ;

assign Q = ( (SELM) ? REG_INTERNAL : D ) ;

always @ (posedge CLK or posedge RST)
begin
	if (RST)
		REG_INTERNAL <= #1 0 ;
	else if (ENA)
	    REG_INTERNAL <= #1 D ;
	else 
	    REG_INTERNAL <= #1 REG_INTERNAL ;
end

endmodule
