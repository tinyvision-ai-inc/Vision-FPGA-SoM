`timescale 1ns / 1ps
module fcla16 (Sum, G, P, A, B, Cin);
input [15:0] A, B;
input Cin;
output [15:0] Sum;
output G, P;
wire	[15:0] gtemp1_b;
wire	[15:0] ptemp1;
wire	[15:0] ctemp1;
wire	[3:0] ctemp2;

wire	[3:0] gouta, pouta;
mpfa r01 (.g_b(gtemp1_b[0]), .p(ptemp1[0]), .Sum(Sum[0]), .A(A[0]), .B(B[0]), .Cin(Cin));
mpfa r02 (.g_b(gtemp1_b[1]), .p(ptemp1[1]), .Sum(Sum[1]), .A(A[1]), .B(B[1]), .Cin(ctemp1[1]));
mpfa r03 (.g_b(gtemp1_b[2]), .p(ptemp1[2]), .Sum(Sum[2]), .A(A[2]), .B(B[2]), .Cin(ctemp1[2]));
mpfa r04 (.g_b(gtemp1_b[3]), .p(ptemp1[3]), .Sum(Sum[3]), .A(A[3]), .B(B[3]), .Cin(ctemp1[3]));
mclg4 b1 (.cout(ctemp1[3:0]), .g_o(gouta[0]), .p_o(pouta[0]), .g_b(gtemp1_b[3:0]), .p(ptemp1[3:0]), .cin(Cin));

mpfa r05 (.g_b(gtemp1_b[4]), .p(ptemp1[4]), .Sum(Sum[4]), .A(A[4]), .B(B[4]), .Cin(ctemp2[1]));
mpfa r06 (.g_b(gtemp1_b[5]), .p(ptemp1[5]), .Sum(Sum[5]), .A(A[5]), .B(B[5]), .Cin(ctemp1[5]));
mpfa r07 (.g_b(gtemp1_b[6]), .p(ptemp1[6]), .Sum(Sum[6]), .A(A[6]), .B(B[6]), .Cin(ctemp1[6]));
mpfa r08 (.g_b(gtemp1_b[7]), .p(ptemp1[7]), .Sum(Sum[7]), .A(A[7]), .B(B[7]), .Cin(ctemp1[7]));
mclg4 b2 (.cout(ctemp1[7:4]), .g_o(gouta[1]), .p_o(pouta[1]), .g_b(gtemp1_b[7:4]), .p(ptemp1[7:4]), .cin(ctemp2[1]));

mpfa r09 (.g_b(gtemp1_b[8]), .p(ptemp1[8]), .Sum(Sum[8]), .A(A[8]), .B(B[8]), .Cin(ctemp2[2]));
mpfa r10 (.g_b(gtemp1_b[9]), .p(ptemp1[9]), .Sum(Sum[9]), .A(A[9]), .B(B[9]), .Cin(ctemp1[9]));
mpfa r11 (.g_b(gtemp1_b[10]), .p(ptemp1[10]), .Sum(Sum[10]), .A(A[10]), .B(B[10]), .Cin(ctemp1[10]));
mpfa r12 (.g_b(gtemp1_b[11]), .p(ptemp1[11]), .Sum(Sum[11]), .A(A[11]), .B(B[11]), .Cin(ctemp1[11]));
mclg4 b3 (.cout(ctemp1[11:8]), .g_o(gouta[2]), .p_o(pouta[2]), .g_b(gtemp1_b[11:8]), .p(ptemp1[11:8]), .cin(ctemp2[2]));

mpfa r13 (.g_b(gtemp1_b[12]), .p(ptemp1[12]), .Sum(Sum[12]), .A(A[12]), .B(B[12]), .Cin(ctemp2[3]));
mpfa r14 (.g_b(gtemp1_b[13]), .p(ptemp1[13]), .Sum(Sum[13]), .A(A[13]), .B(B[13]), .Cin(ctemp1[13]));
mpfa r15 (.g_b(gtemp1_b[14]), .p(ptemp1[14]), .Sum(Sum[14]), .A(A[14]), .B(B[14]), .Cin(ctemp1[14]));
mpfa r16 (.g_b(gtemp1_b[15]), .p(ptemp1[15]), .Sum(Sum[15]), .A(A[15]), .B(B[15]), .Cin(ctemp1[15]));
mclg4 b4 (.cout(ctemp1[15:12]), .g_o(gouta[3]), .p_o(pouta[3]), .g_b(gtemp1_b[15:12]), .p(ptemp1[15:12]), .cin(ctemp2[3]));

mclg16 b5 (.cout(ctemp2), .g_o(G), .p_o(P), .g(gouta), .p(pouta), .cin(Cin));
endmodule // fcla16
