`timescale 10ps/1ps
module PAD_BANK1(PAD, PADIN, PADOUT, PADOEN);
inout PAD;
input PADOUT, PADOEN;
output PADIN;
parameter IO_STANDARD = "SB_LVCMOS";
parameter PULLUP = 1'b0; // by default the IO will have NO pullup, this parameter is used only on bank 0, 1, and 2. Will be ignored when it is placed at bank 3

assign PAD = (~PADOEN) ? PADOUT : 1'bz;
assign PADIN = PAD ;


endmodule
