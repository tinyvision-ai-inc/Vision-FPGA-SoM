`timescale 1ns/1ns
module OPENDRAIN_HW (PADDT, PADDO, PADDI, IOPAD);
    //Port Type List [Expanded Bus/Bit]
    input PADDT;
    input PADDO;
    output PADDI;
    inout IOPAD;


    assign PADDI = IOPAD; 
    assign IOPAD = !PADDT? 1'bz : PADDO? 1'bz : 1'b0;

endmodule 
