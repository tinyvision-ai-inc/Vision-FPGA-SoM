`timescale 1ns/1ns
module PIO (PADDT, PADDO, PADDI, IOPAD);
    //Port Type List [Expanded Bus/Bit]
    input PADDT;
    input PADDO;
    output PADDI;
    inout IOPAD;

    assign PADDI = IOPAD; 
    assign IOPAD = PADDT? PADDO : 1'bz;

        
endmodule 
