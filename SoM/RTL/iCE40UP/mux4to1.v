`timescale 1ps/1ps
module mux4to1 (a, b, c, d, select, o); 
  input a,b,c,d; 
  input  [1:0] select; 
  output o; 
  reg    o;
 
  always @ (a or b or c or d or select) 
  begin 
    case (select) 
      2'b00   : o = a; 
      2'b01   : o = b; 
      2'b10   : o = c; 
      2'b11	  : o = d; 
    endcase 
  end 

endmodule //mux4to1
