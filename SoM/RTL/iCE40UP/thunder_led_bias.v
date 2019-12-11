`timescale 1ns / 10ps
module thunder_led_bias ( ir_nref, ir_vref_in, rgb_nref, rgb_vref_in, irled_en,
rgbled_en, vccio, cbit_ir_en, cbit_rgb_en, icc40u, poc, vss_rgb, vssio_ir );

input vccio;
input poc;
input icc40u;
input cbit_rgb_en;
input rgbled_en;
output ir_vref_in;
input irled_en;
input cbit_ir_en;
output rgb_vref_in;
output rgb_nref;
output ir_nref;
input vss_rgb;
input vssio_ir;

wire ir_on = !icc40u & irled_en & cbit_ir_en;
wire rgb_on = !icc40u & rgbled_en & cbit_rgb_en;

reg ir_nref, ir_vref_in, rgb_nref, rgb_vref_in;

always @ (ir_on or rgb_on)
begin
    if (ir_on)
        begin
        ir_nref = 1'b1;
        ir_vref_in = 1'b1;
        end
    else
        begin
        ir_nref = 1'b0;
        ir_vref_in = 1'b0;
        end

    if (rgb_on)
        begin
        rgb_nref = 1'b1;
        rgb_vref_in = 1'b1;
        end
    else
        begin
        rgb_nref = 1'b0;
        rgb_vref_in = 1'b0;
        end
end
endmodule
