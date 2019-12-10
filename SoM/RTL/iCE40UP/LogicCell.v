`timescale 1ns/1ns
module LogicCell ( carryout, lcout, carryin, clk, clkb, in0,
     in1, in2, in3, sr );

   parameter SEQ_MODE = 4'b0000; //cbit[19:16]  timing parameter
   parameter C_ON = 1'b0; //cbit[20]
   parameter LUT_INIT = 16'b0000000000000000; //cbit[15:0]

output  carryout, lcout;

input  carryin, clk, clkb, in0, in1, in2, in3, sr;

pulldown(gnd_);

    logic_cell LC (
            .cbit({C_ON,SEQ_MODE,LUT_INIT}),
            .carry_in(carryin),
            .carry_out(carryout),
            .clk(clk),
            .clkb(clkb),
            .in0(in0),
            .in1(in1),
            .in2(in2),
            .in3(in3),
            .lc_out(lcout),
            .prog(gnd_),
            .purst(gnd_),
            .s_r(sr));


endmodule
