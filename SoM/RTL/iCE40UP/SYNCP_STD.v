`include "defines2.v"
`timescale 1 ns / 1 ps
module SYNCP_STD
  (
    output      q,        // second flop's output
    input       d,        // data input to first flop
    input       ck,       // rising-edge clock
    input       cdn       // active-low asynchronous reset
   );

`ifdef SYNTHESIS
   wire         q0;
   
   SEH_FDPRBQ_1 u0
     (.Q        (q0),
      .D        (d),
      .CK       (ck),
      .RD       (cdn)
      );
   
   SEH_FDPRBQ_2 u
     (.Q        (q),
      .D        (q0),
      .CK       (ck),
      .RD       (cdn)
      );

   // synopsys dc_script_begin
   // set_dont_touch u true
   // synopsys dc_script_end

`else // !`ifdef SYNTHESIS
   
   reg          q1, q0;
   
   always @(posedge ck or negedge cdn)
     if (~cdn) q0 <= 1'b0;
     else      q0 <= d;

   always @(posedge ck or negedge cdn)
     if (~cdn) q1 <= 1'b0;
     else      q1 <= q0;

   assign q = q1;
   
`endif
   
endmodule // SYNCP_STD
