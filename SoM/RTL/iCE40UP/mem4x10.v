`timescale 1ns/1ps 
module mem4x10 (WDATAIN,WCLK,WE,WADDR,RADDR, RDATAOUT); 
	input [9:0]  WDATAIN; 
	input WCLK; 
	input WE; 
	input [1:0] WADDR;
	input [1:0] RADDR; 
	output [9:0] RDATAOUT; 
	
	reg [9:0] mem[0:3]; 
	
	// read first memory 
	always@(posedge WCLK) 
    	begin 		
		if(WE ==1'b1) begin 
			mem[WADDR] <= WDATAIN; 			
		end 					
    	end 						  	
	assign RDATAOUT = mem[RADDR];     

endmodule 	 
