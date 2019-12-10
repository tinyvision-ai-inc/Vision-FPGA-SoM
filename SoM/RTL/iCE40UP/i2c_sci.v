`include "defines2.v"
`timescale 1 ns / 1 ps
module i2c_sci (/*AUTOARG*/
   // Outputs
   i2ccr1, i2ccmdr, i2ctxdr, i2cbr, i2csaddr, i2ccr1_wt, i2ccmdr_wt,
   i2cbr_wt, i2ctxdr_wt, i2csaddr_wt, i2crxdr_rd, i2cgcdr_rd,
   trim_sda_del, sb_dat_o, sb_ack_o, i2c_irq,
   // Inputs
   SB_ID, i2c_rst_async, sb_clk_i, sb_we_i, sb_stb_i, sb_adr_i,
   sb_dat_i, i2csr, i2crxdr, i2cgcdr, scan_test_mode
   );

   // INPUTS
   // From IP TOP Tie High/Tie Low
   input [`SBAW-5:0] SB_ID;
   
   // From full chip POR ...
   input i2c_rst_async;

   // From System Bus
   input sb_clk_i;
   input sb_we_i;
   input sb_stb_i;

   input [`SBAW-1:0] sb_adr_i;
   input [`SBDW-1:0] sb_dat_i;

   // From I2C_port logc
   input [`SBDW-1:0] i2csr, i2crxdr, i2cgcdr;

   // From SCAN TEST Control
   input             scan_test_mode;
   
   // OUTPUTS
   // To I2C Port Logic
   output [`SBDW-1:0]   i2ccr1, i2ccmdr, i2ctxdr;
   output [`I2CBRW-1:0] i2cbr;
   output [`SBDW-1:0]   i2csaddr;
   
   output               i2ccr1_wt, i2ccmdr_wt, i2cbr_wt, i2ctxdr_wt, i2csaddr_wt;
   output               i2crxdr_rd, i2cgcdr_rd;

   output [`DTRMW-1:0]  trim_sda_del;
   
   // To Sysem Bus
   output [`SBDW-1:0]   sb_dat_o;
   output               sb_ack_o;
   
   // To System Host
   output               i2c_irq;
   
   // REGS
   reg                  ack_reg;
   reg                  id_stb_dly, id_stb_pulse;
   
   reg [`SBDW-1:0]      i2ccr1, i2ccmdr, i2ctxdr;
   reg [`SBDW-1:0]      i2cbrlsb;
   reg [`SBDW-1:0]      i2cbrmsb;
   reg [`SBDW-1:0]      i2csaddr, i2cintcr;
   
   reg [`SBDW-1:0]      rdmux_dat;
   reg [`SBDW-1:0]      sb_dat_o;
   
   // WIRES
   wire                 sb_id_match, sb_ip_match;
   wire                 id_wstb;
   wire                 id_rstb_pulse, id_wstb_pulse;
   wire                 ip_rstb;
   
   wire                 i2ccr1_wt, i2ccmdr_wt, i2cbr_wt, i2ctxdr_wt;
   wire                 i2cbrlsb_wt, i2cbrmsb_wt;
   wire                 i2csaddr_wt;
   wire                 i2crxdr_rd, i2cgcdr_rd;
   wire                 i2cintsr_wt, i2cintsr_rd;
   
   wire                 irq_arbl, irq_trrdy, irq_troe, irq_hgc;
   
   // LOGIC

   // SCI Registers
   assign sb_id_match = (sb_adr_i[`SBAW-1:4] == SB_ID);
   assign sb_ip_match = sb_id_match & (sb_adr_i[3] | (sb_adr_i[3:0] == `ADDR_I2CINTCR) | 
                                                     (sb_adr_i[3:0] == `ADDR_I2CINTSR) |
                                                     (sb_adr_i[3:0] == `ADDR_I2CSADDR));

   assign id_stb      = sb_id_match & sb_stb_i;
   assign ip_stb      = sb_ip_match & sb_stb_i;
   
   assign ip_rstb     = ip_stb & ~sb_we_i;

   assign id_wstb     = id_stb &  sb_we_i;
   
   // SB STB Pulse
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async) id_stb_dly <= 1'b0;
     else               id_stb_dly <= id_stb;

   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async) id_stb_pulse <= 1'b0;
     else               id_stb_pulse <= id_stb & ~id_stb_dly;

   assign id_rstb_pulse = id_stb_pulse & ~sb_we_i;
   assign id_wstb_pulse = id_stb_pulse &  sb_we_i;

   // ACK OUTPUT
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async) ack_reg <= 1'b0;
     else               ack_reg <= ip_stb;
   
   assign sb_ack_o = sb_stb_i & ack_reg;
   
   // System Bus Addassable Registers
   // I2CCR1
   wire i2ccr1_match = (sb_adr_i[3:0] == `ADDR_I2CCR1);
   wire wena_i2ccr1  = id_wstb & i2ccr1_match;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)    i2ccr1 <= `DEFAULT_I2CCR1;
     else if (wena_i2ccr1) i2ccr1 <= sb_dat_i;

   assign i2ccr1_wt = id_wstb_pulse & i2ccr1_match;

   // I2CCMDR
   wire i2ccmdr_match = (sb_adr_i[3:0] == `ADDR_I2CCMDR);
   wire wena_i2ccmdr  = id_wstb & i2ccmdr_match;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)     i2ccmdr <= {`SBDW{1'b0}};
     else if (wena_i2ccmdr) i2ccmdr <= sb_dat_i;

   assign i2ccmdr_wt = id_wstb_pulse & i2ccmdr_match;

   // I2CTXDR
   wire i2ctxdr_match = (sb_adr_i[3:0] == `ADDR_I2CTXDR);
   wire wena_i2ctxdr  = id_wstb & i2ctxdr_match;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)     i2ctxdr <= {`SBDW{1'b0}};
     else if (wena_i2ctxdr) i2ctxdr <= sb_dat_i;

   assign i2ctxdr_wt = id_wstb_pulse & i2ctxdr_match;

   // I2CBRLSB
   wire i2cbrlsb_match = (sb_adr_i[3:0] == `ADDR_I2CBRLSB);
   wire wena_i2cbrlsb  = id_wstb & i2cbrlsb_match;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)      i2cbrlsb <= {`SBDW{1'b0}};
     else if (wena_i2cbrlsb) i2cbrlsb <= sb_dat_i;

   assign i2cbrlsb_wt = id_wstb_pulse & i2cbrlsb_match;

   // I2CBRMSB
   wire i2cbrmsb_match = (sb_adr_i[3:0] == `ADDR_I2CBRMSB);
   wire wena_i2cbrmsb  = id_wstb & i2cbrmsb_match;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)      i2cbrmsb <= {`SBDW{1'b0}};
     else if (wena_i2cbrmsb) i2cbrmsb <= sb_dat_i;

   assign i2cbrmsb_wt = id_wstb_pulse & i2cbrmsb_match;

   // I2CBR
   assign i2cbr = {i2cbrmsb[`I2CBRW-`SBDW-1:0], i2cbrlsb};

   assign i2cbr_wt = i2cbrmsb_wt | i2cbrlsb_wt;
   // assign i2cbr_wt = i2cbrmsb_wt;

   assign trim_sda_del[3:0] = i2cbrmsb[`SBDW-1:`SBDW-4];
   
   // I2CSADDR
   wire i2csaddr_match = (sb_adr_i[3:0] == `ADDR_I2CSADDR);
   wire wena_i2csaddr  = id_wstb & i2csaddr_match;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)      i2csaddr <= {`SBDW{1'b0}};
     else if (wena_i2csaddr) i2csaddr <= sb_dat_i;

   assign i2csaddr_wt = id_wstb_pulse & i2csaddr_match;
   
   // I2CINTCR
   wire i2cintcr_match = (sb_adr_i [3:0] == `ADDR_I2CINTCR);
   wire wena_i2cintcr  = id_wstb & i2cintcr_match;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)      i2cintcr <= `DEFAULT_I2CINTCR;
     else if (wena_i2cintcr) i2cintcr <= sb_dat_i;

   // I2CRXDR RD PULSE
   assign i2crxdr_rd = id_rstb_pulse & (sb_adr_i[3:0] == `ADDR_I2CRXDR);

   // I2CTCDR RD PULSE
   assign i2cgcdr_rd = id_rstb_pulse & (sb_adr_i[3:0] == `ADDR_I2CGCDR);
   
   // sb_dat_o MUX
   always @(/*AUTOSENSE*/`ADDR_I2CBRLSB or `ADDR_I2CBRMSB
            or `ADDR_I2CCMDR or `ADDR_I2CCR1 or `ADDR_I2CGCDR
            or `ADDR_I2CINTCR or `ADDR_I2CINTSR or `ADDR_I2CRXDR
            or `ADDR_I2CSADDR or `ADDR_I2CSR or `ADDR_I2CTXDR or `SBDW
            or i2cbrlsb or i2cbrmsb or i2ccmdr or i2ccr1 or i2cgcdr
            or i2cintcr or i2crxdr or i2csaddr or i2csr or i2ctxdr
            or irq_arbl or irq_hgc or irq_troe or irq_trrdy
            or sb_adr_i)
     begin
      case (sb_adr_i[3:0])
        `ADDR_I2CCR1  : rdmux_dat = i2ccr1;
        `ADDR_I2CCMDR : rdmux_dat = i2ccmdr;
        `ADDR_I2CBRLSB: rdmux_dat = i2cbrlsb;
        `ADDR_I2CBRMSB: rdmux_dat = i2cbrmsb;
        `ADDR_I2CSR   : rdmux_dat = i2csr;
        `ADDR_I2CTXDR : rdmux_dat = i2ctxdr;
        `ADDR_I2CRXDR : rdmux_dat = i2crxdr;
        `ADDR_I2CGCDR : rdmux_dat = i2cgcdr;
        `ADDR_I2CINTCR: rdmux_dat = i2cintcr;
        `ADDR_I2CINTSR: rdmux_dat = {{4{1'b0}}, irq_arbl, irq_trrdy, irq_troe, irq_hgc};
        `ADDR_I2CSADDR: rdmux_dat = i2csaddr;
        default       : rdmux_dat = {`SBDW{1'b0}};
      endcase // case (adr_i[3:0])
   end // always @ (...

   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async) sb_dat_o <= 0;
     else if (ip_rstb)  sb_dat_o <= rdmux_dat;
     else               sb_dat_o <= 0;

   // ****************************************************************************************
   // Interrupt Lotic
   // ****************************************************************************************
   wire match_intsr = (sb_adr_i[3:0] == `ADDR_I2CINTSR);
   assign i2cintsr_wt = id_wstb_pulse & match_intsr;
   assign i2cintsr_rd = id_rstb_pulse & match_intsr;

   wire int_clr_all = i2cintcr[`INDEX_INTCLR] & i2cintsr_rd;
   
   wire int_force = i2cintcr[`INDEX_INTFRC];
   
   // IRQ ARBL
   wire int_arbl;
   wire int_set_arbl = i2csr[`INDEX_ARBL];
   wire int_clr_arbl = (i2cintsr_wt & sb_dat_i[`INDEX_ARBL]) | int_clr_all;
   sci_int_reg intr_arbl(
                         // Outputs
                         .status                (int_arbl),
                         // Inputs
                         .rst_async             (i2c_rst_async),
                         .sb_clk_i              (sb_clk_i),
                         .int_force             (int_force),
                         .int_set               (int_set_arbl),
                         .int_clr               (int_clr_arbl),
                         .scan_test_mode        (scan_test_mode));

   assign irq_arbl = i2cintcr[`INDEX_ARBL] & int_arbl;

   // IRQ TRRDY
   wire int_trrdy;
   wire int_set_trrdy = i2csr[`INDEX_TRRDY];
   wire int_clr_trrdy = (i2cintsr_wt & sb_dat_i[`INDEX_TRRDY]) | int_clr_all;
   sci_int_reg intr_trrdy(
                          // Outputs
                          .status                (int_trrdy),
                          // Inputs
                          .rst_async             (i2c_rst_async),
                          .sb_clk_i              (sb_clk_i),
                          .int_force             (int_force),
                          .int_set               (int_set_trrdy),
                          .int_clr               (int_clr_trrdy),
                          .scan_test_mode        (scan_test_mode));

   assign irq_trrdy = i2cintcr[`INDEX_TRRDY] & int_trrdy;

   // IRQ TROD
   wire int_troe;
   wire int_set_troe = i2csr[`INDEX_TROE];
   wire int_clr_troe = (i2cintsr_wt & sb_dat_i[`INDEX_TROE]) | int_clr_all;
   sci_int_reg intr_troe(
                         // Outputs
                         .status                (int_troe),
                         // Inputs
                         .rst_async             (i2c_rst_async),
                         .sb_clk_i              (sb_clk_i),
                         .int_force             (int_force),
                         .int_set               (int_set_troe),
                         .int_clr               (int_clr_troe),
                         .scan_test_mode        (scan_test_mode));
   
   assign irq_troe = i2cintcr[`INDEX_TROE] & int_troe;

   // IRQ HGC
   wire int_hgc;
   wire int_set_hgc = i2csr[`INDEX_HGC];
   wire int_clr_hgc = (i2cintsr_wt & sb_dat_i[`INDEX_HGC]) | int_clr_all;
   sci_int_reg intr_hgc(
                        // Outputs
                        .status                (int_hgc),
                        // Inputs
                        .rst_async             (i2c_rst_async),
                        .sb_clk_i              (sb_clk_i),
                        .int_force             (int_force),
                        .int_set               (int_set_hgc),
                        .int_clr               (int_clr_hgc),
                        .scan_test_mode        (scan_test_mode));
   
   assign irq_hgc = i2cintcr[`INDEX_HGC] & int_hgc;

   assign i2c_irq = irq_arbl | irq_trrdy | irq_troe | irq_hgc;
   
endmodule // i2c_sci
