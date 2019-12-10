`timescale 1ns/1ns
module FD1P3BZ(D, CK, SP, PD, Q); // synthesis syn_black_box
    (* \desc = "data in" *)
    input D;
    (* \desc = "clock" *)
    input CK;
    (* \desc = "clock enable, active high" *)
    input SP;
    (* \desc = "preset, active high" *)
    input PD;
    (* \desc = "data out" *)
    output Q;

    FD1P3XZ ff_inst(.D(D), .SP(SP), .SR(PD), .CK(CK), .Q(Q));

    defparam ff_inst.REGSET = "SET";
    defparam ff_inst.SRMODE = "ASYNC";

endmodule
