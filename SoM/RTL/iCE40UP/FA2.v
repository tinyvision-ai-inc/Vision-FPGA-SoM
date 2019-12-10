`timescale 1ns/1ns
module FA2 (
   A0, B0, C0, D0, CI0,
   A1, B1, C1, D1, CI1,
   CO0, CO1,
   S0, S1
);  

   input A0, B0, C0, D0, CI0;
   input A1, B1, C1, D1, CI1;
   output CO0, CO1;
   output S0, S1;

   parameter INIT0 = "0xc33c" ;
   parameter INIT1 = "0xc33c" ;

   assign (weak0, weak1) A0 = 1'b0; 
   assign (weak0, weak1) B0 = 1'b0; 
   assign (weak0, weak1) C0 = 1'b0; 
   assign (weak0, weak1) D0 = 1'b0; 
   assign (weak0, weak1) CI0 = 1'b1; 

   assign (weak0, weak1) A1 = 1'b0; 
   assign (weak0, weak1) B1 = 1'b0; 
   assign (weak0, weak1) C1 = 1'b0; 
   assign (weak0, weak1) D1 = 1'b0; 
   assign (weak0, weak1) CI1 = 1'b1; 

   LUT4 lut0(.A(A0), .B(B0), .C(C0), .D(D0), .Z(S0));
   defparam lut0.INIT = INIT0;
   LUT4 lut1(.A(A1), .B(B1), .C(C1), .D(D1), .Z(S1));
   defparam lut1.INIT = INIT1;

   //carry out logic 
   //propagate if B xor C and carry in 
   //generate if B & C 
   assign CO0 = (B0 ^ C0)? CI0 : B0&C0;
   assign CO1 = (B1 ^ C1)? CI1 : B1&C1;

endmodule
