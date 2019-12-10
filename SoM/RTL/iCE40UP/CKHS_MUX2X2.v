`include "defines2.v"
`timescale 1 ns / 1 ps
module CKHS_MUX2X2
  (
   output z,
   input  d1,
   input  d0,
   input  sd
   );

`ifdef SYNTHESIS   
   SEH_MUX2_S_2 u
     (.X	(z),
      .D1	(d1),
      .D0	(d0),
      .S	(sd)
      );
   
   // synopsys dc_script_begin
   // set_dont_touch u true
   // synopsys dc_script_end

`else // !`ifdef SYNTHESIS

   assign z = sd ? d1 : d0;

`endif

endmodule // CKHS_MUX2X2
