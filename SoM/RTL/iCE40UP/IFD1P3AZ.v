`timescale 1ns/1ns
module IFD1P3AZ(D, SP, CK, Q); // synthesis syn_black_box
    (* \desc = "data in" *)
    input D;
    (* \desc = "clock enable, active high" *)
    input SP;
    (* \desc = "clock" *)
    input CK;
    (* \desc = "data out" *)
    output Q;

    wire gnd;
    VLO vlo_inst(.Z(gnd));

    IOL_B iol_inst(.PADDI(D),
                   .DO1(gnd),
                   .DO0(gnd),
                   .CE(SP),
                   .IOLTO(gnd),
                   .HOLD(gnd),
                   .INCLK(CK),
                   .OUTCLK(gnd),
                   .PADDO(),
                   .PADDT(),
                   .DI1(),
                   .DI0(Q)
                  );
    defparam iol_inst.LATCHIN = "NONE_REG";
    defparam iol_inst.DDROUT = "NO";
endmodule
