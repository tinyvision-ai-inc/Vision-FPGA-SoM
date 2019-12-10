`timescale 1 ns / 1 ps
module sci_int_reg(/*AUTOARG*/
   // Outputs
   status,
   // Inputs
   rst_async, sb_clk_i, int_force, int_set, int_clr, scan_test_mode
   );

   // INPUTS
   input rst_async;
   input sb_clk_i;
   input int_force;
   input int_set;
   input int_clr;
   input scan_test_mode;

   // OUTPUTS
   output status;

   // REGISTERS
   reg    status;

   // WIRES
   wire   int_clk;      // either the set signal or forceint
   wire   int_rsta; // asynchronous reset or clear on write
   wire   int_sts;      // value to set (normally=1 scan mode = (set|forceint)

  assign int_clk  = scan_test_mode ? sb_clk_i : (int_set ^ int_force);
  assign int_sts  = scan_test_mode ?((int_set | int_force) & ~int_clr): 1;
  assign int_rsta = scan_test_mode ? rst_async : (int_clr | rst_async );

  ///////////////////////////////////////////////
  // D flip-flop captures interruptable events //
  always @(posedge int_clk or posedge int_rsta)
    if (int_rsta) status <= 1'b0;
    else          status <= int_sts;

endmodule //sci_int_reg
