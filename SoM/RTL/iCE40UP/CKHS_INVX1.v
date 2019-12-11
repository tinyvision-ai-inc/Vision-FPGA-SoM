`include "defines2.v"
`timescale 1 ns / 1 ps
module CKHS_INVX1
  (
    output	z,	// z = ~a
    input 	a
   );

`ifdef SYNTHESIS
   
   SEH_INV_S_1 u
     (.X	(z),
      .A	(a)
      );
   
   // synopsys dc_script_begin
   // set_dont_touch u true
   // synopsys dc_script_end

`else

   assign z = ~a;

`endif // !`ifdef SYNTHESIS
   
endmodule // CKHS_INVX1
