`timescale 1ps/1ps
module HFOSC  ( CLKHFPU,CLKHFEN, CLKHF, TRIM);	
	input CLKHFPU,CLKHFEN;
	output  CLKHF;	
	input [9:0] TRIM;
	parameter CLKHF_DIV = "0b00";
	parameter FABRIC_TRIME = "DISABLE";

HFOSC_CORE OSCInst0( 
.CLKHF_EN(CLKHFEN), 
.CLKHF_PU(CLKHFPU),
.CLKHF(CLKHF) 
) /* synthesis ROUTE_THROUGH_FABRIC= 0 */;
defparam OSCInst0.CLKHF_DIV = CLKHF_DIV;


endmodule 
