`timescale 1ns/1ns
module WARMBOOT (S1, S0, BOOT);

	//Port Type List [Expanded Bus/Bit]
	input S1;
	input S0;
	input BOOT;


	//IP Ports Tied Off for Simulation
	//Attribute List
	`include "convertDeviceString.v"

	WARMBOOT_SUB WARMBOOT_inst(.S1(S1), .S0(S0), .BOOT(BOOT));


endmodule
