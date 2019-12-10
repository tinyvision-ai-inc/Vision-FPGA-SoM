`timescale 1ps/1ps
module LFOSC ( CLKLFEN, CLKLFPU,  CLKLF, TRIM);	 
input CLKLFEN, CLKLFPU;
output CLKLF;	
input [9:0] TRIM;
parameter FABRIC_TRIME = "DISABLE";

LFOSC_CORE OSCInst1 ( 
.CLKLF_EN(CLKLFEN), 
.CLKLF_PU(CLKLFPU),
.CLKLF(CLKLF) 
) /* synthesis ROUTE_THROUGH_FABRIC= 0 */;


endmodule 
