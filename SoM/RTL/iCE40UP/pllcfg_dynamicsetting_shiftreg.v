`timescale 1ps/1ps
module pllcfg_dynamicsetting_shiftreg (pll_sck,pll_sdi, q);
input pll_sck, pll_sdi; 
output [26:0] q;

reg [26:0] q = 27'b0;

always @ (negedge pll_sck)
   begin
	 q[26:0] <= {q[25:0],pll_sdi};
   end

endmodule
