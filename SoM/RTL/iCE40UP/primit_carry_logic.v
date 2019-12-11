`timescale 10ps/1ps
primitive primit_carry_logic (y, v, c, a, b);
   output y;  
   input  v, c, a, b;

   table

// v  c  a  b  :  y
//
   0  ?  ?  ?  :  1;
   1  0  0  0  :  0;
   1  0  0  1  :  0;
   1  0  1  0  :  0;
   1  0  1  1  :  1;
   1  1  0  0  :  0;
   1  1  0  1  :  1;
   1  1  1  0  :  1;
   1  1  1  1  :  1;
   endtable
endprimitive // primit_o_mux

