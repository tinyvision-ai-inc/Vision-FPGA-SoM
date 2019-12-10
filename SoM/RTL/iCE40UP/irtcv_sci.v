`include "defines5.v"
`timescale 1ns/1ps
module irtcv_sci (/*AUTOARG*/
   // Outputs
   irtcvcr, irsysfr, irtcvfr, irtcvdr, irtcvcr_wt, irtcvfr_wt,
   irtcvfr_rd, irtcvdr_wt, irtcvdr_rd, irtcv_rdat,
   // Inputs
   irtcv_rst_async, irtcv_clk, irtcv_cs, irtcv_we, irtcv_den,
   irtcv_adr, irtcv_wdat, irtcvsr, irtcv_rfreq_dat, irtcv_rfreq_upd,
   irtcv_dbuf_dat, irtcv_dbuf_upd
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

   // From IRTCV CONTROL
   input [`IRTCVCBDW-1:0] irtcvsr;    // IR Transceiver Status Data

   input [`IRTCVFRW-1:0]  irtcv_rfreq_dat;  // Calculated Result for Received Frequency
   input 		  irtcv_rfreq_upd;  // Calculated Received Frequency Update
   
   input [`IRTCVDRW-1:0]  irtcv_dbuf_dat;   // Received Data
   input 		  irtcv_dbuf_upd;   // Reveived Data Update
   
   // OUTPUTS
   // IRTCV CTRL Unit
   output [`IRTCVCBDW-1:0] irtcvcr;    // IR Transceiver Control Register
   output [`IRSYSFRW-1:0]  irsysfr;    // IR Transceiver System Clock Frequency Register
   output [`IRTCVFRW-1:0]  irtcvfr;    // IR Transceiver Clock Frequency Register
   output [`IRTCVDRW-1:0]  irtcvdr;    // IR Transceiver Data Register

   output 		   irtcvcr_wt; // IR Transceiver Control Register Written
   output 		   irtcvfr_wt; // IR Transceiver Clock Frequency Register Written (Byte0)
   output                  irtcvfr_rd; // IR Transceiver Clock Frequency Register Read (Byte0)
   output 		   irtcvdr_wt; // IR Transceiver Data Register Written (Byte0)
   output 		   irtcvdr_rd; // IR Transceiver Data Register Read (Byte0)
   
   // To FPGA Fabric
   // output irtcv_ack;
   output [`IRTCVCBDW-1:0] irtcv_rdat; // IR Transceiver Data Register

   // PARAMETERS
   parameter IRSYSFR3W = (`IRSYSFRW-(3*`IRTCVCBDW));    // 28-3*24 
   
   // REGS
   // reg ack_reg;                   // Acknowledge Generation.
   // reg irtcv_we_dly;              // Delay WE signal for hold time in case of racing with clk. 
   
   reg [`IRTCVCBDW-1:0] irtcvcr;     // IR Transceiver Control Register
   reg [IRSYSFR3W-1:0]  irsysfr3;    // IR Transceiver System Clock Frequency Register 3
   reg [`IRTCVCBDW-1:0] irsysfr2;    // IR Transceiver System Clock Frequency Register 2
   reg [`IRTCVCBDW-1:0] irsysfr1;    // IR Transceiver System Clock Frequency Register 1
   reg [`IRTCVCBDW-1:0] irsysfr0;    // IR Transceiver System Clock Frequency Register 0
   reg [`IRTCVCBDW-1:0] irtcvfr2;    // IR Transceiver Line Clock Frequency Register 2
   reg [`IRTCVCBDW-1:0] irtcvfr1;    // IR Transceiver Line Clock Frequency Register 1
   reg [`IRTCVCBDW-1:0] irtcvfr0;    // IR Transceiver Line Clock Frequency Register 0
   reg [`IRTCVCBDW-1:0] irtcvdr1;    // IR Transceiver Data Register 1
   reg [`IRTCVCBDW-1:0] irtcvdr0;    // IR Transceiver Data Register 0

   reg [`IRTCVCBDW-1:0] rdmux_dat;   // IR Transceiver Read back data mux
   reg [`IRTCVCBDW-1:0] irtcv_rdat;  // IR Transceiver Read back data
   
   // WIRES
   wire ip_stb, ip_wstb, ip_rstb;

   wire irtcvcr_match;
   wire irsysfr3_match, irsysfr2_match, irsysfr1_match, irsysfr0_match;
   wire irtcvfr2_match, irtcvfr1_match, irtcvfr0_match;
   wire irtcvdr1_match, irtcvdr0_match;
   wire irtcvsr_match;
   
   /*AUTOWIRE*/


   // LOGIC
   // Could help to reduece the WE timing requirement with ACK around
   // always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
   //    if (irtcv_rst_async) irtcv_we_dly <= 1'b0;
   //    else                 irtcv_we_dly <= irtcv_we;
   // end

   assign ip_stb = irtcv_den;
   // assign ip_wstb = (irtcv_we | irtcv_we_dly) & ip_stb;    // WE Delay
   assign ip_wstb =  irtcv_we & ip_stb;                       // NO WE Delay
   assign ip_rstb = ~irtcv_we & ip_stb;
   
   assign irtcvcr_match   = irtcv_cs & (irtcv_adr[3:0] == `ADDR_IRTCVCR);
   assign irsysfr3_match  = irtcv_cs & (irtcv_adr[3:0] == `ADDR_IRSYSFR3);
   assign irsysfr2_match  = irtcv_cs & (irtcv_adr[3:0] == `ADDR_IRSYSFR2);
   assign irsysfr1_match  = irtcv_cs & (irtcv_adr[3:0] == `ADDR_IRSYSFR1);
   assign irsysfr0_match  = irtcv_cs & (irtcv_adr[3:0] == `ADDR_IRSYSFR0);
   assign irtcvfr2_match  = irtcv_cs & (irtcv_adr[3:0] == `ADDR_IRTCVFR2);
   assign irtcvfr1_match  = irtcv_cs & (irtcv_adr[3:0] == `ADDR_IRTCVFR1);
   assign irtcvfr0_match  = irtcv_cs & (irtcv_adr[3:0] == `ADDR_IRTCVFR0);
   assign irtcvdr1_match  = irtcv_cs & (irtcv_adr[3:0] == `ADDR_IRTCVDR1);
   assign irtcvdr0_match  = irtcv_cs & (irtcv_adr[3:0] == `ADDR_IRTCVDR0);

   assign irtcvsr_match   = irtcv_cs & (irtcv_adr[3:0] == `ADDR_IRTCVSR);
   
   // Not needed for Service IR Transceiver, just in case
   // wire irtcvall_match = irtcvcr_match | irsysfr3_match | irsysfr2_match | irsysfr1_match |
   //                       irsysfr0_match | irtcvfr2_match | irtcvfr1_match | irtcvfr0_match |
   //                       irtcvdr1_match | irtcvdr0_match;
   // wire ip_stb_all = (ip_wstb & irtcvall_match) | (ip_rstb & irtcvsr_match);
   // always @(posedge irtcv_clk or posedge irtcv_rst_async)
   //   if (irtcv_rst_async) ack_reg <= 1'b0;
   //   else                 ack_reg <= ip_stb_all;
   // 
   // assign irtcv_ack = irtcv_den & ack_reg;

   // System Bus Addressable Registers
   // IRTCVCR
   wire wena_irtcvcr = ip_wstb & irtcvcr_match;
   assign irtcvcr_wt = wena_irtcvcr;
   always @(posedge irtcv_clk or posedge irtcv_rst_async)
     if (irtcv_rst_async)   irtcvcr <= `DEFAULT_IRTCVCR;
     else if (wena_irtcvcr) irtcvcr <= irtcv_wdat;
     else                   irtcvcr <= irtcvcr;

   // IRSYSFRs
   wire wena_irsysfr3 = ip_wstb & irsysfr3_match;
   always @(posedge irtcv_clk or posedge irtcv_rst_async)
     if (irtcv_rst_async)    irsysfr3 <= {IRSYSFR3W{1'b0}};
     else if (wena_irsysfr3) irsysfr3 <= irtcv_wdat[IRSYSFR3W-1:0];
     else                    irsysfr3 <= irsysfr3;

   wire wena_irsysfr2 = ip_wstb & irsysfr2_match;
   always @(posedge irtcv_clk or posedge irtcv_rst_async)
     if (irtcv_rst_async)    irsysfr2 <= {`IRTCVCBDW{1'b0}};
     else if (wena_irsysfr2) irsysfr2 <= irtcv_wdat;
     else                    irsysfr2 <= irsysfr2;

   wire wena_irsysfr1 = ip_wstb & irsysfr1_match;
   always @(posedge irtcv_clk or posedge irtcv_rst_async)
     if (irtcv_rst_async)    irsysfr1 <= {`IRTCVCBDW{1'b0}};
     else if (wena_irsysfr1) irsysfr1 <= irtcv_wdat;
     else                    irsysfr1 <= irsysfr1;

   wire wena_irsysfr0 = ip_wstb & irsysfr0_match;
   always @(posedge irtcv_clk or posedge irtcv_rst_async)
     if (irtcv_rst_async)    irsysfr0 <= {`IRTCVCBDW{1'b0}};
     else if (wena_irsysfr0) irsysfr0 <= irtcv_wdat;
     else                    irsysfr0 <= irsysfr0;

   assign irsysfr = {irsysfr3, irsysfr2, irsysfr1, irsysfr0};
   
   // IRTCVFRs
   wire wena_irtcvfr2 = ip_wstb & irtcvfr2_match;
   always @(posedge irtcv_clk or posedge irtcv_rst_async)
     if (irtcv_rst_async)      irtcvfr2 <= {`IRTCVCBDW{1'b0}};
     else if (wena_irtcvfr2)   irtcvfr2 <= irtcv_wdat;
     else if (irtcv_rfreq_upd) irtcvfr2 <= irtcv_rfreq_dat[3*`IRTCVCBDW-1:2*`IRTCVCBDW];
     else                      irtcvfr2 <= irtcvfr2;

   wire wena_irtcvfr1 = ip_wstb & irtcvfr1_match;
   always @(posedge irtcv_clk or posedge irtcv_rst_async)
     if (irtcv_rst_async)      irtcvfr1 <= {`IRTCVCBDW{1'b0}};
     else if (wena_irtcvfr1)   irtcvfr1 <= irtcv_wdat;
     else if (irtcv_rfreq_upd) irtcvfr1 <= irtcv_rfreq_dat[2*`IRTCVCBDW-1:`IRTCVCBDW];
     else                      irtcvfr1 <= irtcvfr1;

   wire wena_irtcvfr0 = ip_wstb & irtcvfr0_match;
   assign irtcvfr_wt  = wena_irtcvfr0;
   always @(posedge irtcv_clk or posedge irtcv_rst_async)
     if (irtcv_rst_async)      irtcvfr0 <= {`IRTCVCBDW{1'b0}};
     else if (wena_irtcvfr0)   irtcvfr0 <= irtcv_wdat;
     else if (irtcv_rfreq_upd) irtcvfr0 <= irtcv_rfreq_dat[`IRTCVCBDW-1:0];
     else                      irtcvfr0 <= irtcvfr0;

   assign irtcvfr = {irtcvfr2, irtcvfr1, irtcvfr0};
   
   // IRTCVDRs
   wire wena_irtcvdr1 = ip_wstb & irtcvdr1_match;
   always @(posedge irtcv_clk or posedge irtcv_rst_async)
     if (irtcv_rst_async)     irtcvdr1 <= {`IRTCVCBDW{1'b0}};
     else if (wena_irtcvdr1)  irtcvdr1 <= irtcv_wdat;
     else if (irtcv_dbuf_upd) irtcvdr1 <= irtcv_dbuf_dat[2*`IRTCVCBDW-1:`IRTCVCBDW];
     else                     irtcvdr1 <= irtcvdr1;

   wire wena_irtcvdr0 = ip_wstb & irtcvdr0_match;
   assign irtcvdr_wt  = wena_irtcvdr0;
   always @(posedge irtcv_clk or posedge irtcv_rst_async)
     if (irtcv_rst_async)     irtcvdr0 <= {`IRTCVCBDW{1'b0}};
     else if (wena_irtcvdr0)  irtcvdr0 <= irtcv_wdat;
     else if (irtcv_dbuf_upd) irtcvdr0 <= irtcv_dbuf_dat[`IRTCVCBDW-1:0];
     else                     irtcvdr0 <= irtcvdr0;

   assign irtcvdr = {irtcvdr1, irtcvdr0};
   
   // irtcv_rdat MUX
   // always @(/*AUTOSENSE*/`IRTCVCBDW or irtcvdr0 or irtcvdr0_match
   always @(irtcvdr0 or irtcvdr0_match
	    or irtcvdr1 or irtcvdr1_match or irtcvfr0
	    or irtcvfr0_match or irtcvfr1 or irtcvfr1_match
	    or irtcvfr2 or irtcvfr2_match or irtcvsr or irtcvsr_match)
     begin
      case ({irtcvfr2_match, irtcvfr1_match, irtcvfr0_match, 
	     irtcvdr1_match, irtcvdr0_match, irtcvsr_match})
        6'b100000 : rdmux_dat = irtcvfr2;
        6'b010000 : rdmux_dat = irtcvfr1;
        6'b001000 : rdmux_dat = irtcvfr0;
        6'b000100 : rdmux_dat = irtcvdr1;
        6'b000010 : rdmux_dat = irtcvdr0;
        6'b000001 : rdmux_dat = irtcvsr;
        default   : rdmux_dat = {`IRTCVCBDW{1'b0}};
      endcase // case ({irtcvfr2_match, irtcvfr1_match, irtcvfr0_match,...
   end // always @ (...

   wire out_act = ip_rstb & (irtcvfr2_match | irtcvfr1_match | irtcvfr0_match | 
	           irtcvdr1_match | irtcvdr0_match | irtcvsr_match);
   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async) irtcv_rdat <= {`IRTCVCBDW{1'b0}};
      else if (out_act)    irtcv_rdat <= rdmux_dat;
      else                 irtcv_rdat <= irtcv_rdat;
   end
   
   assign irtcvdr_rd = ip_rstb & irtcvdr0_match;
   assign irtcvfr_rd = ip_rstb & irtcvfr0_match;
   
endmodule // irtcv_sci
