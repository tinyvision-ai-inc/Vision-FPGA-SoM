`timescale 1ns/1ns
module FD1P3DZ(D, CK, SP, CD, Q); // synthesis syn_black_box
    (* \desc = "data in" *)
    input D;
    (* \desc = "clock" *)
    input CK;
    (* \desc = "clock enable, active high" *)
    input SP;
    (* \desc = "clear, active high" *)
    input CD;
    (* \desc = "data out" *)
    output Q;

    FD1P3XZ ff_inst(.D(D), .SP(SP), .SR(CD), .CK(CK), .Q(Q));

    defparam ff_inst.REGSET = "RESET";
    defparam ff_inst.SRMODE = "ASYNC";

endmodule
