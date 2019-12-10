`timescale 10ps/1ps
primitive primit_o_mux (y, a0, a1, c, p);
   output y;  
   input  a0, a1, c, p;

   table

// a0 a1 c  p  :  y
//
   ?  0  ?  1  :  0;
   ?  1  ?  1  :  1;
   ?  x  ?  1  :  x;
   0  ?  0  0  :  0;
   1  ?  0  0  :  1;
   ?  0  1  0  :  0;
   ?  1  1  0  :  1;
   ?  0  1  ?  :  0;
   ?  1  1  ?  :  1;
   endtable
endprimitive // primit_o_mux

