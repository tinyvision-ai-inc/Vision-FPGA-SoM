`timescale 1ps / 1ps
module SPRAM256KA(ADDRESS, DATAIN, MASKWREN,WREN,CHIPSELECT,CLOCK,STANDBY,SLEEP,POWEROFF,DATAOUT, RDMARGINEN, RDMARGIN, TEST);
input [13:0] ADDRESS;
input [15:0] DATAIN;
input [3:0] MASKWREN;
input WREN,CHIPSELECT,CLOCK,STANDBY,SLEEP,POWEROFF;
output [15:0] DATAOUT;


//HW Visible ports only; doesn't do anything currently for simulation 
input RDMARGINEN; 
input [3:0] RDMARGIN; 
input TEST;

wire [15:0]wem = {MASKWREN[3],MASKWREN[3],MASKWREN[3],MASKWREN[3],
					MASKWREN[2],MASKWREN[2],MASKWREN[2],MASKWREN[2],
					MASKWREN[1],MASKWREN[1],MASKWREN[1],MASKWREN[1],
					MASKWREN[0],MASKWREN[0],MASKWREN[0],MASKWREN[0]};

	
wire not_poweroff; 


assign (weak0, weak1) STANDBY 	=1'b0 ;
assign (weak0, weak1) SLEEP	=1'b0 ;
assign (weak0, weak1) POWEROFF 	=1'b1 ;			// Note: 1'b0-> POWEROFF, 1'b1 -> POWERON at wrapper level. 

assign not_poweroff = ~POWEROFF; 

sadslspk4s1p16384x16m16b4w1c0p1d0t0  spram256k_core_inst (
		.Q(DATAOUT),
		.ADR(ADDRESS),
		.D(DATAIN),
		.WEM(wem),
		.WE(WREN),
		.ME(CHIPSELECT),
		.CLK(CLOCK),
		.TEST1(),
		.RME(),
		.RM(),
		.LS(STANDBY),
		.DS(SLEEP),
		.SD(not_poweroff));	


endmodule
