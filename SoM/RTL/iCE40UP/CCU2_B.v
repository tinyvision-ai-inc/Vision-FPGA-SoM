`timescale 1ns/1ns
module CCU2_B(A0, B0, C0, CIN, A1, B1, C1, COUT, S0, S1); // synthesis syn_black_box

   (* \desc = "Input bit 0 of the first operand" *)
   input A0;
   (* \desc = "Input bit 0 of the second operand" *)
   input B0;
   (* \desc = "Input bit 0 of the third operand" *)
   input C0;
   (* \desc = "Carry in" *)
   input CIN;
   (* \desc = "Input bit 1 of the first operand" *)
   input A1;
   (* \desc = "Input bit 1 of the second operand" *)
   input B1;
   (* \desc = "Input bit 1 of the third operand" *)
   input C1;
   (* \desc = "Output bit 0 of the sum" *)
   output S0;
   (* \desc = "Output bit 1 of the sum" *)
   output S1;
   (* \desc = "Carry out" *)
   output COUT;

   parameter INIT0 = "0xc33c";
   parameter INIT1 = "0xc33c";

   FA2 fa22_inst ( .A0(A0), .B0(B0), .C0(C0), .D0(CIN),
                    .A1(A1), .B1(B1), .C1(C1), .D1(CO0),
                    .CI0(CIN), .CI1(CO0), .CO0(CO0), .CO1(COUT),
                .S0(S0), .S1(S1));
   defparam fa22_inst.INIT0 = INIT0;
   defparam fa22_inst.INIT1 = INIT1;
endmodule
