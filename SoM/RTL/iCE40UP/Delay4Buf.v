`timescale 1ps/1ps
module Delay4Buf (a, s, delay4bufout, muxinvout);
input a;
input [1:0] s;
output delay4bufout, muxinvout;
parameter BUF_DELAY = 150;
parameter MUXINV_DELAY = 100; 

buf # BUF_DELAY  bufinst1 (buf1out, a);
buf # BUF_DELAY  bufinst2 (buf2out, buf1out);
buf # BUF_DELAY  bufinst3 (buf3out, buf2out);
buf # BUF_DELAY  bufinst4 (delay4bufout, buf3out);


mux4to1 muxinst (.a(buf1out), .b(buf2out), .c(buf3out), .d(delay4bufout), .select(s), .o(muxout));
not # MUXINV_DELAY (muxinvout, muxout);

endmodule
