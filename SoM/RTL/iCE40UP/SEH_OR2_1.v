`timescale 1ns / 10ps 
module SEH_OR2_1 (X, A1, A2);
   output X;
   input A1, A2;

   /////////////////////////////////////
   //          FUNCTIONALITY          //
   /////////////////////////////////////


   /////////////////////////////////////
   //             TIMING              //
   /////////////////////////////////////
   `ifdef VIRL_functiononly
       or #1 (X, A1, A2);
   `else
       or (X, A1, A2);
   `endif

   `ifdef VIRL_functiononly

   `else

specify
(A1 +=> X)=(0, 0);
(A2 +=> X)=(0, 0);
endspecify
   `endif

endmodule
