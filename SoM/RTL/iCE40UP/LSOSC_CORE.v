`timescale 1ns/1ns
module LSOSC_CORE (CLKLFPU, CLKLFEN, TRIM9, TRIM8, TRIM7, TRIM6, TRIM5, TRIM4, TRIM3, TRIM2, TRIM1, TRIM0, CLKLF);

	//Port Type List [Expanded Bus/Bit]
	input CLKLFPU;
	input CLKLFEN;
	input TRIM9;
	input TRIM8;
	input TRIM7;
	input TRIM6;
	input TRIM5;
	input TRIM4;
	input TRIM3;
	input TRIM2;
	input TRIM1;
	input TRIM0;
	output CLKLF;


	//Assigning input IP Ports to corresponding SW bit ports [Inputs]
	wire [9:0] TRIM;
	assign TRIM = {TRIM9, TRIM8, TRIM7, TRIM6, TRIM5, TRIM4, TRIM3, TRIM2, TRIM1, TRIM0};

	//IP Ports Tied Off for Simulation
	//Attribute List
	parameter FABRIC_TRIME = "DISABLE";
	`include "convertDeviceString.v"

	LFOSC LFOSC_inst(.CLKLFPU(CLKLFPU), .CLKLFEN(CLKLFEN), .TRIM(TRIM), .CLKLF(CLKLF));
	defparam LFOSC_inst.FABRIC_TRIME = FABRIC_TRIME;


endmodule
