`timescale 1ns / 10ps 
module barcode100_ledio ( IR_PAD, barcode_pwm, cbit_barcode, cbit_ir500, nref, poc, vccio, vref_in, vssio );
output  IR_PAD;

input  barcode_pwm, cbit_ir500, nref, poc, vccio, vref_in, vssio;

input [3:0]  cbit_barcode;

// Buses in the design

wire  [3:0]  ng_en;

// List of primary aliased buses

barcode_driver DRV ( .ng_en(ng_en[3:0]), .VSSIO(vssio), .PAD(IR_PAD), .nref(nref));
barcode_fastslew I29 ( .VCCIO(vccio), .ng_en(ng_en[3:0]), .vref_out(net09), .barcode_pwm(barcode_pwm), .cbit_ir500(cbit_ir500), .poc(poc), .vref_in(vref_in));
thunder_ir_predriver  PREDRV_3_ ( .cbit_ir(cbit_barcode[3]), .ng_en(ng_en[3]), .poc(poc), .sg11_pwm(barcode_pwm), .vccio(vccio), .vref_in(net09));
thunder_ir_predriver  PREDRV_2_ ( .cbit_ir(cbit_barcode[2]), .ng_en(ng_en[2]), .poc(poc), .sg11_pwm(barcode_pwm), .vccio(vccio), .vref_in(net09));
thunder_ir_predriver  PREDRV_1_ ( .cbit_ir(cbit_barcode[1]), .ng_en(ng_en[1]), .poc(poc), .sg11_pwm(barcode_pwm), .vccio(vccio), .vref_in(net09));
thunder_ir_predriver  PREDRV_0_ ( .cbit_ir(cbit_barcode[0]), .ng_en(ng_en[0]), .poc(poc), .sg11_pwm(barcode_pwm), .vccio(vccio), .vref_in(net09));



endmodule
