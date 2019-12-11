`include "defines5.v"
`timescale 1ns/1ps
module irtcv_ctrl (/*AUTOARG*/
   // Outputs
   ir_out, irtcv_busy, irtcv_drdy, irtcv_err, irtcvsr,
   irtcv_rfreq_dat, irtcv_rfreq_upd, irtcv_dbuf_dat, irtcv_dbuf_upd,
   // Inputs
   irtcv_rst_async, irtcv_clk, irtcv_exe, irtcv_learn, ir_in, irtcvcr,
   irsysfr, irtcvfr, irtcvdr, irtcvcr_wt, irtcvfr_wt, irtcvfr_rd,
   irtcvdr_wt, irtcvdr_rd
   );

   // INPUTS
   // From full chip POR ...
   input irtcv_rst_async;         // Asynchronize Reset, to POR

   // From System Bus
   input irtcv_clk;               // IR Transceiver Control Bus clock

   input irtcv_exe;               // IR Transceiver Control Execute; Level sensitive
   input irtcv_learn;             // IR Transceiver Learning mode; Level sensitive

   // From IR Sensor
   input ir_in;                   // IR input signal in learning mode.
   
   // IRTCV SCI Block
   input [`IRTCVCBDW-1:0] irtcvcr;    // IR Transceiver Control Register
   input [`IRSYSFRW-1:0]  irsysfr;    // IR Transceiver System Clock Frequency Register
   input [`IRTCVFRW-1:0]  irtcvfr;    // IR Transceiver Clock Frequency Register
   input [`IRTCVDRW-1:0]  irtcvdr;    // IR Transceiver Data Register

   input 		  irtcvcr_wt; // IR Transceiver Control Register Written
   input 		  irtcvfr_wt; // IR Transceiver Clock Frequency Register Written (Byte0)
   input                  irtcvfr_rd; // IR Transceiver Clock Frequency Register Read (Byte0)
   input 		  irtcvdr_wt; // IR Transceiver Data Register Written (Byte0)
   input 		  irtcvdr_rd; // IR Transceiver Data Register Read (Byte0)

   // OUTPUTS
   // IO or FPGA Fabric
   output ir_out;
   
   // To FPGA Fabric
   output irtcv_busy;                 // IR Transceiver BUSY
   output irtcv_drdy;                 // IR Transceiver Data ReaDY
   output irtcv_err;                  // IR Transceiver ERRor

   // To IRTCV SCI
   output [`IRTCVCBDW-1:0] irtcvsr;   // IR Transceiver Status

   output [`IRTCVFRW-1:0]  irtcv_rfreq_dat;  // Calculated Result for Received Frequency
   output 		   irtcv_rfreq_upd;  // Calculated Received Frequency Update

   output [`IRTCVDRW-1:0]  irtcv_dbuf_dat;   // Received Data
   output 		   irtcv_dbuf_upd;   // Reveived Data Update
   
   // REGS
   reg [2:0]  irtcv_exe_sense, irtcv_lrn_sense;
   reg [1:0]  irtcv_din_sync, irtcv_din_sense;
   reg [7:0]  irtcv_din_dfltr;

   reg [2:0]  tcv_state, tcv_next;
   reg [3:0]  cal_state, cal_next;
   reg [1:0]  div_state, div_next;
   
   reg [`IRTCVCRW-1:0] freq_cnt;
   reg [`IRTCVDRW-2:0] tcv_cnt;
   
   reg [`IRTCVCRW-1:0] irtcv_fcnt_reg, irtcv_duty_reg;
   reg 		       freq_cnt_duty_d;
   reg 		       irtcv_busy, irtcv_drdy, irtcv_rcfrdy, irtcv_daterr, irtcv_dovfl, irtcv_covfl;
   
   reg 		       irtcv_trcv1_det, irtcv_trcv1_dly;
   reg 		       dbuf_updmask;
   reg 		       ir_out;
   reg 		       irtcv_din_fltout;

   // WIRES
   wire irtcv_enable, irtcv_dt33, irtcv_outpol, irtcv_disoe, irtcv_usrmax, irtcv_remeas;
   wire [1:0] irtcv_ifsel;

   wire       irtcv_execute, irtcv_exerise, irtcv_exefall;
   wire       irtcv_lrnsync, irtcv_lrnrise, irtcv_lrnfall;
   wire       irin_rise;

   wire       tcvfsm_error, tcvfsm_hold, tcvfsm_restart, tcvfsm_act2nul, tcvfsm_remeas, tcvfsm_resume;
   wire       irtcv_init, irtcv_trn, irtcv_rwat, irtcv_rmes, irtcv_ract, irtcv_rnul;
   wire       rcv_states, rln_states;
   
   wire       div_start1, div_calc1, div_fin1;
   wire       div_start2, div_calc2, div_fin2;
   wire       div_start3, div_calc3, div_fin3;
   wire       cal_busy, cal_cnt, cal_duty, cal_freq;
   wire       div_start, div_fin;
   wire       irtcv_tip;

   wire       irtcv_trcv1_chg;
   wire       irtcv_rcnt_upd, irtcv_rfreq_upd;
   wire       irtcv_dbuf_cap, irtcv_dbuf_upd;

   wire       freq_cnt_rst, freq_cnt_run;
   wire       freq_cnt_done, freq_cnt_duty, freq_cnt_qcyc, freq_cnt_zero;
   wire       tcv_cnt_done, tcv_cnt_lmax;
   wire       irtcv_dchk, rcv_chg_chk;

   wire       statflag_rst;
   wire       dbufrdy_rst, dbufrdy_act, dbufrdy_set, rcfrdy_rst;
   wire       daterr_rst, daterr_set, dovfl_set, covfl_set;

   wire       tcv_cnt_rst0, tcv_cnt_rst1, tcv_cnt_incr, tcv_cnt_decr;

   wire [`IRTCVDRW-1:0] tcv_cnt_incr1, tcv_cnt_decr1;
   wire [`IRTCVDRW-2:0] tcv_cnt_lrnmax;
   
   wire [`IRTCVCRW-1:0] irtcv_duty_val, irtcv_qduty_val;
   wire [`IRTCVCRW:0] 	freq_cnt_incr1;
   
   /*AUTOWIRE*/
   
   // PARAMETERS
   parameter DIV_DIVID_WD = 28;    // 32;
   parameter DIV_DIVIS_WD = 28;    // 32;
   parameter DIV_COUNT_WD = 5;

   // TCV State FSM States Defination
   parameter TCVST_IDLE  = 3'b000;
   parameter TCVST_INIT  = 3'b001;
   parameter TCVST_TRN   = 3'b011;
   parameter TCVST_RWAT  = 3'b100;
   parameter TCVST_RMES  = 3'b101;
   parameter TCVST_RACT  = 3'b111;
   parameter TCVST_RNUL  = 3'b110;

   // DIV Calculation Control FSM States Defination
   parameter CALST_IDLE = 4'b0000;
   parameter CALST_STT1 = 4'b0001;
   parameter CALST_CAL1 = 4'b0011;
   parameter CALST_FIN1 = 4'b0010;
   parameter CALST_STT2 = 4'b0110;
   parameter CALST_CAL2 = 4'b0111;
   parameter CALST_FIN2 = 4'b0101;
   parameter CALST_STT3 = 4'b1001;
   parameter CALST_CAL3 = 4'b1011;
   parameter CALST_FIN3 = 4'b1010;

   // DIV FSM States Defination
   parameter DIVST_IDLE = 2'b00;
   parameter DIVST_INIT = 2'b01;
   parameter DIVST_CALC = 2'b11;
   parameter DIVST_FADJ = 2'b10;
   
   // ******************************************
   // LOGIC
   // Control Signal Assignments
   assign irtcv_enable = irtcvcr[`BIT_IRTCVCR_EN];
   assign irtcv_dt33   = irtcvcr[`BIT_IRTCVCR_DT33];
   assign irtcv_outpol = irtcvcr[`BIT_IRTCVCR_OPOL];
   assign irtcv_disoe  = irtcvcr[`BIT_IRTCVCR_DISOE];
   assign irtcv_usrmax = irtcvcr[`BIT_IRTCVCR_USRMAX];
   assign irtcv_remeas = irtcvcr[`BIT_IRTCVCR_REMEASEN];
   assign irtcv_ifsel  = irtcvcr[`BIT_IRTCVCR_IFSEL:`BIT_IRTCVCR_IFSEL-1];

   // IRTCV_EXE detection
   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async)   irtcv_exe_sense <= 3'b000;
      else if (irtcv_enable) irtcv_exe_sense <= {irtcv_exe, irtcv_exe_sense[2:1]};
      else                   irtcv_exe_sense <= 3'b000;
   end
   
   assign irtcv_execute =  irtcv_exe_sense[1] |  irtcv_exe_sense[0];
   assign irtcv_exerise =  irtcv_exe_sense[1] & ~irtcv_exe_sense[0];
   assign irtcv_exefall = ~irtcv_exe_sense[1] &  irtcv_exe_sense[0];
   
//   assign irtcv_rst_sync = irtcv_exerise;

   // IRTCV_LEARN detection
   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async)   irtcv_lrn_sense <= 3'b000;
      else if (irtcv_enable) irtcv_lrn_sense <= {irtcv_learn, irtcv_lrn_sense[2:1]};
      else                   irtcv_lrn_sense <= 3'b000;
   end
   
   assign irtcv_lrnsync =  irtcv_lrn_sense[1] |  irtcv_lrn_sense[0];
   assign irtcv_lrnrise =  irtcv_lrn_sense[1] & ~irtcv_lrn_sense[0];
   assign irtcv_lrnfall = ~irtcv_lrn_sense[1] &  irtcv_lrn_sense[0];
   
   // IR Input Filter
   // IR Input Synchronizer
   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async)    irtcv_din_sync <= 2'b00;
      else                    irtcv_din_sync <= {ir_in, irtcv_din_sync[1]};
   end

   wire ir_in_sync = irtcv_din_sync[0];
   wire [6:0] dfltr_ingl = ({7{ir_in_sync}} | irtcv_din_dfltr[7:1]);
   wire [6:0] dfltr_ingh = ({7{ir_in_sync}} & irtcv_din_dfltr[7:1]);
   wire [6:0] dfltr_in   = irtcv_din_fltout ? dfltr_ingl : dfltr_ingh;
   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async)    irtcv_din_dfltr <= {8{1'b0}};
      else if (irtcv_lrnsync) irtcv_din_dfltr <= {ir_in_sync, dfltr_in};
      else                    irtcv_din_dfltr <= {8{1'b0}};
   end

   always @(/*AUTOSENSE*/ir_in_sync or irtcv_din_dfltr or irtcv_ifsel) begin
      case (irtcv_ifsel)
	 2'b00   : irtcv_din_fltout = ir_in_sync;
	 2'b01   : irtcv_din_fltout = irtcv_din_dfltr[6];
	 2'b10   : irtcv_din_fltout = irtcv_din_dfltr[4];
	 2'b11   : irtcv_din_fltout = irtcv_din_dfltr[0];
	 default : irtcv_din_fltout = ir_in_sync;
      endcase // case (irtcv_ifsel)
   end
     
   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async)    irtcv_din_sense <= 2'b00;
      else if (irtcv_lrnsync) irtcv_din_sense <= {irtcv_din_fltout, irtcv_din_sense[1]};
      else                    irtcv_din_sense <= 2'b00;
   end

   assign irin_rise   = irtcv_din_sense[1] & ~irtcv_din_sense[0];
 
   // ********************************************************************************
   // Next State Logic for IR Transceiver
   wire tcv_stop_rcv = ~irtcv_execute;
   wire tcv_stop_trn = ~irtcv_execute & ((irtcv_daterr & irtcv_disoe) | (freq_cnt_done & tcv_cnt_done));

   assign tcvfsm_error   = (daterr_set | irtcv_daterr) & irtcv_disoe;
   assign tcvfsm_hold    = irtcv_dbuf_cap & irtcv_drdy;
   assign tcvfsm_restart = covfl_set & ~irin_rise;
   assign tcvfsm_act2nul = rcv_chg_chk & irtcv_trcv1_dly;
   assign tcvfsm_remeas  = (irtcv_remeas | dbuf_updmask) & irtcv_rnul & irin_rise;
   assign tcvfsm_resume  = ~irtcv_remeas & irin_rise;
   
   always @(/*AUTOSENSE*/cal_busy or irin_rise or irtcv_drdy
	    or irtcv_exerise or irtcv_lrnsync or tcv_state
	    or tcv_stop_rcv or tcv_stop_trn or tcvfsm_act2nul
	    or tcvfsm_hold or tcvfsm_remeas or tcvfsm_restart
	    or tcvfsm_resume) begin
      case (tcv_state)
	TCVST_IDLE : begin
	   if (irtcv_exerise)       tcv_next = TCVST_INIT;
	   else                     tcv_next = TCVST_IDLE;
	end
	TCVST_INIT : begin
	   if (tcv_stop_rcv)        tcv_next = TCVST_IDLE;
	   else if (~cal_busy) begin
              if (irtcv_lrnsync)    tcv_next = TCVST_RWAT;
	      else if (~irtcv_drdy) tcv_next = TCVST_TRN;
	      else                  tcv_next = TCVST_INIT;
	   end
	   else                     tcv_next = TCVST_INIT;
	end
	TCVST_TRN : begin
	   if (tcv_stop_trn)        tcv_next = TCVST_IDLE;
	   else if (tcvfsm_hold)    tcv_next = TCVST_INIT;
	   else                     tcv_next = TCVST_TRN;
	end
	TCVST_RWAT : begin
	   if (tcv_stop_rcv)        tcv_next = TCVST_IDLE;
	   else if (irin_rise)      tcv_next = TCVST_RMES;
	   else                     tcv_next = TCVST_RWAT;
	end
	TCVST_RMES : begin
	   if (tcv_stop_rcv)        tcv_next = TCVST_IDLE;
	   else if (irin_rise)      tcv_next = TCVST_RACT;
	   else if (tcvfsm_restart) tcv_next = TCVST_RWAT;
	   else                     tcv_next = TCVST_RMES;
	end
	TCVST_RACT : begin
	   if (tcv_stop_rcv)        tcv_next = TCVST_IDLE;
	   else if (tcvfsm_act2nul) tcv_next = TCVST_RNUL;
	   else                     tcv_next = TCVST_RACT;
	end
	TCVST_RNUL : begin
	   if (tcv_stop_rcv)        tcv_next = TCVST_IDLE;
	   else if (tcvfsm_remeas)  tcv_next = TCVST_RMES;
	   else if (tcvfsm_resume)  tcv_next = TCVST_RACT;
	   else                     tcv_next = TCVST_RNUL;
	end
	default :                   tcv_next = TCVST_IDLE;
      endcase // case (irtcv_state)
   end
   
   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async)   tcv_state <= TCVST_IDLE;
      else if (irtcv_enable) tcv_state <= tcv_next;
      else                   tcv_state <= TCVST_IDLE;
   end

   assign irtcv_init = (tcv_state == TCVST_INIT);
   assign irtcv_trn  = (tcv_state == TCVST_TRN);
   assign irtcv_rwat = (tcv_state == TCVST_RWAT);
   assign irtcv_rmes = (tcv_state == TCVST_RMES);
   assign irtcv_ract = (tcv_state == TCVST_RACT);
   assign irtcv_rnul = (tcv_state == TCVST_RNUL);

   assign rln_states = irtcv_ract | irtcv_rnul;
   assign rcv_states = irtcv_rmes | rln_states;
   
   assign irtcv_rcnt_upd = irtcv_rmes & irin_rise;
   
   // IR Transceiver Status Generate
   assign statflag_rst = irtcvcr_wt | irtcv_lrnrise;
   // Busy Flag
   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async) irtcv_busy <= 1'b0;
      else                 irtcv_busy <= (tcv_next != TCVST_IDLE) | (cal_next != CALST_IDLE);
   end

   // TIP Flag
   assign irtcv_tip  = irtcv_trn | rcv_states;

   // DBURRDY Flag
   assign dbufrdy_rst = (irtcv_lrnsync ? (irtcv_exerise | irtcvdr_rd) : (irtcv_enable & irtcvdr_wt));
   assign dbufrdy_act = (irtcv_lrnsync ? irtcv_dbuf_upd : irtcv_dbuf_cap);
   assign dbufrdy_set = dbufrdy_act | irtcvcr_wt | irtcv_lrnfall;
   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async)  irtcv_drdy <= 1'b1;
      else if (dbufrdy_rst) irtcv_drdy <= 1'b0;
      else if (dbufrdy_set) irtcv_drdy <= 1'b1;
      else                  irtcv_drdy <= irtcv_drdy;
   end

   // Received Frequency Ready Flag
   assign rcfrdy_rst = irtcvfr_rd | statflag_rst;
   assign irtcv_rfreq_upd = irtcv_lrnsync & div_fin3;
   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async)      irtcv_rcfrdy <= 1'b0;
      else if (rcfrdy_rst)      irtcv_rcfrdy <= 1'b0;
      else if (irtcv_rfreq_upd) irtcv_rcfrdy <= 1'b1;
      else                      irtcv_rcfrdy <= irtcv_rcfrdy;
   end

   // Data Error Flag
   assign daterr_rst = irtcv_exerise | statflag_rst;
   assign daterr_set = dbufrdy_act & irtcv_drdy;
   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async) irtcv_daterr <= 1'b0;
      else if (daterr_rst) irtcv_daterr <= 1'b0;
      else if (daterr_set) irtcv_daterr <= 1'b1;
      else                 irtcv_daterr <= irtcv_daterr;
   end

   // Learning Data Overflow Flag
   assign dovfl_set = irtcv_lrnsync & tcv_cnt_incr & tcv_cnt_lmax & ~dbuf_updmask;
   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async)   irtcv_dovfl <= 1'b0;
      else if (statflag_rst) irtcv_dovfl <= 1'b0;
      else if (dovfl_set)    irtcv_dovfl <= 1'b1;
      else                   irtcv_dovfl <= irtcv_dovfl;
   end

   // Learning Clock Counter Overflow Flag
   assign covfl_set = irtcv_lrnsync & irtcv_rmes & freq_cnt_incr1[`IRTCVCRW];
   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async)   irtcv_covfl <= 1'b0;
      else if (statflag_rst) irtcv_covfl <= 1'b0;
      else if (covfl_set)    irtcv_covfl <= 1'b1;
      else                   irtcv_covfl <= irtcv_covfl;
   end

   assign irtcv_err = irtcv_daterr;
   assign irtcvsr = {irtcv_busy, irtcv_tip, 1'b0, irtcv_covfl, irtcv_dovfl, irtcv_daterr, irtcv_rcfrdy, irtcv_drdy};
   
   // *******************************************************************************
   // IR Transceiver Frequency Counter
   // assign freq_cnt_rst = ~irtcv_tip | (~irtcv_rmes & freq_cnt_done) | ((irtcv_rmes | irtcv_rnul) & irin_rise);
   assign freq_cnt_rst = ~irtcv_tip | (~irtcv_rmes & freq_cnt_done) | (rcv_states & irin_rise);
   assign freq_cnt_run = irtcv_tip;
   
   assign freq_cnt_incr1 = freq_cnt + 1;
   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async)   freq_cnt <= {`IRTCVCRW{1'b0}};
      else if (freq_cnt_rst) freq_cnt <= {{`IRTCVCRW-1{1'b0}}, 1'b1};
      else if (freq_cnt_run) freq_cnt <= freq_cnt_incr1[`IRTCVCRW-1:0];
      else                   freq_cnt <= freq_cnt;
   end
			
   assign freq_cnt_done = (freq_cnt == irtcv_fcnt_reg);
   assign freq_cnt_duty = (freq_cnt == irtcv_duty_val);
   assign freq_cnt_qcyc = (freq_cnt == irtcv_qduty_val);
   assign freq_cnt_zero = ~(|freq_cnt[`IRTCVCRW-1:1]) & freq_cnt[0];   // 1

   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async)   freq_cnt_duty_d <= 1'b0;
      else if (freq_cnt_run) freq_cnt_duty_d <= freq_cnt_duty;
      else                   freq_cnt_duty_d <= freq_cnt_duty_d;
   end
   
   // Learning mode decision
   wire irtcv_trcv1_dset = (irtcv_rwat | irtcv_rnul) & irin_rise;
   
   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async)       irtcv_trcv1_det <= 1'b0;
      else if (irtcv_trn) begin
	 if (irtcv_dbuf_cap)     irtcv_trcv1_det <= irtcvdr[`IRTCVDRW-1];
	 else                    irtcv_trcv1_det <= irtcv_trcv1_det;
      end
      else if (irtcv_trcv1_dset) irtcv_trcv1_det <= 1'b1;
      else if (rcv_states) begin 
	 if (freq_cnt_qcyc)      irtcv_trcv1_det <= irtcv_din_sense[0];
	 else                    irtcv_trcv1_det <= irtcv_trcv1_det;
      end
      else                       irtcv_trcv1_det <= 1'b0;
   end

   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async)       irtcv_trcv1_dly <= 1'b0;
      else if (irtcv_trn) begin
	 if (freq_cnt_zero)      irtcv_trcv1_dly <= irtcv_trcv1_det;
	 else                    irtcv_trcv1_dly <= irtcv_trcv1_dly;
      end
      else if (irtcv_trcv1_dset) irtcv_trcv1_dly <= 1'b1;
      else if (rcv_states) begin
	 if (freq_cnt_duty)      irtcv_trcv1_dly <= irtcv_trcv1_det;
	 else                    irtcv_trcv1_dly <= irtcv_trcv1_dly;
      end
      else                       irtcv_trcv1_dly <= 1'b0;
   end

   assign irtcv_trcv1_chg = irtcv_trcv1_det ^ irtcv_trcv1_dly;
   assign irtcv_dchk      = rln_states & freq_cnt_duty;
   assign rcv_chg_chk     = irtcv_dchk & irtcv_trcv1_chg;
		       
   // IR Transceiver Pulse Counter
   assign irtcv_dbuf_dat = {irtcv_trcv1_dly, tcv_cnt[`IRTCVDRW-2:0]};
   
   assign irtcv_dbuf_cap = irtcv_trn & freq_cnt_zero & tcv_cnt_done;
   assign irtcv_dbuf_upd = ((rcv_chg_chk | (irtcv_rnul & irin_rise) | (irtcv_lrnsync & irtcv_exefall)) & ~dbuf_updmask) | dovfl_set;

   assign tcv_cnt_rst0 = irtcv_rwat | (irtcv_rnul & irin_rise);
   assign tcv_cnt_rst1 = irtcv_init | rcv_chg_chk;
   assign tcv_cnt_incr = irtcv_dchk | (irtcv_rmes & irin_rise);
   assign tcv_cnt_decr = (irtcv_trn & freq_cnt_zero);

   assign tcv_cnt_incr1 = tcv_cnt + 1;
   assign tcv_cnt_decr1 = tcv_cnt - 1;

   wire tcv_capval_lsb = (|irtcvdr[`IRTCVDRW-2:1]) ? irtcvdr[0] : 1'b1;
   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async)     tcv_cnt <= {(`IRTCVDRW-1){1'b0}};
      else if (tcv_cnt_rst0)   tcv_cnt <= {(`IRTCVDRW-1){1'b0}};
      else if (tcv_cnt_rst1)   tcv_cnt <= {{(`IRTCVDRW-2){1'b0}}, 1'b1};
      else if (irtcv_dbuf_cap) tcv_cnt <= {1'b0, irtcvdr[`IRTCVDRW-2:1], tcv_capval_lsb};
      else if (tcv_cnt_incr)   tcv_cnt <= tcv_cnt_lmax ? tcv_cnt : tcv_cnt_incr1[`IRTCVDRW-2:0];
      else if (tcv_cnt_decr)   tcv_cnt <= tcv_cnt_decr1[`IRTCVDRW-2:0];
      else                     tcv_cnt <= tcv_cnt;
   end
   
   assign tcv_cnt_done = ~(|tcv_cnt[`IRTCVDRW-2:1]) & tcv_cnt[0];    // 1
   assign tcv_cnt_lmax = (tcv_cnt == tcv_cnt_lrnmax);

   wire dbuf_updmask_rst = rcv_chg_chk | tcvfsm_remeas | irtcv_lrnfall;
   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async)       dbuf_updmask <= 1'b0;
      else if (dbuf_updmask_rst) dbuf_updmask <= 1'b0;
      else if (dovfl_set)        dbuf_updmask <= 1'b1;
      else                       dbuf_updmask <= dbuf_updmask;
   end
   
   //Final Output Register
   // wire irout_enable  = irtcv_trn & freq_cnt_zero & (irtcv_dbuf_cap ? irtcvdr[`IRTCVDRW-1] : irtcv_trcv1_det) & ~tcv_cnt_done;
   wire irout_enable  = irtcv_trn & freq_cnt_zero & (irtcv_dbuf_cap ? (irtcvdr[`IRTCVDRW-1] & ~irtcv_drdy) : irtcv_trcv1_det);
   wire irout_disable = freq_cnt_duty_d;
   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async)       ir_out <= 1'b0;
      else if (irtcv_trn & ~tcvfsm_error) begin
	 if (irout_enable)       ir_out <= ~irtcv_outpol;
	 else if (irout_disable) ir_out <=  irtcv_outpol;
      end
      else                       ir_out <=  irtcv_outpol;
   end

   // ********************************************************************************
   // DIV Calculation Control FSM

   assign div_start1 = (cal_state == CALST_STT1);
   assign div_calc1  = (cal_state == CALST_CAL1);
   assign div_fin1   = (cal_state == CALST_FIN1);
   assign div_start2 = (cal_state == CALST_STT2);
   assign div_calc2  = (cal_state == CALST_CAL2);
   assign div_fin2   = (cal_state == CALST_FIN2);
   assign div_start3 = (cal_state == CALST_STT3);
   assign div_calc3  = (cal_state == CALST_CAL3);
   assign div_fin3   = (cal_state == CALST_FIN3);
   
   assign cal_busy  = (cal_state != CALST_IDLE);
   assign cal_cnt   = div_start1 | div_calc1;
   assign cal_duty  = div_start2 | div_calc2;
   assign cal_freq  = div_start3 | div_calc3;

   assign div_start = div_start1 | div_start2 | div_start3;
   
   always @(/*AUTOSENSE*/cal_state or div_fin or irtcv_rcnt_upd
	    or irtcvfr_wt) begin
      case (cal_state)
	CALST_IDLE : begin
	   if (irtcvfr_wt)          cal_next = CALST_STT1;
	   else if (irtcv_rcnt_upd) cal_next = CALST_STT3;
	   else                     cal_next = CALST_IDLE;
	end
	CALST_STT1 :                cal_next = CALST_CAL1;
	CALST_CAL1 : begin
	   if (div_fin)             cal_next = CALST_FIN1;
	   else                     cal_next = CALST_CAL1;
	end
	CALST_FIN1 :                cal_next = CALST_STT2;
	CALST_STT2 :                cal_next = CALST_CAL2;
	CALST_CAL2 : begin
	   if (div_fin)             cal_next = CALST_FIN2;
	   else                     cal_next = CALST_CAL2;
	end
	CALST_FIN2 :                cal_next = CALST_IDLE;
	CALST_STT3 :                cal_next = CALST_CAL3;
	CALST_CAL3 : begin
	   if (div_fin)             cal_next = CALST_FIN3;
	   else                     cal_next = CALST_CAL3;
	end
	CALST_FIN3 :                cal_next = CALST_IDLE;
	default    :                cal_next = CALST_IDLE;
      endcase // case (cal_state)
   end // always @ (...

   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async)   cal_state <= CALST_IDLE;
      else if (irtcv_enable) cal_state <= cal_next;
      else                   cal_state <= CALST_IDLE;
   end

   // ********************************************************************************
   // 32 Bits Divider
   reg [DIV_COUNT_WD-1:0] div_count;
   reg [DIV_DIVID_WD-1:0] div_divid;
   reg [DIV_DIVID_WD-1:0] div_accum;
   
   wire 		  div_rst, div_run, div_adj, div_done;
   
   reg [DIV_DIVID_WD-1:0] num_divid;
   reg [DIV_DIVIS_WD-1:0] num_divis;
   reg [DIV_COUNT_WD-1:0] num_count;

   // Divider cases selection
   // always @(/*AUTOSENSE*/`IRTCVCRW or `IRTCVFRW or cal_cnt or cal_duty
   always @(cal_cnt or cal_duty
	    or cal_freq or div_divid or irsysfr or irtcv_dt33
	    or irtcv_fcnt_reg or irtcvfr) begin
      case ({cal_cnt, cal_duty, cal_freq})
	3'b100  : begin 
	   num_divid = irsysfr[DIV_DIVID_WD-1:0];
	   num_divis = {{(DIV_DIVIS_WD-`IRTCVFRW){1'b0}}, irtcvfr};
	   num_count = DIV_DIVID_WD-1;
	end
	3'b010  : begin 
	   num_divid = div_divid;
	   num_divis = irtcv_dt33 ? 3 : 2;
	   num_count = DIV_DIVID_WD-1;
	end
	3'b001  : begin 
	   num_divid = irsysfr[DIV_DIVID_WD-1:0];
	   num_divis = {{(DIV_DIVIS_WD-`IRTCVCRW){1'b0}}, irtcv_fcnt_reg};
	   num_count = DIV_DIVID_WD-1;    // `IRSYSFRW-1;
	end
	default : begin
	   num_divid = irsysfr[DIV_DIVID_WD-1:0];
	   num_divis = {{(DIV_DIVIS_WD-`IRTCVFRW){1'b0}}, irtcvfr};
	   num_count = DIV_DIVID_WD-1;
	end
      endcase // case ({cal_cnt, cal_duty, cal_freq})
   end
   
   // DIV LOGIC
   assign div_done = (div_count == num_count);
   always @(/*AUTOSENSE*/div_done or div_start or div_state) begin
      case (div_state)
	DIVST_IDLE : begin
	   if (div_start) div_next = DIVST_INIT;
	   else           div_next = DIVST_IDLE;
	end
	DIVST_INIT :      div_next = DIVST_CALC;
	DIVST_CALC : begin
	   if (div_done)  div_next = DIVST_FADJ;
	   else           div_next = DIVST_CALC;
	end
	DIVST_FADJ :      div_next = DIVST_IDLE;
	default    :      div_next = DIVST_IDLE;
      endcase // case (div_state)
   end // always @ (...

   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async)   div_state <= DIVST_IDLE;
      else if (irtcv_enable) div_state <= div_next;
      else                   div_state <= DIVST_IDLE;
   end

   assign div_rst  = (div_state == DIVST_INIT);
   assign div_run  = (div_state == DIVST_CALC);
   assign div_adj  = (div_state == DIVST_FADJ);
   assign div_fin  = div_adj;

   wire [DIV_DIVIS_WD-1:0] div_divis = div_adj ? {1'b0, num_divis[DIV_DIVIS_WD-1:1]} : num_divis[DIV_DIVIS_WD-1:0];
   
   wire [DIV_DIVID_WD:0]   div_sub_val   = div_accum - div_divis;
   wire                    div_sub_neg   = div_sub_val[DIV_DIVID_WD];
   wire [DIV_DIVID_WD-1:0] div_accum_nxt = div_sub_neg ? div_accum : div_sub_val;

   wire [DIV_COUNT_WD:0] div_count_incr1 = div_count + 1;
   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async) div_count <= {5{1'b0}};
      else if (div_rst)    div_count <= {5{1'b0}};
      else if (div_run)    div_count <= div_count_incr1[DIV_COUNT_WD-1:0];
      else                 div_count <= div_count;
   end

   wire accum_run = div_run & ~div_done;
   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async) div_accum <= {32{1'b0}};
      else if (div_rst)    div_accum <= {{31{1'b0}}, num_divid[DIV_DIVID_WD-1]};
      else if (accum_run)  div_accum <= {div_accum_nxt[DIV_DIVID_WD-2:0], div_divid[DIV_DIVID_WD-1]};
      else                 div_accum <= div_accum;
   end
   
   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async) div_divid <= {32{1'b0}};
      else if (div_rst)    div_divid <= {num_divid[DIV_DIVID_WD-2:0], 1'b0};
      else if (div_run)    div_divid <= {div_divid[DIV_DIVID_WD-2:0], ~div_sub_neg};
      else if (div_adj)    div_divid <= div_sub_neg ? div_divid : div_divid + 1;
      else                 div_divid <= div_divid;
   end

   assign irtcv_rfreq_dat = div_divid[`IRTCVFRW-1:0];
   
   // Calculation Results
   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async)     irtcv_fcnt_reg <= {`IRTCVCRW{1'b1}};
      else if (irtcv_rwat)     irtcv_fcnt_reg <= {`IRTCVCRW{1'b1}};
      else if (irtcv_rcnt_upd) irtcv_fcnt_reg <= freq_cnt;
      else if (div_fin1)       irtcv_fcnt_reg <= div_divid[`IRTCVCRW-1:0];
      else                     irtcv_fcnt_reg <= irtcv_fcnt_reg;
   end

   wire lrnmax_set = irtcv_usrmax & irtcv_lrnrise;
   always @(posedge irtcv_clk or posedge irtcv_rst_async) begin
      if (irtcv_rst_async) irtcv_duty_reg <= {`IRTCVCRW{1'b0}};
      else if (lrnmax_set) irtcv_duty_reg <= irtcvdr;
      else if (div_fin2)   irtcv_duty_reg <= div_divid[`IRTCVCRW-1:0];
      else                 irtcv_duty_reg <= irtcv_duty_reg;
   end

   assign irtcv_duty_val  = irtcv_lrnsync ? {1'b0, irtcv_fcnt_reg[`IRTCVCRW-1:1]} : irtcv_duty_reg;
   assign irtcv_qduty_val = {{2{1'b0}}, irtcv_fcnt_reg[`IRTCVCRW-1:2]};
   assign tcv_cnt_lrnmax  = irtcv_usrmax ? irtcv_duty_reg[`IRTCVCRW-2:0] : {(`IRTCVCRW-1){1'b1}};
   
// ************************************************************************************
   
`ifndef SYNTHESIS
// synopsys translate_off

   // CAL FSM States in ASCII
   reg [32*8-1:0] cal_state_ascii;
   always @(cal_state) begin
      case (cal_state)
	CALST_IDLE : cal_state_ascii = "CAL_IDLE";
	CALST_STT1 : cal_state_ascii = "CAL_START1";
	CALST_CAL1 : cal_state_ascii = "CAL_CALCULATE1";
	CALST_FIN1 : cal_state_ascii = "CAL_FINISH1";
	CALST_STT2 : cal_state_ascii = "CAL_START2";
	CALST_CAL2 : cal_state_ascii = "CAL_CALCULATE2";
	CALST_FIN2 : cal_state_ascii = "CAL_FINISH2";
	CALST_STT2 : cal_state_ascii = "CAL_START3";
	CALST_CAL2 : cal_state_ascii = "CAL_CALCULATE3";
	CALST_FIN3 : cal_state_ascii = "CAL_FINISH3";
	default    : cal_state_ascii = "UNDEFINED";
      endcase // case (cal_state)
   end // always @ (cal_state)
   
   // DIV FSM States in ASCII
   reg [32*8-1:0] div_state_ascii;
   always @(div_state) begin
      case (div_state)
        DIVST_IDLE : div_state_ascii = "DIV_IDLE";
	DIVST_INIT : div_state_ascii = "DIV_RESET";
	DIVST_CALC : div_state_ascii = "DIV_RUN";
	DIVST_FADJ : div_state_ascii = "DIV_FADJ";
	default    : div_state_ascii = "UNDEFINED";
      endcase // case (div_state)
   end
	
   // FSM States in ASCII
   reg [32*8-1:0] tcv_state_ascii;
   always @(tcv_state)
     begin
	case (tcv_state)
	  TCVST_IDLE : tcv_state_ascii = "TCV_IDLE";
	  TCVST_INIT : tcv_state_ascii = "TCV_INIT";
	  TCVST_TRN  : tcv_state_ascii = "TCV_TRAN";
	  TCVST_RWAT : tcv_state_ascii = "TCV_LWAIT";
	  TCVST_RMES : tcv_state_ascii = "TCV_LMEAS";
	  TCVST_RACT : tcv_state_ascii = "TCV_LDACT";
	  TCVST_RNUL : tcv_state_ascii = "TCV_LDNUL";
	  default    : tcv_state_ascii = "UNDEFINED";
	endcase // case (tcv_state)
     end // always @ (tcv_state)

// synopsys translate_on   
`endif //  `ifndef SYNTHESIS
   
endmodule // irtcv_ctrl
