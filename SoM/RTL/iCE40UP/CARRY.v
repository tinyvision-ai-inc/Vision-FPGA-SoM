`timescale 1ps/1ps
module CARRY (CO, I0, I1, CI);
input I0, I1, CI;
output CO;
reg CI_int;

   assign CO = (CI_int * I0) | (CI_int * I1) | (I0 * I1);

   always @(CI)
	if ((CI == 1'b0) || (CI == 1'b1))
		CI_int = CI;
	else
		CI_int = 1'b0; // take care of CI is not connected if the CI is an output from LUT instead of from another CARRY


endmodule
