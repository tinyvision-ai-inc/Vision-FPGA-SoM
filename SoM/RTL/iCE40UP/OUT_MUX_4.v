`timescale 1ns / 1ps
module OUT_MUX_4 (
    ADDER_COMBINATORIAL ,
	ACCUM_REGISTER ,
	MULT_8x8 ,
	MULT_16x16 ,
	SELM ,
	OUT  
	 ) ;

    input [15:0] ADDER_COMBINATORIAL ;
	input [15:0] ACCUM_REGISTER ;
	input [15:0] MULT_8x8 ;
	input [15:0] MULT_16x16 ;
	input [1:0] SELM ;
	output [15:0] OUT;  
	reg [15:0] OUT;  
	 
 
always @(SELM or ADDER_COMBINATORIAL or ACCUM_REGISTER or MULT_8x8 or MULT_16x16)
      case (SELM[1:0])
         2'b00: OUT = ADDER_COMBINATORIAL ; // Combinatorial output
         2'b01: OUT = ACCUM_REGISTER ; // Accumulator register output
         2'b10: OUT = MULT_8x8;  // MULT_8x8
         2'b11: OUT = MULT_16x16;  // MULT_16x16
      endcase	 

endmodule
