`timescale 1ns/1ns
module IOL_B (PADDI, DO1, DO0, CE, IOLTO, HOLD, INCLK, OUTCLK, PADDO, PADDT, DI1, DI0);

	//Port Type List [Expanded Bus/Bit]
	input PADDI;
	input DO1;
	input DO0;
	input CE;
	input IOLTO;
	input HOLD;
	input INCLK;
	input OUTCLK;
	output PADDO;
	output PADDT;
	output DI1;
	output DI0;



	//IP Ports Tied Off for Simulation
	//Attribute List
	parameter LATCHIN = "NONE_REG";
	parameter DDROUT = "NO";
	`include "convertDeviceString.v"

	IOLOGIC IOLOGIC_inst(.PADDI(PADDI), .DO1(DO1), .DO0(DO0), .CE(CE), .IOLTO(IOLTO), .HOLD(HOLD), .INCLK(INCLK), .OUTCLK(OUTCLK), .PADDO(PADDO), .PADDT(PADDT), .DI1(DI1), .DI0(DI0));
	defparam IOLOGIC_inst.LATCHIN = LATCHIN;
	defparam IOLOGIC_inst.DDROUT = DDROUT;


endmodule
