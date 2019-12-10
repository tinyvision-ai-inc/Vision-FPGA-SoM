`timescale 1ns/1ns
module I3C_HW (PADDT, PADDO, PADDI, IOPAD, PU_ENB, WEAK_PU_ENB);
    //Port Type List [Expanded Bus/Bit]
    input PADDT;
    input PADDO;
    output PADDI;
    inout IOPAD;
    input PU_ENB;
    input WEAK_PU_ENB;
    PIO pioInst (.PADDT(PADDT), .PADDO(PADDO), .PADDI(PADDI), .IOPAD(IOPAD));       
endmodule 
