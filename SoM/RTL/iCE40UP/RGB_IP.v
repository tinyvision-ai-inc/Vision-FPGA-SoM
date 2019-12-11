`timescale 1ps/1ps
module RGB_IP ( 
CLK,RST,PARAMSOK,RGBCOLOR,BRIGHTNESS,BREATHRAMP,BLINKRATE,REDPWM,GREENPWM,BLUEPWM
); 
	input CLK; 
	input RST; 			
	input PARAMSOK; 
	input [3:0]  RGBCOLOR; 
	input [3:0] BRIGHTNESS; 
	input [3:0]BREATHRAMP; 
	input [3:0] BLINKRATE; 
	output REDPWM; 
	output GREENPWM; 
	output BLUEPWM;

LED_control RGBPWMinst (
       .clk27M(CLK),        
       .rst(RST),           
       .params_ok(PARAMSOK),     
       .RGB_color(RGBCOLOR),     
       .Brightness(BRIGHTNESS),    
       .BreatheRamp(BREATHRAMP),   
       .BlinkRate(BLINKRATE),     
       .red_pwm (REDPWM),       
       .grn_pwm(GREENPWM),       
       .blu_pwm(BLUEPWM)        
        );


endmodule 
