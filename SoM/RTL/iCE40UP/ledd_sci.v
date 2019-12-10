`include "defines4.v"
`timescale 1ns/1ps
module ledd_sci (/*AUTOARG*/
   // Outputs
   leddcr0, leddbr, leddonr, leddofr, leddbcrr, leddbcfr, leddpwrr,
   leddpwgr, leddpwbr,
   // Inputs
   ledd_rst_async, ledd_clk, ledd_cs, ledd_den, ledd_adr, ledd_dat
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

   // OUTPUTS
   // LED PWM Driver Unit
   output [`LEDCBDW-1:0] leddcr0;    // LED Driver Control Register 0
   output [`LEDCBDW-1:0] leddbr;     // LED Driver Clock Pre-scale Register
   output [`LEDCBDW-1:0] leddonr;    // LED Driver ON Time Register
   output [`LEDCBDW-1:0] leddofr;    // LED Driver OFF Time Register
   output [`LEDCBDW-1:0] leddbcrr;   // LED Driver Breath ON Control Register
   output [`LEDCBDW-1:0] leddbcfr;   // LED Driver Breath OFF Control Register
   output [`LEDCBDW-1:0] leddpwrr;   // LED Driver RED Pulse Width Register
   output [`LEDCBDW-1:0] leddpwgr;   // LED Driver GREEN Pulse Width Register
   output [`LEDCBDW-1:0] leddpwbr;   // LED Driver BLUE Pulse Width Register

   // To FPGA Fabric
   // output ledd_ack;
   
   // REGS
   // reg ack_reg;                   // Acknowledge Generation.
   
   reg [`LEDCBDW-1:0] leddcr0;    // LED Driver Control Register 0
   reg [`LEDCBDW-1:0] leddbr;     // LED Driver Clock Pre-scale Register
   reg [`LEDCBDW-1:0] leddonr;    // LED Driver ON Time Register
   reg [`LEDCBDW-1:0] leddofr;    // LED Driver OFF Time Register
   reg [`LEDCBDW-1:0] leddbcrr;   // LED Driver Breath ON Control Register
   reg [`LEDCBDW-1:0] leddbcfr;   // LED Driver Breath OFF Control Register
   reg [`LEDCBDW-1:0] leddpwrr;   // LED Driver RED Pulse Width Register
   reg [`LEDCBDW-1:0] leddpwgr;   // LED Driver GREEN Pulse Width Register
   reg [`LEDCBDW-1:0] leddpwbr;   // LED Driver BLUE Pulse Width Register

   // WIRES
   wire ip_wstb;

   wire leddcr0_match, leddbr_match;
   wire leddonr_match, leddofr_match;
   wire leddbcrr_match, leddbcfr_match;
   wire leddpwrr_match, leddpwgr_match, leddpwbr_match;
   
   /*AUTOWIRE*/


   // LOGIC
   assign ip_wstb = ledd_den;

   assign leddcr0_match  = ledd_cs & (ledd_adr[3:0] == `ADDR_LEDDCR0);
   assign leddbr_match   = ledd_cs & (ledd_adr[3:0] == `ADDR_LEDDBR);
   assign leddonr_match  = ledd_cs & (ledd_adr[3:0] == `ADDR_LEDDONR);
   assign leddofr_match  = ledd_cs & (ledd_adr[3:0] == `ADDR_LEDDOFR);
   assign leddbcrr_match = ledd_cs & (ledd_adr[3:0] == `ADDR_LEDDBCRR);
   assign leddbcfr_match = ledd_cs & (ledd_adr[3:0] == `ADDR_LEDDBCFR);
   assign leddpwrr_match = ledd_cs & (ledd_adr[3:0] == `ADDR_LEDDPWRR);
   assign leddpwgr_match = ledd_cs & (ledd_adr[3:0] == `ADDR_LEDDPWGR);
   assign leddpwbr_match = ledd_cs & (ledd_adr[3:0] == `ADDR_LEDDPWBR);
   
   // Not needed for Service LED Driver, just in case
   // wire leddall_match = leddcr0_match | leddbr_match | 
   // 	                leddonr_match | leddofr_match | 
   // 	                leddbcrr_match | leddbcfr_match | 
   // 	                leddpwrr_match | leddpwgr_match | leddpwbr_match;
   // wire ip_stb_all = ip_wstb & leddall_match;
   // always @(posedge ledd_clk or posedge ledd_rst_async)
   //   if (ledd_rst_async) ack_reg <= 1'b0;
   //   else                ack_reg <= ip_stb_all;
   // 
   // assign ledd_ack = ledd_den & ack_reg;

   // System Bus Addressable Registers
   // LEDDCR0
   wire wena_leddcr0 = ip_wstb & leddcr0_match;
   always @(posedge ledd_clk or posedge ledd_rst_async)
     if (ledd_rst_async)    leddcr0 <= `DEFAULT_LEDDCR0;
     else if (wena_leddcr0) leddcr0 <= ledd_dat;
     else                   leddcr0 <= leddcr0;

   // LEDDBR
   wire wena_leddbr = ip_wstb & leddbr_match;
   always @(posedge ledd_clk or posedge ledd_rst_async)
     if (ledd_rst_async)   leddbr <= `DEFAULT_LEDDBR;
     else if (wena_leddbr) leddbr <= ledd_dat;
     else                  leddbr <= leddbr;

   // LEDDONR
   wire wena_leddonr = ip_wstb & leddonr_match;
   always @(posedge ledd_clk or posedge ledd_rst_async)
     if (ledd_rst_async)    leddonr <= {`LEDCBDW{1'b0}};
     else if (wena_leddonr) leddonr <= ledd_dat;
     else                   leddonr <= leddonr;
   
   // LEDDOFR
   wire wena_leddofr = ip_wstb & leddofr_match;
   always @(posedge ledd_clk or posedge ledd_rst_async)
     if (ledd_rst_async)    leddofr <= {`LEDCBDW{1'b0}};
     else if (wena_leddofr) leddofr <= ledd_dat;
     else                   leddofr <= leddofr;

   // LEDDBCRR
   wire wena_leddbcrr = ip_wstb & leddbcrr_match;
   always @(posedge ledd_clk or posedge ledd_rst_async)
     if (ledd_rst_async)     leddbcrr <= {`LEDCBDW{1'b0}};
     else if (wena_leddbcrr) leddbcrr <= ledd_dat;
     else                    leddbcrr <= leddbcrr;

   // LEDDBCFR
   wire wena_leddbcfr = ip_wstb & leddbcfr_match;
   always @(posedge ledd_clk or posedge ledd_rst_async)
     if (ledd_rst_async)     leddbcfr <= {`LEDCBDW{1'b0}};
     else if (wena_leddbcfr) leddbcfr <= ledd_dat;
     else                    leddbcfr <= leddbcfr;

   // LEDDPWRR
   wire wena_leddpwrr = ip_wstb & leddpwrr_match;
   always @(posedge ledd_clk or posedge ledd_rst_async)
     if (ledd_rst_async)     leddpwrr <= {`LEDCBDW{1'b0}};
     else if (wena_leddpwrr) leddpwrr <= ledd_dat;
     else                    leddpwrr <= leddpwrr;
   
   // LEDDPWGR
   wire wena_leddpwgr = ip_wstb & leddpwgr_match;
   always @(posedge ledd_clk or posedge ledd_rst_async)
     if (ledd_rst_async)     leddpwgr <= {`LEDCBDW{1'b0}};
     else if (wena_leddpwgr) leddpwgr <= ledd_dat;
     else                    leddpwgr <= leddpwgr;
   
   // LEDDPWRR
   wire wena_leddpwbr = ip_wstb & leddpwbr_match;
   always @(posedge ledd_clk or posedge ledd_rst_async)
     if (ledd_rst_async)     leddpwbr <= {`LEDCBDW{1'b0}};
     else if (wena_leddpwbr) leddpwbr <= ledd_dat;
     else                    leddpwbr <= leddpwbr;
   
endmodule // ledd_sci
