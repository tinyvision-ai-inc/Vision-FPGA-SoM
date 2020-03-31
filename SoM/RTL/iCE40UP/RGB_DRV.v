`timescale 1ps/1ps
module RGB_DRV (RGBLEDEN,RGB0PWM, RGB1PWM ,RGB2PWM, RGBPU, RGB0, RGB1, RGB2 );
input  RGBLEDEN,RGB0PWM, RGB1PWM ,RGB2PWM, RGBPU;
output   RGB0, RGB1, RGB2; 
parameter RGB0_CURRENT = "0b000000";
parameter RGB1_CURRENT = "0b000000";
parameter RGB2_CURRENT = "0b000000";
parameter FABRIC_TRIME = "DISABLE";
RGB_DRV_CORE inst (.RGBLED_EN(RGBLEDEN ),.RGB0_PWM( RGB0PWM), .RGB1_PWM (RGB1PWM ),.RGB2_PWM(RGB2PWM ), .RGB_PU( RGBPU), .RGB0( RGB0), .RGB1( RGB1), .RGB2(RGB2));
defparam inst.RGB0_CURRENT= RGB0_CURRENT;
defparam inst.RGB1_CURRENT= RGB1_CURRENT;
defparam inst.RGB2_CURRENT= RGB2_CURRENT;	


endmodule