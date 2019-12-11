`timescale 1ns / 1ps
module CARRY_IN_MUX (
	CICAS,
	CI,
	CARRYMUX_SEL,
	ADDER_CI
	);
	
	input CICAS;
	input CI;
	input [1:0] CARRYMUX_SEL;
	output ADDER_CI;
	reg ADDER_CI;
	
always @(CARRYMUX_SEL or CICAS or CI)
      case (CARRYMUX_SEL[1:0])
         2'b00: ADDER_CI = 0 ; 
         2'b01: ADDER_CI = 1 ; 
         2'b10: ADDER_CI = CICAS; 
         2'b11: ADDER_CI = CI; 
      endcase	 

endmodule
