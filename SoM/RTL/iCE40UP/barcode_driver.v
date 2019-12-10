`timescale 1ns / 10ps 
module barcode_driver ( PAD, VSSIO, ng_en, nref );

output  PAD;

input  VSSIO, nref;

input [3:0]  ng_en;



sink_driver  I29 ( .ngen(ng_en[3]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver  I28 ( .ngen(ng_en[3]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver  I27 ( .ngen(ng_en[3]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver  I26 ( .ngen(ng_en[2]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver  I25 ( .ngen(ng_en[0]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver  I24 ( .ngen(ng_en[1]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));

endmodule
