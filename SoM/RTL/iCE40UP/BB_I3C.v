`timescale 1ns/1ns
module BB_I3C (T_N, I, O, B, PU_ENB, WEAK_PU_ENB);

	//Port Type List [Expanded Bus/Bit]
	input T_N;
	input I;
	output O;
	inout B;
	input PU_ENB;
	input WEAK_PU_ENB;



	//IP Ports Tied Off for Simulation

	I3C_HW I3C_inst(.PADDT(T_N), .PADDO(I), .PADDI(O), .IOPAD(B), .PU_ENB(PU_ENB), .WEAK_PU_ENB(WEAK_PU_ENB));


endmodule
