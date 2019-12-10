`include "defines3.v"
`timescale 1 ns / 1 ps
module spi_port (/*AUTOARG*/
   // Outputs
   mclk_o, mclk_oe, mosi_o, mosi_oe, miso_o, miso_oe, mcsn_o, mcsn_oe,
   spisr, spirxdr, spi_wkup,
   // Inputs
   spi_rst_async, sck_tcv, mosi_i, miso_i, scsn_usr, sb_clk_i, spicr0,
   spicr1, spicr2, spibr, spicsr, spitxdr, spicr0_wt, spicr1_wt,
   spicr2_wt, spibr_wt, spicsr_wt, spitxdr_wt, spirxdr_rd
   );

   /**************************************************************/
   // INPUTS
   /**************************************************************/
   input spi_rst_async;
   
   input sck_tcv;
   input mosi_i, miso_i;
   input scsn_usr;
   
   input sb_clk_i;

   input [`SBDW-1:0] spicr0;    //SPI Control Register 0 from SCI (Optional, Default F00)
   input [`SBDW-1:0] spicr1;    //SPI Control Register 1 from SCI
   input [`SBDW-1:0] spicr2;    //SPI Control Register 2 from SCI    
   input [`SBDW-1:0] spibr;     //SPI Baud rate Register from SCI
   input [`SBDW-1:0] spicsr;    //SPI Master Chip Select Mask from SCI
   input [`SBDW-1:0] spitxdr;   //SPI Transmit Data Register from SCI

   input spicr0_wt, spicr1_wt, spicr2_wt, spibr_wt, spicsr_wt, spitxdr_wt;
   input spirxdr_rd;

   /**************************************************************/
   // OUTPUTS
   /**************************************************************/
   output mclk_o, mclk_oe;      //SPI Master Clock Output & Enable
   output mosi_o, mosi_oe;
   output miso_o, miso_oe;
   output [`SBDW-1:0] mcsn_o, mcsn_oe;
   
   output [`SBDW-1:0] spisr;
   output [`SBDW-1:0] spirxdr;

   output             spi_wkup;
   
   /**************************************************************/
   // REGISTERS
   /**************************************************************/
   reg spi_busy_sync, spi_tip_sync;
   reg spi_trdy, spi_rrdy, spi_toe, spi_roe, spi_mdf;

   reg rcv_rdy, trn_reg;
   reg [`SBCW-1:0] tcv_cnt;
   reg [`SBDW-1:0] tcv_reg, rcv_reg;
   reg [1:0]      spi_trn_cap_sync, spi_trn_nb_cap_sync, spi_rcv_upd_sync;
   reg [1:0]      byte_bndy_sync, byte_bndy_nd_sync;
   reg [3:0]      mst_state, mst_next;                 // PSM WH : CF-9 (Change from 3 bits to 4 bits)
   reg [3:0]      dly_cnt;
   reg [`SBDW-1:0] mcsn_o;
   reg             mclk_oe;
   reg [`SBDW-1:0] slave_trn_dat;
   reg            spi_mhld_act, spi_trdy_sample, spi_rrdy_sample, spi_trdy_srmok;
   reg            spi_mfin_sync;

   reg 		  byte_bndy, byte_bndy_nd;
   reg            rcv_bit;
   
   reg 		  spi_master;

   // reg 		  mclk_sense, mcsn_sense;          // PSM WH : CF-9 (Comment out since using `SYNCP)
   
   /**************************************************************/
   // WIRES
   /**************************************************************/
   wire spis_rst_sync, spim_rst_sync, spi_rst_sync;
   wire sb_ctr_wt, sb_csr_wt, sb_rst_wt;
   wire st_cken, st_mcsn, st_ldly, st_mrun, st_hold, st_tdly, st_rcsn, st_ckds, st_idly;
   wire mcsn, spi_csn_all;
   wire spi_slv_en, spi_mstr_en, tcv_en;
   wire delay_done;

   wire spi_busy, spi_tip;
   wire spi_mck_exp;
   // wire spi_intf;

   wire trn_out;
   wire byte_init;
   wire byte_bndy_mhld_pulse, byte_bndy_nd_pulse;
   wire tcv_cap_upd, spi_trn_cap, spi_trn_cap_nb, spi_rcv_upd;
   wire trn_cap_bit, trn_shf_bit;
   wire [`SBDW-1:0] tcv_cap_dat, tcv_shf_dat;
   wire [`SBDW-1:0] trn_dat;
   wire [`SBDW-1:0] mcsn_oe;
   
   // ******************************************
   // ** SPI Coontrol Register Bit Definition **
   // ******************************************
   wire spi_en       = spicr1[7];
   wire spi_wkup_usr = spicr1[6];
   
   wire spi_tx_edge  = spicr1[4];
   wire spi_stx_dir  = spicr1[3];
   wire spi_scsdis   = spicr1[2];
   wire [1:0] spi_iodir = spicr1[1:0];


   wire spi_mstr   = spicr2[7];
   wire spi_mcsh   = spicr2[6];
   wire spi_srme   = spicr2[5] & ~spi_mstr;
   wire spi_sfbk   = ~spicr2[4] & spicr2[3] & ~spi_mstr;
   // wire spi_dual   = spicr2[4] & ~spicr2[3];
   // wire spi_quad   = spicr2[4] & spicr2[3];
   wire spi_cpol   = spicr2[2];
   wire spi_cpha   = spicr2[1];
   wire spi_lsbf   = spicr2[0];

   wire spi_mclk_exp = spibr[7];
   
   wire [3:0] spi_ldly_cnt = spi_tx_edge ? {spicr0[2:0], 1'b1} : {1'b0, spicr0[2:0]};
   wire [3:0] spi_tdly_cnt = {1'b0, spicr0[5:3]};
   wire [3:0] spi_idly_cnt = {{2{1'b0}}, spicr0[7:6]};

   wire       mclk_settle, mcsn_settle;         // PSM WH : CF-9
   wire       master_en, master_start, master_hldcs, master_done;

   wire       spi_port_sck_tcv_inv;

   wire       scsn_int = spi_scsdis & master_en ? 1'b1 : scsn_usr;    // Lightning

   // ********************************************************************************************
   // SCK_TCV Handlin;, Easy to anchor the generated clock
   // ********************************************************************************************
   wire       sck_tcv_inv;
   wire       sck_tcv_fin;
   CKHS_INVX1 u_sclk_inv (.z(sck_tcv_inv), .a(sck_tcv));
   CKHS_MUX2X2 u_sclk_mux (.z(sck_tcv_fin), .d1(sck_tcv_inv), .d0(sck_tcv), .sd(spi_port_sck_tcv_inv));
   // ********************************************************************************************

   // ********************************************************************************************
   // SCK_TCV_EARLY Handling; Easy to anchor the generated clock
   // ********************************************************************************************
   wire       sck_tcv_early;
   wire       sck_tcv_early_fin = spi_port_sck_tcv_inv ^ mclk_o;             // PSM WH : FB-11
   CKHS_BUFX4 u_sck_tcv_early_buf (.z(sck_tcv_early), .a(sck_tcv_early_fin));
   // ********************************************************************************************
                           
   assign sb_ctr_wt = spicr0_wt | spicr1_wt | spicr2_wt | spibr_wt;
   assign sb_csr_wt = spicsr_wt;
   assign sb_rst_wt = sb_ctr_wt | sb_csr_wt;
   
   assign spis_rst_sync = sb_rst_wt;
   assign spim_rst_sync = st_idly & delay_done;
   // assign spi_rst_sync  = spi_master ? spim_rst_sync : spis_rst_sync;
   assign spi_rst_sync = spis_rst_sync;                                                 // PSM WH : FB-02
   
   // ******************************************
   // ************ Master Mode FSM *************
   // ******************************************
   parameter mst_idle = 4'b0000;                // PSM WH : CF-9
   parameter mst_cken = 4'b0001;                // PSM WH : CF-9
   parameter mst_ckmo = 4'b0011;                // PSM WH : CF-9
   parameter mst_mcsn = 4'b0010;                // PSM WH : CF-9
   parameter mst_ldly = 4'b0110;                // PSM WH : CF-9
   parameter mst_mrun = 4'b0111;                // PSM WH : CF-9
   parameter mst_mhld = 4'b0101;                // PSM WH : CF-9
   parameter mst_tdly = 4'b0100;                // PSM WH : CF-9
   parameter mst_rcsn = 4'b1100;                // PSM WH : CF-9
   parameter mst_csmo = 4'b1101;                // PSM WH : CF-9
   parameter mst_ckds = 4'b1001;                // PSM WH : CF-9
   parameter mst_idly = 4'b1000;                // PSM WH : CF-9

   // States
   // assign    spi_master = (mst_state != mst_idle);
   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async) spi_master <= 1'b0;
     else               spi_master <= (mst_next != mst_idle);

   assign    st_cken = (mst_state == mst_cken);       // PSM WH : CF-9
   assign    st_mcsn = (mst_state == mst_mcsn);
   assign    st_ldly = (mst_state == mst_ldly);
   assign    st_mrun = (mst_state == mst_mrun);
   assign    st_hold = (mst_state == mst_mhld);
   assign    st_tdly = (mst_state == mst_tdly);
   assign    st_rcsn = (mst_state == mst_rcsn);
   assign    st_ckds = (mst_state == mst_ckds);       // PSM WH : CF-9
   assign    st_idly = (mst_state == mst_idly);
   
   // Combinational portion of the state machine
   wire      master_nocsn = (&spicsr);
   assign    master_en    = spi_en & spi_mstr;
   assign    master_start = master_en & ~spi_trdy & ~master_nocsn;
   assign    master_hldcs = byte_bndy_mhld_pulse & ~sb_rst_wt;
   assign    master_done  = sb_ctr_wt | (byte_bndy_nd_pulse & (~master_en | spi_mfin_sync));

   wire      finish_hold = ~spi_trdy | sb_rst_wt;
   always @(/*AUTOSENSE*/delay_done or finish_hold or master_done
            or master_hldcs or master_nocsn or master_start
            or mclk_settle or mcsn_settle or mst_state)
     begin
        case (mst_state)
          mst_idle : begin
             if (master_start)     mst_next = mst_cken;
             else                  mst_next = mst_idle;
          end
	  mst_cken :               mst_next = mst_ckmo;              // PSM WH : CF-9
	  mst_ckmo : begin                                           // PSM WH : CF-9
	     if (mclk_settle)      mst_next = mst_mcsn;              // PSM WH : CF-9
	     else                  mst_next = mst_ckmo;              // PSM WH : CF-9
	  end                                                        // PSM WH : CF-9
          mst_mcsn : begin
             if (master_nocsn)     mst_next = mst_idle;
	     else                  mst_next = mst_ldly;
	  end
          mst_ldly : begin
             if (delay_done)       mst_next = mst_mrun;
             else                  mst_next = mst_ldly;
          end
          mst_mrun : begin
             if (master_hldcs)     mst_next = mst_mhld;
             else if (master_done) mst_next = mst_tdly;
             else                  mst_next = mst_mrun;
          end
          mst_mhld : begin
             if (finish_hold)      mst_next = mst_mrun;              // PSM WH : FB-11
             else                  mst_next = mst_mhld;
          end
          mst_tdly : begin
             if (delay_done)       mst_next = mst_rcsn;
             else                  mst_next = mst_tdly;
          end
          mst_rcsn :               mst_next = mst_csmo;
	  mst_csmo : begin                                           // PSM WH : CF-9
	     if (mcsn_settle)      mst_next = mst_ckds;              // PSM WH : CF-9
	     else                  mst_next = mst_csmo;              // PSM WH : CF-9
	  end                                                        // PSM WH : CF-9
	  mst_ckds :               mst_next = mst_idly;              // PSM WH : CF-9
          mst_idly : begin
             if (delay_done)       mst_next = mst_idle;
             else                  mst_next = mst_idly;
          end
          default :                mst_next = mst_idle;
        endcase // case(mst_state)
     end // always @ (...

   // Sequential block
   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async) mst_state <= mst_idle;
     else               mst_state <= mst_next;
   
   // ******************************************
   // ********* Master Clock Divider ***********
   // ******************************************
   reg mclk_en;
   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async)             mclk_en <= 1'b0;
     else if (st_cken)              mclk_en <= 1'b1;              // PSM WH : CF-9 (change from st_mcsn to st_cken)
     else if (st_idly & delay_done) mclk_en <= 1'b0;
   
   wire dly_cnt_st = st_ldly | st_tdly | st_idly;
   // wire mclk_run = st_mrun | dly_cnt_st;
   // wire mclk_tog = st_mrun;
   wire mclk_tog = st_mrun & ~(master_hldcs | master_done);       // PSM WH : FB-01
   wire mclk_run = mclk_tog | dly_cnt_st;                         // PSM WH : FB-01
   
   wire hlf_cyc;
   spi_div #(6, 6'b000001) mclk_divider (// Outputs
                                         .clk_out       (mclk_o),
                                         .hlf_cyc       (hlf_cyc),
                                         // Inputs
                                         .clk_in        (sb_clk_i),
                                         .clk_en        (mclk_en),
                                         .clk_run       (mclk_run),
                                         .clk_tog       (mclk_tog),
                                         .clk_pol       (spi_cpol),
                                         .div_exp       (spi_mclk_exp),
                                         .div           (spibr[5:0]));
   
   // ******************************************
   // ****** Master L/T/I Delay Counter ********
   // ******************************************
   wire dly_cnt_en = dly_cnt_st & hlf_cyc;
   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async) dly_cnt <= 4'b0000;
     else if (st_mcsn)  dly_cnt <= spi_ldly_cnt;
     else if (st_mrun)  dly_cnt <= spi_tdly_cnt;
     else if (st_rcsn)  dly_cnt <= spi_idly_cnt;
     else               dly_cnt <= dly_cnt_en ? dly_cnt - 1 : dly_cnt;
   
   assign delay_done = (dly_cnt == 4'b0000) & dly_cnt_en;

   // ******************************************
   // ******* Master Chip Select output ********
   // ******************************************
   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async)     mcsn_o <= 8'b11111111;
     else if (st_mcsn)      mcsn_o <= spicsr;
     else if (st_rcsn)      mcsn_o <= 8'b11111111;

   assign mcsn_oe = ~mcsn_o;

   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async)     mclk_oe <= 1'b0;
     else if (st_cken)      mclk_oe <= 1'b1;                         // PSM WH : CF-9 (change from st_mcsn to st_cken)
     else if (st_ckds)      mclk_oe <= 1'b0;                         // PSM WH : CF-9 (change from st_rcsn_d[0] to st_ckds)
   
   // ******************************************
   // *********** SPI status flags *************
   // ******************************************
   assign spi_busy = ~spi_csn_all;
   assign spi_tip  = ~byte_bndy;

   reg 	  byte_bndy_early;                                           // PSM WH : FB-11
   always @(posedge sck_tcv_early or posedge spi_csn_all)            // PSM WH : FB-11
     if (spi_csn_all) byte_bndy_early <= 1'b1;                       // PSM WH : FB-11
     else if (tcv_en) byte_bndy_early <= (tcv_cnt == 3'b110);        // PSM WH : FB-11
     else             byte_bndy_early <= byte_bndy;                  // PSM WH : FB-11
   
   always @(negedge sck_tcv_early or posedge spi_csn_all)            // PSM WH : FB-11
     if (spi_csn_all) byte_bndy_nd <= 1'b1;                          // PSM WH : FB-11
     else             byte_bndy_nd <= byte_bndy_early;               // PSM WH : FB-11

   always @(posedge sck_tcv_early or posedge spi_csn_all)
     if (spi_csn_all) spi_mhld_act <= 1'b0;
     else if (tcv_en) spi_mhld_act <= spi_mstr & spi_mcsh & spi_trdy & (tcv_cnt == 3'b110); 
   
   // Synchronizers
   // always @(posedge sb_clk_i) byte_bndy_sync <= {byte_bndy_sync[0], byte_bndy};
   always @(posedge sb_clk_i) byte_bndy_sync <= {byte_bndy_sync[0], spi_mhld_act};    // PSM WH : FB-11
   assign byte_bndy_mhld_pulse = byte_bndy_sync[0] & ~byte_bndy_sync[1];

   always @(negedge sb_clk_i) byte_bndy_nd_sync <= {byte_bndy_nd_sync[0], byte_bndy_nd};   // Lightning
   assign byte_bndy_nd_pulse = byte_bndy_nd_sync[0] & ~byte_bndy_nd_sync[1];
   
   always @(posedge sb_clk_i) spi_trn_cap_sync <= {spi_trn_cap_sync[0], spi_trn_cap};
   wire   spi_trn_cap_pulse = ~spi_trn_cap_sync[0] & spi_trn_cap_sync[1];

   always @(posedge sb_clk_i) spi_trn_nb_cap_sync <= {spi_trn_nb_cap_sync[0], spi_trn_cap_nb};
   wire   spi_trn_nb_cap_pulse = ~spi_trn_nb_cap_sync[0] & spi_trn_nb_cap_sync[1];

   always @(posedge sb_clk_i) spi_rcv_upd_sync <= {spi_rcv_upd_sync[0], spi_rcv_upd};
   // wire   spi_rcv_upd_pulse = ~spi_rcv_upd_sync[0] & spi_rcv_upd_sync[1];
   wire   spi_rcv_upd_pulse = spi_rcv_upd_sync[0] & ~spi_rcv_upd_sync[1];              // PSM WH : FB-11
   
   // always @(posedge sb_clk_i) mclk_sense <= sck_tcv_fin;  // PSM WH : CF-9
   wire   mclk_sense;
   SYNCP_STD mclk_sync (.cdn(1'b1), .ck(sb_clk_i), .d(sck_tcv_fin), .q(mclk_sense));
   assign mclk_settle = ~(spi_cpha ^ mclk_sense);       // PSM WH : CF-9 (-> ((spi_cpol ^ spi_cpha) ?? ~spi_cpol : spi_cpol) == mclk_sense)

   // always @(posedge sb_clk_i) mcsn_sense <= mcsn;    // PSM WH : CF-9
   wire   mcsn_sense;
   SYNCP_STD mcsn_sync (.cdn(1'b1), .ck(sb_clk_i), .d(mcsn), .q(mcsn_sense));
   assign mcsn_settle = mcsn_sense;                     // PSM WH : CF-9
   
   // Master Sychronize termination
   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async)               spi_mfin_sync <= 1'b0;
     else if (spi_master & sb_csr_wt) spi_mfin_sync <= 1'b1;
     else if (spim_rst_sync)          spi_mfin_sync <= 1'b0;
   
   // Status Flags
   always @(posedge sb_clk_i) spi_busy_sync <= spi_busy;
   always @(posedge sb_clk_i) spi_tip_sync  <= spi_tip;

   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async)          spi_trdy <= 1'b1;
     else if (spi_rst_sync)      spi_trdy <= 1'b1;
     else if (spitxdr_wt)        spi_trdy <= 1'b0;
     else if (spi_trn_cap_pulse) spi_trdy <= 1'b1;

   reg [1:0] spi_trdy_sample_sense;
   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async) spi_trdy_sample_sense <= 2'b00;
     else               spi_trdy_sample_sense <= {spi_trdy_sample_sense[0], spi_trdy_sample};
   wire      spi_trdy_sample_sense_rp = spi_trdy_sample_sense[0] & ~spi_trdy_sample_sense[1];
   wire      spi_trdy_sample_sense_fp = ~spi_trdy_sample_sense[0] & spi_trdy_sample_sense[1];

   reg 	     spi_trdy_sample_flag;
   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async) spi_trdy_sample_flag <= 1'b0;
     else if (spi_trdy_sample_sense_rp) spi_trdy_sample_flag <= 1'b1;
     else if (st_hold & spitxdr_wt)     spi_trdy_sample_flag <= 1'b0;  
     else if (spi_trdy_sample_sense_fp) spi_trdy_sample_flag <= 1'b0;  
   
   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async)             spi_toe <= 1'b0;
     else if (spi_rst_sync)         spi_toe <= 1'b0; 
     else if (spitxdr_wt)           spi_toe <= 1'b0;
     else if (spi_trn_nb_cap_pulse) spi_toe <= spi_trdy_sample_flag ? spi_trdy_sample_flag : spi_toe;
   
   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async)          spi_rrdy <= 1'b0;
     else if (spi_rst_sync)      spi_rrdy <= 1'b0;
     else if (spirxdr_rd)        spi_rrdy <= 1'b0;
     else if (spi_rcv_upd_pulse) spi_rrdy <= 1'b1;

   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async)          spi_roe <= 1'b0;
     else if (spi_rst_sync)      spi_roe <= 1'b0;
     else if (spirxdr_rd)        spi_roe <= 1'b0;
     else if (spi_rcv_upd_pulse) spi_roe <= spi_rrdy ? spi_rrdy : spi_roe;

   wire      spi_mode_fail = spi_master & (~scsn_int);

   always @(posedge sb_clk_i or posedge spi_rst_async)
     if (spi_rst_async)      spi_mdf <= 1'b0;
     else if (spi_rst_sync)  spi_mdf <= 1'b0;
     else if (spi_mode_fail) spi_mdf <= 1'b1;
   
   // ******************************************
   // ******** SPI Transmitter/Receiver ********
   // ******************************************
   // SPI Clock Option 
   assign spi_port_sck_tcv_inv = (spi_cpha ^ spi_cpol);

   assign mcsn = (&mcsn_o);
   assign spi_csn_all = scsn_int & mcsn;
   assign spi_slv_en  = spi_en & ~scsn_int;
   assign spi_mstr_en = spi_en & ~mcsn;
   assign tcv_en = spi_slv_en | spi_mstr_en;
   
   // Receiver Data Mux
   wire rcv_bit_spi = spi_master ? miso_i : mosi_i;

   always @(/*AUTOSENSE*/miso_i or mosi_i or rcv_bit_spi or spi_iodir)                                           // Lightning
     begin
       case (spi_iodir)
         2'b00   : rcv_bit = rcv_bit_spi;
         2'b01   : rcv_bit = miso_i;
         2'b10   : rcv_bit = mosi_i;
         2'b11   : rcv_bit = rcv_bit_spi;
         default : rcv_bit = rcv_bit_spi;
       endcase // case (spi_iodir)
     end

   // Transmitter Data Mux
   assign trn_dat = spi_master ? spitxdr : slave_trn_dat;

   wire   spi_trdy_sample_rst = spi_csn_all & ~spi_trdy;
   wire   spi_trdy_sample_set = spi_csn_all &  spi_trdy;
   wire   byte_sample = (tcv_cnt == 3'b110);
   always @(posedge sck_tcv_fin or posedge spi_trdy_sample_rst or posedge spi_trdy_sample_set)
     if (spi_trdy_sample_rst)      spi_trdy_sample <= 1'b0;
     else if (spi_trdy_sample_set) spi_trdy_sample <= 1'b1;
     else if (byte_sample)         spi_trdy_sample <= spi_trdy;

   always @(posedge sck_tcv_fin or posedge spi_csn_all)
     if (spi_csn_all)      spi_trdy_srmok <= 1'b1;
     else if (byte_sample) spi_trdy_srmok <= spi_trdy_sample;

   always @(posedge sck_tcv_fin or posedge spi_csn_all)
     if (spi_csn_all)      spi_rrdy_sample <= 1'b0;
     else if (byte_sample) spi_rrdy_sample <= spi_rrdy;                        // PSM WH/JC : FB-18
   
   always @(/*AUTOSENSE*/`SBDW or spi_rrdy_sample or spi_sfbk
            or spi_srme or spi_stx_dir or spi_trdy_sample
            or spi_trdy_srmok or spitxdr)
     begin
        if (spi_srme) begin
           if (~spi_trdy_sample & ~spi_trdy_srmok)     slave_trn_dat = spitxdr;
           else if (~spi_trdy_sample & spi_trdy_srmok) slave_trn_dat = {`SBDW{1'b0}};
           else                                        slave_trn_dat = {`SBDW{1'b1}};
        end
        else if (spi_sfbk) begin
           if (~spi_trdy_sample)                       slave_trn_dat = spitxdr;
           else if (spi_rrdy_sample)                   slave_trn_dat = {`SBDW{1'b0}};
           else                                        slave_trn_dat = {`SBDW{1'b1}};
        end
        else begin
           if (spi_trdy_sample & ~spi_stx_dir)         slave_trn_dat = {`SBDW{1'b1}};
           else                                        slave_trn_dat = spitxdr;
        end
     end // always @ (...
   
   // Tranceiver counter
   always @(posedge sck_tcv_fin or posedge spi_csn_all)
     if (spi_csn_all) tcv_cnt <= {`SBCW{1'b1}};
     else if (tcv_en) tcv_cnt <= tcv_cnt + 1;

   // Byte transmitte/receive done
   always @(posedge sck_tcv_fin or posedge spi_csn_all)
     if (spi_csn_all) byte_bndy <= 1'b1;
     else if (tcv_en) byte_bndy <= (tcv_cnt == 3'b110);

   // always @(negedge sck_tcv_fin or posedge spi_csn_all)  // PSM WH : FB-11
   //   if (spi_csn_all) byte_bndy_nd <= 1'b1;              // PSM WH : FB-11
   //   else             byte_bndy_nd <= byte_bndy;         // PSM WH : FB-11
   
   assign byte_init = ~(|tcv_cnt);

   // Receive data ready flag (skip first time)
   always @(posedge sck_tcv_fin or posedge spi_csn_all)
     if (spi_csn_all)    rcv_rdy <= 1'b0;
     else if (byte_init) rcv_rdy <= 1'b1;

   // Receiver / Shifter
   assign tcv_cap_upd = tcv_en & byte_bndy;
   assign spi_trn_cap = (tcv_cap_upd & (~spi_trdy_sample | spi_mhld_act) & (~spi_srme | ~spi_trdy_srmok));
   assign spi_trn_cap_nb = (tcv_cap_upd & (~spi_srme | ~spi_trdy_srmok));
   
   assign spi_rcv_upd = rcv_rdy & tcv_cap_upd;
   
   assign tcv_cap_dat = spi_lsbf ? {rcv_bit, trn_dat[`SBDW-1:1]} : {trn_dat[`SBDW-2:0], rcv_bit};
   assign tcv_shf_dat = spi_lsbf ? {rcv_bit, tcv_reg[`SBDW-1:1]} : {tcv_reg[`SBDW-2:0], rcv_bit};

   wire   tcv_reg_rst_0 = spi_csn_all & ~trn_dat[0];
   wire   tcv_reg_set_0 = spi_csn_all &  trn_dat[0];

   wire   tcv_reg_rst_7 = spi_csn_all & ~trn_dat[7];
   wire   tcv_reg_set_7 = spi_csn_all &  trn_dat[7];

   always @(posedge sck_tcv_fin or posedge tcv_reg_rst_0 or posedge tcv_reg_set_0)
     if (tcv_reg_rst_0)      tcv_reg[0] <= 1'b0;
     else if (tcv_reg_set_0) tcv_reg[0] <= 1'b1;
     else if (tcv_cap_upd)   tcv_reg[0] <= tcv_cap_dat[0];
     else if (tcv_en)        tcv_reg[0] <= tcv_shf_dat[0];
   
   always @(posedge sck_tcv_fin or posedge spi_csn_all)
     if (spi_csn_all)        tcv_reg[`SBDW-2:1] <= {`SBDW-2{1'b1}};
     else if (tcv_cap_upd)   tcv_reg[`SBDW-2:1] <= tcv_cap_dat[`SBDW-2:1];
     else if (tcv_en)        tcv_reg[`SBDW-2:1] <= tcv_shf_dat[`SBDW-2:1];

   always @(posedge sck_tcv_fin or posedge tcv_reg_rst_7 or posedge tcv_reg_set_7)
     if (tcv_reg_rst_7)      tcv_reg[`SBDW-1] <= 1'b0;
     else if (tcv_reg_set_7) tcv_reg[`SBDW-1] <= 1'b1;
     else if (tcv_cap_upd)   tcv_reg[`SBDW-1] <= tcv_cap_dat[`SBDW-1];
     else if (tcv_en)        tcv_reg[`SBDW-1] <= tcv_shf_dat[`SBDW-1];
   
   // Transimitter
   assign trn_cap_bit = spi_lsbf ? trn_dat[0] : trn_dat[`SBDW-1];
   assign trn_shf_bit = spi_lsbf ? tcv_reg[0] : tcv_reg[`SBDW-1];

   wire   trn_reg_rst = spi_csn_all & ~trn_cap_bit;
   wire   trn_reg_set = spi_csn_all &  trn_cap_bit;
   always @(negedge sck_tcv_fin or posedge trn_reg_rst or posedge trn_reg_set)
     if (trn_reg_rst)      trn_reg <= 1'b0;
     else if (trn_reg_set) trn_reg <= 1'b1;
     else if (tcv_cap_upd) trn_reg <= trn_cap_bit;
     else if (tcv_en)      trn_reg <= trn_shf_bit;

   assign trn_out = spi_tx_edge ? (tcv_cap_upd ? trn_cap_bit : trn_shf_bit) : trn_reg;
   
   // Receiver Buffer
   // always @(negedge sck_tcv_fin or posedge spi_csn_all)
   //   if (spi_csn_all)      rcv_reg <= {`SBDW{1'b1}};
   //   else if (spi_rcv_upd) rcv_reg <= tcv_reg;
   always @(posedge sck_tcv_fin)                                            // PSM WH : FB-11
     if (rcv_rdy & tcv_en & (tcv_cnt == 3'b110)) rcv_reg <= tcv_shf_dat;    // PSM WH : FB-11
   
   // ******************************************
   // ************* Wakeup Signal **************
   // ******************************************
   assign spi_wkup = (spi_wkup_usr & ~scsn_int);
   
   // ******************************************
   // *********** SPI Output Signals ***********
   // ******************************************
   // Outputs to Wishbone Bus
   assign spirxdr = rcv_reg;
   assign spisr   = {spi_tip_sync, spi_busy_sync, 1'b0, spi_trdy, spi_rrdy, spi_toe, spi_roe, spi_mdf};

   // Output to Pins
   reg    mosi_oe;
   always @(/*AUTOSENSE*/spi_iodir or spi_mstr_en or spi_slv_en)    // Lightning
     begin
        case (spi_iodir)
          2'b00   : mosi_oe = spi_mstr_en;
          2'b01   : mosi_oe = (spi_mstr_en) | (spi_slv_en);
          2'b10   : mosi_oe = 1'b0;
          2'b11   : mosi_oe = spi_mstr_en;
          default : mosi_oe = spi_mstr_en;
        endcase // case (spi_iodir)
     end
                              
   assign mosi_o  = mosi_oe ? trn_out : 1'b1;

   reg miso_oe;
   always @(/*AUTOSENSE*/spi_iodir or spi_mstr_en or spi_slv_en)    // Lightning
     begin
        case (spi_iodir)
          2'b00   : miso_oe = spi_slv_en;
          2'b01   : miso_oe = 1'b0;
          2'b10   : miso_oe = (spi_mstr_en) | (spi_slv_en);
          2'b11   : miso_oe = spi_slv_en;
          default : miso_oe = spi_slv_en;
        endcase // case (spi_iodir)
     end
   
   assign miso_o  = miso_oe ? trn_out : 1'b1;

endmodule // spi_port
