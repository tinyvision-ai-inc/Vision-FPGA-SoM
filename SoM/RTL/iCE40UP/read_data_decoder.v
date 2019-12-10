`timescale 1ps/1ps
module read_data_decoder (
	di,
	ai,
	do
);

parameter READ_MODE = 0;

input [15:0] di;
input [2:0] ai;
output [15:0] do;
reg [15:0] do;

reg [1:0]mode;

initial 
begin
	if(READ_MODE == 0)
		mode = 2'b00;
	else if(READ_MODE == 1)
		mode = 2'b01;
	else if(READ_MODE == 2)
		mode = 2'b10;
	else if(READ_MODE == 3)
		mode = 2'b11;
	else
	begin
		$display (" SBT ERROR :  Unknown RAM READ MODE\n");
		$display (" Valid Modes are : 0, 1, 2, 3\n");
		//$display (" 0 -- 256X16 mode \n 1-- 512X8 mode \n 2 -- 1024X4 mode \n 3 -- 2048X2  mode \n");
		$finish;
	end
end

always @(mode, di, ai)
begin
	casex({mode,ai})
		5'b00xxx: do = di;
		5'b01xx0: do = {1'b0,di[14],1'b0,di[12],1'b0,di[10],1'b0,di[8],1'b0,di[6],1'b0,di[4],1'b0,di[2],1'b0,di[0]};
		5'b01xx1: do = {1'b0,di[15],1'b0,di[13],1'b0,di[11],1'b0,di[9],1'b0,di[7],1'b0,di[5],1'b0,di[3],1'b0,di[1]};
		5'b10x00: do = {1'b0,1'b0,di[12],1'b0,1'b0,1'b0,di[8],1'b0,1'b0,1'b0,di[4],1'b0,1'b0,1'b0,di[0],1'b0};
		5'b10x01: do = {1'b0,1'b0,di[13],1'b0,1'b0,1'b0,di[9],1'b0,1'b0,1'b0,di[5],1'b0,1'b0,1'b0,di[1],1'b0};
		5'b10x10: do = {1'b0,1'b0,di[14],1'b0,1'b0,1'b0,di[10],1'b0,1'b0,1'b0,di[6],1'b0,1'b0,1'b0,di[2],1'b0};
		5'b10x11: do = {1'b0,1'b0,di[15],1'b0,1'b0,1'b0,di[11],1'b0,1'b0,1'b0,di[7],1'b0,1'b0,1'b0,di[3],1'b0};
		5'b11000: do = {1'b0,1'b0,1'b0,1'b0,di[8],1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,di[0],1'b0,1'b0,1'b0};
		5'b11001: do = {1'b0,1'b0,1'b0,1'b0,di[9],1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,di[1],1'b0,1'b0,1'b0};
		5'b11010: do = {1'b0,1'b0,1'b0,1'b0,di[10],1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,di[2],1'b0,1'b0,1'b0};
		5'b11011: do = {1'b0,1'b0,1'b0,1'b0,di[11],1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,di[3],1'b0,1'b0,1'b0};
		5'b11100: do = {1'b0,1'b0,1'b0,1'b0,di[12],1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,di[4],1'b0,1'b0,1'b0};
		5'b11101: do = {1'b0,1'b0,1'b0,1'b0,di[13],1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,di[5],1'b0,1'b0,1'b0};
		5'b11110: do = {1'b0,1'b0,1'b0,1'b0,di[14],1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,di[6],1'b0,1'b0,1'b0};
		5'b11111: do = {1'b0,1'b0,1'b0,1'b0,di[15],1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,di[7],1'b0,1'b0,1'b0};
		default:
		begin
			$display ("SBT ERROR: End up in unknown address\n");
			$finish;
		end
	endcase
end

endmodule  // read_data_decoder
