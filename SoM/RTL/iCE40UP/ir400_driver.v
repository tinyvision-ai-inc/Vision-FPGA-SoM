`timescale 1ns / 10ps 
module ir400_driver ( PAD, VSSIO, ng_en, nref );
output  PAD;

input  VSSIO, nref;

input [7:0]  ng_en;

// List of primary aliased buses



sink_driver I29 ( .ngen(ng_en[0]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver I28 ( .ngen(ng_en[0]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver I27 ( .ngen(ng_en[0]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver I26 ( .ngen(ng_en[1]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver I25 ( .ngen(ng_en[1]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver I24 ( .ngen(ng_en[1]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver I23 ( .ngen(ng_en[2]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver I22 ( .ngen(ng_en[2]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver I21 ( .ngen(ng_en[2]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver I20 ( .ngen(ng_en[3]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver I19 ( .ngen(ng_en[3]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver I18 ( .ngen(ng_en[3]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver I17 ( .ngen(ng_en[4]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver I16 ( .ngen(ng_en[4]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver I15 ( .ngen(ng_en[4]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver I14 ( .ngen(ng_en[5]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver I13 ( .ngen(ng_en[5]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver I12 ( .ngen(ng_en[5]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver I11 ( .ngen(ng_en[6]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver I10 ( .ngen(ng_en[6]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver I9 ( .ngen(ng_en[6]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver I8 ( .ngen(ng_en[7]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver I7 ( .ngen(ng_en[7]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));
sink_driver I6 ( .ngen(ng_en[7]), .PAD(PAD), .VSSIO(VSSIO), .nref(nref));

endmodule
