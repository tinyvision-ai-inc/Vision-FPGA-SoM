`timescale 1ns / 10ps
module ir_ledio ( IR_PAD, cbit_ir, ir_pwm, nref, vccio, vref_in, vssio, poc);

input vref_in;
input vccio;
input poc;
input nref;
inout IR_PAD;
input vssio;
input ir_pwm;
input  [9:0] cbit_ir;

wire [9:0] cbit_ir_en;
reg IR_PAD_out;

assign cbit_ir_en[9] = cbit_ir[9] & ir_pwm;
assign cbit_ir_en[8] = cbit_ir[8] & ir_pwm;
assign cbit_ir_en[7] = cbit_ir[7] & ir_pwm;
assign cbit_ir_en[6] = cbit_ir[6] & ir_pwm;
assign cbit_ir_en[5] = cbit_ir[5] & ir_pwm;
assign cbit_ir_en[4] = cbit_ir[4] & ir_pwm;
assign cbit_ir_en[3] = cbit_ir[3] & ir_pwm;
assign cbit_ir_en[2] = cbit_ir[2] & ir_pwm;
assign cbit_ir_en[1] = cbit_ir[1] & ir_pwm;
assign cbit_ir_en[0] = cbit_ir[0] & ir_pwm;

always @ (cbit_ir_en or nref or poc or vref_in)
begin
    if (nref & vref_in & !poc)
        begin
        casez (cbit_ir_en)
        10'b1?????????: IR_PAD_out = 1'b0;
        10'b?1????????: IR_PAD_out = 1'b0;
        10'b??1???????: IR_PAD_out = 1'b0;
        10'b???1??????: IR_PAD_out = 1'b0;
        10'b????1?????: IR_PAD_out = 1'b0;
        10'b?????1????: IR_PAD_out = 1'b0;
        10'b??????1???: IR_PAD_out = 1'b0;
        10'b???????1??: IR_PAD_out = 1'b0;
        10'b????????1?: IR_PAD_out = 1'b0;
        10'b?????????1: IR_PAD_out = 1'b0;
        10'b0000000000: IR_PAD_out = 1'bz;
        endcase
        end

    else
        IR_PAD_out = 1'bz;
end

assign IR_PAD = IR_PAD_out;

endmodule
