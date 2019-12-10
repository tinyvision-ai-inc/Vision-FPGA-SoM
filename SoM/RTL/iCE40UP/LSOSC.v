`timescale 1ns/1ns
module LSOSC(CLKLFPU, CLKLFEN, CLKLF); // synthesis syn_black_box
    (* \desc = "Power up the oscillator. After power up, output will be stable after 100us. Active high" *)
    input CLKLFPU;
    (* \desc = "Enable the clock output. Enable should be low for the 100us power up period. Active high" *)
    input CLKLFEN;
    (* \desc = "Oscillator output" *)
    output CLKLF;

    wire gnd;
    VLO vlo_inst(.Z(gnd));

    LSOSC_CORE osc_inst(.CLKLFPU(CLKLFPU), .CLKLFEN(CLKLFEN), .CLKLF(CLKLF),
                  .TRIM0(gnd), .TRIM1(gnd), .TRIM2(gnd), .TRIM3(gnd), .TRIM4(gnd), .TRIM5(gnd), .TRIM6(gnd), .TRIM7(gnd), .TRIM8(gnd), .TRIM9(gnd));

endmodule
