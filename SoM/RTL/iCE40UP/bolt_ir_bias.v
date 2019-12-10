`timescale 1ns / 10ps 
module bolt_ir_bias ( i200uref, ir_nref, ir_vref_in, barcode_en, cbit_barcode_en, cbit_ir_en, cbit_ir_half_cur, cbit_rgb_en, icc40u, irled_en, poc, rgbled_en, vccio, vssio_ir );
output  i200uref, ir_nref, ir_vref_in;

input  barcode_en, cbit_barcode_en, cbit_ir_en, cbit_ir_half_cur, cbit_rgb_en, icc40u, irled_en, poc, rgbled_en, vccio, vssio_ir;

wire ir_barcode_en = (irled_en & cbit_ir_en) | (barcode_en & cbit_barcode_en);
wire ir_on = !icc40u & ir_barcode_en;

reg ir_vref_in, i200uref;
  
assign ir_nref = 1'b1;
  
always @ (ir_on)
begin
if (ir_on)
	begin
	ir_vref_in <= 1'b1;
	end
else 
	begin
	ir_vref_in <= 1'b0;
	end
end

wire i200u_on = !icc40u & ( ir_barcode_en | (rgbled_en & cbit_rgb_en));

always @ (i200u_on)
begin
if (i200u_on)
	begin
	i200uref <= 1'b1;
	end
else 
	begin
	i200uref <= 1'bz;
	end
end


endmodule
