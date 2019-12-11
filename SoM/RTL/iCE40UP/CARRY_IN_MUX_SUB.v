`timescale 1ps/1ps
module CARRY_IN_MUX_SUB (carry_init_out, carry_init_in);
   parameter C_INIT = 2'b00;  //c[1:0]
output carry_init_out;
input carry_init_in;
wire [1:0] select_bits;
reg carry_init_out;
assign select_bits = {C_INIT};
   always @ (select_bits or carry_init_in)
      case (select_bits)
         2'b00 :  carry_init_out = 1'b0;
         2'b01 :  carry_init_out = 1'b1;
         2'b10 :  carry_init_out = carry_init_in;
//         2'b11 :  carry_init_out = carry_init_in;
         default  : carry_init_out = 1'b0;
      endcase

endmodule
