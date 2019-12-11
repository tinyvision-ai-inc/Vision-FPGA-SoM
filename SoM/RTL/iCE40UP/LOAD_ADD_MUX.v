`timescale 1ns / 1ps
module LOAD_ADD_MUX (
    ADDER ,
	LOAD_DATA ,
	LOAD,
	OUT
   );

	input [15:0] ADDER ;
	input [15:0] LOAD_DATA ;
	input LOAD;
	output [15:0] OUT;
   
	assign OUT = ( (LOAD) ? LOAD_DATA : ADDER ) ;
	
endmodule
