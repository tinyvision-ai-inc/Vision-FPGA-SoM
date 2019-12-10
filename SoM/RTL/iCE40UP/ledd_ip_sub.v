`include "defines4.v"
`timescale 1ns/1ps
module ledd_ip_sub (/*AUTOARG*/
   // Outputs
   pwm_out_r, pwm_out_g, pwm_out_b, ledd_on,
   // Inputs
   ledd_rst_async, ledd_clk, ledd_cs, ledd_den, ledd_adr, ledd_dat,
   ledd_exe
   );

   // INPUTS
   // From full chip POR ...
   input ledd_rst_async;          // Asynchronize Reset, to POR

   // From System Bus
   input ledd_clk;                // LED Control Bus clock

   input ledd_cs;                 // LED Driver IP Chip Select
   input ledd_den;                // LED Control Bus Data Enable

   input [`LEDCBAW-1:0] ledd_adr; // LED Control Bus Address
   input [`LEDCBDW-1:0] ledd_dat; // LED Control Bus Data

   input ledd_exe;                // LED Driver Execute, level sensitive, active High.
   
   // OUTPUTS
   // IO or FPGA Fabric
   output pwm_out_r;
   output pwm_out_g;
   output pwm_out_b;
   
   // To FPGA Fabric
   output ledd_on;
   
   // REGS


   // WIRES
   
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [`LEDCBDW-1:0]	leddbcfr;		// From ledd_sci_inst of ledd_sci.v
   wire [`LEDCBDW-1:0]	leddbcrr;		// From ledd_sci_inst of ledd_sci.v
   wire [`LEDCBDW-1:0]	leddbr;			// From ledd_sci_inst of ledd_sci.v
   wire [`LEDCBDW-1:0]	leddcr0;		// From ledd_sci_inst of ledd_sci.v
   wire [`LEDCBDW-1:0]	leddofr;		// From ledd_sci_inst of ledd_sci.v
   wire [`LEDCBDW-1:0]	leddonr;		// From ledd_sci_inst of ledd_sci.v
   wire [`LEDCBDW-1:0]	leddpwbr;		// From ledd_sci_inst of ledd_sci.v
   wire [`LEDCBDW-1:0]	leddpwgr;		// From ledd_sci_inst of ledd_sci.v
   wire [`LEDCBDW-1:0]	leddpwrr;		// From ledd_sci_inst of ledd_sci.v
   // End of automatics


   // LOGIC
   
   ledd_sci ledd_sci_inst (/*AUTOINST*/
			   // Outputs
			   .leddcr0		(leddcr0[`LEDCBDW-1:0]),
			   .leddbr		(leddbr[`LEDCBDW-1:0]),
			   .leddonr		(leddonr[`LEDCBDW-1:0]),
			   .leddofr		(leddofr[`LEDCBDW-1:0]),
			   .leddbcrr		(leddbcrr[`LEDCBDW-1:0]),
			   .leddbcfr		(leddbcfr[`LEDCBDW-1:0]),
			   .leddpwrr		(leddpwrr[`LEDCBDW-1:0]),
			   .leddpwgr		(leddpwgr[`LEDCBDW-1:0]),
			   .leddpwbr		(leddpwbr[`LEDCBDW-1:0]),
			   // Inputs
			   .ledd_rst_async	(ledd_rst_async),
			   .ledd_clk		(ledd_clk),
			   .ledd_cs		(ledd_cs),
			   .ledd_den		(ledd_den),
			   .ledd_adr		(ledd_adr[`LEDCBAW-1:0]),
			   .ledd_dat		(ledd_dat[`LEDCBDW-1:0]));

   ledd_ctrl ledd_ctrl_inst (/*AUTOINST*/
			     // Outputs
			     .pwm_out_r		(pwm_out_r),
			     .pwm_out_g		(pwm_out_g),
			     .pwm_out_b		(pwm_out_b),
			     .ledd_on		(ledd_on),
			     // Inputs
			     .ledd_rst_async	(ledd_rst_async),
			     .ledd_clk		(ledd_clk),
			     .ledd_exe		(ledd_exe),
			     .leddcr0		(leddcr0[`LEDCBDW-1:0]),
			     .leddbr		(leddbr[`LEDCBDW-1:0]),
			     .leddonr		(leddonr[`LEDCBDW-1:0]),
			     .leddofr		(leddofr[`LEDCBDW-1:0]),
			     .leddbcrr		(leddbcrr[`LEDCBDW-1:0]),
			     .leddbcfr		(leddbcfr[`LEDCBDW-1:0]),
			     .leddpwrr		(leddpwrr[`LEDCBDW-1:0]),
			     .leddpwgr		(leddpwgr[`LEDCBDW-1:0]),
			     .leddpwbr		(leddpwbr[`LEDCBDW-1:0]));


endmodule // ledd_ip_sub
