`timescale 10ps/1ps
module carry_logic (cout, carry_in, a, a_bar, b, b_bar, vg_en);

//the output signal
output cout;

//the input signals
input carry_in, a, a_bar, b, b_bar, vg_en;

  
  primit_carry_logic (cout, vg_en, carry_in, a, b );

endmodule // carry_logic
