`timescale 1ps/1ps
module LUT4_SIM (O, I0, I1, I2, I3);
   parameter LUT_INIT = 16'h0000;
input I0, I1, I2, I3;
output O;
wire [15:0] mask;

reg luts;
reg I3_in, I2_in, I1_in, I0_in;
/*initial
begin
  luts = 1'b0;
  I3_in = 1'b0;
  I2_in = 1'b0;
  I1_in = 1'b0;
  I0_in = 1'b0;
end*/
always @ (I3 or I2 or I1 or I0)
  begin
    I3_in = I3;
    I2_in = I2;
    I1_in = I1;
    I0_in = I0;
  end
assign mask = LUT_INIT;
assign O = luts;

reg tmp;
always @(I3_in or I2_in or I1_in or I0_in ) begin
   tmp = I3_in ^ I2_in ^ I1_in ^ I0_in;
   #0.01;
   if (tmp === 0 || tmp === 1)
      luts = mask[{I3_in, I2_in, I1_in, I0_in}];
   else
      luts = lut_mux ({lut_mux (mask[15:12], {I1_in, I0_in}), lut_mux (mask[11:8], {I1_in, I0_in}), lut_mux (mask[7:4], {I1_in, I0_in}), lut_mux (mask[3:0], {I1_in, I0_in})}, {I3_in, I2_in});
end

function lut_mux;
input [3:0] d;
input [1:0] s;
   begin
      if ((s[1]^s[0] ==1) || (s[1]^s[0] ==0))
         lut_mux = d[s];
      else if ((d[0] ^ d[1]) == 0 && (d[2] ^ d[3]) == 0 && (d[0] ^ d[2]) == 0)
         lut_mux = d[0];
      else if ((s[1] == 0) && (d[0] == d[1]))
         lut_mux = d[0];
      else if ((s[1] == 1) && (d[2] == d[3]))
         lut_mux = d[2];
      else if ((s[0] == 0) && (d[0] == d[2]))
         lut_mux = d[0];
      else if ((s[0] == 1) && (d[1] == d[3]))
         lut_mux = d[1];
      else
         lut_mux = 1'bx;
   end
endfunction
endmodule
