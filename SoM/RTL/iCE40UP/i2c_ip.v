`include "defines2.v"
`timescale 1ns/1ps
module i2c_ip (/*AUTOARG*/
   // Outputs
   sda_out, sda_oe, scl_out, scl_oe, sb_dat_o, sb_ack_o, i2c_irq,
   i2c_wkup,
   // Inputs
   SB_ID, ADDR_LSB_USR, i2c_rst_async, sda_in, scl_in, del_clk,
   sb_clk_i, sb_we_i, sb_stb_i, sb_adr_i, sb_dat_i, scan_test_mode
   );

   // INPUTS
   // From IP TOP Tie High/Tie Low
   input [`SBAW-5:0] SB_ID;
   input [1:0]       ADDR_LSB_USR;
   
   // From full chip POR ...
   input i2c_rst_async;

   // From I2C Bus
   input sda_in, scl_in;
   
   // From System Bus
   input del_clk;               // Could tie to sb_clk_i outside if there is no other High Frequency Source

   input sb_clk_i;
   input sb_we_i;
   input sb_stb_i;

   input [`SBAW-1:0] sb_adr_i;
   input [`SBDW-1:0] sb_dat_i;

   // From CFG Trim Control
   // input [3:0]       trim_sda_del;    Not Support by default

   // From SCAN TEST Control
   input             scan_test_mode;
   
   
   // OUTPUTS
   // To I2C Bus
   output            sda_out, sda_oe;
   output            scl_out, scl_oe;
   
   // To Sysem Bus
   output [`SBDW-1:0]   sb_dat_o;
   output               sb_ack_o;
   
   // To System Host
   output               i2c_irq;

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
   wire [7:0]           i2csr;                  // From i2c_port_inst of i2c_port.v
   wire [`SBDW-1:0]     i2ctxdr;                // From i2c_sci_inst of i2c_sci.v
   wire                 i2ctxdr_wt;             // From i2c_sci_inst of i2c_sci.v
   wire [`DTRMW-1:0]    trim_sda_del;           // From i2c_sci_inst of i2c_sci.v
   // End of automatics


   // LOGIC
   
   i2c_sci i2c_sci_inst (/*AUTOINST*/
                         // Outputs
                         .i2ccr1                (i2ccr1[`SBDW-1:0]),
                         .i2ccmdr               (i2ccmdr[`SBDW-1:0]),
                         .i2ctxdr               (i2ctxdr[`SBDW-1:0]),
                         .i2cbr                 (i2cbr[`I2CBRW-1:0]),
                         .i2csaddr              (i2csaddr[`SBDW-1:0]),
                         .i2ccr1_wt             (i2ccr1_wt),
                         .i2ccmdr_wt            (i2ccmdr_wt),
                         .i2cbr_wt              (i2cbr_wt),
                         .i2ctxdr_wt            (i2ctxdr_wt),
                         .i2csaddr_wt           (i2csaddr_wt),
                         .i2crxdr_rd            (i2crxdr_rd),
                         .i2cgcdr_rd            (i2cgcdr_rd),
                         .trim_sda_del          (trim_sda_del[`DTRMW-1:0]),
                         .sb_dat_o              (sb_dat_o[`SBDW-1:0]),
                         .sb_ack_o              (sb_ack_o),
                         .i2c_irq               (i2c_irq),
                         // Inputs
                         .SB_ID                 (SB_ID[`SBAW-5:0]),
                         .i2c_rst_async         (i2c_rst_async),
                         .sb_clk_i              (sb_clk_i),
                         .sb_we_i               (sb_we_i),
                         .sb_stb_i              (sb_stb_i),
                         .sb_adr_i              (sb_adr_i[`SBAW-1:0]),
                         .sb_dat_i              (sb_dat_i[`SBDW-1:0]),
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
                           .ADDR_LSB_USR        (ADDR_LSB_USR[1:0]),
                           .i2c_rst_async       (i2c_rst_async),
                           .sda_in              (sda_in),
                           .scl_in              (scl_in),
                           .del_clk             (del_clk),
                           .sb_clk_i            (sb_clk_i),
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
