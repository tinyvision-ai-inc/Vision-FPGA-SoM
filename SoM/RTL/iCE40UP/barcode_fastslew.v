`timescale 1ns / 10ps 
module barcode_fastslew ( ng_en, vref_out, VCCIO, barcode_pwm, cbit_ir500, poc,
vref_in );


output  vref_out;

input  VCCIO, barcode_pwm, cbit_ir500, poc, vref_in;

output [3:0]  ng_en;

assign vref_out = vref_in;

wire ng_sel = !(barcode_pwm | cbit_ir500);

assign ng_en = ng_sel? 4'b0 : 4'bz;


endmodule
