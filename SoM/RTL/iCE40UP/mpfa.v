`timescale 1ns / 1ps
module mpfa (g_b, p,Sum, A, B, Cin);
input A, B, Cin;
output g_b, p, Sum;


assign g_b = ~(A & B);
assign p = A ^ B;

assign Sum  = p ^ Cin;

endmodule // mpfa
