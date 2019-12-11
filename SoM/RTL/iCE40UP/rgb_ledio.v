`timescale 1ns / 10ps
module rgb_ledio ( RGB_PAD, cbit_rgb, nref, rgb_pwm, vccio, vref_in, vssio, poc );

input vref_in;
input vccio;
input poc;
input nref;
input vssio;
inout RGB_PAD;
input  [5:0] cbit_rgb;
input rgb_pwm;

wire [5:0] cbit_rgb_en;
reg RGB_PAD_out;

assign cbit_rgb_en[5] = cbit_rgb[5] & rgb_pwm;
assign cbit_rgb_en[4] = cbit_rgb[4] & rgb_pwm;
assign cbit_rgb_en[3] = cbit_rgb[3] & rgb_pwm;
assign cbit_rgb_en[2] = cbit_rgb[2] & rgb_pwm;
assign cbit_rgb_en[1] = cbit_rgb[1] & rgb_pwm;
assign cbit_rgb_en[0] = cbit_rgb[0] & rgb_pwm;

always @ (cbit_rgb_en or nref or poc or vref_in)
begin
    if (nref & vref_in & !poc)
        begin
        casez (cbit_rgb_en)
        6'b1?????: RGB_PAD_out = 1'b0;
        6'b?1????: RGB_PAD_out = 1'b0;
        6'b??1???: RGB_PAD_out = 1'b0;
        6'b???1??: RGB_PAD_out = 1'b0;
        6'b????1?: RGB_PAD_out = 1'b0;
        6'b?????1: RGB_PAD_out = 1'b0;
        6'b000000: RGB_PAD_out = 1'bz;
        endcase
        end

    else
        RGB_PAD_out = 1'bz;

end

assign RGB_PAD = RGB_PAD_out;

endmodule
