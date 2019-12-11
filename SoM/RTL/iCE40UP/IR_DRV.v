`timescale 1ps/1ps
module IR_DRV (IRLEDEN,IRPWM,IRPU,IRLED);

input IRLEDEN,IRPWM,IRPU ;
output IRLED;	  

parameter IR_CURRENT = "0b0000000000"; 
IR_DRV_CORE inst (.IRLED_EN(IRLEDEN),.IR_PWM(IRPWM),.IR_PU(IRPU),.IRLED(IRLED));
defparam inst.IR_CURRENT=IR_CURRENT;


endmodule
