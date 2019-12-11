`timescale 1ns / 10ps 
module rgbdrive24max3 ( RGB0_DI, RGB1_DI, RGB2_DI, rgb0, rgb1, rgb2, vccio, BSEN, RGB0_DO, RGB0_IE, RGB0_OEN, RGB1_DO, RGB1_IE, RGB1_OEN, RGB2_DO, RGB2_IE, RGB2_OEN, cbit_rgb0, cbit_rgb1, cbit_rgb2, cbit_rgb_en, cbit_rgb_half_cur, i200uref, nor_in, poc, rgb_pwm, rgbled_en );

output  RGB0_DI, RGB1_DI, RGB2_DI;

inout  rgb0, rgb1, rgb2, vccio;

input  BSEN, RGB0_DO, RGB0_IE, RGB0_OEN, RGB1_DO, RGB1_IE, RGB1_OEN, RGB2_DO, RGB2_IE, RGB2_OEN, cbit_rgb_en, cbit_rgb_half_cur, i200uref, nor_in, poc, rgbled_en;

input [2:0]  rgb_pwm;
input [5:0]  cbit_rgb2;
input [5:0]  cbit_rgb1;
input [5:0]  cbit_rgb0;

// List of primary aliased buses



SUMB_bscan_HX8mA_sp I64 ( .POC(poc), .BSEN(BSEN), .OEN(RGB2_OEN), .IE(RGB2_IE), .REN(BSEN), .DO(RGB2_DO), .PAD(rgb2), .DI(RGB2_DI), .VDDIO(vccio), .nor_in(nor_in), .PGATE(net038));
SUMB_bscan_HX8mA_sp I59 ( .POC(poc), .BSEN(BSEN), .OEN(RGB0_OEN), .IE(RGB0_IE), .REN(BSEN), .DO(RGB0_DO), .PAD(rgb0), .DI(RGB0_DI), .VDDIO(vccio), .nor_in(nor_in), .PGATE(net039));
SUMB_bscan_HX8mA_sp I17 ( .POC(poc), .BSEN(BSEN), .OEN(RGB1_OEN), .IE(RGB1_IE), .REN(BSEN), .DO(RGB1_DO), .PAD(rgb1), .DI(RGB1_DI), .VDDIO(vccio), .nor_in(nor_in), .PGATE(net63));
SVSS_sbt_a I76 ( .VDDIO(vccio));
rgb24max3 I43 ( rgb0, rgb1, rgb2, cbit_rgb0, cbit_rgb1, cbit_rgb2, cbit_rgb_en, cbit_rgb_half_cur, i200uref, poc, rgb_pwm, rgbled_en, vccio);

endmodule
