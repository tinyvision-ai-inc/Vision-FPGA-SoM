`timescale 1ns/1ns
module PUR (PUR_N);

	//Port Type List [Expanded Bus/Bit]
	input PUR_N;



	//IP Ports Tied Off for Simulation
	//Attribute List
	parameter RST_PULSE = "1";
	`include "convertDeviceString.v"
	//Converted Attribute List [For Device Binary / Hex String]
	localparam CONVERTED_RST_PULSE = convertDeviceString(RST_PULSE);

	PUR_SIM PUR_inst(.PUR_N(PUR_N));
	defparam PUR_inst.RST_PULSE = CONVERTED_RST_PULSE;


endmodule
