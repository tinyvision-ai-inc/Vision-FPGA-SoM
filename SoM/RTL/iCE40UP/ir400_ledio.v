`timescale 1ns / 10ps 
module ir400_ledio ( IR_PAD, cbit_ir, ir_pwm, nref, poc, vccio, vref_in, vssio );
output  IR_PAD;

input  ir_pwm, nref, poc, vccio, vref_in, vssio;

input [7:0]  cbit_ir;

// Buses in the design

wire  [7:0]  ng_en;

// List of primary aliased buses


ir400_driver DRV ( .ng_en(ng_en[7:0]), .VSSIO(vssio), .PAD(IR_PAD), .nref(nref));
thunder_ir_predriver  PREDRV_7_ ( .cbit_ir(cbit_ir[7]), .ng_en(ng_en[7]), .poc(poc), .sg11_pwm(ir_pwm), .vccio(vccio), .vref_in(vref_in));
thunder_ir_predriver  PREDRV_6_ ( .cbit_ir(cbit_ir[6]), .ng_en(ng_en[6]), .poc(poc), .sg11_pwm(ir_pwm), .vccio(vccio), .vref_in(vref_in));
thunder_ir_predriver  PREDRV_5_ ( .cbit_ir(cbit_ir[5]), .ng_en(ng_en[5]), .poc(poc), .sg11_pwm(ir_pwm), .vccio(vccio), .vref_in(vref_in));
thunder_ir_predriver  PREDRV_4_ ( .cbit_ir(cbit_ir[4]), .ng_en(ng_en[4]), .poc(poc), .sg11_pwm(ir_pwm), .vccio(vccio), .vref_in(vref_in));
thunder_ir_predriver  PREDRV_3_ ( .cbit_ir(cbit_ir[3]), .ng_en(ng_en[3]), .poc(poc), .sg11_pwm(ir_pwm), .vccio(vccio), .vref_in(vref_in));
thunder_ir_predriver  PREDRV_2_ ( .cbit_ir(cbit_ir[2]), .ng_en(ng_en[2]), .poc(poc), .sg11_pwm(ir_pwm), .vccio(vccio), .vref_in(vref_in));
thunder_ir_predriver  PREDRV_1_ ( .cbit_ir(cbit_ir[1]), .ng_en(ng_en[1]), .poc(poc), .sg11_pwm(ir_pwm), .vccio(vccio), .vref_in(vref_in));
thunder_ir_predriver  PREDRV_0_ ( .cbit_ir(cbit_ir[0]), .ng_en(ng_en[0]), .poc(poc), .sg11_pwm(ir_pwm), .vccio(vccio), .vref_in(vref_in));

endmodule
