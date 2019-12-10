`include "defines5.v"
`timescale 1ns/1ps
module irtcv_ip (/*AUTOARG*/
   // Outputs
   ir_out, irtcv_busy, irtcv_drdy, irtcv_err, irtcv_rdat,
   // Inputs
   irtcv_rst_async, irtcv_clk, irtcv_cs, irtcv_we, irtcv_den,
   irtcv_adr, irtcv_wdat, irtcv_exe, irtcv_learn, ir_in
   );

   // INPUTS
   // From full chip POR ...
   input irtcv_rst_async;           // Asynchronize Reset, to POR

   // From System Bus
   input irtcv_clk;                 // IR Transceiver Control Bus clock

   input irtcv_cs;                  // IR Transceiver IP Chip Select
   input irtcv_we;                  // IR Transceiver Control Bus Write Enable
   input irtcv_den;                 // IR Transceiver Control Bus Data Enable

   input [`IRTCVCBAW-1:0] irtcv_adr;  // IR Transceiver Control Bus Address
   input [`IRTCVCBDW-1:0] irtcv_wdat; // IR Transceiver Control Bus Data

   input irtcv_exe;                   // IR Transceiver Execute, level sensitive, active High.
   input irtcv_learn;                 // IR Transceiver Learning mode; Level sensitive

   // From IR Sensor
   input ir_in;                       // IR Seneor Input
   
   // OUTPUTS
   // IO or FPGA Fabric
   output ir_out;
   
   // To FPGA Fabric
   output irtcv_busy;                 // IR Transceiver BUSY
   output irtcv_drdy;                 // IR Transceiver Data ReaDY
   output irtcv_err;                  // IR Transceiver ERRor

   output [`IRTCVCBDW-1:0] irtcv_rdat; // IR Transceiver Data Register
   
   // REGS


   // WIRES
   
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [`IRSYSFRW-1:0]	irsysfr;		// From irtcv_sci_inst of irtcv_sci.v
   wire [`IRTCVDRW-1:0]	irtcv_dbuf_dat;		// From irtcv_ctrl_inst of irtcv_ctrl.v
   wire			irtcv_dbuf_upd;		// From irtcv_ctrl_inst of irtcv_ctrl.v
   wire [`IRTCVFRW-1:0]	irtcv_rfreq_dat;	// From irtcv_ctrl_inst of irtcv_ctrl.v
   wire			irtcv_rfreq_upd;	// From irtcv_ctrl_inst of irtcv_ctrl.v
   wire [`IRTCVCBDW-1:0] irtcvcr;		// From irtcv_sci_inst of irtcv_sci.v
   wire			irtcvcr_wt;		// From irtcv_sci_inst of irtcv_sci.v
   wire [`IRTCVDRW-1:0]	irtcvdr;		// From irtcv_sci_inst of irtcv_sci.v
   wire			irtcvdr_rd;		// From irtcv_sci_inst of irtcv_sci.v
   wire			irtcvdr_wt;		// From irtcv_sci_inst of irtcv_sci.v
   wire [`IRTCVFRW-1:0]	irtcvfr;		// From irtcv_sci_inst of irtcv_sci.v
   wire			irtcvfr_rd;		// From irtcv_sci_inst of irtcv_sci.v
   wire			irtcvfr_wt;		// From irtcv_sci_inst of irtcv_sci.v
   wire [`IRTCVCBDW-1:0] irtcvsr;		// From irtcv_ctrl_inst of irtcv_ctrl.v
   // End of automatics


   // LOGIC
   
   irtcv_sci irtcv_sci_inst (/*AUTOINST*/
			     // Outputs
			     .irtcvcr		(irtcvcr[`IRTCVCBDW-1:0]),
			     .irsysfr		(irsysfr[`IRSYSFRW-1:0]),
			     .irtcvfr		(irtcvfr[`IRTCVFRW-1:0]),
			     .irtcvdr		(irtcvdr[`IRTCVDRW-1:0]),
			     .irtcvcr_wt	(irtcvcr_wt),
			     .irtcvfr_wt	(irtcvfr_wt),
			     .irtcvfr_rd	(irtcvfr_rd),
			     .irtcvdr_wt	(irtcvdr_wt),
			     .irtcvdr_rd	(irtcvdr_rd),
			     .irtcv_rdat	(irtcv_rdat[`IRTCVCBDW-1:0]),
			     // Inputs
			     .irtcv_rst_async	(irtcv_rst_async),
			     .irtcv_clk		(irtcv_clk),
			     .irtcv_cs		(irtcv_cs),
			     .irtcv_we		(irtcv_we),
			     .irtcv_den		(irtcv_den),
			     .irtcv_adr		(irtcv_adr[`IRTCVCBAW-1:0]),
			     .irtcv_wdat	(irtcv_wdat[`IRTCVCBDW-1:0]),
			     .irtcvsr		(irtcvsr[`IRTCVCBDW-1:0]),
			     .irtcv_rfreq_dat	(irtcv_rfreq_dat[`IRTCVFRW-1:0]),
			     .irtcv_rfreq_upd	(irtcv_rfreq_upd),
			     .irtcv_dbuf_dat	(irtcv_dbuf_dat[`IRTCVDRW-1:0]),
			     .irtcv_dbuf_upd	(irtcv_dbuf_upd));

   irtcv_ctrl irtcv_ctrl_inst (/*AUTOINST*/
			       // Outputs
			       .ir_out		(ir_out),
			       .irtcv_busy	(irtcv_busy),
			       .irtcv_drdy	(irtcv_drdy),
			       .irtcv_err	(irtcv_err),
			       .irtcvsr		(irtcvsr[`IRTCVCBDW-1:0]),
			       .irtcv_rfreq_dat	(irtcv_rfreq_dat[`IRTCVFRW-1:0]),
			       .irtcv_rfreq_upd	(irtcv_rfreq_upd),
			       .irtcv_dbuf_dat	(irtcv_dbuf_dat[`IRTCVDRW-1:0]),
			       .irtcv_dbuf_upd	(irtcv_dbuf_upd),
			       // Inputs
			       .irtcv_rst_async	(irtcv_rst_async),
			       .irtcv_clk	(irtcv_clk),
			       .irtcv_exe	(irtcv_exe),
			       .irtcv_learn	(irtcv_learn),
			       .ir_in		(ir_in),
			       .irtcvcr		(irtcvcr[`IRTCVCBDW-1:0]),
			       .irsysfr		(irsysfr[`IRSYSFRW-1:0]),
			       .irtcvfr		(irtcvfr[`IRTCVFRW-1:0]),
			       .irtcvdr		(irtcvdr[`IRTCVDRW-1:0]),
			       .irtcvcr_wt	(irtcvcr_wt),
			       .irtcvfr_wt	(irtcvfr_wt),
			       .irtcvfr_rd	(irtcvfr_rd),
			       .irtcvdr_wt	(irtcvdr_wt),
			       .irtcvdr_rd	(irtcvdr_rd));


endmodule // irtcv_ip
