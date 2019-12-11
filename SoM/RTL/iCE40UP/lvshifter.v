`timescale 1ns / 10ps 
module lvshifter ( AO, AOB, A, POC, VDDIO );

output  AO, AOB;

input  A, POC, VDDIO;

reg AO, AOB;

always @ (A or POC or VDDIO)
begin

		if (POC & A)
			begin
			AO <= 1'bx;
			AOB <= 1'bx;
			end
		else
			if (POC & !A)
				begin
				AO <= 1'b0;
				AOB <= 1'b1;
				end
			else
				begin
				AO <= A;
				AOB <= !A;
				end
end

endmodule
