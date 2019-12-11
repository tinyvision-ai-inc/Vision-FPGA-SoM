`timescale 1ns/1ns
module HSOSC1P8V (CLKHFPU, CLKHFEN, CLKHF); // synthesis syn_black_box

    (* \desc = "Power up the oscillator. After power up, output will be stable after 100us. Active high" *)
	input CLKHFPU;
    (* \desc = "Enable the clock output. Enable should be low for the 100us power up period. Active high" *)
	input CLKHFEN;
    (* \desc = "Oscillator output" *)
	output CLKHF;

	wire gnd;
	wire vcc;

    (* \desc = "Clock divider selection. 0b00 = 48MHz, 0b01 = 24MHz, 0b10 = 12MHz, 0b11 = 6MHz", \otherValues = "{0b01, 0b10, 0b11}" *)
	parameter CLKHF_DIV = "0b00";

	VLO vlo_inst(.Z(gnd));
	VHI vhi_inst(.Z(vcc));

	HSOSC_CORE osc_inst(.CLKHFPU(CLKHFPU), .CLKHFEN(CLKHFEN), .CLKHF(CLKHF), .TRIM0(gnd), .TRIM1(gnd), .TRIM2(gnd), .TRIM3(gnd), .TRIM4(vcc), .TRIM5(gnd), .TRIM6(gnd), .TRIM7(gnd), .TRIM8(vcc), .TRIM9(gnd));
	defparam osc_inst.CLKHF_DIV = CLKHF_DIV;
	defparam osc_inst.FABRIC_TRIME = "ENABLE";

endmodule
