`timescale 1ns/1ns
module FILTER (FILTERIN, FILTEROUT);

	//Port Type List [Expanded Bus/Bit]
	input FILTERIN;
	output FILTEROUT;



	//IP Ports Tied Off for Simulation
	//Attribute List
	`include "convertDeviceString.v"

	FILTER_50NS FILTER_inst(.FILTERIN(FILTERIN), .FILTEROUT(FILTEROUT));


endmodule
