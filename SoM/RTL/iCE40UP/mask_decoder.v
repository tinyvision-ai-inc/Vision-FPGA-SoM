`timescale 1ps/1ps
module mask_decoder (
	mi,
	ai,
	mo
);

parameter WRITE_MODE = 0;

input [15:0] mi;
input [2:0] ai;
output [15:0] mo;

reg [15:0] mo;

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

always @(mode, mi, ai )
begin
	casex({mode,ai})
		5'b00xxx: mo = mi;
		5'b01xx0: mo = 16'hAAAA;
		5'b01xx1: mo = 16'h5555;
		5'b10x00: mo = 16'hEEEE;
		5'b10x01: mo = 16'hDDDD;
		5'b10x10: mo = 16'hBBBB;
		5'b10x11: mo = 16'h7777;
		5'b11000: mo = 16'hFEFE;
		5'b11001: mo = 16'hFDFD;
		5'b11010: mo = 16'hFBFB;
		5'b11011: mo = 16'hF7F7;
		5'b11100: mo = 16'hEFEF;
		5'b11101: mo = 16'hDFDF;
		5'b11110: mo = 16'hBFBF;
		5'b11111: mo = 16'h7F7F;
		default : 
		begin
			$display ("SBT ERROR: End up in unknown address\n");
			$finish;
		end
	endcase
end

endmodule  // mask_decoder
