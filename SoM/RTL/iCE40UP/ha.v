`timescale 1ns / 1ps
module ha (Cout, Sum, A, B);
input A, B;
output Cout, Sum;

assign Cout = A & B;
assign Sum  = A ^ B;

endmodule // ha
