`timescale 1ns / 10ps 
module bolt_ir_barcode ( i200uref, barcode_pad, ir_pad, barcode_en, barcode_pwm, cbit_barcode, cbit_barcode_en, cbit_ir500, cbit_ir, cbit_ir_en, cbit_ir_half_cur, cbit_rgb_en, drivergnd, icc40u, ir_pwm, irled_en, poc, rgbled_en, vccio );

output  i200uref;

output  barcode_pad, ir_pad;

input  barcode_en, barcode_pwm, cbit_barcode_en, cbit_ir500, cbit_ir_en, cbit_ir_half_cur, cbit_rgb_en, drivergnd, icc40u, ir_pwm, irled_en, poc, rgbled_en, vccio;

input [3:0]  cbit_barcode;
input [7:0]  cbit_ir;

// List of primary aliased buses

irled400ma IR ( .cbit_ir_half_cur(cbit_ir_half_cur), .rgbled_en(rgbled_en), .irled_en(irled_en), .icc40u(icc40u), .cbit_rgb_en(cbit_rgb_en), .cbit_ir_en(cbit_ir_en), .cbit_barcode_en(cbit_barcode_en), .barcode_en(barcode_en), .drivergnd(drivergnd), .ir_pad(ir_pad), .i200uref(i200uref), .ir_nref(ir_nref), .ir_vref(ir_vref), .cbit_ir(cbit_ir[7:0]), .poc(poc), .vccio(vccio), .ir_pwm(ir_pwm));
barcode100ma BAR ( .barcode_pad(barcode_pad), .cbit_ir500(cbit_ir500), .cbit_barcode(cbit_barcode[3:0]), .barcode_pwm(barcode_pwm), .poc(poc), .drivergnd(drivergnd), .vccio(vccio), .ir_nref(ir_nref), .ir_vref(ir_vref));

endmodule
