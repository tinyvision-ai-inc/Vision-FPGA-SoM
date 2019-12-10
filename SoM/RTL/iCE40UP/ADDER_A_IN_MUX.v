`timescale 1ns / 1ps
module ADDER_A_IN_MUX (
    ACCUMULATOR_REG ,
	DIRECT_INPUT ,
	SELM ,
	ADDER_A_MUX
   );
	
    input [15:0] ACCUMULATOR_REG ;
	input [15:0] DIRECT_INPUT ;
	input SELM ;
	output [15:0] ADDER_A_MUX;

	assign ADDER_A_MUX = ( (SELM) ? DIRECT_INPUT : ACCUMULATOR_REG ) ;

endmodule
