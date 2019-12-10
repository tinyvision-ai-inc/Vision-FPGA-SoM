`timescale 1ns/1ns
module PUR_SIM (PUR_N);
  input PUR_N;
parameter RST_PULSE = 1;

reg PURNET;

initial
begin
 PURNET = 1'b0;
 #RST_PULSE
 PURNET = 1'b1;
end

endmodule
