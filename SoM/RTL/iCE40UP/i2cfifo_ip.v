`include "defines6.v"
`timescale 1ns/1ps
module i2cfifo_ip (/*AUTOARG*/
   // Outputs
   sda_out, sda_oe, scl_out, scl_oe, dat_o, ack_o, 
   i2c_wkup, irq, mrdcmpl, srdwr, 
   txfifo_e, txfifo_ae, txfifo_f,
   rxfifo_e, rxfifo_af, rxfifo_f,
   // Inputs
   ADDR_LSB_USR, del_clk, i2c_rst_async, scan_test_mode, 
   sda_in, scl_in, 
   clk_i, we_i, stb_i, cs_i, adr_i, dat_i, fifo_rst     
   );

   // INPUTS
   // From IP TOP Tie High/Tie Low
   //input [`SBAW-5:0] SB_ID;
   input [1:0]       ADDR_LSB_USR;
   
   // From full chip POR ...
   input i2c_rst_async;

   // From I2C Bus
   input sda_in, scl_in;
   
   // From System Bus
   input del_clk;               // Could tie to clk_i outside if there is no other High Frequency Source

   input clk_i;
   input we_i;
   input stb_i;
   input cs_i;
   input fifo_rst;

   input [`SBAW-1:0] adr_i;
   input [`FIDW-1:0] dat_i;

   // From CFG Trim Control
   // input [3:0]       trim_sda_del;    Not Support by default

   // From SCAN TEST Control
   input             scan_test_mode;
   
   
   // OUTPUTS
   // To I2C Bus
   output            sda_out, sda_oe;
   output            scl_out, scl_oe;
   
   // To Sysem Bus
   output [`FIDW-1:0]   dat_o;
   output               ack_o;
   
   // To System Host
   output               irq;
   output               mrdcmpl, srdwr;
   output 						  txfifo_e, txfifo_ae, txfifo_f;
   output 							rxfifo_e, rxfifo_af, rxfifo_f;

   // Optional system function
   // output               i2c_hsmode;    // Potentially send out to turn on optional pull up current source
   output               i2c_wkup;         // Signal to wakeup from standy/sleep mode, Rising edge detect at Power Manager Block
   
   // REGS


   // WIRES

   
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire                 i2c_hsmode;             // From i2c_port_inst of i2c_port.v
   wire [`I2CBRW-1:0]   i2cbr;                  // From i2c_sci_inst of i2c_sci.v
   wire                 i2cbr_wt;               // From i2c_sci_inst of i2c_sci.v
   wire [`SBDW-1:0]     i2ccmdr;                // From i2c_sci_inst of i2c_sci.v
   wire                 i2ccmdr_wt;             // From i2c_sci_inst of i2c_sci.v
   wire [`SBDW-1:0]     i2ccr1;                 // From i2c_sci_inst of i2c_sci.v
   wire                 i2ccr1_wt;              // From i2c_sci_inst of i2c_sci.v
   wire [7:0]           i2cgcdr;                // From i2c_port_inst of i2c_port.v
   wire                 i2cgcdr_rd;             // From i2c_sci_inst of i2c_sci.v
   wire [7:0]           i2crxdr;                // From i2c_port_inst of i2c_port.v
   wire                 i2crxdr_rd;             // From i2c_sci_inst of i2c_sci.v
   wire [`SBDW-1:0]     i2csaddr;               // From i2c_sci_inst of i2c_sci.v
   wire                 i2csaddr_wt;            // From i2c_sci_inst of i2c_sci.v
   wire [1:0]           i2csaddr_lsb;           // From i2c_sci_inst of i2c_sci.v
   wire [7:0]           i2csr;                  // From i2c_port_inst of i2c_port.v
   wire [`SBDW-1:0]     i2ctxdr;                // From i2c_sci_inst of i2c_sci.v
   wire                 i2ctxdr_wt;             // From i2c_sci_inst of i2c_sci.v
   wire [`DTRMW-1:0]    trim_sda_del;           // From i2c_sci_inst of i2c_sci.v
   // End of automatics

   // mux logic for i2csaddr 2 lsbs
   wire [1:0] mux_saddr_lsb;
   assign mux_saddr_lsb = i2ccr1[4] ? i2csaddr_lsb : ADDR_LSB_USR;
        

   // LOGIC
   
   i2cfifo_sci i2cfifo_sci_inst (/*AUTOINST*/
                         // Outputs
                         .i2ccr1                (i2ccr1[`SBDW-1:0]),
                         .i2ccmdr               (i2ccmdr[`SBDW-1:0]),
                         .i2ctxdr               (i2ctxdr[`SBDW-1:0]),
                         .i2cbr                 (i2cbr[`I2CBRW-1:0]),
                         .i2csaddr              (i2csaddr[`SBDW-1:0]),
                         .i2csaddr_lsb          (i2csaddr_lsb),
                         .i2ccr1_wt             (i2ccr1_wt),
                         .i2ccmdr_wt            (i2ccmdr_wt),
                         .i2cbr_wt              (i2cbr_wt),
                         .i2ctxdr_wt            (i2ctxdr_wt),
                         .i2csaddr_wt           (i2csaddr_wt),
                         .i2crxdr_rd            (i2crxdr_rd),
                         .i2cgcdr_rd            (i2cgcdr_rd),
                         .trim_sda_del          (trim_sda_del[`DTRMW-1:0]),
                         .sb_dat_o              (dat_o[`FIDW-1:0]),
                         .sb_ack_o              (ack_o),
                         .i2c_irq               (irq),
                         .mrdcmpl								(mrdcmpl),		
                         .srdwr                 (srdwr),       
                         .txfifo_empty          (txfifo_e), 
                         .txfifo_aempty         (txfifo_ae),  
                         .txfifo_full           (txfifo_f),  
                         .rxfifo_empty          (rxfifo_e),  
                         .rxfifo_afull          (rxfifo_af), 
                         .rxfifo_full           (rxfifo_f),  
                         // Inputs              (
                         //.SB_ID                 (SB_ID[`SBAW-5:0]),
                         .i2c_rst_async         (i2c_rst_async),
                         .scl_i                 (scl_in),
                         .sda_i                 (sda_in),
                         .sb_clk_i              (clk_i),
                         .sb_we_i               (we_i),
                         .sb_stb_i              (stb_i),
                         .sb_cs_i               (cs_i),
                         .sb_adr_i              (adr_i),
                         .sb_dat_i              (dat_i),
                         .sb_fifo_rst           (fifo_rst),
                         .i2csr                 (i2csr[`SBDW-1:0]),
                         .i2crxdr               (i2crxdr[`SBDW-1:0]),
                         .i2cgcdr               (i2cgcdr[`SBDW-1:0]),
                         .scan_test_mode        (scan_test_mode));

   i2c_port i2c_port_inst (/*AUTOINST*/
                           // Outputs
                           .sda_out             (sda_out),
                           .sda_oe              (sda_oe),
                           .scl_out             (scl_out),
                           .scl_oe              (scl_oe),
                           .i2crxdr             (i2crxdr[7:0]),
                           .i2cgcdr             (i2cgcdr[7:0]),
                           .i2csr               (i2csr[7:0]),
                           .i2c_hsmode          (i2c_hsmode),
                           .i2c_wkup            (i2c_wkup),
                           // Inputs
                           .ADDR_LSB_USR        (mux_saddr_lsb),
                           .i2c_rst_async       (i2c_rst_async),
                           .sda_in              (sda_in),
                           .scl_in              (scl_in),
                           .del_clk             (del_clk),
                           .sb_clk_i            (clk_i),
                           .i2ccr1              (i2ccr1[`SBDW-1:0]),
                           .i2ccmdr             (i2ccmdr[`SBDW-1:0]),
                           .i2ctxdr             (i2ctxdr[`SBDW-1:0]),
                           .i2cbr               (i2cbr[`I2CBRW-1:0]),
                           .i2csaddr            (i2csaddr[`SBDW-1:0]),
                           .i2ccr1_wt           (i2ccr1_wt),
                           .i2ccmdr_wt          (i2ccmdr_wt),
                           .i2cbr_wt            (i2cbr_wt),
                           .i2ctxdr_wt          (i2ctxdr_wt),
                           .i2csaddr_wt         (i2csaddr_wt),
                           .i2crxdr_rd          (i2crxdr_rd),
                           .i2cgcdr_rd          (i2cgcdr_rd),
                           .trim_sda_del        (trim_sda_del[3:0]),
                           .scan_test_mode      (scan_test_mode));


endmodule // i2c_ip
