`timescale 1ns / 10ps 
module rgb24max3 ( rgb0, rgb1, rgb2, cbit_rgb0, cbit_rgb1, cbit_rgb2, cbit_rgb_en, cbit_rgb_half_cur, i200uref, poc, rgb_pwm, rgbled_en, vccio );
output  rgb0, rgb1, rgb2;

input  cbit_rgb_en, cbit_rgb_half_cur, i200uref, poc, rgbled_en, vccio;

input [5:0]  cbit_rgb1;
input [5:0]  cbit_rgb2;
input [2:0]  rgb_pwm;
input [5:0]  cbit_rgb0;

// List of primary aliased buses



rgb_ledio RGB0 ( .poc(poc), .RGB_PAD(rgb0), .cbit_rgb(cbit_rgb0[5:0]), .nref(rgb_nref), .rgb_pwm(rgb_pwm[0]), .vccio(vccio), .vref_in(rgb_vref), .vssio(vss_));
rgb_ledio RGB2 ( .poc(poc), .RGB_PAD(rgb2), .cbit_rgb(cbit_rgb2[5:0]), .nref(rgb_nref), .rgb_pwm(rgb_pwm[2]), .vccio(vccio), .vref_in(rgb_vref), .vssio(vss_));
rgb_ledio RGB1 ( .poc(poc), .RGB_PAD(rgb1), .cbit_rgb(cbit_rgb1[5:0]), .nref(rgb_nref), .rgb_pwm(rgb_pwm[1]), .vccio(vccio), .vref_in(rgb_vref), .vssio(vss_));
bolt_rgb_bias RGB_BIAS ( .cbit_rgb_half_cur(cbit_rgb_half_cur), .i200uref(i200uref), .poc(poc), .cbit_rgb_en(cbit_rgb_en), .rgb_nref(rgb_nref), .rgb_vref_in(rgb_vref), .rgbled_en(rgbled_en), .vccio(vccio));

endmodule
