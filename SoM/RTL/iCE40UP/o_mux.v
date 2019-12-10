`timescale 10ps/1ps
module o_mux (O, in0, in1, cbit, prog);

//the output signal
output O;

//the input signals
input in0, in1, cbit, prog;

  primit_o_mux (O, in0, in1, cbit, prog);


endmodule // o_mux
