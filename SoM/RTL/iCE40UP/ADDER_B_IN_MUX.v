`timescale 1ns / 1ps
module ADDER_B_IN_MUX (
    MULT_INPUT ,
	MULT_8x8 ,
	MULT_16x16 ,
	SIGNEXTIN ,
	SELM ,
	ADDER_B_MUX
	);

    input [15:0] MULT_INPUT ;
	input [15:0] MULT_8x8 ;
	input [15:0] MULT_16x16 ;
	input SIGNEXTIN ;
	input [1:0] SELM ;
	output [15:0] ADDER_B_MUX;
	
//	wire [15:0] DIRECT_8x8_SELECT ;
//	assign DIRECT_8x8_SELECT = ( (SELM[0]) ? MULT_8x8   : MULT_INPUT) ;
//	assign ADDER_B_MUX       = ( (SELM[1:0]=2'b10) ? MULT_16x16 : DIRECT_8x8_SELECT) ;

	reg [15:0] ADDER_B_MUX;
	
always @(SELM or MULT_INPUT or MULT_8x8 or MULT_16x16 or SIGNEXTIN)
      case (SELM[1:0])
         2'b00: ADDER_B_MUX = MULT_INPUT ; 
         2'b01: ADDER_B_MUX = MULT_8x8 ; 
         2'b10: ADDER_B_MUX = MULT_16x16; 
         2'b11: ADDER_B_MUX = {16{SIGNEXTIN}}; 
      endcase	 
	
endmodule
