`include "defines4.v"
`timescale 1ns/1ps
module ledd_pwmc (/*AUTOARG*/
   // Outputs
   ledd_pwmout,
   // Inputs
   ledd_rst_async, ledd_clk, ledd_on_pwm, ledd_frsel, ledd_lfsr,
   ledd_bcmd, ledd_extend, leddst_breath, mult_rst, mult_run,
   mult_cap, accum_rst, accum_pst, accum_frz, accum_add_all,
   accum_sub, ledd_pwmcnt, ledd_pwmval
   );

   // INPUTS
   // From full chip POR ...
   input ledd_rst_async;          // Asynchronize Reset, to POR

   // From System Bus
   input ledd_clk;                // LED Control Bus clock

   // From LEDD CTRL
   input ledd_on_pwm;
   input ledd_frsel;
   input ledd_lfsr;
   input ledd_bcmd;
   input ledd_extend;
   input leddst_breath;
   
   input mult_rst, mult_run, mult_cap;
   input accum_rst, accum_pst, accum_frz, accum_add_all, accum_sub;
   
   input [`LEDDPWW-1:0] ledd_pwmcnt;
   input [`LEDDPWW-1:0] ledd_pwmval;

   // OUTPUTS
   // IO or FPGA Fabric
   output ledd_pwmout;
   
   // REGS
   reg [16:0] accum;
   reg [15:0] step;
   
   reg 	      ledd_pwmout;

   // WIRES
   wire [`LEDDPWW-1:0] ledd_pwmdest;
   wire [`LEDDPWW-1:0] ledd_caldest;
   wire [`LEDDPWW-1:0] accum_pwmval, accum_dest;

   // LOGIC
   
   // Step Size Calculation
   wire [16:0] accum_pst_val = ledd_frsel ? {{8{1'b1}}, {9{1'b0}}} : {1'b0, {8{1'b1}}, {8{1'b0}}};    // PSE
   wire [16:0] accum_frz_val = ledd_frsel ? {ledd_pwmval, {9{1'b0}}} : {1'b0, ledd_pwmval, {8{1'b0}}};
   wire [17:0] accum_add_val = accum + step;                                                          // PSE
   wire [17:0] accum_sub_val = accum - step;                                                          // PSE

   wire        accum_add_cap = ledd_frsel ? accum_add_val[17] : accum_add_val[16];
   wire        accum_sub_cap = ledd_frsel ? accum_sub_val[17] : accum_sub_val[16];
   
   always @(posedge ledd_clk or posedge ledd_rst_async)
     begin
	if (ledd_rst_async)     accum <= {17{1'b0}};
	else if (accum_rst)     accum <= {17{1'b0}};
	else if (accum_pst)     accum <= accum_pst_val;                                            // PSE
	else if (accum_frz)     accum <= accum_frz_val;
	else if (accum_add_all) accum <= accum_add_cap ? accum : accum_add_val[16:0];              // PSE
	else if (accum_sub)     accum <= accum_sub_cap ? accum : accum_sub_val[16:0];              // PSE
	else                    accum <= accum;
     end

   assign ledd_caldest = ledd_bcmd ? ledd_pwmval : {8{1'b1}};
   always @(posedge ledd_clk or posedge ledd_rst_async)
     begin
	if (ledd_rst_async) step <= {16{1'b0}};
	else if (mult_rst)  step <= {{8{1'b0}}, ledd_caldest};
	else if (mult_run)  step <= {step[14:0], 1'b0};
	else if (mult_cap)  step <= {{4{1'b0}}, accum[15:4]};
     end

   // LED Driver PWM Output Register
   assign accum_pwmval = ledd_frsel ? accum[16:9] : accum[15:8];
   assign accum_dest   = (accum_pwmval < ledd_pwmval) ? accum_pwmval : ledd_pwmval;
   
   assign ledd_pwmdest = leddst_breath ? accum_dest : ledd_pwmval;

   // wire ledd_pwmout_val = ledd_lfsr ? (ledd_pwmcnt <= ledd_pwmdest) : (ledd_pwmcnt < ledd_pwmdest) | (ledd_extend & (&ledd_pwmval));
   wire ledd_pwmout_val = (ledd_pwmcnt < ledd_pwmdest) | (ledd_extend & (&accum_dest));
   always @(posedge ledd_clk or posedge ledd_rst_async)
     if (ledd_rst_async)   ledd_pwmout <= 1'b0;
     else if (ledd_on_pwm) ledd_pwmout <= ledd_pwmout_val;
     else                  ledd_pwmout <= 1'b0;

endmodule // ledd_pwmc
