`timescale 1ps/1ps
module write_data_decoder (
	di,
	do
);

parameter WRITE_MODE = 0;

input [15:0] di;
output [15:0] do;

reg [15:0] do;


reg [1:0]mode;

initial 
begin
	if(WRITE_MODE == 0)
		mode = 2'b00;
	else if(WRITE_MODE == 1)
		mode = 2'b01;
	else if(WRITE_MODE == 2)
		mode = 2'b10;
	else if(WRITE_MODE == 3)
		mode = 2'b11;
	else
	begin
		$display (" SBT ERROR :  Unknown RAM WRITE MODE\n");
		$display (" Valid Modes are : 0, 1, 2, 3\n");
		//$display (" 0 -- 256X16 mode \n 1-- 512X8 mode \n 2 -- 1024X4 mode \n 3 -- 2048X2  mode \n");
		$finish;
	end
end

always @(mode, di )
begin
	case(mode)
		2'b00: do = di;
		2'b01: do = {di[14],di[14],di[12],di[12],di[10],di[10],di[8],di[8],di[6],di[6],di[4],di[4],di[2],di[2],di[0],di[0]};
		2'b10: do = {di[13],di[13],di[13],di[13],di[9],di[9],di[9],di[9],di[5],di[5],di[5],di[5],di[1],di[1],di[1],di[1]};
		2'b11: do = {di[11],di[11],di[11],di[11],di[11],di[11],di[11],di[11],di[3],di[3],di[3],di[3],di[3],di[3],di[3],di[3]};
	endcase
end

endmodule  // write_data_decoder
