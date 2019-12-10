`timescale 1ns/1ns
module BUF (A, Z);
	
	input A;
	output Z;
	parameter BUF_DELAY = "0";
	buf #BUF_DELAY (Z, A) ;

endmodule // BUFFER
