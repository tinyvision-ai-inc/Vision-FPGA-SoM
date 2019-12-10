`include "defines2.v"
`timescale 1 ns / 1 ps
module CKHS_MUX4X2
  (
   output z,
   input  d3,
   input  d2,
   input  d1,
   input  d0,
   input  sd2,
   input  sd1
   );

`ifdef SYNTHESIS   
   SEH_MUX4_DG_2 u
     (.X	(z),
      .D3	(d3),
      .D2	(d2),
      .D1	(d1),
      .D0	(d0),
      .S1	(sd2),
      .S0	(sd1)
      );
   
   // synopsys dc_script_begin
   // set_dont_touch u true
   // synopsys dc_script_end

`else // !`ifdef SYNTHESIS

   reg    x;
   always @(/*AUTOSENSE*/d0 or d1 or d2 or d3 or sd1 or sd2)
     begin
        case ({sd2, sd1})
          2'b00   : x = d0;
          2'b01   : x = d1;
          2'b10   : x = d2;
          2'b11   : x = d3;
          default : x = d0;
        endcase // case ({sd2, sd1})
     end

   assign z = x;
   
`endif
   
endmodule // CKHS_MUX4X2
