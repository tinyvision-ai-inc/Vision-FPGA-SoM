`timescale 1ps/1ps
module ShiftReg427 (clk, init, phase0, phase90);
input clk, init; 
output phase0, phase90;

parameter SHIFTREG_DIV_MODE = 2'b00; // 00-->Divide by 4 ,  01-->Divide by 7 , 
				     //	10 --> "INVALID mode" , 11--> Divide by 5(HDMI).

reg ff1, ff2, ff3, ff4, ff5, ff6, ff7;

always @ (posedge clk or posedge init)
   begin
	if (init)  
		begin
			ff1	 = 1'b0;
			ff2	 = 1'b0;
			ff3	 = 1'b0;
			ff4	 = 1'b1;
			ff5	 = 1'b1;
			ff6	 = 1'b1;
			ff7	 = 1'b1;
		end
	else	
		begin
	   	    	ff1 <= ff7;
			ff2 <= ff1;
			ff3 <= ff2;
			ff4 <= ff3;
		//	ff5 <= ff4;
			if 	(SHIFTREG_DIV_MODE == 2'b00)
			begin 
				ff5 <= ff4; 
				ff6 <= ff2;
			end 
			else if (SHIFTREG_DIV_MODE == 2'b01)
			begin 
				ff5 <= ff4; 
				ff6 <= ff5;
			end 
			else if (SHIFTREG_DIV_MODE == 2'b11)
			begin
				ff5 <= ff2; 
				ff6 <= ff5;
			end 
			else if (SHIFTREG_DIV_MODE == 2'b10) 
			begin 
				$display("Incorrect SHIFTREG_DIV_MODE set for simulation\n");
				$finish; 
			end 

			ff7 <= ff6;
		end
    end

assign phase0 = ff1;
assign phase90 = ff2;

endmodule
