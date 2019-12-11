`timescale 1ns/1ns
module RGB_CORE (CURREN, RGBLEDEN, RGB0PWM, RGB1PWM, RGB2PWM, TRIM9, TRIM8, TRIM7, TRIM6, TRIM5, TRIM4, TRIM3, TRIM2, TRIM1, TRIM0, RGB2, RGB1, RGB0);

	//Port Type List [Expanded Bus/Bit]
	input CURREN;
	input RGBLEDEN;
	input RGB0PWM;
	input RGB1PWM;
	input RGB2PWM;
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
	output RGB2;
	output RGB1;
	output RGB0;


	//IP Ports Tied Off for Simulation
	//Attribute List
	parameter CURRENT_MODE = "0";
	parameter RGB0_CURRENT = "0b000000";
	parameter RGB1_CURRENT = "0b000000";
	parameter RGB2_CURRENT = "0b000000";
	parameter FABRIC_TRIME = "DISABLE";
	`include "convertDeviceString.v"
	//Converted Attribute List [For Device Binary / Hex String]
	/*
	localparam CONVERTED_CURRENT_MODE = convertDeviceString(CURRENT_MODE);
	localparam CONVERTED_RGB0_CURRENT = convertDeviceString(RGB0_CURRENT);
	localparam CONVERTED_RGB1_CURRENT = convertDeviceString(RGB1_CURRENT);
	localparam CONVERTED_RGB2_CURRENT = convertDeviceString(RGB2_CURRENT);
	*/
	RGBA_DRV RGBA_DRV_inst(.CURREN(CURREN), .RGBLEDEN(RGBLEDEN), .RGB0PWM(RGB0PWM), .RGB1PWM(RGB1PWM), .RGB2PWM(RGB2PWM), .TRIM9(TRIM9), .TRIM8(TRIM8), .TRIM7(TRIM7), .TRIM6(TRIM6), .TRIM5(TRIM5), .TRIM4(TRIM4), .TRIM3(TRIM3), .TRIM2(TRIM2), .TRIM1(TRIM1), .TRIM0(TRIM0), .RGB2(RGB2), .RGB1(RGB1), .RGB0(RGB0));

/*	defparam RGBA_DRV_inst.CURRENT_MODE = CONVERTED_CURRENT_MODE;
	defparam RGBA_DRV_inst.RGB0_CURRENT = CONVERTED_RGB0_CURRENT[5:0];
	defparam RGBA_DRV_inst.RGB1_CURRENT = CONVERTED_RGB1_CURRENT[5:0];
	defparam RGBA_DRV_inst.RGB2_CURRENT = CONVERTED_RGB2_CURRENT[5:0];
*/
	defparam RGBA_DRV_inst.CURRENT_MODE = CURRENT_MODE;
	defparam RGBA_DRV_inst.RGB0_CURRENT = RGB0_CURRENT[5:0];
	defparam RGBA_DRV_inst.RGB1_CURRENT = RGB1_CURRENT[5:0];
	defparam RGBA_DRV_inst.RGB2_CURRENT = RGB2_CURRENT[5:0];
	defparam RGBA_DRV_inst.FABRIC_TRIME = FABRIC_TRIME;


endmodule
