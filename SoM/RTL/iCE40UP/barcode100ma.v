`timescale 1ns / 10ps 
module barcode100ma ( barcode_pad, drivergnd, vccio, barcode_pwm, cbit_barcode, cbit_ir500, ir_nref, ir_vref, poc );
inout  drivergnd, vccio;
output barcode_pad;
input  barcode_pwm, cbit_ir500, ir_nref, ir_vref, poc;

input [3:0]  cbit_barcode;

// List of primary aliased buses



barcode100_ledio IR ( .cbit_barcode(cbit_barcode[3:0]), .cbit_ir500(cbit_ir500), .barcode_pwm(barcode_pwm), .poc(poc), .vssio(drivergnd), .vccio(vccio), .IR_PAD(barcode_pad), .nref(ir_nref), .vref_in(ir_vref));
esd_btbdiodes I116 ( .vssx(drivergnd));

endmodule
