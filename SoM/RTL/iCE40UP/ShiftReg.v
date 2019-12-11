`timescale 1ps/1ps
module ShiftReg (clk, init, phase0, phase90, phase180, phase270);
input clk, init; 
output phase0, phase90, phase180, phase270;

reg phase0, phase90, phase180, phase270;

always @ (posedge clk or posedge init)
   begin
	if (init)  
		begin
			phase0	 = 1'b0;
			phase90  = 1'b0;
			phase180 = 1'b1;
			phase270 = 1'b1;
		end
	else	
		begin
   	    	phase0 	 <=	phase270;
   	    	phase90  <=	phase0;
   	    	phase180 <=	phase90;
   	    	phase270 <=	phase180;
		end
    end
endmodule
