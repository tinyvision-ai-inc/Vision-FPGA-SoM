`include "defines3.v"
`timescale 1ns/1ps
module spi_ip (/*AUTOARG*/
   // Outputs
   mclk_o, mclk_oe, mosi_o, mosi_oe, miso_o, miso_oe, mcsn_o, mcsn_oe,
   sb_dat_o, sb_ack_o, spi_irq, spi_wkup,
   // Inputs
   SB_ID, spi_rst_async, sck_tcv, mosi_i, miso_i, scsn_usr, sb_clk_i,
   sb_we_i, sb_stb_i, sb_adr_i, sb_dat_i, scan_test_mode
   );

   // INPUTS
   // From IP TOP Tie High/Tie Low
   input [`SBAW-5:0] SB_ID;
   
   // From full chip POR ...
   input spi_rst_async;

   // From SPI Bus
   input sck_tcv;
   input mosi_i, miso_i;
   input scsn_usr;
   
   // From System Bus
   input sb_clk_i;
   input sb_we_i;
   input sb_stb_i;

   input [`SBAW-1:0] sb_adr_i;
   input [`SBDW-1:0] sb_dat_i;

   // From SCAN TEST Control
   input             scan_test_mode;
   
   
   // OUTPUTS
   // To SPI Bus
   output mclk_o, mclk_oe;      //SPI Master Clock Output & Enable
   output mosi_o, mosi_oe;
   output miso_o, miso_oe;
   output [`SBDW-1:0] mcsn_o, mcsn_oe;
   
   // To Sysem Bus
   output [`SBDW-1:0]   sb_dat_o;
   output               sb_ack_o;
   
   // To System Host
   output               spi_irq;

   // Optional system function
   output               spi_wkup;         // Signal to wakeup from standy/sleep mode, Rising edge detect at Power Manager Block
   
   // REGS


   // WIRES
   
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [`SBDW-1:0]     spibr;                  // From spi_sci_inst of spi_sci.v
   wire                 spibr_wt;               // From spi_sci_inst of spi_sci.v
   wire [`SBDW-1:0]     spicr0;                 // From spi_sci_inst of spi_sci.v
   wire                 spicr0_wt;              // From spi_sci_inst of spi_sci.v
   wire [`SBDW-1:0]     spicr1;                 // From spi_sci_inst of spi_sci.v
   wire                 spicr1_wt;              // From spi_sci_inst of spi_sci.v
   wire [`SBDW-1:0]     spicr2;                 // From spi_sci_inst of spi_sci.v
   wire                 spicr2_wt;              // From spi_sci_inst of spi_sci.v
   wire [`SBDW-1:0]     spicsr;                 // From spi_sci_inst of spi_sci.v
   wire                 spicsr_wt;              // From spi_sci_inst of spi_sci.v
   wire [`SBDW-1:0]     spirxdr;                // From spi_port_inst of spi_port.v
   wire                 spirxdr_rd;             // From spi_sci_inst of spi_sci.v
   wire [`SBDW-1:0]     spisr;                  // From spi_port_inst of spi_port.v
   wire [`SBDW-1:0]     spitxdr;                // From spi_sci_inst of spi_sci.v
   wire                 spitxdr_wt;             // From spi_sci_inst of spi_sci.v
   // End of automatics


   // LOGIC
   
   spi_sci spi_sci_inst (/*AUTOINST*/
                         // Outputs
                         .spicr0                (spicr0[`SBDW-1:0]),
                         .spicr1                (spicr1[`SBDW-1:0]),
                         .spicr2                (spicr2[`SBDW-1:0]),
                         .spibr                 (spibr[`SBDW-1:0]),
                         .spicsr                (spicsr[`SBDW-1:0]),
                         .spitxdr               (spitxdr[`SBDW-1:0]),
                         .spicr0_wt             (spicr0_wt),
                         .spicr1_wt             (spicr1_wt),
                         .spicr2_wt             (spicr2_wt),
                         .spibr_wt              (spibr_wt),
                         .spicsr_wt             (spicsr_wt),
                         .spitxdr_wt            (spitxdr_wt),
                         .spirxdr_rd            (spirxdr_rd),
                         .sb_dat_o              (sb_dat_o[`SBDW-1:0]),
                         .sb_ack_o              (sb_ack_o),
                         .spi_irq               (spi_irq),
                         // Inputs
                         .SB_ID                 (SB_ID[`SBAW-5:0]),
                         .spi_rst_async         (spi_rst_async),
                         .sb_clk_i              (sb_clk_i),
                         .sb_we_i               (sb_we_i),
                         .sb_stb_i              (sb_stb_i),
                         .sb_adr_i              (sb_adr_i[`SBAW-1:0]),
                         .sb_dat_i              (sb_dat_i[`SBDW-1:0]),
                         .spisr                 (spisr[`SBDW-1:0]),
                         .spirxdr               (spirxdr[`SBDW-1:0]),
                         .scan_test_mode        (scan_test_mode));

   spi_port spi_port_inst (/*AUTOINST*/
                           // Outputs
                           .mclk_o              (mclk_o),
                           .mclk_oe             (mclk_oe),
                           .mosi_o              (mosi_o),
                           .mosi_oe             (mosi_oe),
                           .miso_o              (miso_o),
                           .miso_oe             (miso_oe),
                           .mcsn_o              (mcsn_o[`SBDW-1:0]),
                           .mcsn_oe             (mcsn_oe[`SBDW-1:0]),
                           .spisr               (spisr[`SBDW-1:0]),
                           .spirxdr             (spirxdr[`SBDW-1:0]),
                           .spi_wkup            (spi_wkup),
                           // Inputs
                           .spi_rst_async       (spi_rst_async),
                           .sck_tcv             (sck_tcv),
                           .mosi_i              (mosi_i),
                           .miso_i              (miso_i),
                           .scsn_usr            (scsn_usr),
                           .sb_clk_i            (sb_clk_i),
                           .spicr0              (spicr0[`SBDW-1:0]),
                           .spicr1              (spicr1[`SBDW-1:0]),
                           .spicr2              (spicr2[`SBDW-1:0]),
                           .spibr               (spibr[`SBDW-1:0]),
                           .spicsr              (spicsr[`SBDW-1:0]),
                           .spitxdr             (spitxdr[`SBDW-1:0]),
                           .spicr0_wt           (spicr0_wt),
                           .spicr1_wt           (spicr1_wt),
                           .spicr2_wt           (spicr2_wt),
                           .spibr_wt            (spibr_wt),
                           .spicsr_wt           (spicsr_wt),
                           .spitxdr_wt          (spitxdr_wt),
                           .spirxdr_rd          (spirxdr_rd));


endmodule // spi_ip
