`include "defines3.v"
`timescale 1 ns / 1 ps
module spi_sci (/*AUTOARG*/
   // Outputs
   spicr0, spicr1, spicr2, spibr, spicsr, spitxdr, spicr0_wt,
   spicr1_wt, spicr2_wt, spibr_wt, spicsr_wt, spitxdr_wt, spirxdr_rd,
   sb_dat_o, sb_ack_o, spi_irq,
   // Inputs
   SB_ID, spi_rst_async, sb_clk_i, sb_we_i, sb_stb_i, sb_adr_i,
   sb_dat_i, spisr, spirxdr, scan_test_mode
   );

   // INPUTS
   // From IP TOP Tie High/Tie Low
   input [`SBAW-5:0] SB_ID;
   
   // From full chip POR ...
   input spi_rst_async;

   // From System Bus
   input sb_clk_i;
   input sb_we_i;
   input sb_stb_i;

   input [`SBAW-1:0] sb_adr_i;
   input [`SBDW-1:0] sb_dat_i;

   // From I2C_port logc
   input [`SBDW-1:0] spisr, spirxdr;

   // From SCAN TEST Control
   input             scan_test_mode;
   
   // OUTPUTS
   // To I2C Port Logic
   output [`SBDW-1:0]   spicr0, spicr1, spicr2, spibr, spicsr, spitxdr;
   
   output               spicr0_wt, spicr1_wt, spicr2_wt, spibr_wt, spicsr_wt, spitxdr_wt;
   output               spirxdr_rd;

   // To Sysem Bus
   output [`SBDW-1:0]   sb_dat_o;
   output               sb_ack_o;
   
   // To System Host
   output               spi_irq;
   
   // REGS
   reg                  ack_reg;
   reg                  id_stb_dly, id_stb_pulse;
   
   reg [`SBDW-1:0]      spicr0, spicr1, spicr2, spibr, spicsr, spitxdr;
   reg [`SBDW-1:0]      spiintcr;
   
   reg [`SBDW-1:0]      rdmux_dat;
   reg [`SBDW-1:0]      sb_dat_o;
   
   // WIRES
   wire                 sb_id_match, sb_ip_match;
   wire                 id_wstb;
   wire                 id_rstb_pulse, id_wstb_pulse;
   wire                 ip_rstb;
   
   wire                 spicr0_wt, spicr1_wt, spicr2_wt, spibr_wt, spicsr_wt, spitxdr_wt;
   wire                 spirxdr_rd;
   wire                 spiintsr_wt, spiintsr_rd;
   
   wire                 irq_mdf, irq_roe, irq_toe, irq_rrdy, irq_trdy;
   
   // LOGIC

   // SCI Registers
   assign sb_id_match = (sb_adr_i[`SBAW-1:4] == SB_ID);
   assign sb_ip_match = sb_id_match & (sb_adr_i[3] | (sb_adr_i[3:0] == `ADDR_SPIINTCR) | (sb_adr_i[3:0] == `ADDR_SPIINTSR));

   assign id_stb      = sb_id_match & sb_stb_i;
   assign ip_stb      = sb_ip_match & sb_stb_i;
   
   assign ip_rstb     = ip_stb & ~sb_we_i;

   assign id_wstb     = id_stb &  sb_we_i;
   
   // SB STB Pulse
   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async) id_stb_dly <= 1'b0;
     else               id_stb_dly <= id_stb;

   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async) id_stb_pulse <= 1'b0;
     else               id_stb_pulse <= id_stb & ~id_stb_dly;

   assign id_rstb_pulse = id_stb_pulse & ~sb_we_i;
   assign id_wstb_pulse = id_stb_pulse &  sb_we_i;

   // ACK OUTPUT
   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async) ack_reg <= 1'b0;
     else               ack_reg <= ip_stb;
   
   assign sb_ack_o = sb_stb_i & ack_reg;
   
   // System Bus Addassable Registers
   // SPICR0
   wire spicr0_match = (sb_adr_i[3:0] == `ADDR_SPICR0);
   wire wena_spicr0  = id_wstb & spicr0_match;
   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async)    spicr0 <= `DEFAULT_SPICR0;
     else if (wena_spicr0) spicr0 <= sb_dat_i;

   assign spicr0_wt = id_wstb_pulse & spicr0_match;

   // SPICR1
   wire spicr1_match = (sb_adr_i[3:0] == `ADDR_SPICR1);
   wire wena_spicr1  = id_wstb & spicr1_match;
   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async)    spicr1 <= `DEFAULT_SPICR1;
     else if (wena_spicr1) spicr1 <= sb_dat_i;

   assign spicr1_wt = id_wstb_pulse & spicr1_match;

   // SPICR2
   wire spicr2_match = (sb_adr_i[3:0] == `ADDR_SPICR2);
   wire wena_spicr2  = id_wstb & spicr2_match;
   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async)    spicr2 <= `DEFAULT_SPICR2;
     else if (wena_spicr2) spicr2 <= sb_dat_i;

   assign spicr2_wt = id_wstb_pulse & spicr2_match;

   // SPIBR
   wire spibr_match = (sb_adr_i[3:0] == `ADDR_SPIBR);
   wire wena_spibr  = id_wstb & spibr_match;
   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async)   spibr <= {`SBDW{1'b0}};
     else if (wena_spibr) spibr <= sb_dat_i;

   assign spibr_wt = id_wstb_pulse & spibr_match;

   // SPICSR
   wire spicsr_match = (sb_adr_i[3:0] == `ADDR_SPICSR);
   wire wena_spicsr  = id_wstb & spicsr_match;
   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async)    spicsr <= {`SBDW{1'b0}};
     else if (wena_spicsr) spicsr <= sb_dat_i;

   assign spicsr_wt = id_wstb_pulse & spicsr_match;
   
   // SPITXDR
   wire spitxdr_match = (sb_adr_i[3:0] == `ADDR_SPITXDR);
   wire wena_spitxdr  = id_wstb & spitxdr_match;
   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async)     spitxdr <= {`SBDW{1'b0}};
     else if (wena_spitxdr) spitxdr <= sb_dat_i;

   assign spitxdr_wt = id_wstb_pulse & spitxdr_match;

   // SPIINTCR
   wire spiintcr_match = (sb_adr_i [3:0] == `ADDR_SPIINTCR);
   wire wena_spiintcr  = id_wstb & spiintcr_match;
   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async)      spiintcr <= `DEFAULT_SPIINTCR;
     else if (wena_spiintcr) spiintcr <= sb_dat_i;

   // SPIRXDR RD PULSE
   assign spirxdr_rd = id_rstb_pulse & (sb_adr_i[3:0] == `ADDR_SPIRXDR);

   // sb_dat_o MUX
   always @(/*AUTOSENSE*/`ADDR_SPIBR or `ADDR_SPICR0 or `ADDR_SPICR1
            or `ADDR_SPICR2 or `ADDR_SPICSR or `ADDR_SPIINTCR
            or `ADDR_SPIINTSR or `ADDR_SPIRXDR or `ADDR_SPISR
            or `ADDR_SPITXDR or `SBDW or irq_mdf or irq_roe
            or irq_rrdy or irq_toe or irq_trdy or sb_adr_i or spibr
            or spicr0 or spicr1 or spicr2 or spicsr or spiintcr
            or spirxdr or spisr or spitxdr)
     begin
      case (sb_adr_i[3:0])
        `ADDR_SPICR0  : rdmux_dat = spicr0;
        `ADDR_SPICR1  : rdmux_dat = spicr1;
        `ADDR_SPICR2  : rdmux_dat = spicr2;
        `ADDR_SPIBR   : rdmux_dat = spibr;
        `ADDR_SPISR   : rdmux_dat = spisr;
        `ADDR_SPITXDR : rdmux_dat = spitxdr;
        `ADDR_SPIRXDR : rdmux_dat = spirxdr;
        `ADDR_SPICSR  : rdmux_dat = spicsr;
        `ADDR_SPIINTCR: rdmux_dat = spiintcr;
        `ADDR_SPIINTSR: rdmux_dat = {{3{1'b0}}, irq_trdy, irq_rrdy, irq_toe, irq_roe, irq_mdf};
        default       : rdmux_dat = {`SBDW{1'b0}};
      endcase // case (adr_i[3:0])
   end // always @ (...

   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async) sb_dat_o <= 0;
     else if (ip_rstb)  sb_dat_o <= rdmux_dat;
     else               sb_dat_o <= 0;

   // ****************************************************************************************
   // Interrupt Lotic
   // ****************************************************************************************
   wire match_intsr = (sb_adr_i[3:0] == `ADDR_SPIINTSR);
   assign spiintsr_wt = id_wstb_pulse & match_intsr;
   assign spiintsr_rd = id_rstb_pulse & match_intsr;

   wire int_clr_all = spiintcr[`INDEX_INTCLR] & spiintsr_rd;
   
   wire int_force = spiintcr[`INDEX_INTFRC];
   
   // IRQ ARBL
   wire int_mdf;
   wire int_set_mdf = spisr[`INDEX_MDF];
   wire int_clr_mdf = (spiintsr_wt & sb_dat_i[`INDEX_MDF]) | int_clr_all;
   sci_int_reg intr_mdf(
                        // Outputs
                        .status                (int_mdf),
                        // Inputs
                        .rst_async             (spi_rst_async),
                        .sb_clk_i              (sb_clk_i),
                        .int_force             (int_force),
                        .int_set               (int_set_mdf),
                        .int_clr               (int_clr_mdf),
                        .scan_test_mode        (scan_test_mode));
   
   assign irq_mdf = spiintcr[`INDEX_MDF] & int_mdf;

   // IRQ ROE
   wire int_roe;
   wire int_set_roe = spisr[`INDEX_ROE];
   wire int_clr_roe = (spiintsr_wt & sb_dat_i[`INDEX_ROE]) | int_clr_all;
   sci_int_reg intr_roe(
                        // Outputs
                        .status                (int_roe),
                        // Inputs
                        .rst_async             (spi_rst_async),
                        .sb_clk_i              (sb_clk_i),
                        .int_force             (int_force),
                        .int_set               (int_set_roe),
                        .int_clr               (int_clr_roe),
                        .scan_test_mode        (scan_test_mode));
   
   assign irq_roe = spiintcr[`INDEX_ROE] & int_roe;

   // IRQ TOE
   wire int_toe;
   wire int_set_toe = spisr[`INDEX_TOE];
   wire int_clr_toe = (spiintsr_wt & sb_dat_i[`INDEX_TOE]) | int_clr_all;
   sci_int_reg intr_toe(
                        // Outputs
                        .status                (int_toe),
                        // Inputs
                        .rst_async             (spi_rst_async),
                        .sb_clk_i              (sb_clk_i),
                        .int_force             (int_force),
                        .int_set               (int_set_toe),
                        .int_clr               (int_clr_toe),
                        .scan_test_mode        (scan_test_mode));
   
   assign irq_toe = spiintcr[`INDEX_TOE] & int_toe;
   
   // IRQ RRDY
   wire int_rrdy;
   wire int_set_rrdy = spisr[`INDEX_RRDY];
   wire int_clr_rrdy = (spiintsr_wt & sb_dat_i[`INDEX_RRDY]) | int_clr_all;
   sci_int_reg intr_rrdy(
                         // Outputs
                         .status                (int_rrdy),
                         // Inputs
                         .rst_async             (spi_rst_async),
                         .sb_clk_i              (sb_clk_i),
                         .int_force             (int_force),
                         .int_set               (int_set_rrdy),
                         .int_clr               (int_clr_rrdy),
                         .scan_test_mode        (scan_test_mode));
   
   assign irq_rrdy = spiintcr[`INDEX_RRDY] & int_rrdy;

   // IRQ TRDY
   wire int_trdy;
   wire int_set_trdy = spisr[`INDEX_TRDY];
   wire int_clr_trdy = (spiintsr_wt & sb_dat_i[`INDEX_TRDY]) | int_clr_all;
   sci_int_reg intr_trdy(
                         // Outputs
                         .status                (int_trdy),
                         // Inputs
                         .rst_async             (spi_rst_async),
                         .sb_clk_i              (sb_clk_i),
                         .int_force             (int_force),
                         .int_set               (int_set_trdy),
                         .int_clr               (int_clr_trdy),
                         .scan_test_mode        (scan_test_mode));
   
   assign irq_trdy = spiintcr[`INDEX_TRDY] & int_trdy;

   assign spi_irq = irq_mdf | irq_roe | irq_toe | irq_rrdy | irq_trdy;
   
endmodule // i2c_sci
