`timescale 1ns / 10ps 
module bolt_rgb_bias ( rgb_nref, rgb_vref_in, cbit_rgb_en, cbit_rgb_half_cur, i200uref, poc, rgbled_en, vccio );
output  rgb_nref, rgb_vref_in;

input  cbit_rgb_en, cbit_rgb_half_cur, i200uref, poc, rgbled_en, vccio;

wire rgb_on = rgbled_en & cbit_rgb_en & i200uref;

reg rgb_vref_in;

assign rgb_nref = 1'b1;

always @ (rgb_on)
begin
	if (rgb_on)
		begin
		//rgb_nref <= 1'b1;
		rgb_vref_in <= 1'b1;
		end
	else 
		begin
		//rgb_nref <= 1'b0;
		rgb_vref_in <= 1'b0;
		end 
end

endmodule
