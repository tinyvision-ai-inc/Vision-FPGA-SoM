`timescale 1ns / 1ps
module fcla8 (Sum, G, P, A, B, Cin);
input [7:0] A, B;
input Cin;
output [7:0] Sum;
output G, P;
wire	[7:0] gtemp1;
wire	[7:0] ptemp1;
wire	[7:0] ctemp1;
wire	 ctemp2;

wire	[1:0] gouta, pouta;

mpfa r01 (.g_b(gtemp1[0]), .p(ptemp1[0]), .Sum(Sum[0]), .A(A[0]), .B(B[0]), .Cin(Cin));
mpfa r02 (.g_b(gtemp1[1]), .p(ptemp1[1]), .Sum(Sum[1]), .A(A[1]), .B(B[1]), .Cin(ctemp1[1]));
mpfa r03 (.g_b(gtemp1[2]), .p(ptemp1[2]), .Sum(Sum[2]), .A(A[2]), .B(B[2]), .Cin(ctemp1[2]));
mpfa r04 (.g_b(gtemp1[3]), .p(ptemp1[3]), .Sum(Sum[3]), .A(A[3]), .B(B[3]), .Cin(ctemp1[3]));
mclg4 b1 (.cout(ctemp1[3:0]), .g_o(gouta[0]), .p_o(pouta[0]), .g_b(gtemp1[3:0]), .p(ptemp1[3:0]), .cin(Cin));

mpfa r05 (.g_b(gtemp1[4]), .p(ptemp1[4]), .Sum(Sum[4]), .A(A[4]), .B(B[4]), .Cin(ctemp2));
mpfa r06 (.g_b(gtemp1[5]), .p(ptemp1[5]), .Sum(Sum[5]), .A(A[5]), .B(B[5]), .Cin(ctemp1[5]));
mpfa r07 (.g_b(gtemp1[6]), .p(ptemp1[6]), .Sum(Sum[6]), .A(A[6]), .B(B[6]), .Cin(ctemp1[6]));
mpfa r08 (.g_b(gtemp1[7]), .p(ptemp1[7]), .Sum(Sum[7]), .A(A[7]), .B(B[7]), .Cin(ctemp1[7]));
mclg4 b2 (.cout(ctemp1[7:4]), .g_o(gouta[1]), .p_o(pouta[1]), .g_b(gtemp1[7:4]), .p(ptemp1[7:4]), .cin(ctemp2));

assign ctemp2=~(~gouta[0] & ~(pouta[0] & Cin));

assign G = ~(~gouta[1] & ~(pouta[1] & gouta[0]));
assign P = pouta[1] & pouta[0];

endmodule // fcla8
