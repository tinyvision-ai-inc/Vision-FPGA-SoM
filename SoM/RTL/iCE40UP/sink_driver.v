`timescale 1ns / 10ps 
module sink_driver ( PAD, VSSIO, ngen, nref );

output  PAD;

input  VSSIO, ngen, nref;

reg PAD_out;

always @ (ngen or nref)
begin
	if (nref & ngen)
		PAD_out <= 1'b0;
	else 
		PAD_out <= 1'bz;
end

assign PAD = PAD_out;

endmodule
