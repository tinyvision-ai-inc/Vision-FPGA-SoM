`timescale 1ns/1ns
module HSOSC_CORE (CLKHFPU, CLKHFEN, TRIM9, TRIM8, TRIM7, TRIM6, TRIM5, TRIM4, TRIM3, TRIM2, TRIM1, TRIM0, CLKHF);

	//Port Type List [Expanded Bus/Bit]
	input CLKHFPU;
	input CLKHFEN;
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
	output CLKHF;


	//Assigning input IP Ports to corresponding SW bit ports [Inputs]
	wire [9:0] TRIM;
	assign TRIM = {TRIM9, TRIM8, TRIM7, TRIM6, TRIM5, TRIM4, TRIM3, TRIM2, TRIM1, TRIM0};

	//IP Ports Tied Off for Simulation
	//Attribute List
	//parameter CLKHF_DIV = "0x0"; //"0b00";
	parameter CLKHF_DIV = "0b00";
	parameter FABRIC_TRIME = "DISABLE";
	`include "convertDeviceString.v"
	//Converted Attribute List [For Device Binary / Hex String]
	//localparam CONVERTED_CLKHF_DIV = convertDeviceString(CLKHF_DIV);

	HFOSC HFOSC_inst(.CLKHFPU(CLKHFPU), .CLKHFEN(CLKHFEN), .TRIM(TRIM), .CLKHF(CLKHF));
	//defparam HFOSC_inst.CLKHF_DIV = CONVERTED_CLKHF_DIV[1:0];
	defparam HFOSC_inst.CLKHF_DIV = CLKHF_DIV;
	defparam HFOSC_inst.FABRIC_TRIME = FABRIC_TRIME;


endmodule
