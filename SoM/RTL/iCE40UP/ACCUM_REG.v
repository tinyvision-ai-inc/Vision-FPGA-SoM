`timescale 1ns / 1ps
module ACCUM_REG (
	D ,
	Q ,
	ENA ,
	CLK ,
	RST
	);

	input [15:0] D ;
	output [15:0] Q;
	reg [15:0] Q;
	input ENA ;
	input CLK ;
	input RST;
	
	always @(posedge CLK or posedge RST)
      if (RST) // Syncronous reset overrides all other controls
				Q <= 16'h0 ;
		else
			if(ENA) // Update Q whenever LOAD or ENAble asserted
			    Q <=  D ; 	 //#1 D ;
			else
			    Q <= Q ;     //#1 Q ;
		
endmodule 
