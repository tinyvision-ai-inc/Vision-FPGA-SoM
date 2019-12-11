`timescale 1ns/1ns
module BB_B (T_N, I, O, B);

	//Port Type List [Expanded Bus/Bit]
	input T_N;
	input I;
	output O;
	inout B;



	//IP Ports Tied Off for Simulation

	PIO PIO_inst(.PADDT(T_N), .PADDO(I), .PADDI(O), .IOPAD(B));


endmodule
