`timescale 1ps/1ps
module RGBA_DRV(RGB0, RGB0PWM, RGB1, RGB1PWM, RGB2, RGB2PWM, CURREN, RGBLEDEN, TRIM9, TRIM8, TRIM7, TRIM6, TRIM5, TRIM4, TRIM3, TRIM2, TRIM1, TRIM0); 

// *** Input to UUT ***
input            RGB0PWM;
 input            RGB1PWM;
 input            RGB2PWM;
 input            CURREN;
 input            RGBLEDEN;
 input            TRIM9;
 input            TRIM8;
 input            TRIM7;
 input            TRIM6;
 input            TRIM5;
 input            TRIM4;
 input            TRIM3;
 input            TRIM2;
 input            TRIM1;
 input            TRIM0;

// *** Inouts to UUT ***

// *** Outputs from UUT ***
output            RGB0;
 output            RGB1;
 output            RGB2;

parameter          CURRENT_MODE= 0;
 parameter          RGB0_CURRENT= 6'b000000;
 parameter          RGB1_CURRENT= 6'b000000;
 parameter          RGB2_CURRENT= 6'b000000;
parameter FABRIC_TRIME = "DISABLE";

//** Instantiate the  module **
RGBA_DRV_CORE  #(.CURRENT_MODE(CURRENT_MODE), .RGB0_CURRENT(RGB0_CURRENT), .RGB1_CURRENT(RGB1_CURRENT), .RGB2_CURRENT(RGB2_CURRENT))
 inst_RGBA_DRV    (
                      .RGB0PWM (RGB0PWM),
                      .RGB1PWM (RGB1PWM),
                      .RGB2PWM (RGB2PWM),
                      .CURREN (CURREN),
                      .RGBLEDEN (RGBLEDEN),

                      .RGB0 (RGB0),
                      .RGB1 (RGB1),
                      .RGB2 (RGB2));


endmodule
