`timescale 1ns / 10ps 
module thunder_ledio ( IR_PAD, RGB0_PAD, RGB1_PAD, RGB2_PAD, cbit_ir, cbit_ir_en, cbit_rgb0, cbit_rgb1, cbit_rgb2, cbit_rgb_en, icc40u, ir_pwm, irled_en, poc, rgb0_pwm, rgb1_pwm, rgb2_pwm, rgbled_en, vccio, vss_rgb, vssio_ir );

inout  IR_PAD, RGB0_PAD, RGB1_PAD, RGB2_PAD;

input  cbit_ir_en, cbit_rgb_en, icc40u, ir_pwm, irled_en, poc, rgb0_pwm, rgb1_pwm, rgb2_pwm, rgbled_en, vccio, vss_rgb, vssio_ir;

input [5:0]  cbit_rgb0;
input [5:0]  cbit_rgb2;
input [5:0]  cbit_rgb1;
input [9:0]  cbit_ir;

// List of primary aliased buses



ir_ledio IR ( .poc(poc), .vssio(vssio_ir), .vccio(vccio), .IR_PAD(IR_PAD), .cbit_ir(cbit_ir[9:0]), .ir_pwm(ir_pwm), .nref(ir_nref), .vref_in(ir_vref));
thunder_led_bias BIAS ( .vss_rgb(vss_rgb), .vssio_ir(vssio_ir), .poc(poc), .icc40u(icc40u), .cbit_rgb_en(cbit_rgb_en), .cbit_ir_en(cbit_ir_en), .ir_nref(ir_nref), .ir_vref_in(ir_vref), .rgb_nref(rgb_nref), .rgb_vref_in(rgb_vref), .irled_en(irled_en), .rgbled_en(rgbled_en), .vccio(vccio));
rgb_ledio RGB0 ( .poc(poc), .RGB_PAD(RGB0_PAD), .cbit_rgb(cbit_rgb0[5:0]), .nref(rgb_nref), .rgb_pwm(rgb0_pwm), .vccio(vccio), .vref_in(rgb_vref), .vssio(vss_rgb));
rgb_ledio RGB2 ( .poc(poc), .RGB_PAD(RGB2_PAD), .cbit_rgb(cbit_rgb2[5:0]), .nref(rgb_nref), .rgb_pwm(rgb2_pwm), .vccio(vccio), .vref_in(rgb_vref), .vssio(vss_rgb));
rgb_ledio RGB1 ( .poc(poc), .RGB_PAD(RGB1_PAD), .cbit_rgb(cbit_rgb1[5:0]), .nref(rgb_nref), .rgb_pwm(rgb1_pwm), .vccio(vccio), .vref_in(rgb_vref), .vssio(vss_rgb));

endmodule
