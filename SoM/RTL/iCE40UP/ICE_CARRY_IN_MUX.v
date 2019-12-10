`timescale 10ps/1ps
module ICE_CARRY_IN_MUX (carryinitout, carryinitin);
   parameter C_INIT = 2'b00;  //c[1:0]
output carryinitout;
input carryinitin;
wire [1:0] select_bits;
reg carryinitout;
assign select_bits = {C_INIT};
   always @ (select_bits or carryinitin)
      case (select_bits)
         2'b00 :  carryinitout = 1'b0;
         2'b01 :  carryinitout = 1'b1;
         2'b10 :  carryinitout = carryinitin;
//         2'b11 :  carry_init_out = carry_init_in;
         default  : carryinitout = 1'b0;
      endcase

endmodule
