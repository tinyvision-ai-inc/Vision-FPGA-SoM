`timescale 1ns / 10ps 
module irled400ma ( i200uref, ir_nref, ir_vref, drivergnd, ir_pad, vccio, barcode_en, cbit_barcode_en, cbit_ir, cbit_ir_en, cbit_ir_half_cur, cbit_rgb_en, icc40u, ir_pwm, irled_en, poc, rgbled_en );
output  i200uref, ir_nref, ir_vref;

inout  drivergnd, vccio;

output ir_pad;

input  barcode_en, cbit_barcode_en, cbit_ir_en, cbit_ir_half_cur, cbit_rgb_en, icc40u, ir_pwm, irled_en, poc, rgbled_en;

input [7:0]  cbit_ir;

// List of primary aliased buses

ir400_ledio IR ( .cbit_ir(cbit_ir[7:0]), .poc(poc), .vssio(drivergnd), .vccio(vccio), .IR_PAD(ir_pad), .ir_pwm(ir_pwm), .nref(ir_nref), .vref_in(ir_vref));
bolt_ir_bias BIAS ( .barcode_en(barcode_en), .cbit_barcode_en(cbit_barcode_en), .cbit_ir_half_cur(cbit_ir_half_cur), .i200uref(i200uref), .vssio_ir(drivergnd), .poc(poc), .icc40u(icc40u), .cbit_rgb_en(cbit_rgb_en), .cbit_ir_en(cbit_ir_en), .ir_nref(ir_nref), .ir_vref_in(ir_vref), .irled_en(irled_en), .rgbled_en(rgbled_en), .vccio(vccio));
esd_btbdiodes I116 ( .vssx(drivergnd));

endmodule
