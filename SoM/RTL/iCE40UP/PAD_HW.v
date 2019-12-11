`timescale 1ns/1ns
module PAD_HW (PADDT, PADDO, PADDI, IOPAD);
    //Port Type List [Expanded Bus/Bit]
    input PADDT;
    input PADDO;
    output PADDI;
    inout IOPAD;

    PIO pioInst (.PADDT(PADDT), .PADDO(PADDO), .PADDI(PADDI), .IOPAD(IOPAD));       
endmodule 
