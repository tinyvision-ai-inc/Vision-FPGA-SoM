`timescale 1ns/1ns
module OFD1P3AZ(D, SP, CK, Q); // synthesis syn_black_box
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

    IOL_B iol_inst(.PADDI(gnd),
                   .DO1(gnd),
                   .DO0(D),
                   .CE(SP),
                   .IOLTO(gnd),
                   .HOLD(gnd),
                   .INCLK(gnd),
                   .OUTCLK(CK),
                   .PADDO(Q),
                   .PADDT(),
                   .DI1(),
                   .DI0()
                  );
    defparam iol_inst.LATCHIN = "LATCH_REG";
    defparam iol_inst.DDROUT = "NO";

endmodule
