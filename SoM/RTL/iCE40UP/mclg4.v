`timescale 1ns / 1ps
module mclg4 (cout, g_o, p_o, g_b, p, cin);
input [3:0] g_b, p;
input cin;
output [3:0] cout;
output g_o, p_o;

wire	s1, s2, s3, s4, s5, s6,s7,s8,s9;

wire  [2:0] g;
assign g[0] =~g_b[0];
assign g[1] =~g_b[1];
assign g[2] =~g_b[2];

assign s1 = ~(p[0] & cin);
assign cout[1] =~(g_b[0] & s1);

assign s2 = ~(p[1] & g[0]);
assign s3 = ~(p[1] & p[0] & cin);
assign cout[2] =~(g_b[1] & s2 & s3);

assign s4 = ~(p[2] & g[1]);
assign s5 = ~(p[2] & p[1] & g[0]);
assign s6 = ~(p[2] & p[1] & p[0] & cin);
assign cout[3] =~(g_b[2] & s4 & s5 & s6);

assign s7 =~(p[3] & g[2]);
assign s8 =~(p[3] & p[2] & g[1]);
assign s9 =~(p[3] & p[2] & p[1] & g[0]);
assign g_o =~(g_b[3] & s7 & s8 & s9);

assign p_o =(p[3] & p[2] & p[1] & p[0]);

endmodule // mclg4
