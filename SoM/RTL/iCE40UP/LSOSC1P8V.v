`timescale 1ns/1ns
module LSOSC1P8V (CLKLFPU, CLKLFEN, CLKLF); // synthesis syn_black_box

    (* \desc = "Power up the oscillator. After power up, output will be stable after 100us. Active high" *)
	input CLKLFPU;
    (* \desc = "Enable the clock output. Enable should be low for the 100us power up period. Active high" *)
	input CLKLFEN;
    (* \desc = "Oscillator output" *)
	output CLKLF;

	//Wires and Registers
	wire gnd;
	wire vcc;

	VLO vlo_inst(.Z(gnd));
	VHI vhi_inst(.Z(vcc));

	LSOSC_CORE osc_inst(.CLKLFPU(CLKLFPU), .CLKLFEN(CLKLFEN), .CLKLF(CLKLF), .TRIM0(vcc), .TRIM1(vcc), .TRIM2(vcc), .TRIM3(gnd), .TRIM4(vcc), .TRIM5(vcc), .TRIM6(gnd), .TRIM7(gnd), .TRIM8(vcc), .TRIM9(gnd));
	defparam osc_inst.FABRIC_TRIME = "ENABLE";

endmodule
