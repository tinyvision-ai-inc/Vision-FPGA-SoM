`include "defines2.v"
`timescale 1ns/1ps
module i2c_port (/*AUTOARG*/
   // Outputs
   sda_out, sda_oe, scl_out, scl_oe, i2crxdr, i2cgcdr, i2csr,
   i2c_hsmode, i2c_wkup,
   // Inputs
   ADDR_LSB_USR, i2c_rst_async, sda_in, scl_in, del_clk, sb_clk_i,
   i2ccr1, i2ccmdr, i2ctxdr, i2cbr, i2csaddr, i2ccr1_wt, i2ccmdr_wt,
   i2cbr_wt, i2ctxdr_wt, i2csaddr_wt, i2crxdr_rd, i2cgcdr_rd,
   trim_sda_del, scan_test_mode
   );

   // INPUTS
   // From Top Level Tie High/Tie Low
   input [1:0] ADDR_LSB_USR;

   // From full chip POR ...
   input i2c_rst_async;

   // From I2C Bus
   input sda_in;
   input scl_in;

   // From System Bus
   input del_clk;
   
   input sb_clk_i;
   
   // From SCI
   input [`SBDW-1:0]   i2ccr1, i2ccmdr, i2ctxdr;
   input [`I2CBRW-1:0] i2cbr;
   input [`SBDW-1:0]   i2csaddr;
   
   input        i2ccr1_wt, i2ccmdr_wt, i2cbr_wt, i2ctxdr_wt, i2csaddr_wt;
   input        i2crxdr_rd, i2cgcdr_rd;

   // From Trim Reg
   input [3:0]  trim_sda_del;

   // SCAN TEST SUPPORT
   input 	scan_test_mode;    // SCAN TEST SUPPORT
   
   // OUTPUTS
   // Port
   output       sda_out, sda_oe;
   output       scl_out, scl_oe;
   // To SCI
   output [7:0] i2crxdr;
   output [7:0] i2cgcdr;
   output [7:0] i2csr;

   // IO if needed
   output       i2c_hsmode;    // Potentially send out to turn on optional pull up current source
   
   // Power Manager
   output       i2c_wkup;      // Signal to wakeup from standy/sleep mode, Rising edge detect at Power Manager Block

   //*****************************************
   // Define states of the state machine
   //*****************************************
   parameter    TR_IDLE = 3'b000;
   parameter    TR_ADDR = 3'b001;
   parameter    TR_ACKA = 3'b011;
   parameter    TR_INFO = 3'b010;
   parameter    TR_ACKB = 3'b110;
   parameter    TR_RDAT = 3'b111;
   parameter    TR_ACKD = 3'b101;

   parameter    MC_IDLE = 4'b0000;
   parameter    MC_STAP = 4'b0010;
   parameter    MC_STAA = 4'b1000;
   parameter    MC_STAB = 4'b1001;
   parameter    MC_STAC = 4'b1011;
   parameter    MC_STAD = 4'b1010;
   parameter    MC_TRCA = 4'b1110;
   parameter    MC_TRCB = 4'b1111;
   parameter    MC_TRCC = 4'b1101;
   parameter    MC_TRCD = 4'b1100;
   parameter    MC_STRP = 4'b0011;
   parameter    MC_STOP = 4'b0001;
   parameter    MC_STOA = 4'b0100;
   parameter    MC_STOB = 4'b0110;
   parameter    MC_STOC = 4'b0111;
   parameter    MC_STOD = 4'b0101;

   // WIRES
   wire scl_clk = scl_in;
   wire trst_addr, trst_acka, trst_info, trst_ackb, trst_ackd;

   wire addr_gen, addr_hsmode, addr_10bit, addr_match2, addr_info;
   wire addr_musr7, addr_musr10;
   wire addr_mcfg7, addr_mcfg10;
   wire addr_match7, addr_match10;
   wire addr_ok, addr_ok_usr7, addr_ok_usr10, addr_ok_usr;

   wire info_updrst, info_updaddr, info_wkup, info_haddr;

   wire i2c_trn, i2c_rcv;
   wire i2c_trn_sync_mux;    // AEFB 00

   wire cap_txdr_act_nst, cap_txdr_act_syn, cap_txdr_act, cap_txdr_fin;
   wire rcv_rst, trcv_rst, trcv_all, trcv_shift, trcv_done;

   wire acka, ackb, ackd;
   wire i2c_troe, i2c_trrdy;

   wire rcv_addr_upd, rcv_info_upd, rcv_data_upd;
   wire upd_gcsr, upd_gcdr, upd_rxdr;

   wire tr_sda_ack, tr_sda_en, tr_sda_out;
   wire trst_ack_all;
   wire start_arbl;
   wire cmd_exec_en, cmd_exec_run, cmd_exec_fin;
   wire cmd_start, cmd_stop, cmd_rd, cmd_wt, cmd_rdwt;
   wire exec_start, exec_stop, exec_rd, exec_wt;
   wire rdwt_eval;
   
   wire [7:0] i2c_trn_dat;

   wire       sda_out_int;
   wire       sda_out_sense;

   wire       clk_str_cyc;

   wire       trst_rw_ok;
   wire       clk_en, clk_max;
   
   wire       trcv_start_pulse;
   wire       i2c_sb_rst;
   wire       exec_stsp;
   wire       mc_next_busy;
   wire       trst_busy;
   
   wire       trcv_cnt6_pulse, trcv_cnt6_sense;
   wire       ckstr_cnt_en;

   // REGISTERS
   reg       trcv_start, trcv_stop, trcv_arbl;
   reg [2:0] trcv_start_sync;
   reg [2:0] tr_state, tr_next;
   reg [7:0] trn_reg, rcv_reg;
   reg [2:0] trcv_cnt;
   reg       trn_rw, rcv_rw, rcv_arc, trn_ack;
   reg [6:0] rcv_addr;
   reg [7:0] rcv_info;
   reg [7:0] rcv_data;

   reg i2c_hsmode;

   reg i2c_hgc, i2c_arbl, i2c_trdy, i2c_toe, i2c_rrdy, i2c_roe;

   reg trst_ack_all_nd, trst_ack_all_pd;
   reg trcv_start_rst_d;
   reg exec_start_d;

   reg sda_out_sense_r;

   reg i2c_rcv_ok;
   reg tr_scl_out;

   reg mc_trn_pre, mc_trn_en;
   reg mc_sda_pre, mc_sda_out;
   reg mc_scl_pre, mc_scl_out;
   reg del_zero_states;
   
   reg [2:0] del_cnt_set_sense;

   reg trst_idle;
   reg trst_tip;
   reg trst_data;
   reg trcv_cnt6;

   reg mcst_master;
   reg cmd_exec_active;
   reg cmd_exec_wt;
   reg [1:0] exec_stsp_det;

   reg        trst_arc_d_sync, trst_arc_d_sync0;
   reg        trst_rw_ok_sync, trst_rw_ok_sync0;
   reg        i2c_rarc_sync, i2c_rarc_sync0;
   reg        i2c_srw_sync, i2c_srw_sync0;
   reg        i2c_arbl_sync, i2c_arbl_sync0;
   reg        i2c_tip_sync, i2c_tip_sync0;
   reg        i2c_busy_sync, i2c_busy_sync0;
   reg        i2c_scl_sense, i2c_scl_sense0;
   reg        mst_scl_sense, mst_scl_sense0;
   reg 	      i2c_trn_sync, i2c_trn_sync0;
   reg 	      i2c_rcv_sync, i2c_rcv_sync0;
   reg 	      addr_ok_usr_sync, addr_ok_usr_sync0;
   reg        addr_ok_sync, addr_ok_sync0;           // AEFB 00
   
   reg [2:0]  trcv_cnt6_sync;
   reg [1:0]  upd_rxdr_sync, upd_gcdr_sync, upd_gcsr_sync;
   reg [1:0]  cap_txdr_sync;
   
   reg        mcmd_stcmd, mcmd_start, mcmd_stop, cmd_exec_en_d;

   reg [15:0] clk_cnt;
   reg [3:0]  mc_state, mc_next;

   reg [7:0] i2crxdr;
   reg [7:0]  i2cgcdr;

   reg 	      ckstr_flag;
   
   //*****************************************
   // SCL SIDE
   //*****************************************

   // *****************************************
   // I2C Control Register Definition
   // *****************************************
   wire         i2c_en      = i2ccr1[7];
   wire         i2c_gcen    = i2c_en & i2ccr1[6];
   wire         i2c_wkupen  = i2c_en & i2ccr1[5];
   wire [1:0]   sda_del_sel = i2ccr1[3:2];

   wire         i2c_sta     = i2ccmdr[7];
   wire         i2c_sto     = i2ccmdr[6];
   wire         i2c_rd      = i2ccmdr[5] | i2ccmdr[1];
   wire         i2c_wt      = i2ccmdr[4];
   wire         i2c_nack    = i2ccmdr[3];
   wire         i2c_cksdis  = i2ccmdr[2];
   wire 	i2c_rbufdis = i2ccmdr[1];
   // wire      i2c_iack    = i2ccmdr[0];

   wire         i2c_rwbit   = i2ctxdr[0];

   // *****************************************
   // Generate start and stop Flag
   // *****************************************
   assign i2c_sb_rst = (i2ccr1_wt | i2cbr_wt | i2csaddr_wt);
   
   wire trcv_async_rst = ~scan_test_mode & (trcv_stop | i2c_rst_async | (i2ccr1_wt & ~i2c_en));
   // wire trcv_async_rst = por | (~scan_test_mode & trcv_stop);

   // Detect I2C Cycle Start
   // wire trcv_start_rst0 = i2c_rst_async | trcv_stop;
   always @(posedge scl_clk or posedge trcv_async_rst)
     if (trcv_async_rst) trcv_start_rst_d <= 1'b0;
     else                trcv_start_rst_d <= trcv_start;

   wire trcv_start_rst = i2c_rst_async | trcv_start_rst_d;
   always @(negedge sda_in or posedge trcv_start_rst)
     if (trcv_start_rst) trcv_start <= 1'b0;
     else                trcv_start <= trcv_start | scl_in; 

   // Detect I2C Cycle Stop
   wire trcv_stop_rst = (i2c_rst_async | trcv_start);
   always @(posedge sda_in or posedge trcv_stop_rst)
     if (trcv_stop_rst) trcv_stop <= 1'b0;
     else               trcv_stop <= scl_in;

   // Detect I2C Arbitration Lost
   wire trcv_arbl_rst = (trst_idle | i2c_rst_async);
   wire trcv_arbl_set = tr_sda_en & ~sda_in & sda_out;
   always @(posedge scl_clk or posedge trcv_arbl_rst)
     if (trcv_arbl_rst)      trcv_arbl <= 1'b0;
     else if (trcv_arbl_set) trcv_arbl <= 1'b1;

   // I2C HS_MODE flag
   wire hsmode_det = trst_acka & addr_hsmode;
   always @(negedge scl_clk or posedge i2c_rst_async)
     if (i2c_rst_async)   i2c_hsmode <= 1'b0;
     else if (trcv_stop)  i2c_hsmode <= 1'b0;
     else if (hsmode_det) i2c_hsmode <= 1'b1;

   always @(negedge scl_clk or posedge i2c_rst_async)
     if (i2c_rst_async) trst_ack_all_nd <= 1'b0;
     else               trst_ack_all_nd <= trst_ack_all;

   always @(posedge scl_clk or posedge i2c_rst_async)
     if (i2c_rst_async) trst_ack_all_pd <= 1'b0;
     else               trst_ack_all_pd <= trst_ack_all_nd;

   assign clk_str_cyc = trst_ack_all_nd & ~trst_ack_all_pd;
   
   // *****************************************
   // FSM check the addr byte and track rw opp
   // *****************************************
   // assign trst_idle = (tr_state == TR_IDLE);
   always @(negedge scl_clk or posedge trcv_async_rst)
     if (trcv_async_rst)  trst_idle <= 1'b1;
     else if (trcv_stop)  trst_idle <= 1'b1;
     else if (trcv_start) trst_idle <= 1'b0;
     else                 trst_idle <= (tr_next ==  TR_IDLE);
   
   assign trst_addr = (tr_state == TR_ADDR);
   assign trst_acka = (tr_state == TR_ACKA);
   assign trst_info = (tr_state == TR_INFO);
   assign trst_ackb = (tr_state == TR_ACKB);
   assign trst_ackd = (tr_state == TR_ACKD);

   assign trst_ack_all = (trst_acka | trst_ackb | trst_ackd);

   // assign trst_tip   = trcv_all;
   // always @(negedge scl_clk or posedge trcv_async_rst)
   //   if (trcv_async_rst) trst_tip <= 1'b0;
   //   else                trst_tip <= ~trcv_stop & (trcv_start || tr_next ==  TR_RDAT || tr_next ==  TR_INFO || tr_next ==  TR_ADDR);
   always @(posedge scl_clk or posedge trcv_async_rst)         // PSM WH : FB-09
     if (trcv_async_rst) trst_tip <= 1'b0;                     // PSM WH : FB-09
     else                trst_tip <= ~trst_ack_all;            // PSM WH : FB-09
   
   // assign trst_data = (tr_state == TR_RDAT);
   always @(negedge scl_clk or posedge trcv_async_rst)
     if (trcv_async_rst)              trst_data <= 1'b0;
     else if (trcv_stop | trcv_start) trst_data <= 1'b0;
     else                             trst_data <= (tr_next ==  TR_RDAT);
   
   assign trst_busy = ~trst_idle;
   
   // Conbinational Next State Logic
   always @(/*AUTOSENSE*/addr_info or tr_state or trcv_done)
     begin
        case (tr_state)
          TR_IDLE :                      tr_next = TR_IDLE;
          TR_ADDR : begin
             if (trcv_done)              tr_next = TR_ACKA;
             else                        tr_next = TR_ADDR;
          end
          TR_ACKA : begin
             if (addr_info)              tr_next = TR_INFO;
             else                        tr_next = TR_RDAT;
          end
          TR_INFO : begin
             if (trcv_done)              tr_next = TR_ACKB;
             else                        tr_next = TR_INFO;
          end
          TR_ACKB :                      tr_next = TR_RDAT;
          TR_RDAT : begin
             if (trcv_done)              tr_next = TR_ACKD;
             else                        tr_next = TR_RDAT;
          end
          TR_ACKD :                      tr_next = TR_RDAT;
          default :                      tr_next = TR_IDLE;
        endcase // case(tr_state)
     end // always @ (...

   // Sequential block
   always @(negedge scl_clk or posedge trcv_async_rst)
     if (trcv_async_rst)  tr_state <= TR_IDLE;
     else if (trcv_stop)  tr_state <= TR_IDLE;
     else if (trcv_start) tr_state <= TR_ADDR;
     else                 tr_state <= tr_next;

   // *****************************************
   // Receiver
   // *****************************************
   assign rcv_rst    = trst_idle;
   assign trcv_rst   = trst_idle | trst_ack_all | (trcv_start & ~trcv_start_rst_d);
   assign trcv_all   = trst_addr | trst_info | trst_data;
   assign trcv_shift = trcv_all & ~clk_str_cyc;
   assign trcv_done  = (trcv_cnt == 3'b111);

   // assign trcv_cnt6  = (trcv_cnt == 3'b110);
   always @(posedge scl_clk or posedge trcv_async_rst)
     if (trcv_async_rst)  trcv_cnt6 <= 1'b0;
     else if (trcv_rst)   trcv_cnt6 <= 1'b0;
     else if (trcv_shift) trcv_cnt6 <= (trcv_cnt == 3'b101);
	    
   wire   trn_reg_rst_0 = ~trcv_async_rst & (cap_txdr_act & ~i2c_trn_dat[0]);
   wire   trn_reg_set_0 = trcv_async_rst  | (cap_txdr_act &  i2c_trn_dat[0]);
   always @(negedge scl_clk or posedge trn_reg_rst_0 or posedge trn_reg_set_0)
     if (trn_reg_rst_0)      trn_reg[0] <= 1'b0;
     else if (trn_reg_set_0) trn_reg[0] <= 1'b1;
     else if (trcv_shift)    trn_reg[0] <= 1'b1;

   wire   trn_reg_rst_1 = ~trcv_async_rst & (cap_txdr_act & ~i2c_trn_dat[1]);
   wire   trn_reg_set_1 = trcv_async_rst  | (cap_txdr_act &  i2c_trn_dat[1]);
   always @(negedge scl_clk or posedge trn_reg_rst_1 or posedge trn_reg_set_1)
     if (trn_reg_rst_1)      trn_reg[1] <= 1'b0;
     else if (trn_reg_set_1) trn_reg[1] <= 1'b1;
     else if (trcv_shift)    trn_reg[1] <= trn_reg[0];

   wire   trn_reg_rst_2 = ~trcv_async_rst & (cap_txdr_act & ~i2c_trn_dat[2]);
   wire   trn_reg_set_2 = trcv_async_rst  | (cap_txdr_act &  i2c_trn_dat[2]);
   always @(negedge scl_clk or posedge trn_reg_rst_2 or posedge trn_reg_set_2)
     if (trn_reg_rst_2)      trn_reg[2] <= 1'b0;
     else if (trn_reg_set_2) trn_reg[2] <= 1'b1;
     else if (trcv_shift)    trn_reg[2] <= trn_reg[1];

   wire   trn_reg_rst_3 = ~trcv_async_rst & (cap_txdr_act & ~i2c_trn_dat[3]);
   wire   trn_reg_set_3 = trcv_async_rst  | (cap_txdr_act &  i2c_trn_dat[3]);
   always @(negedge scl_clk or posedge trn_reg_rst_3 or posedge trn_reg_set_3)
     if (trn_reg_rst_3)      trn_reg[3] <= 1'b0;
     else if (trn_reg_set_3) trn_reg[3] <= 1'b1;
     else if (trcv_shift)    trn_reg[3] <= trn_reg[2];

   wire   trn_reg_rst_4 = ~trcv_async_rst & (cap_txdr_act & ~i2c_trn_dat[4]);
   wire   trn_reg_set_4 = trcv_async_rst  | (cap_txdr_act &  i2c_trn_dat[4]);
   always @(negedge scl_clk or posedge trn_reg_rst_4 or posedge trn_reg_set_4)
     if (trn_reg_rst_4)      trn_reg[4] <= 1'b0;
     else if (trn_reg_set_4) trn_reg[4] <= 1'b1;
     else if (trcv_shift)    trn_reg[4] <= trn_reg[3];

   wire   trn_reg_rst_5 = ~trcv_async_rst & (cap_txdr_act & ~i2c_trn_dat[5]);
   wire   trn_reg_set_5 = trcv_async_rst  | (cap_txdr_act &  i2c_trn_dat[5]);
   always @(negedge scl_clk or posedge trn_reg_rst_5 or posedge trn_reg_set_5)
     if (trn_reg_rst_5)      trn_reg[5] <= 1'b0;
     else if (trn_reg_set_5) trn_reg[5] <= 1'b1;
     else if (trcv_shift)    trn_reg[5] <= trn_reg[4];
   
   wire   trn_reg_rst_6 = ~trcv_async_rst & (cap_txdr_act & ~i2c_trn_dat[6]);
   wire   trn_reg_set_6 = trcv_async_rst  | (cap_txdr_act &  i2c_trn_dat[6]);
   always @(negedge scl_clk or posedge trn_reg_rst_6 or posedge trn_reg_set_6)
     if (trn_reg_rst_6)      trn_reg[6] <= 1'b0;
     else if (trn_reg_set_6) trn_reg[6] <= 1'b1;
     else if (trcv_shift)    trn_reg[6] <= trn_reg[5];

   wire   trn_reg_rst_7 = ~trcv_async_rst & (cap_txdr_act & ~i2c_trn_dat[7]);
   wire   trn_reg_set_7 = trcv_async_rst  | (cap_txdr_act &  i2c_trn_dat[7]);
   always @(negedge scl_clk or posedge trn_reg_rst_7 or posedge trn_reg_set_7)
     if (trn_reg_rst_7)      trn_reg[7] <= 1'b0;
     else if (trn_reg_set_7) trn_reg[7] <= 1'b1;
     else if (trcv_shift)    trn_reg[7] <= trn_reg[6];
   
   
   always @(posedge scl_clk or posedge trcv_async_rst)
     if (trcv_async_rst) rcv_reg <= {8{1'b1}};
     else if (rcv_rst)   rcv_reg <= {8{1'b1}};
     else if (trcv_all)  rcv_reg <= {rcv_reg[6:0], sda_in};

   always @(posedge scl_clk or posedge trcv_async_rst)
     if (trcv_async_rst)  trcv_cnt <= 3'b000;
     else if (trcv_rst)   trcv_cnt <= 3'b000;
     else if (trcv_shift) trcv_cnt <= trcv_cnt + 1;

   assign rcv_addr_upd = trst_addr & trcv_done;
   always @(negedge scl_clk or posedge trcv_async_rst)
     if (trcv_async_rst)    rcv_addr <= 7'b1111111;
     else if (trcv_start)   rcv_addr <= 7'b1111111;
     else if (rcv_addr_upd) rcv_addr <= rcv_reg[7:1];

   always @(negedge scl_clk or posedge trcv_async_rst)
     if (trcv_async_rst)    rcv_rw <= 1'b0;
     else if (trcv_start)   rcv_rw <= 1'b0;
     else if (rcv_addr_upd) rcv_rw <= rcv_reg[0];

   wire   rcv_info_rst = trcv_stop | (rcv_addr_upd & ~rcv_reg[0]);
   assign rcv_info_upd = trst_info & trcv_done;
   always @(negedge scl_clk or posedge trcv_async_rst)
     if (trcv_async_rst)    rcv_info <= 8'b11111111;
     else if (rcv_info_rst) rcv_info <= 8'b11111111;
     else if (rcv_info_upd) rcv_info <= rcv_reg;

   assign rcv_data_upd = trst_data & trcv_done;
   always @(negedge scl_clk or posedge i2c_rst_async)                         // Do not reset for STOP, Give time to SB host to take data
     if (i2c_rst_async)     rcv_data <= 8'b11111111;
     else if (rcv_data_upd) rcv_data <= rcv_reg;

   always @(posedge scl_clk or posedge trcv_async_rst)
     if (trcv_async_rst)    rcv_arc <= 1'b1;
     else if (trst_ack_all) rcv_arc <= sda_in;

   always @(negedge scl_clk or posedge trcv_async_rst)
     if (trcv_async_rst)            trn_ack <= 1'b1;
     else if (trcv_all & trcv_done) trn_ack <= ~i2c_nack;

   // Receiving Information Decoding
   wire [7:0] slave_addr_msb = (|i2csaddr) ? i2csaddr : `DEFAULT_SADDRMSB;
   
   wire   gen_match   = (rcv_addr[6:0] == `GENERAL_ADDR) & ~rcv_rw;
   assign addr_gen    = i2c_gcen & gen_match;                                  // ACK
   assign addr_hsmode = i2c_en & (rcv_addr[6:2] == `HSMODE_ADDR);              // NO ACK
   assign addr_10bit  = i2c_en & (rcv_addr[6:2] == `S10BIT_ADDR);              // ACK
   assign addr_match2 = i2c_en & (rcv_addr[1:0] == slave_addr_msb[7:6]);
   
   assign addr_info    = gen_match | (addr_10bit & ~rcv_rw);                   // Need Info

   assign info_updrst  = addr_gen & (rcv_info == `GEN_UPDRST);  // Update partial slave addr from pin and reset
   assign info_updaddr = addr_gen & (rcv_info == `GEN_UPDADDR); // Update partial slave address from pin only (RSVD)
   assign info_wkup    = addr_gen & (rcv_info == `GEN_WKUPCMD); // For Wakeup from standby/sleep mode
   assign info_haddr   = addr_gen & rcv_info[0];

   wire   info_all = info_updrst | info_updaddr | info_wkup | info_haddr; 

   wire [9:0] slave_addr_10bit = {rcv_addr[1:0], rcv_info};
   wire [9:0] slave_addr_usr;

   assign slave_addr_usr = {slave_addr_msb, ADDR_LSB_USR};
   assign addr_musr7     = i2c_en & (rcv_addr[6:0] == slave_addr_usr[6:0]);
   assign addr_musr10    = i2c_en & (slave_addr_10bit == slave_addr_usr) & addr_10bit;
   
   assign addr_match7    = addr_musr7;
   assign addr_match10   = addr_musr10;
   
   // CFG FIFO Operation
   assign i2c_trn_dat = i2ctxdr;
   
   assign trst_rw_ok    = trst_data & rcv_rw;
   
   assign addr_ok       = addr_match7 | addr_match10 | mcst_master;
   assign addr_ok_usr7  = addr_musr7 | mcst_master;
   assign addr_ok_usr10 = addr_musr10 | mcst_master;
   assign addr_ok_usr   = addr_ok_usr7 | addr_ok_usr10;

   assign i2c_wkup = (i2c_wkupen & (addr_musr7 | addr_musr10)) | info_wkup;

   wire i2c_trn_mst = (trst_addr | ~trn_rw) & mc_trn_en;                                    // AEFB 00
   assign i2c_trn = mcst_master ? i2c_trn_mst : (rcv_rw & addr_ok);                         // AEFB 00
   assign i2c_trn_sync_mux = mcst_master ? i2c_trn_mst : (i2c_srw_sync & addr_ok_sync);     // AEFB 00
   
   assign i2c_rcv = ~i2c_trn & (addr_ok | info_haddr);

   wire   rst_rcv_ok = i2c_rst_async | trcv_start_pulse;
   always @(posedge scl_clk or posedge rst_rcv_ok)
     if (rst_rcv_ok)                 i2c_rcv_ok <= 1'b0;
     else if (trst_data & trcv_cnt6) i2c_rcv_ok <= i2c_rcv;
   
   // Determine the ACK
   assign acka = ~mcst_master & (addr_gen | (addr_10bit & addr_match2) | addr_match7) & trn_ack;
   assign ackb = ~mcst_master & (info_all | addr_match10) & trn_ack;
   assign ackd = (i2c_rcv & trn_ack);

   assign tr_sda_ack = (trst_acka & acka) | (trst_ackb & ackb) | (trst_ackd & ackd);
   assign tr_sda_en  = trcv_all & i2c_trn & (~rcv_arc | mcst_master);
   assign tr_sda_out = tr_sda_en ? trn_reg[7] : ~tr_sda_ack;

   // Wishbone registers control signal
   wire rcv_mon_srcv = (i2c_rcv & i2c_rrdy & ~i2c_cksdis);
   assign upd_gcsr = info_haddr & trst_ackb & scl_in;
   assign upd_gcdr = info_all & trst_ackb & scl_in;
   // assign upd_rxdr = i2c_rcv_ok & clk_str_cyc & (i2c_rbufdis | ~rcv_mon_srcv);
   assign upd_rxdr = i2c_rcv_ok & trst_arc_d_sync & (i2c_rbufdis | ~rcv_mon_srcv);    // SH feedback from NEC issue.
   
   //*****************************************
   // sb_clk domain
   //*****************************************
   wire   i2c_arbl_pulse;

   wire   mcst_staa, mcst_stac, mcst_trcb, mcst_trcc, mcst_stob, mcst_stoc;
   // wire   mcst_stab, mcst_trcd;
   // wire   i2c_intf;

   wire [7:0] i2csr;
   wire [9:0] div_fin;

   //************** Synchronizers **************
   always @(posedge sb_clk_i or posedge i2c_rst_async)
       if (i2c_rst_async)    trst_arc_d_sync0 <= 1'b0;
       else		     trst_arc_d_sync0 <= clk_str_cyc;
   always @(posedge sb_clk_i or posedge i2c_rst_async) 
       if (i2c_rst_async)    trst_arc_d_sync  <= 1'b0;
       else		     trst_arc_d_sync  <= trst_arc_d_sync0;

   always @(posedge sb_clk_i) i2c_rarc_sync0 <= rcv_arc;
   always @(posedge sb_clk_i) i2c_rarc_sync  <= i2c_rarc_sync0;

   always @(posedge sb_clk_i) i2c_srw_sync0 <= rcv_rw;
   always @(posedge sb_clk_i) i2c_srw_sync  <= i2c_srw_sync0;

   always @(posedge sb_clk_i) i2c_arbl_sync0 <= trcv_arbl;
   always @(posedge sb_clk_i) i2c_arbl_sync  <= i2c_arbl_sync0;
   assign i2c_arbl_pulse = i2c_arbl_sync0 & ~i2c_arbl_sync;

   // always @(posedge sb_clk_i) i2c_tip_sync0 <= trst_tip;
   always @(posedge sb_clk_i) i2c_tip_sync0 <= trst_tip | trcv_start | trcv_start_rst_d;    // PSM WH : FB-09
   always @(posedge sb_clk_i) i2c_tip_sync  <= i2c_tip_sync0;

   always @(posedge sb_clk_i) i2c_busy_sync0 <= trst_busy;
   always @(posedge sb_clk_i) i2c_busy_sync  <= i2c_busy_sync0;

   always @(posedge sb_clk_i) trst_rw_ok_sync0 <= trst_rw_ok;
   always @(posedge sb_clk_i) trst_rw_ok_sync  <= trst_rw_ok_sync0;

   always @(posedge sb_clk_i) addr_ok_sync0 <= addr_ok;                      // AEFB 00
   always @(posedge sb_clk_i) addr_ok_sync  <= addr_ok_sync0;                // AEFB 00
   

   always @(negedge scl_clk or posedge i2c_rst_async)
       if (i2c_rst_async)    i2c_trn_sync0 <= 1'b0;
       else                  i2c_trn_sync0 <= ~rcv_arc & i2c_trn;
   always @(posedge sb_clk_i) i2c_trn_sync  <= i2c_trn_sync0;

   always @(negedge scl_clk or posedge i2c_rst_async)
       if (i2c_rst_async)    i2c_rcv_sync0 <= 1'b0;
       else                  i2c_rcv_sync0 <= i2c_rcv;
   always @(posedge sb_clk_i) i2c_rcv_sync  <= i2c_rcv_sync0;

   always @(posedge scl_clk or posedge i2c_rst_async)
       if (i2c_rst_async)    addr_ok_usr_sync0 <= 1'b0;
       else                  addr_ok_usr_sync0 <= addr_ok_usr;
   always @(posedge sb_clk_i) addr_ok_usr_sync  <= addr_ok_usr_sync0;

   //******** Synchronized Pulse Generation ******
   always @(posedge sb_clk_i) upd_rxdr_sync[1:0] <= {upd_rxdr_sync[0], upd_rxdr};
   wire   upd_rxdr_pulse = i2c_rbufdis ? (upd_rxdr_sync[0] & ~upd_rxdr_sync[1]) : (~upd_rxdr_sync[0] & upd_rxdr_sync[1]);

   always @(posedge sb_clk_i) upd_gcdr_sync[1:0] <= {upd_gcdr_sync[0], upd_gcdr};
   wire   upd_gcdr_pulse = upd_gcdr_sync[0] & ~upd_gcdr_sync[1];

   always @(posedge sb_clk_i) upd_gcsr_sync[1:0] <= {upd_gcsr_sync[0], upd_gcsr};
   wire   upd_gcsr_pulse = upd_gcsr_sync[0] & ~upd_gcsr_sync[1];

   // Sense SCL rising
   always @(posedge sb_clk_i) i2c_scl_sense0 <= scl_in;
   always @(posedge sb_clk_i) i2c_scl_sense  <= i2c_scl_sense0;

   // Sense master SCL drive high
   always @(posedge sb_clk_i) mst_scl_sense0 <= mc_scl_out;
   always @(posedge sb_clk_i) mst_scl_sense  <= mst_scl_sense0;

   // Sync trcv cnt6
   always @(posedge sb_clk_i) trcv_cnt6_sync[2:0] <= {trcv_cnt6_sync[1:0], trcv_cnt6};
   assign trcv_cnt6_pulse = ~mcst_master & trcv_cnt6_sync[0] & ~trcv_cnt6_sync[1];
   assign trcv_cnt6_sense = ~mcst_master & trcv_cnt6_sync[2] & i2c_scl_sense & ~clk_max;

   // **************************************************
   // Slave Clock Stretching Logic
   // **************************************************
   wire   i2c_mon_strn   = (i2c_trn_sync & i2c_trdy & ~i2c_cksdis);
   wire   i2c_mon_srcv   = (i2c_rcv_sync & i2c_rrdy & ~i2c_cksdis);
   wire   i2c_mon_slv    = i2c_mon_strn | i2c_mon_srcv;
   wire   i2c_ckstr_qual = ~mcst_master & trst_arc_d_sync;
   wire   i2c_ckstr_det  = i2c_ckstr_qual & addr_ok_usr_sync & ~i2c_cksdis;

   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)                    tr_scl_out <= 1'b1;
     else if (i2c_sb_rst)                  tr_scl_out <= 1'b1;
     else if (i2c_ckstr_det & i2c_mon_slv) tr_scl_out <= 1'b0;
     else if (i2c_ckstr_qual & clk_en)     tr_scl_out <= 1'b1;
   
   assign ckstr_cnt_en  = i2c_ckstr_qual & ~i2c_mon_slv;
   
   // **************************************************
   // SCL generation counter
   // **************************************************
   assign div_fin = (|i2cbr) ? i2cbr : `DEFAULT_I2CBR;

   assign clk_en  = (clk_cnt == {16{1'b0}});
   assign clk_max = (clk_cnt == {16{1'b1}});
   
   // Detect clock stretching
   assign exec_stsp       = exec_start | exec_stop;
   wire   mc_slaves_ckstr = mst_scl_sense & ~i2c_scl_sense;
   wire   mc_master_ckstr = cmd_exec_active & ~i2c_cksdis & ((~trst_rw_ok_sync & i2c_trdy) | (trst_rw_ok_sync & i2c_rrdy) | ~rdwt_eval) & ~exec_stsp;  // Add rdwt_eval prevent clk miscount
   wire   mc_ckstr        = mc_slaves_ckstr | mc_master_ckstr;

   // Flag indicate that clk stretch happened
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)        ckstr_flag <= 1'b0;
     else if (mcst_trcb)       ckstr_flag <= 1'b0;
     else if (mc_master_ckstr) ckstr_flag <= 1'b1;

   // clock cnt control
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async) exec_stsp_det <= 2'b00;
     else               exec_stsp_det <= {exec_stsp, exec_stsp_det[1]};
   wire   clk_cnt_stsp_set = exec_stsp_det[1] & ~exec_stsp_det[0];
   wire   mcst_start       = exec_stsp_det[0];
   
   wire clk_cnt_rst  = (~i2c_en | trcv_cnt6_pulse) & ~clk_en;
   wire clk_cnt_set  = (mc_next_busy & clk_en) | clk_cnt_stsp_set;
   wire clk_dcnt_run = ((mc_next_busy | mcst_master) & ~mc_ckstr) | ckstr_cnt_en;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     begin
       if (i2c_rst_async)        clk_cnt <= {16{1'b0}};
       else if (i2c_sb_rst)      clk_cnt <= {16{1'b0}};
       else if (clk_cnt_rst)     clk_cnt <= {16{1'b0}};
       else if (trcv_cnt6_sense) clk_cnt <= clk_cnt + 1;
       else if (clk_cnt_set)     clk_cnt <= {{6{1'b0}}, div_fin};
       else if (clk_dcnt_run)    clk_cnt <= clk_cnt - 1;
     end

   // **************************************************

   // Master Command Execution
   // **************************************************

   // New Command Flag
   wire ncmd_rst = i2c_sb_rst | start_arbl;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     begin
       if (i2c_rst_async)     mcmd_stcmd <= 1'b0;
       else if (ncmd_rst)     mcmd_stcmd <= 1'b0;
       else if (cmd_exec_fin) mcmd_stcmd <= 1'b0;
       else if (i2ccmdr_wt)   mcmd_stcmd <= i2c_sta;
     end

   always @(posedge sb_clk_i or posedge i2c_rst_async)
     begin
       if (i2c_rst_async)               mcmd_start <= 1'b0;
       else if (ncmd_rst)               mcmd_start <= 1'b0;
       else if (cmd_exec_fin)           mcmd_start <= 1'b0;
       else if (mcmd_stcmd & ~i2c_trdy) mcmd_start <= 1'b1;
     end
   
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     begin
       if (i2c_rst_async)             mcmd_stop <= 1'b0;
       else if (i2c_sb_rst)           mcmd_stop <= 1'b0;
       else if (cmd_exec_fin)         mcmd_stop <= 1'b0;
       else if (i2ccmdr_wt & i2c_sto) mcmd_stop <= 1'b1;
     end

   assign cmd_start   = i2c_en & i2c_sta & cmd_wt;                          // start cmd must include wt
   assign cmd_stop    = i2c_en & i2c_sto & ~i2c_sta;
   assign cmd_rd      = i2c_en & i2c_rd  & ~i2c_wt;
   assign cmd_wt      = i2c_en & i2c_wt  & ~i2c_rd;

   // assign cmd_exec_active = (mcst_trcd & trst_arc_d_sync);
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)   cmd_exec_active <= 1'b0;
     else if (i2c_sb_rst) cmd_exec_active <= 1'b0;
     else                 cmd_exec_active <= clk_en ? (mc_next == MC_TRCD) & trst_arc_d_sync : cmd_exec_active;

   assign cmd_exec_en = (~mcst_master | cmd_exec_active);
   
   assign start_arbl = i2ccmdr_wt & cmd_start & ~mcst_master & i2c_busy_sync;

   always @(posedge sb_clk_i) cmd_exec_en_d <= cmd_exec_en;

   assign cmd_exec_run = (cmd_exec_en) & ~start_arbl;
   
   // assign cmd_exec_wt  = (cmd_exec_active | mcst_stab) & ~start_arbl;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)   cmd_exec_wt <= 1'b0;
     else if (i2c_sb_rst) cmd_exec_wt <= 1'b0;
     else                 cmd_exec_wt <= clk_en ? ((((mc_next == MC_TRCD) & trst_arc_d_sync) | (mc_next == MC_STAB)) & ~start_arbl) : cmd_exec_wt;
   
   assign cmd_exec_fin = ~cmd_exec_en & cmd_exec_en_d;

   assign exec_start   = cmd_start & cmd_exec_run & mcmd_start;
   assign exec_stop    = cmd_stop  & cmd_exec_run & mcmd_stop;
   assign exec_rd      = cmd_rd    & cmd_exec_run;
   assign exec_wt      = cmd_wt    & cmd_exec_wt;

   wire   cap_txdr_mstr    = exec_wt;
   wire   cap_txdr_slv_en  = i2c_trn & ~i2c_mon_strn;
   wire   cap_txdr_slv     = cap_txdr_slv_en & clk_str_cyc;
   wire   cap_txdr_slv_syn = cap_txdr_slv_en & trst_arc_d_sync;                              // SH NEC 2nd
   assign cap_txdr_act_nst = (cap_txdr_mstr | cap_txdr_slv);
   assign cap_txdr_act_syn = (cap_txdr_mstr | cap_txdr_slv_syn);                             // SH NEC 2nd
   assign cap_txdr_act     = ~scan_test_mode & cap_txdr_act_nst;

   always @(posedge sb_clk_i) cap_txdr_sync <= {cap_txdr_sync[0], cap_txdr_act_syn};         // SH NEC 2nd
   
   assign cap_txdr_fin     = ~cap_txdr_sync[0] & cap_txdr_sync[1];
   
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     begin
       if (i2c_rst_async)   trn_rw <= 1'b0;
       else if (i2c_sb_rst) trn_rw <= 1'b0;
       else if (exec_start) trn_rw <= (i2c_sta & i2c_rwbit);
     end

   // **************************************************
   // FSM for START/STOP Generation and SCL Generation
   // **************************************************
   assign mc_next_busy = (mc_next != MC_IDLE);
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)   mcst_master <= 1'b0;
     else if (i2c_sb_rst) mcst_master <= 1'b0;
     else                 mcst_master <= clk_en ? mc_next_busy : mcst_master;
   
   assign mcst_staa   = (mc_state == MC_STAA);
   // assign mcst_stab   = (mc_state == MC_STAB);
   assign mcst_stac   = (mc_state == MC_STAC);
   assign mcst_trcb   = (mc_state == MC_TRCB);
   assign mcst_trcc   = (mc_state == MC_TRCC);
   // assign mcst_trcd   = (mc_state == MC_TRCD);
   assign mcst_stob   = (mc_state == MC_STOB);
   assign mcst_stoc   = (mc_state == MC_STOC);

   assign rdwt_eval = ( exec_rd & trn_rw) | (exec_wt & ~trn_rw);

   wire   mcst_exec_start = mcst_start & exec_start;
   wire   mcst_exec_stop  = mcst_start & exec_stop;
   
   // Conbinational Next State Logic
   always @(/*AUTOSENSE*/ckstr_flag or exec_start or exec_stop
            or mc_state or mcst_exec_start or mcst_exec_stop
            or rdwt_eval or trst_arc_d_sync)
     begin
        case (mc_state)
          MC_IDLE : begin
             if (mcst_exec_start)      mc_next = MC_STAP;
             else if (mcst_exec_stop)  mc_next = MC_STOP;
             else                      mc_next = MC_IDLE;
          end
          MC_STAP :                    mc_next = MC_STAA;
          MC_STAA :                    mc_next = MC_STAB;
          MC_STAB :                    mc_next = MC_STAC;
          MC_STAC :                    mc_next = MC_STAD;
          MC_STAD :                    mc_next = MC_TRCA;

          MC_TRCA :                    mc_next = MC_TRCB;
          MC_TRCB :                    mc_next = MC_TRCC;
          MC_TRCC :                    mc_next = MC_TRCD;
          MC_TRCD : begin
             if (trst_arc_d_sync) begin
                if (exec_start)        mc_next = MC_STRP;
                else if (exec_stop)    mc_next = MC_STOA;
                else if (rdwt_eval) begin
		   if (ckstr_flag)     mc_next = MC_STAD;    // Change from TRCA to STAD for full 1st bit setup time after clock stretch
		   else                mc_next = MC_TRCA;
		end
                else                   mc_next = MC_TRCD;
             end
             else                      mc_next = MC_TRCA;
          end
          MC_STRP :                    mc_next = MC_STAA;
	  MC_STOP :                    mc_next = MC_STOA;
          MC_STOA :                    mc_next = MC_STOB;
          MC_STOB :                    mc_next = MC_STOC;
          MC_STOC :                    mc_next = MC_STOD;
          MC_STOD :                    mc_next = MC_IDLE;
          default :                    mc_next = MC_IDLE;
        endcase // case(mc_state)
     end // always @ (...

   // Sequential block
   wire arbl_det = ((mcst_trcb | mcst_trcc) & i2c_arbl);
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)   mc_state <= MC_IDLE;
     else if (i2c_sb_rst) mc_state <= MC_IDLE;
     else if (arbl_det)   mc_state <= MC_IDLE;
     else                 mc_state <= clk_en ? mc_next : mc_state;

   always @(negedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)   mc_trn_en <= 1'b0;
     else if (i2c_sb_rst) mc_trn_en <= 1'b0;
     // else if (clk_en)     mc_trn_en <= mc_trn_pre;
     else                 mc_trn_en <= mc_trn_pre;
   
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)   mc_sda_out <= 1'b1;
     else if (i2c_sb_rst) mc_sda_out <= 1'b1;
     // else if (clk_en)     mc_sda_out <= mc_sda_pre;
     else                 mc_sda_out <= mc_sda_pre;
   
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)   mc_scl_out <= 1'b1;
     else if (i2c_sb_rst) mc_scl_out <= 1'b1;
     // else if (clk_en)     mc_scl_out <= mc_scl_pre;
     else                 mc_scl_out <= mc_scl_pre;

   wire del_zero_nxt_sts = ((mc_next == MC_STAA) | (mc_next == MC_STAB) | (mc_next == MC_STAC) |
			    (mc_next == MC_STOA) | (mc_next == MC_STOB) | (mc_next == MC_STOC));
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)   del_zero_states <= 1'b0;
     else if (i2c_sb_rst) del_zero_states <= 1'b0;
     else                 del_zero_states <= del_zero_nxt_sts;
   
   // SDA_OUT AND SCL_OUT
   always @(/*AUTOSENSE*/mc_next)
     begin
        case (mc_next)
          MC_IDLE : begin
             mc_sda_pre = 1'b1;
             mc_scl_pre = 1'b1;
             mc_trn_pre = 1'b0;
          end
	  MC_STAP : begin
	     mc_sda_pre = 1'b1;
             mc_scl_pre = 1'b1;
             mc_trn_pre = 1'b0;
          end
          MC_STAA : begin
             mc_sda_pre = 1'b1;
             mc_scl_pre = 1'b1;
             mc_trn_pre = 1'b0;
          end
          MC_STAB : begin
             mc_sda_pre = 1'b0;
             mc_scl_pre = 1'b1;
             mc_trn_pre = 1'b0;
          end
          MC_STAC : begin
             mc_sda_pre = 1'b0;
             mc_scl_pre = 1'b0;
             mc_trn_pre = 1'b0;
          end
          MC_STAD : begin
             mc_sda_pre = 1'b1;
             mc_scl_pre = 1'b0;
             mc_trn_pre = 1'b1;
          end
          MC_TRCA : begin
             mc_sda_pre = 1'b1;
             mc_scl_pre = 1'b0;
             mc_trn_pre = 1'b1;
          end
          MC_TRCB : begin
             mc_sda_pre = 1'b1;
             mc_scl_pre = 1'b1;
             mc_trn_pre = 1'b1;
          end
          MC_TRCC : begin
             mc_sda_pre = 1'b1;
             mc_scl_pre = 1'b1;
             mc_trn_pre = 1'b1;
          end
          MC_TRCD : begin
             mc_sda_pre = 1'b1;
             mc_scl_pre = 1'b0;
             mc_trn_pre = 1'b1;
          end
          MC_STRP : begin
             mc_sda_pre = 1'b1;
             mc_scl_pre = 1'b0;
             mc_trn_pre = 1'b0;
          end
	  MC_STOP : begin
	     mc_sda_pre = 1'b1;
             mc_scl_pre = 1'b0;
             mc_trn_pre = 1'b0;
          end
          MC_STOA : begin
             mc_sda_pre = 1'b0;
             mc_scl_pre = 1'b0;
             mc_trn_pre = 1'b0;
          end
          MC_STOB : begin
             mc_sda_pre = 1'b0;
             mc_scl_pre = 1'b1;
             mc_trn_pre = 1'b0;
          end
          MC_STOC : begin
             mc_sda_pre = 1'b1;
             mc_scl_pre = 1'b1;
             mc_trn_pre = 1'b0;
          end
          MC_STOD : begin
             mc_sda_pre = 1'b1;
             mc_scl_pre = 1'b1;
             mc_trn_pre = 1'b0;
          end
          default : begin
             mc_sda_pre = 1'b1;
             mc_scl_pre = 1'b1;
             mc_trn_pre = 1'b0;
          end
        endcase // case(mc_state)
     end // always @ (...


   //*****************************************
   // Interrupt Flags
   //*****************************************
   always @(posedge sb_clk_i) trcv_start_sync <= {trcv_start, trcv_start_sync[2:1]};
   assign trcv_start_pulse = (trcv_start_sync[2] | trcv_start_sync[1]) & ~trcv_start_sync[0];
   
   wire   i2c_int_rst = i2c_sb_rst | trcv_start_pulse;

   // Hardware General Call Received Flag
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)       i2c_hgc <= 1'b0;
     else if (i2c_int_rst)    i2c_hgc <= 1'b0;
     else if (i2cgcdr_rd)     i2c_hgc <= 1'b0;
     else if (upd_gcsr_pulse) i2c_hgc <= 1'b1;

   // Arbitration Lost Flag
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)       i2c_arbl <= 1'b0;
     else if (i2c_int_rst)    i2c_arbl <= 1'b0;
     else if (i2c_arbl_pulse) i2c_arbl <= 1'b1;
     else if (start_arbl)     i2c_arbl <= 1'b1;

   // Transmitter Register Ready Flag
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)     i2c_trdy <= 1'b1;
     else if (i2ctxdr_wt)   i2c_trdy <= 1'b0;
     else if (i2c_int_rst)  i2c_trdy <= 1'b1;
     else if (cap_txdr_fin) i2c_trdy <= 1'b1;

   // Transmitter Register Overrun Error Flag
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)    i2c_toe <= 1'b0;
     else if (i2c_int_rst) i2c_toe <= 1'b0;
     else if (i2ctxdr_wt)  i2c_toe <= ~i2c_trdy ? ~i2c_trdy : i2c_toe;

   // Receiving Register Ready Flag
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)       i2c_rrdy <= 1'b0;
     else if (i2crxdr_rd)     i2c_rrdy <= 1'b0;
     else if (i2c_int_rst)    i2c_rrdy <= 1'b0;
     else if (upd_rxdr_pulse) i2c_rrdy <= 1'b1;

   // Receiving Register Overrun Error Flag
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)    i2c_roe <= 1'b0;
     else if (i2c_int_rst) i2c_roe <= 1'b0;
     else if (i2crxdr_rd)  i2c_roe <= 1'b0;
     else if (upd_rxdr_pulse) i2c_roe <= i2c_rrdy ? i2c_rrdy : i2c_roe;

   assign i2c_trrdy = i2c_trn_sync_mux ? i2c_trdy : i2c_rrdy;                       // AEFB 00
   // assign i2c_troe  = i2c_trn ? i2c_toe : i2c_roe;
   assign i2c_troe  = i2c_trn ? ((~i2c_tip_sync & rcv_arc) | i2c_toe) : i2c_roe;    // PSM WH : FB-10

   //*****************************************
   // Output Regs
   //*****************************************
   // General Call Info Register
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)       i2cgcdr <= {8{1'b0}};
     else if (i2c_sb_rst)     i2cgcdr <= {8{1'b0}};
     else if (upd_gcdr_pulse) i2cgcdr <= rcv_info;

   // Receiving Data Register
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)       i2crxdr <= {8{1'b0}};
     else if (i2c_sb_rst)     i2crxdr <= {8{1'b0}};
     else if (upd_rxdr_pulse) i2crxdr <= rcv_data;

   // I2C Status Register
   // assign i2csr = {(i2c_tip_sync | mcst_master), i2c_busy_sync, i2c_rarc_sync, i2c_srw_sync, i2c_arbl, i2c_trrdy, i2c_troe, i2c_hgc};
   assign i2csr = {i2c_tip_sync, i2c_busy_sync, i2c_rarc_sync, i2c_srw_sync, i2c_arbl, i2c_trrdy, i2c_troe, i2c_hgc};  // PSM WH : FB-09 / FB-10

   //*****************************************
   // SDA, SCL Output
   //*****************************************
   assign sda_out_int = mc_sda_out & tr_sda_out;

   assign scl_out = mc_scl_out & tr_scl_out;
   assign scl_oe  = ~scl_out;

   //*****************************************
   // 300 ns for SDA
   //*****************************************
   reg [1:0] sda_out_det;
   reg [5:0] sda_del_cnt;
   reg [5:0] n_del_cnt;
   reg       sda_del_cnt_en;
   reg 	     sda_no_del;
   
   wire      sda_del_cnt_up;
   // wire [3:0] n_del = (|trim_sda_del) ? trim_sda_del : `N_SDA_DEL_075;
   wire [3:0] n_del = trim_sda_del;
   
   wire       del_rstn_async_logic = ~(i2c_rst_async | i2c_sb_rst);
   wire       del_rstn_async;
   SYNCP_STD rstn_sync (.d(1'b1), .ck(del_clk), .cdn(del_rstn_async_logic), .q(del_rstn_async));  // async on, sync off
   wire       del_rst_async = ~del_rstn_async;
       
   always @(posedge del_clk or posedge del_rst_async) 
     if (del_rst_async) sda_no_del <= 1'b0;
     else               sda_no_del <= (del_zero_states | (&sda_del_sel));

   always @(/*AS*/n_del or sda_del_sel)
     begin
        case (sda_del_sel)
          2'b00   : n_del_cnt = {n_del, 1'b0, 1'b0};
          2'b01   : n_del_cnt = {1'b0, n_del, 1'b0};
          2'b10   : n_del_cnt = {1'b0, 1'b0, n_del};
          2'b11   : n_del_cnt = {6{1'b0}};
          default : n_del_cnt = {6{1'b0}};
        endcase // case(sda_del_sel)
     end

   assign sda_del_cnt_up = ~(|sda_del_cnt);
   // assign sda_del_cnt_up = (sda_del_cnt == 6'b000011);    // PSM WH : WJ C&V - Consider synchronization and transition latency. More acruate in actual delay

   always @(posedge del_clk or posedge del_rst_async) 
     if (del_rst_async) sda_out_det <= {2{1'b0}};
     else               sda_out_det <= {sda_out_int, sda_out_det[1]};
   wire   sda_out_pulse = sda_out_det[0] ^ sda_out_det[1];

   always @(posedge del_clk or posedge del_rst_async)
     if (del_rst_async)       sda_del_cnt_en <= 1'b0;
     else if (sda_del_cnt_up) sda_del_cnt_en <= 1'b0;
     else if (sda_out_pulse)  sda_del_cnt_en <= 1'b1;

   always @(posedge del_clk or posedge del_rst_async) 
     if (del_rst_async) del_cnt_set_sense <= {3'b100};
     else               del_cnt_set_sense <= {i2ccr1_wt, del_cnt_set_sense[2:1]};
   wire   sda_del_cnt_set = del_cnt_set_sense[1] & ~del_cnt_set_sense[0];
   
   always @(posedge del_clk or posedge del_rst_async)
     if (del_rst_async)                         sda_del_cnt <= {6{1'b0}};
     else if (sda_del_cnt_set | sda_del_cnt_up) sda_del_cnt <= n_del_cnt;
     else if (sda_del_cnt_en)                   sda_del_cnt <= sda_del_cnt - 1;

   always @(posedge del_clk or posedge del_rst_async)
     if (del_rst_async)       sda_out_sense_r <= 1'b1;
     else if (sda_del_cnt_up) sda_out_sense_r <= sda_out_int;

   assign  sda_out_sense = (sda_no_del) ? sda_out_int : sda_out_sense_r;

   // assign  sda_out = sda_out_sense;
   assign sda_out = sda_out_sense;
   assign sda_oe  = ~sda_out;
   
endmodule // i2c_port
