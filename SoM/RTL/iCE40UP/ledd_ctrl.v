`include "defines4.v"
`timescale 1ns/1ps
module ledd_ctrl (/*AUTOARG*/
   // Outputs
   pwm_out_r, pwm_out_g, pwm_out_b, ledd_on,
   // Inputs
   ledd_rst_async, ledd_clk, ledd_exe, leddcr0, leddbr, leddonr,
   leddofr, leddbcrr, leddbcfr, leddpwrr, leddpwgr, leddpwbr
   );

   // INPUTS
   // From full chip POR ...
   input ledd_rst_async;          // Asynchronize Reset, to POR

   // From System Bus
   input ledd_clk;                // LED Control Bus clock

   input ledd_exe;                // LED Control Execute; Level sensitive
   
   // LEDD SCI Block
   input [`LEDCBDW-1:0] leddcr0;    // LED Driver Control Register 0
   input [`LEDCBDW-1:0] leddbr;     // LED Driver Clock Pre-scale Register
   input [`LEDCBDW-1:0] leddonr;    // LED Driver ON Time Register
   input [`LEDCBDW-1:0] leddofr;    // LED Driver OFF Time Register
   input [`LEDCBDW-1:0] leddbcrr;   // LED Driver Breath ON Control Register
   input [`LEDCBDW-1:0] leddbcfr;   // LED Driver Breath OFF Control Register
   input [`LEDCBDW-1:0] leddpwrr;   // LED Driver RED Pulse Width Register
   input [`LEDCBDW-1:0] leddpwgr;   // LED Driver GREEN Pulse Width Register
   input [`LEDCBDW-1:0] leddpwbr;   // LED Driver BLUE Pulse Width Register

   // OUTPUTS
   // IO or FPGA Fabric
   output pwm_out_r;
   output pwm_out_g;
   output pwm_out_b;
   
   // To FPGA Fabric
   output ledd_on;

   // REGS
   reg [2:0]  ledd_exe_sense;
   reg [8:0]  t_const;
   reg [8:0]  t_mult;
   reg [9:0]  time_dest;
   reg [19:0] time_cnt;
   reg [3:0]  state, next_state;

   reg [3:0]  time_ramp;
   reg 	      ledd_bcmd;
   reg [3:0]  mult_cnt;
   
   reg [`LEDDBRW-1:0] ledd_pscnt;
   reg 		      ledd_ps32k;

   reg [`LEDDPWW-1:0] ledd_pwmcnter;
   reg [`LEDDPWW-1:0] ledd_onfcnt;

   reg pwm_out_r, pwm_out_g, pwm_out_b;
   reg ledd_on;
   
   // WIRES
   wire ledd_enable, ledd_frsel, ledd_outpol, ledd_outskew, ledd_qstop, ledd_lfsr, ledd_bcrena;
   wire ledd_bcfena, ledd_bcrmd, ledd_bcfmd;
   wire ledd_extend;
   wire [1:0] ledd_psmsb;
   wire [3:0] ledd_ramprt, ledd_rampft;
	
   wire [`LEDDBRW-1:0] ledd_psvalue;
   wire [`LEDDPWW-1:0] ledd_pwmcnt;
   
   wire ledd_execute, ledd_exerise, ledd_rst_sync;
   wire ledd_pscnt0;
   wire ledd_fr32k, ledd_fr64k;
   wire ledd_frena, ledd_frstart;
   wire ledd_always;

   wire ledd_start;
   wire ledd_pwmset;
   wire ledd_on_org;
   wire ledd_on_pwm;
   
   wire leddst_idle;
   wire leddst_calr, leddst_capr, leddst_rampr, leddst_ledon;
   wire leddst_calf, leddst_capf, leddst_rampf, leddst_ledof;
   wire leddst_steady, leddst_mult, leddst_breath;
   wire leddst_rampr_all, leddst_rampf_all;
   
   wire mult_rst, mult_run, mult_cap, mult_done;
   wire ramp_rdone, ramp_fdone;
   
   wire accum_rst, accum_pst, accum_frz, accum_add, accum_sub, accum_mult, accum_add_all;
   
   wire [11:0] time_goal;
   wire        time_up, time_done;

   wire        ledd_pwm_out_r, ledd_pwm_out_g, ledd_pwm_out_b;
   
   /*AUTOWIRE*/
   
   // PARAMETERS
   parameter st_idle  = 4'b0000;
   parameter st_calr  = 4'b1000;
   parameter st_capr  = 4'b1010;
   parameter st_rampr = 4'b1011;
   parameter st_ledon = 4'b1001;
   parameter st_calf  = 4'b1101;
   parameter st_capf  = 4'b1100;
   parameter st_rampf = 4'b1110;
   parameter st_ledof = 4'b0110;
   
   assign ledd_on_org = state[3];
   assign ledd_on_pwm = (leddst_rampr | leddst_ledon | leddst_calf | leddst_capf | leddst_rampf) ;
   
   // LOGIC
   // Control Signal Assignments
   assign ledd_enable  = leddcr0[`BIT_LEDDCR0_EN];
   assign ledd_frsel   = leddcr0[`BIT_LEDDCR0_FR];
   assign ledd_outpol  = leddcr0[`BIT_LEDDCR0_POL];
   assign ledd_outskew = leddcr0[`BIT_LEDDCR0_SKEW];
   assign ledd_qstop   = leddcr0[`BIT_LEDDCR0_QSTOP];
   assign ledd_lfsr    = leddcr0[`BIT_LEDDCR0_LFSR];
   assign ledd_psmsb   = leddcr0[`BIT_LEDDCR0_BREXT:`BIT_LEDDCR0_BREXT-1];
   assign ledd_psvalue = {ledd_psmsb, leddbr};
   assign ledd_bcrena  = leddbcrr[`BIT_LEDDBCRR_EN];
   assign ledd_bcfena  = leddbcrr[`BIT_LEDDBCRR_ALL] ? ledd_bcrena : leddbcfr[`BIT_LEDDBCFR_EN];
   assign ledd_bcrmd   = leddbcrr[`BIT_LEDDBCRR_MD];
   assign ledd_bcfmd   = leddbcrr[`BIT_LEDDBCRR_ALL] ? ledd_bcrmd : leddbcfr[`BIT_LEDDBCFR_MD];
   assign ledd_ramprt  = leddbcrr[3:0];
   assign ledd_rampft  = leddbcrr[`BIT_LEDDBCRR_ALL] ? ledd_ramprt : leddbcfr[3:0];
   assign ledd_extend  = leddbcfr[`BIT_LEDDBCFR_EXT];

   assign ledd_always = ~(|leddofr) & ~ledd_bcfena;                 // PSE
   
   assign ledd_pscnt0 = ~(|ledd_pscnt);

   // LEDD_EXEC detection
   always @(posedge ledd_clk or posedge ledd_rst_async)
     if (ledd_rst_async) ledd_exe_sense <= 3'b000;
     else                ledd_exe_sense <= {(ledd_enable & ledd_exe), ledd_exe_sense[2:1]};

   assign ledd_execute = ledd_exe_sense[1] &  ledd_exe_sense[0];    // PSE
   assign ledd_exerise = ledd_exe_sense[1] & ~ledd_exe_sense[0];    // PSE

   assign ledd_rst_sync = ledd_exerise;

   wire ledd_active = ~leddst_idle;
   // Service LED Driver Pre-Scale Counter
   always @(posedge ledd_clk or posedge ledd_rst_async)
     begin
	if (ledd_rst_async)     ledd_pscnt <= {`LEDDBRW{1'b0}};
	else if (ledd_rst_sync) ledd_pscnt <= ledd_psvalue;
	else if (ledd_active) begin
	  if (ledd_pscnt0)      ledd_pscnt <= ledd_psvalue;
	  else                  ledd_pscnt <= ledd_pscnt - 1;
	end
        else                    ledd_pscnt <= ledd_pscnt;
     end

   always @(posedge ledd_clk or posedge ledd_rst_async)
     begin
	if (ledd_rst_async)     ledd_ps32k <= 1'b0;
	else if (ledd_rst_sync) ledd_ps32k <= 1'b0;
	else if (ledd_active) begin
	   if (ledd_pscnt0)     ledd_ps32k <= ~ledd_ps32k;
	   else                 ledd_ps32k <= ledd_ps32k;
	end
	else                    ledd_ps32k <= ledd_ps32k;
     end
	
   assign ledd_fr32k = ledd_ps32k & ledd_pscnt0;
   assign ledd_fr64k = ledd_pscnt0;

   assign ledd_frena = ledd_frsel ? ledd_fr64k : ledd_fr32k;

   wire lfsr_pwmcnt_ff = ledd_lfsr & (&ledd_pwmcnter);
   reg 	lfsr_pwmcnt_ff_d;
   wire lfsr_pwmcnt_ff_den = ledd_lfsr & ledd_frena;
   always @(posedge ledd_clk or posedge ledd_rst_async)
     begin
	if (ledd_rst_async)          lfsr_pwmcnt_ff_d <= 1'b0;
	else if (ledd_rst_sync)      lfsr_pwmcnt_ff_d <= 1'b0;
	else if (lfsr_pwmcnt_ff_den) lfsr_pwmcnt_ff_d <= lfsr_pwmcnt_ff;
	else                         lfsr_pwmcnt_ff_d <= lfsr_pwmcnt_ff_d;
     end

   wire lfsr_hold = lfsr_pwmcnt_ff & ~lfsr_pwmcnt_ff_d;
   
   // LED Driver Flick Rate Counter
   always @(posedge ledd_clk or posedge ledd_rst_async)
     begin
	if (ledd_rst_async)     ledd_pwmcnter <= {`LEDDPWW{1'b1}};
	else if (ledd_rst_sync) ledd_pwmcnter <= {`LEDDPWW{1'b1}};
	else if (ledd_frena) begin
	   if (ledd_lfsr)       ledd_pwmcnter <= lfsr_hold ? ledd_pwmcnter : ledd_pwmcnter[0] ? ((ledd_pwmcnter >> 1) ^ `LFSR_POLY) : (ledd_pwmcnter >> 1);
	   else                 ledd_pwmcnter <= ledd_pwmcnter + 1;
	end
	else                    ledd_pwmcnter <= ledd_pwmcnter;
     end

   assign ledd_pwmcnt = lfsr_hold ? {`LEDDPWW{1'b0}} : ledd_pwmcnter;
			
   // assign ledd_frstart = ~(|ledd_pwmcnt) & ledd_frena;    // All Zero Detection
   assign ledd_frstart = (&ledd_pwmcnter) & ledd_frena & ~lfsr_pwmcnt_ff_d;    // All ONE Detection PSE

   // FSM State Decode
   assign leddst_idle  = (state == st_idle);
   assign leddst_calr  = (state == st_calr);
   assign leddst_capr  = (state == st_capr);
   assign leddst_rampr = (state == st_rampr);
   assign leddst_ledon = (state == st_ledon);
   assign leddst_calf  = (state == st_calf);
   assign leddst_capf  = (state == st_capf);
   assign leddst_rampf = (state == st_rampf);
   assign leddst_ledof = (state == st_ledof);

   assign leddst_steady = leddst_ledon | leddst_ledof;
   assign leddst_mult   = leddst_calr  | leddst_calf;
   assign leddst_breath = leddst_rampr | leddst_rampf;

   assign leddst_rampr_all = leddst_calr | leddst_capr | leddst_rampr | leddst_ledof;
   assign leddst_rampf_all = leddst_calf | leddst_capf | leddst_rampf | leddst_ledon;
   
   // Next State Logice for the FSM
   wire quick_stop_en = ledd_qstop & ~ledd_execute;    // MOD0 : Quick Stop not frame bounded.
   always @(/*AUTOSENSE*/ledd_always or ledd_bcfena or ledd_bcrena
	    or ledd_execute or ledd_exerise or mult_done
	    or quick_stop_en or state or time_done)
     begin
	next_state = st_idle;
	case (state)
	  st_idle : begin
	     if (ledd_exerise) begin
		if (ledd_bcrena)      next_state = st_calr;
		else                  next_state = st_ledon;
	     end
	     else                     next_state = st_idle;
	  end
	  st_calr : begin
	     if (mult_done)           next_state = st_capr;
	     else                     next_state = st_calr;
	  end
	  st_capr : begin
	                              next_state = st_rampr;
	  end
	  st_rampr : begin
	     if (quick_stop_en)       next_state = st_idle;
	     else if (time_done)      next_state = st_ledon;
	     else                     next_state = st_rampr;
	  end
	  st_ledon : begin
	     if (quick_stop_en)       next_state = st_idle;
	     else if (time_done & ~ledd_always) begin
		if (ledd_bcfena)      next_state = st_calf;
		else                  next_state = st_ledof;
	     end
	     else if (time_done & ledd_always) begin
		if (ledd_execute)     next_state = st_ledon;
		else if (ledd_bcfena) next_state = st_calf;
		else                  next_state = st_idle;
	     end
	     else                     next_state = st_ledon;
	  end // case: st_ledon
	  st_calf : begin
	     if (mult_done)           next_state = st_capf;
	     else                     next_state = st_calf;
	  end
	  st_capf : begin
	                              next_state = st_rampf;
	  end
	  st_rampf : begin
	     if (quick_stop_en)       next_state = st_idle;
	     else if (time_done)      next_state = st_ledof;
	     else                     next_state = st_rampf;
	  end
	  st_ledof : begin
	     if (~ledd_execute)       next_state = st_idle;
	     else if (time_done) begin
		if (ledd_bcrena)      next_state = st_calr;
		else                  next_state = st_ledon;
	     end
	     else                     next_state = st_ledof;
	  end
	  default : begin
	                              next_state = st_idle;
	  end
	endcase // case (state)
     end // always @ (...

   // Sequencial Logic for the FSM
   always @(posedge ledd_clk or posedge ledd_rst_async)
     if (ledd_rst_async) state <= st_idle;
     else                state <= next_state;
   
   // Time count mux RAMP UP/DN
   always @(/*AUTOSENSE*/ledd_bcfmd or ledd_bcrmd or ledd_rampft
	    or ledd_ramprt or leddst_rampf_all or leddst_rampr_all)
     begin
	case ({leddst_rampr_all, leddst_rampf_all})
	  2'b10   : begin 
	     time_ramp = ledd_ramprt;
	     ledd_bcmd = ledd_bcrmd;
	  end
	  2'b01   : begin 
	     time_ramp = ledd_rampft;
	     ledd_bcmd = ledd_bcfmd;
	  end
	  default : begin
	     time_ramp = ledd_ramprt;
	     ledd_bcmd = ledd_bcrmd;
	  end
	endcase // case ({leddst_rmapr, leddst_rampf})
     end

   wire [4:0] time_ramp_adj = time_ramp + 1;
   // Time count mux for ON/OFF/RAMP
   always @(/*AUTOSENSE*/leddofr or leddonr or leddst_breath
	    or leddst_ledof or leddst_ledon or time_ramp_adj)
     begin
	case ({leddst_breath, leddst_ledon, leddst_ledof})
	  3'b100  : time_dest = {1'b0, time_ramp_adj, {4{1'b0}}};
	  3'b010  : time_dest = {leddonr, {2{1'b0}}};
	  3'b001  : time_dest = {leddofr, {2{1'b0}}};
	  default : time_dest = {10{1'b0}};
	endcase // case ({(leddst_rampr | leddst_rampf), leddst_ledon, leddst_ledof})
     end

   assign time_goal = ledd_frsel ? {1'b0, time_dest, 1'b0} : {1'b0, 1'b0, time_dest};
   
   // LED Drive ON/OFF/RAMP Time Counter
   wire time_cnt_rst = mult_rst | ((leddst_rampr | leddst_rampf) & time_done);
   wire time_cnt_run = (leddst_breath | leddst_steady) & ledd_frena;
   always @(posedge ledd_clk or posedge ledd_rst_async)
     begin
	if (ledd_rst_async)    time_cnt <= {{19{1'b0}}, 1'b1};
	else if (time_cnt_rst) time_cnt <= {{19{1'b0}}, 1'b1};    // MOD0 : Count start from 1, instead goal -1.
	else if (time_cnt_run) time_cnt <= time_cnt + 1;
     end   


   assign time_up = (time_cnt[19:8] == time_goal);
   
   assign time_done   = time_up & ledd_frena;
   
   // Time constant look-up table
   always @(/*AUTOSENSE*/time_ramp) 
     begin
	case (time_ramp)
	  4'd0   : t_const = 9'd256;   // 256/1  ;256      ;16
	  4'd1   : t_const = 9'd128;   // 256/2  ;128      ;32
	  4'd2   : t_const = 9'd85;    // 256/3  ;85.33333 ;48
	  4'd3   : t_const = 9'd64;    // 256/4  ;64       ;64
	  4'd4   : t_const = 9'd51;    // 256/5  ;51.2     ;80
	  4'd5   : t_const = 9'd43;    // 256/6  ;42.66667 ;96
	  4'd6   : t_const = 9'd37;    // 256/7  ;36.5714  ;112
	  4'd7   : t_const = 9'd32;    // 256/8  ;32       ;128
	  4'd8   : t_const = 9'd28;    // 256/9  ;28.44444 ;155
	  4'd9   : t_const = 9'd26;    // 256/10 ;25.6     ;160
	  4'd10  : t_const = 9'd23;    // 256/11 ;23.27273 ;176
	  4'd11  : t_const = 9'd21;    // 256/12 ;21,33333 ;192
	  4'd12  : t_const = 9'd20;    // 256/13 ;19.69231 ;208
	  4'd13  : t_const = 9'd18;    // 256/14 ;18.28571 ;224
	  4'd14  : t_const = 9'd17;    // 256/15 ;17.06667 ;240
	  4'd15  : t_const = 9'd16;    // 256/16 ;16       ;256
	  default: t_const = 9'd256;   // 256/1
	endcase // case (time_ramp)
     end // always @ (...

   // Time Constant multiplication shifter   MOD0
   always @(posedge ledd_clk or posedge ledd_rst_async)
     begin
	if (ledd_rst_async) t_mult <= {9{1'b0}};
	else if (mult_rst)  t_mult <= t_const;
	else if (mult_run)  t_mult <= {1'b0, t_mult[8:1]};
	else                t_mult <= t_mult;
     end

   // Clock Cycle count for multiplication and output slew at Fsys.
   wire mult_cnt_rst = ledd_start | (leddst_steady & time_done);
   wire mult_cnt_run = leddst_mult;
   always @(posedge ledd_clk or posedge ledd_rst_async)
     begin
	if (ledd_rst_async)    mult_cnt <= {4{1'b0}};
	else if (mult_cnt_rst) mult_cnt <= {4{1'b0}};
	else if (mult_cnt_run) mult_cnt <= mult_cnt + 1;
	else                   mult_cnt <= mult_cnt;
     end
   
   wire mult_cnt_done = (mult_cnt == 4'd9);
   assign mult_done  = leddst_mult &  mult_cnt_done;

   // PWM Sub-module control
   assign ledd_start = (leddst_idle & ledd_exerise);
   assign mult_rst   = ledd_start | ((leddst_ledon | leddst_ledof) & time_done);
   assign mult_run   = leddst_mult & ~mult_cnt_done;
   assign mult_cap   = (leddst_capr | leddst_capf);
   
   assign ramp_rdone = (leddst_rampr & time_done);
   assign ramp_fdone = (leddst_rampf & time_done);
   
   assign accum_rst  = leddst_capr | ramp_fdone | mult_rst;
   assign accum_pst  = leddst_capf & ~ledd_bcfmd;
   assign accum_frz  = ramp_rdone | (leddst_capf & ledd_bcfmd);
   assign accum_add  = leddst_rampr & ledd_frstart;
   assign accum_sub  = leddst_rampf & ledd_frstart;
   assign accum_mult = mult_run & t_mult[0];
   
   assign accum_add_all = accum_add | accum_mult;
		      
   wire leddst_laston = ledd_bcfena ? leddst_rampf : leddst_ledof;
   assign ledd_pwmset = ledd_frstart & ~(leddst_laston & time_up) & ~quick_stop_en;

   // PWM sub-module instantiation for each color
   // RED
   /*ledd_pwmc AUTO_TEMPLATE (
    .ledd_pwmout    (ledd_pwm_out_r),
    .ledd_pwmval    (leddpwrr),
    ); */
   ledd_pwmc pwmc_r (/*AUTOINST*/
		     // Outputs
		     .ledd_pwmout	(ledd_pwm_out_r),	 // Templated
		     // Inputs
		     .ledd_rst_async	(ledd_rst_async),
		     .ledd_clk		(ledd_clk),
		     .ledd_on_pwm	(ledd_on_pwm),
		     .ledd_frsel	(ledd_frsel),
		     .ledd_lfsr		(ledd_lfsr),
		     .ledd_bcmd		(ledd_bcmd),
		     .ledd_extend	(ledd_extend),
		     .leddst_breath	(leddst_breath),
		     .mult_rst		(mult_rst),
		     .mult_run		(mult_run),
		     .mult_cap		(mult_cap),
		     .accum_rst		(accum_rst),
		     .accum_pst		(accum_pst),
		     .accum_frz		(accum_frz),
		     .accum_add_all	(accum_add_all),
		     .accum_sub		(accum_sub),
		     .ledd_pwmcnt	(ledd_pwmcnt[`LEDDPWW-1:0]),
		     .ledd_pwmval	(leddpwrr));		 // Templated

   // GREEN
   /*ledd_pwmc AUTO_TEMPLATE (
    .ledd_pwmout    (ledd_pwm_out_g),
    .ledd_pwmval    (leddpwgr),
    ); */
   ledd_pwmc pwmc_g (/*AUTOINST*/
		     // Outputs
		     .ledd_pwmout	(ledd_pwm_out_g),	 // Templated
		     // Inputs
		     .ledd_rst_async	(ledd_rst_async),
		     .ledd_clk		(ledd_clk),
		     .ledd_on_pwm	(ledd_on_pwm),
		     .ledd_frsel	(ledd_frsel),
		     .ledd_lfsr		(ledd_lfsr),
		     .ledd_bcmd		(ledd_bcmd),
		     .ledd_extend	(ledd_extend),
		     .leddst_breath	(leddst_breath),
		     .mult_rst		(mult_rst),
		     .mult_run		(mult_run),
		     .mult_cap		(mult_cap),
		     .accum_rst		(accum_rst),
		     .accum_pst		(accum_pst),
		     .accum_frz		(accum_frz),
		     .accum_add_all	(accum_add_all),
		     .accum_sub		(accum_sub),
		     .ledd_pwmcnt	(ledd_pwmcnt[`LEDDPWW-1:0]),
		     .ledd_pwmval	(leddpwgr));		 // Templated

   // BLUE
   /*ledd_pwmc AUTO_TEMPLATE (
    .ledd_pwmout    (ledd_pwm_out_b),
    .ledd_pwmval    (leddpwbr),
    ); */
   ledd_pwmc pwmc_b (/*AUTOINST*/
		     // Outputs
		     .ledd_pwmout	(ledd_pwm_out_b),	 // Templated
		     // Inputs
		     .ledd_rst_async	(ledd_rst_async),
		     .ledd_clk		(ledd_clk),
		     .ledd_on_pwm	(ledd_on_pwm),
		     .ledd_frsel	(ledd_frsel),
		     .ledd_lfsr		(ledd_lfsr),
		     .ledd_bcmd		(ledd_bcmd),
		     .ledd_extend	(ledd_extend),
		     .leddst_breath	(leddst_breath),
		     .mult_rst		(mult_rst),
		     .mult_run		(mult_run),
		     .mult_cap		(mult_cap),
		     .accum_rst		(accum_rst),
		     .accum_pst		(accum_pst),
		     .accum_frz		(accum_frz),
		     .accum_add_all	(accum_add_all),
		     .accum_sub		(accum_sub),
		     .ledd_pwmcnt	(ledd_pwmcnt[`LEDDPWW-1:0]),
		     .ledd_pwmval	(leddpwbr));		 // Templated

   // Final Output Polarity and Skew Option
   // RED LED
   always @(posedge ledd_clk or posedge ledd_rst_async)
     begin
	if (ledd_rst_async) pwm_out_r <= 1'b0;
	else                pwm_out_r <= ledd_outpol ^ ledd_pwm_out_r;
     end

   // GREEN LED
   reg [7:0] skew_delay_g;
   reg 	     delay_pwm_out_g;
   wire      skew_pwm_out_g;
   
   always @(posedge ledd_clk or posedge ledd_rst_async)
     begin
	if (ledd_rst_async)    skew_delay_g <= {8{1'b0}};
	else if (ledd_outskew) skew_delay_g <= {skew_delay_g[6:0], ledd_pwm_out_g};
	else                   skew_delay_g <= skew_delay_g;
     end

   always @(/*AutOSENSE*/ledd_psmsb or ledd_pwm_out_g or skew_delay_g)
     begin
	case (ledd_psmsb)
	  2'b00   : delay_pwm_out_g = skew_delay_g[0];
	  2'b01   : delay_pwm_out_g = skew_delay_g[1];
	  2'b10   : delay_pwm_out_g = skew_delay_g[3];
	  2'b11   : delay_pwm_out_g = skew_delay_g[7];
	  default : delay_pwm_out_g = ledd_pwm_out_g;
	endcase // case (ledd_psmsb)
     end

   assign skew_pwm_out_g = ledd_outskew ? delay_pwm_out_g : ledd_pwm_out_g;
	  
   always @(posedge ledd_clk or posedge ledd_rst_async)
     begin
	if (ledd_rst_async) pwm_out_g <= 1'b0;
	else                pwm_out_g <= ledd_outpol ^ skew_pwm_out_g;
     end

   // BLUE LED
   reg [15:0] skew_delay_b;
   reg 	      delay_pwm_out_b;
   wire       skew_pwm_out_b;

   always @(posedge ledd_clk or posedge ledd_rst_async)
     begin
	if (ledd_rst_async)    skew_delay_b <= {16{1'b0}};
	else if (ledd_outskew) skew_delay_b <= {skew_delay_b[14:0], ledd_pwm_out_b};
	else                   skew_delay_b <= skew_delay_b;
     end

   always @(/*AUTOSENSE*/ledd_psmsb or ledd_pwm_out_b or skew_delay_b)
     begin
	case (ledd_psmsb)
	  2'b00   : delay_pwm_out_b = skew_delay_b[1];
	  2'b01   : delay_pwm_out_b = skew_delay_b[3];
	  2'b10   : delay_pwm_out_b = skew_delay_b[7];
	  2'b11   : delay_pwm_out_b = skew_delay_b[15];
	  default : delay_pwm_out_b = ledd_pwm_out_b;
	endcase // case (ledd_psmsb)
     end

   assign skew_pwm_out_b = ledd_outskew ? delay_pwm_out_b : ledd_pwm_out_b;
   
   always @(posedge ledd_clk or posedge ledd_rst_async)
     begin
	if (ledd_rst_async) pwm_out_b <= 1'b0;
	else                pwm_out_b <= ledd_outpol ^ skew_pwm_out_b;
     end

   // Re-shape the ledd_on signal to cover the skew
   reg  ledd_on_ext;
   wire ledd_on_int;

   always @(/*AUTOSENSE*/ledd_psmsb or skew_delay_b)
     begin
	case (ledd_psmsb)
	  2'b00   : ledd_on_ext = (skew_delay_b[1]);
	  2'b01   : ledd_on_ext = (|skew_delay_b[3:0]);
	  2'b10   : ledd_on_ext = (|skew_delay_b[7:0]);
	  2'b11   : ledd_on_ext = (|skew_delay_b[15:0]);
	  default : ledd_on_ext = 1'b0;
	endcase // case (ledd_psmsb)
     end

   assign ledd_on_int = ledd_outskew ? (ledd_on_org | ledd_on_ext) : ledd_on_org;
   
   always @(posedge ledd_clk or posedge ledd_rst_async)
     begin
	if (ledd_rst_async) ledd_on <= 1'b0;
	else                ledd_on <= ledd_on_int;
     end

   
`ifndef SYNTHESIS
// synopsys translate_off
 
   // FSM States in ASCII
   reg [32*8-1:0] state_ascii;
   always @(state)
     begin
	case (state)
	  st_idle  : state_ascii = "IDLE";
	  st_calr  : state_ascii = "CAL_RUP";
	  st_capr  : state_ascii = "CAP_RUP";
	  st_rampr : state_ascii = "RAMP_UP";
	  st_ledon : state_ascii = "STEADY_ON";
	  st_calf  : state_ascii = "CAL_RDN";
	  st_capf  : state_ascii = "CAP_RDN";
	  st_rampf : state_ascii = "RAMP_DN";
	  st_ledof : state_ascii = "STEADY_OFF";
	  default  : state_ascii = "UNDEFINED";
	endcase // case (state)
     end // always @ (state)

   // Virtual Brightness Monitor
   wire        mon_off = ~ledd_active;
   // Brightness monitor for RED LED
   reg [255:0] virtual_red;
   integer     bright_red;
   
   always @(posedge ledd_clk or posedge ledd_rst_async) begin
      if (ledd_rst_async)  virtual_red <= {256{1'b0}};
      else if (mon_off)    virtual_red <= {256{1'b0}};
      else if (ledd_frena) virtual_red <= {ledd_pwm_out_r, virtual_red[255:1]};
      else                 virtual_red <= virtual_red;
   end
   
   always @(posedge ledd_clk or posedge ledd_rst_async) begin
      if (ledd_rst_async) bright_red = 0;
      else if (mon_off)   bright_red = 0;
      else if (ledd_frena) begin
	 case ({ledd_pwm_out_r, virtual_red[0]})
	   2'b00 :        bright_red = bright_red;
	   2'b01 :        bright_red = bright_red - 1;
	   2'b10 :        bright_red = bright_red + 1;
	   2'b11 :        bright_red = bright_red;
	   default :      bright_red = bright_red;
	 endcase // case ({ledd_pwm_out_r, virtual_red[0]})
      end
   end // always @ (posedge ledd_clk or posedge ledd_rst_async)
   
   // Brightness monitor for GREEN LED
   reg [255:0] virtual_green;
   integer     bright_green;
   always @(posedge ledd_clk or posedge ledd_rst_async) begin
      if (ledd_rst_async)  virtual_green <= {256{1'b0}};
      else if (mon_off)    virtual_green <= {256{1'b0}};
      else if (ledd_frena) virtual_green <= {ledd_pwm_out_g, virtual_green[255:1]};
      else                 virtual_green <= virtual_green;
   end
   
   always @(posedge ledd_clk or posedge ledd_rst_async) begin
      if (ledd_rst_async) bright_green = 0;
      else if (mon_off)   bright_green = 0;
      else if (ledd_frena) begin
	 case ({ledd_pwm_out_g, virtual_green[0]})
	   2'b00 :        bright_green = bright_green;
	   2'b01 :        bright_green = bright_green - 1;
	   2'b10 :        bright_green = bright_green + 1;
	   2'b11 :        bright_green = bright_green;
	   default :      bright_green = bright_green;
	 endcase // case ({ledd_pwm_out_g, virtual_green[0]})
      end
   end // always @ (posedge ledd_clk or posedge ledd_rst_async)

   // Brightness monitor for BLUE LED
   reg [255:0] virtual_blue;
   integer     bright_blue;
   always @(posedge ledd_clk or posedge ledd_rst_async) begin
      if (ledd_rst_async)  virtual_blue <= {256{1'b0}};
      else if (mon_off)    virtual_blue <= {256{1'b0}};
      else if (ledd_frena) virtual_blue <= {ledd_pwm_out_b, virtual_blue[255:1]};
      else                 virtual_blue <= virtual_blue;
   end

   always @(posedge ledd_clk or posedge ledd_rst_async) begin
      if (ledd_rst_async) bright_blue = 0;
      else if (mon_off)   bright_blue = 0;
      else if (ledd_frena) begin
	 case ({ledd_pwm_out_b, virtual_blue[0]})
	   2'b00 :        bright_blue = bright_blue;
	   2'b01 :        bright_blue = bright_blue - 1;
	   2'b10 :        bright_blue = bright_blue + 1;
	   2'b11 :        bright_blue = bright_blue;
	   default :      bright_blue = bright_blue;
	 endcase // case ({ledd_pwm_out_b, virtual_blue[0]})
      end
   end // always @ (posedge ledd_clk or posedge ledd_rst_async)

// synopsys translate_on   
`endif //  `ifndef SYNTHESIS
   
endmodule // ledd_ctrl
