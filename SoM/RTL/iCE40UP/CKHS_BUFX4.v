`include "defines2.v"
`timescale 1 ns / 1 ps
module CKHS_BUFX4
  (
   output z,
   input  a
   );
   
`ifdef SYNTHESIS 
 
   SEH_BUF_S_4 u
     (.X	(z),
      .A	(a)
      );
   
   // synopsys dc_script_begin
   // set_dont_touch u true
   // synopsys dc_script_end

`else // !`ifdef SYNTHESIS

   assign z = a;

`endif

endmodule // CKHS_BUFX4
