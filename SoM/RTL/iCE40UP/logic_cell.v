`timescale 1ns/1ns
module logic_cell ( carry_out, lc_out, carry_in, cbit, clk, clkb, in0,
     in1, in2, in3, prog, purst, s_r );
output  carry_out, lc_out;

input  carry_in, clk, clkb, in0, in1, in2, in3, prog, purst, s_r;

input [20:0]  cbit;
supply0 gnd_;
supply1 vdd_;



coredffr REG ( .purst(purst), .d(LUT4_outd), .q(rego),
     .cbit(cbit[17:16]), .clkb(clkb), .clk(clk), .S_R(s_r));
carry_logic ICARRY_LOGIC ( .b_bar(in1b1), .carry_in(carry_in), .b(in1),
     .cout(carry_out), .a(in2), .a_bar(in2b1), .vg_en(cbit[20]));
o_mux Iomux ( .in1(rego), .O(lc_out), .cbit(cbit[19]), .prog(prog),
     .in0(LUT4_outd));
clut4 iclut4 ( .in0b(in0b1), .in3b(in3b1), .in2b(in2b1),
     .lut4(LUT4_outd), .in1b(in1b1), .in2(in2), .in1(in1), .in0(in0),
     .in3(in3), .cbit(cbit[15:0]));
inv_hvt I163 ( .A(in3), .Y(in3b1));
inv_hvt I164 ( .A(in1), .Y(in1b1));
inv_hvt I162 ( .A(in2), .Y(in2b1));
inv_hvt I161 ( .A(in0), .Y(in0b1));

endmodule
