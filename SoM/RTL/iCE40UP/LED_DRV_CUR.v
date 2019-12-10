`timescale 1ps/1ps
module LED_DRV_CUR  ( EN, LEDPU);
input EN;
output LEDPU;

wire powerup;

   assign powerup = (EN === 1'b1) ? 1'b0 : 1'b1; //Constant current source
   buf (LEDPU, powerup) ;

endmodule
