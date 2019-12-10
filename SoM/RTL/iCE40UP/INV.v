`timescale 1ns/1ns
module INV (A, Z);

input A;
output Z;

assign Z = ~A; 

endmodule
