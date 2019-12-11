`timescale 1ns / 10ps 
module thunder_ir_predriver ( ng_en, cbit_ir, sg11_pwm, vccio, vref_in, poc
);

output  ng_en;

input  cbit_ir, poc, sg11_pwm, vccio, vref_in;

reg ng_en;

wire sg11_pwn_int = sg11_pwm & cbit_ir;

lvshifter  LVS ( .POC(poc), .A(sg11_pwn_int), .AOB(sgio_pwm_n), .AO(sgio_pwm), .VDDIO(vccio));

always @ (sg11_pwm or cbit_ir or vref_in or sgio_pwm)

begin
	if (sgio_pwm & !poc)
		ng_en <= vref_in;
	else 
		ng_en <= 1'b0;
end

endmodule
