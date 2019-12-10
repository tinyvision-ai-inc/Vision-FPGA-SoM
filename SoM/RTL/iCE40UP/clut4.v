`timescale 10ps/1ps
module clut4 (lut4, in0, in1, in2, in3, in0b, in1b, in2b, in3b, cbit);

//the output signal
output lut4;

//the input signals
input in0, in1, in2, in3, in0b, in1b, in2b, in3b;
input [15:0] cbit;

reg lut4;
      

   reg tmp;

   always @(in0 or in1 or in2 or in3 or in0b or in1b or in2b or in3b or cbit) begin

      tmp = in0 ^ in1 ^ in2 ^ in3;

      if ({in3, in2, in1, in0} != ~{in3b, in2b, in1b, in0b})
         lut4 = 1'bx;
      else if (tmp == 0 || tmp == 1)
         lut4 = cbit[{in3, in2, in1, in0}];
      else
         lut4 = lut_mux ({lut_mux (cbit[15:12], {in1, in0}), lut_mux (cbit[11:8], {in1, in0}), lut_mux (cbit[7:4], {in1, in0}), lut_mux (cbit[3:0], {in1, in0})}, {in3, in2});

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


endmodule // clut4
