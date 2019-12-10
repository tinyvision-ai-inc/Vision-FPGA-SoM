`timescale 1ns / 1ps
module fa (Cout, Sum, A, B, C);
input A, B, C;
output Cout, Sum;

//assign Cout = ((A&B) | (B&C) |(A&C));

assign Cout = ~(~(A&B) & ~(B&C) & ~(A&C));
assign Sum  = A^B^C;

endmodule // fa
