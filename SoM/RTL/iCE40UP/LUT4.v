`timescale 1ns/1ps
module LUT4(A, B, C, D, Z); 
  parameter INIT = "0x0000";

  input A;
  input B;
  input C;
  input D;
  output Z;

  wire Z_wire;

  `include "convertDeviceString.v"

  LUT4_SIM lut4(.I0(A), .I1(B), .I2(C), .I3(D), .O(Z_wire));
  defparam lut4.LUT_INIT = convertDeviceString(INIT); 

  buf #0.1 (Z, Z_wire);

endmodule
