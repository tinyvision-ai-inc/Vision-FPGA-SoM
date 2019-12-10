/************************************************************************/
/*  (c) 2009; Analog Bits, Inc. - Proprietary and Confidential          */
/*   Version:     2009.03.11                                            */
/*      Date:     March 11, 2009                                         */
/************************************************************************/
/*   Wide Range PLL logic model                                         */
/*                                                                      */
/************************************************************************/
/*                                                                      */
/*  Application Notes:                                                  */
/*                                                                      */
/*  - To initialize the simulation properly, the RESET signal must be   */
/*    asserted at the beginning of the simulation.                      */
/*                                                                      */
/*   - The constants MIN_OUT_FREQ and MAX_OUT_FREQ are used to make     */
/*     sure that the output of the PLL is within an acceptable fre-     */
/*     quency range.  However, even if the frequency of the PLL out-    */
/*     put is within spec, the settings of DIVR, DIVF, or DIVQ may      */
/*     be incorrect, and cause another part of the PLL to be oper-      */
/*     ating out of spec.                                               */
/*                                                                      */
/*          - MIN_DREF_FREQ and MAX_DREF_FREQ are used to ensure that   */
/*            the post-divider reference signal is within the fre-      */
/*            quency range given in the design specifications.          */
/*                                                                      */
/*          - MIN_VCO_FREQ and MAX_VCO_FREQ are used to ensure that     */
/*            the vco signal is within the frequency range given in     */
/*            the design specifications.                                */
/*                                                                      */
/*          - MIN_REF_FREQ and MAX_REF_FREQ are used to ensure that     */
/*            the incoming REF clock signal is within the frequency     */
/*            range given in the design specifications.                 */
/*                                                                      */
/*   - The feedback loop is partially implemented (in the model FB has  */
/*     limited functionality). FB _does_ need to be connected directly  */
/*     or through clock tree to PLLOUT when FSE is low, or tied off     */
/*     when FSE is high. Otherwise, the results of the simulation may   */
/*     not be accurate, the pll will not assert LOCK, and several       */
/*     warning may appear when the model is being simulated.            */
/************************************************************************/

`timescale 1ps/1ps

/****************************************************/
/* these time period constants are in picoseconds:  */
/*     100,000 -> 10MHz                             */
/*       7,500 -> 133MHz                            */
/*       4,292 -> 233MHz                            */
/*       1,875 -> 533MHz                            */
/****************************************************/

`define MIN_VCO_FREQ 20'd4292
`define MAX_VCO_FREQ 20'd1875
`define MIN_REF_FREQ 20'd100_000
`define MAX_REF_FREQ 20'd7500
`define MIN_DREF_FREQ 20'd100_000
`define MAX_DREF_FREQ 20'd7500
`define MIN_OUT_FREQ 20'd100_000
`define MAX_OUT_FREQ 20'd1875
`define PULSE_MIN 20'd350

module  ABIPTBS8 (
		REF,
		FB,
		FSE,
		BYPASS,
		RESET,
		DIVF5,
		DIVF4,
		DIVF3,
		DIVF2,
		DIVF1,
		DIVF0,
		DIVQ2,
		DIVQ1,
		DIVQ0,
		DIVR3,
		DIVR2,
		DIVR1,
		DIVR0,
		RANGE2,
		RANGE1,
		RANGE0,

		LOCK,
		PLLOUT
);

//----------------------------------------------------------------------
// Port Declarations
//----------------------------------------------------------------------

// Input
  input         REF;	// Reference Clock
  input         FB;
  input         FSE;
  input         BYPASS;	// Bypass - Active HIGH
  input         RESET;	// Reset  - Active HIGH
  input         DIVF5;	// Feedback Divider Control
  input         DIVF4;
  input         DIVF3;
  input         DIVF2;
  input         DIVF1;
  input         DIVF0;
  input         DIVR3;	// Reference Divider Control
  input         DIVR2;
  input         DIVR1;
  input         DIVR0;
  input         DIVQ2;	// Output Divider Control for PLLOUT
  input         DIVQ1;
  input         DIVQ0;
  input         RANGE2;	// RANGE pins
  input         RANGE1;
  input         RANGE0;


// Output
  output        LOCK;	// PLL locked when HIGH
  output        PLLOUT;

  reg warning_flag, ref_freq_chg, on_vco, on_flag, ff_lock;
  reg vco_low_flag, vco_high_flag;
  reg rFreq_low_flag, rFreq_high_flag, drFreq_low_flag, drFreq_high_flag;
  reg oFreq_low_flag, oFreq_high_flag;
  reg pos_pulse_flag, neg_pulse_flag;
  reg lock_enabled_flag, pll_lock_reg;
  reg phase_lock;
  reg [3:0] lock_count_reg;
  reg [3:0] fb_count;
  reg vco_ck, pllout_ck, divided_ref, divided_fb;
  reg range_byp, range_warn, reset_init;

  reg phase_adjust; //markes when we do a phase adjust, so that we don't unlock

  time last_posedge_ref, last_negedge_ref, period_ref, period_ref1, period_ref2;
  time last_posedge_fb, period_fb, period_fb1, period_fb2, period_fb3, period_fb4;
  time last_posedge_divfb, period_divfb, last_posedge_divref, period_divref;
  time last_posedge_vco, period_vco, last_posedge_out, period_out;
  time low_time_vco, high_time_vco;
  time low_time_pllout, high_time_pllout;
  time low_time_divref, high_time_divref;
//  time low_time_divfb, high_time_divfb; //no need for divided_fb in internal FB mode
  integer correction, correction_ref;
  integer correction_ph;

  integer mult_divq, mult_divr, divider_divf;
  integer mult_divq_dly, mult_divr_dly, divider_divf_dly;
  integer divider_external, divider_external_dly;
  integer nb_ref_cycles, nb_fb_cycles, nb_divref_cycles, nb_divfb_cycles;
  integer nb_vco_cycles, nb_pllout_cycles;
  integer divf_count; //for external FB, to create divided_fb signal

  real period_ref_real, period_fb_real, inner_freq_margin;
  real period_fb1_real, period_fb2_real,period_fb3_real, period_fb4_real;
  real fb_compare, fb_compare1, fb_compare2, fb_comp_skip;
  real period_divfb_real, period_divref_real;

  wire on_wire;
  wire bypassi;

  wire ref_ck, fbi;
  wire fsei, reseti, range2i, range1i, range0i;
  wire divf5i, divf4i, divf3i, divf2i, divf1i, divf0i;
  wire divr3i, divr2i, divr1i, divr0i;
  wire divq2i, divq1i, divq0i;
  wire pllouti;

  wire locki;

//Internal signals
  buf u0   (ref_ck,REF);
  buf u1   (fbi,FB);
  buf u2   (fsei,FSE);
//  buf u3   (bypassi,BYPASS);
  buf u4   (reseti,RESET);

  buf u12  (range2i,RANGE2);
  buf u11  (range1i,RANGE1);
  buf u10  (range0i,RANGE0);

  buf u25  (divf5i,DIVF5);
  buf u24  (divf4i,DIVF4);
  buf u23  (divf3i,DIVF3);
  buf u22  (divf2i,DIVF2);
  buf u21  (divf1i,DIVF1);
  buf u20  (divf0i,DIVF0);

  buf u33  (divr3i,DIVR3);
  buf u32  (divr2i,DIVR2);
  buf u31  (divr1i,DIVR1);
  buf u30  (divr0i,DIVR0);

  buf u42  (divq2i,DIVQ2);
  buf u41  (divq1i,DIVQ1);
  buf u40  (divq0i,DIVQ0);

  buf u90  (PLLOUT,pllouti);
  buf u91  (LOCK,locki);

  assign bypassi = ( BYPASS | range_byp ) ;

//
//  These muxes are re-written to provide more testability in verilog.
//  If the user does not drive BYPASS or RESET, it will cause an unknown
//  on the output to direct the user's attention to the problem.
//
//  assign pllouti = bypassi ? ref_ck  :
//                    reseti ? 1'b0  : 
//                reset_init ? pllout_ck : 1'b0;  If reset_init has not gone high, output does not start toggling
//  reset_init is internal, initialized to zero, so can only be zero or one, never 'x'
//
  assign pllouti = (bypassi === 1'b1) ? ref_ck  :
                  ((bypassi === 1'b0) ? (( reseti === 1'b1) ? 1'b0 : 
                                         ( reseti === 1'b0) ? ((reset_init === 1'b1) ? pllout_ck : 1'b0 ) : 1'bx ) : 1'bx );

//  assign on_wire = bypassi ? 1'b0  :
//                    reseti ? 1'b0  : on_flag;
//
  assign on_wire = (bypassi === 1'b1) ? 1'b0  :
                  ((bypassi === 1'b0) ? (( reseti === 1'b1) ? 1'b0 : 
                                         ( reseti === 1'b0) ? on_flag : 1'b0 ) : 1'b0 ) ;

//  assign locki = pll_lock_reg && (fsei | phase_lock);
  assign locki = (fsei === 1'b0) ? phase_lock :
                ((fsei === 1'b1) ? pll_lock_reg : 1'b0 ) ;

  initial
     begin
	range_byp <= 1'b0;
	range_warn <= 1'b0;
	reset_init <= 1'b0;
	phase_adjust <= 1'b0;

	warning_flag <= 1'b1;
	ref_freq_chg <= 1'b0;
	on_vco <= 1'b0;
	on_flag <= 1'b0;
	ff_lock <= 1'b0;
	vco_low_flag <= 1'b0;
	vco_high_flag <= 1'b0;
	rFreq_low_flag <= 1'b0;
	rFreq_high_flag <= 1'b0;
	drFreq_low_flag <= 1'b0;
	drFreq_high_flag <= 1'b0;
	oFreq_low_flag <= 1'b0;
	oFreq_high_flag <= 1'b0;
	pos_pulse_flag <= 1'b0;
	neg_pulse_flag <= 1'b0;
	lock_enabled_flag <= 1'b0;
	pll_lock_reg <= 1'b0;
	phase_lock <= 1'b0;

	lock_count_reg <= 4'b0000;
	fb_count <= 4'b0000;
	last_posedge_ref <= 0;
	last_negedge_ref <= 0;
	period_ref <= 0;
	period_ref1 <= 0;
	period_ref2 <= 0;
	last_posedge_fb <= 0;
	period_fb <= 0;
	period_fb1 <= 0;
	period_fb2 <= 0;
	period_fb3 <= 0;
	period_fb4 <= 0;
	last_posedge_vco <= 0;
	period_vco <= 0;
	low_time_vco <= 0;
	high_time_vco <= 0;
	last_posedge_divfb <= 0;
	period_divfb <= 0;
	last_posedge_divref <= 0;
	period_divref <= 0;
	last_posedge_out <= 0;
	period_out <= 0;
	low_time_pllout <= 0;
	high_time_pllout <= 0;
	correction <= 0;
	correction_ph <= 0;
	low_time_divref <= 0;
	high_time_divref <= 0;
	correction_ref <= 0;

	period_ref_real <= 0;
	period_fb_real <= 0;
	inner_freq_margin <= 0;
	period_fb1_real <= 0;
	period_fb2_real <= 0;
	fb_compare <= 0;
	fb_compare1 <= 0;
	fb_compare2 <= 0;
	fb_comp_skip <=0;
	period_divref_real <= 0;
	period_divfb_real <= 0;

	mult_divq <= 0;
	mult_divr <= 0;
	divider_divf <= 0;
	mult_divq_dly <= 0;
	mult_divr_dly <= 0;
	divider_divf_dly <= 0;
	divider_external <= 1;
	divider_external_dly <= 1;
	nb_ref_cycles <= 0;
	nb_fb_cycles <= 0;
	nb_vco_cycles <= 0;
	nb_pllout_cycles <= 0;
	nb_divref_cycles <= 0;
	nb_divfb_cycles <= 0;

	vco_ck <= 1'b0;
	divided_ref <= 1'b0;
	divided_fb <= 1'b0;
	pllout_ck <= 1'b0;

	divf_count <= 1'b0;
     end

//
// Calculate counter integer values
//
always @(divr3i or divr2i or divr1i or divr0i)
    begin
	mult_divr <= {divr3i, divr2i, divr1i, divr0i} + 1;
    end

always @(divq2i or divq1i or divq0i)
   begin
	case ({divq2i,divq1i,divq0i})
	  3'b000: mult_divq <= 1;
	  3'b001: mult_divq <= 2;
	  3'b010: mult_divq <= 4;
	  3'b011: mult_divq <= 8;
	  3'b100: mult_divq <= 16;
	  3'b101: mult_divq <= 32;
	  3'b110: begin
			mult_divq <= 32;
			$display ("\n");
			$display ("**********************Attention************************* \n");
			$display ("The setting on DIVQ is not valid (cannot divide by 64)  \n");
			$display ("DIVQ is being treated as 101 (divide by 32) for the rest \n");
			$display ("of the simulation. \n");
			$display ("\n");
			$display ("   Simulation time is %t\n", $time);
			$display ("***************************************************** \n");
			$display ("\n");
		  end
	  3'b111: begin
			mult_divq <= 32;
			$display ("\n");
			$display ("**********************Attention************************* \n");
			$display ("The setting on DIVQ is not valid (cannot divide by 128)  \n");
			$display ("DIVQ is being treated as 101 (divide by 32) for the rest \n");
			$display ("of the simulation. \n");
			$display ("\n");
			$display ("   Simulation time is %t\n", $time);
			$display ("***************************************************** \n");
			$display ("\n");
		  end
	endcase
    end

always @(divf5i or divf4i or divf3i or divf2i or divf1i or divf0i)
    begin 
	divider_divf <= ({divf5i,divf4i,divf3i,divf2i,divf1i,divf0i} + 1);
    end

//
// Check for RESET initialization
//  (If RESET does not go high, PLL output will not toggle
always @(posedge RESET or posedge bypassi)
    begin
	reset_init <= 1'b1;
    end

//
// Calculate REF period, divided_ref period, vco variables
//
always @(posedge ref_ck)
    begin
	if (last_posedge_ref !== 0) 
           begin
		divider_external_dly <= divider_external;
		divider_divf_dly <= divider_divf;
		mult_divr_dly <= mult_divr;
		mult_divq_dly <= mult_divq;
		period_ref <= $time - last_posedge_ref;
		period_ref_real <= $time - last_posedge_ref;
		low_time_divref <= (period_ref * mult_divr) / 2;
		high_time_divref <= (period_ref * mult_divr) / 2;
		if (fsei == 1'b0)
		     begin //external
			low_time_pllout <= (period_ref * mult_divr) / (divider_external * divider_divf * 2);
			if (low_time_pllout!== 0) high_time_pllout <= (period_ref*mult_divr)/(divider_external*divider_divf)-low_time_pllout;
			else high_time_pllout <= (period_ref * mult_divr) / (divider_external * divider_divf * 2);
			//added for vco
			low_time_vco <= (period_ref * mult_divr) / (mult_divq * divider_external * divider_divf * 2);
			if (low_time_vco !== 0) high_time_vco <= (period_ref*mult_divr) / (mult_divq*divider_external*divider_divf)-low_time_vco;
			else high_time_vco <= (period_ref * mult_divr) / (mult_divq * divider_external * divider_divf * 2);
		     end
		else
		     begin //internal
			low_time_pllout <= ( period_ref * mult_divq * mult_divr) / (divider_divf * 2);
			if (low_time_pllout!== 0) high_time_pllout <= (period_ref*mult_divq*mult_divr) / (divider_divf) - low_time_pllout;
			else high_time_pllout <= ( period_ref * mult_divq * mult_divr) / (divider_divf * 2);
			//added for vco
			low_time_vco <= (period_ref * mult_divr) / (divider_divf * 2);
			if (low_time_vco !== 0) high_time_vco <= (period_ref*mult_divr)/(divider_divf) - low_time_vco;
			else high_time_vco <= (period_ref * mult_divr) / (divider_divf * 2);
		     end
		nb_ref_cycles <= nb_ref_cycles + 1;
		if ((period_ref !== 0) && !bypassi && !reseti) 
		begin
		    on_vco <= 1'b1;
		    on_flag <= 1'b1;
		end

		//Track minimum negative pulse width
		if ( (($time - last_negedge_ref) < `PULSE_MIN ) && !neg_pulse_flag )
		  begin
		   $display ("\n");
		   $display ("************************Attention************************\n");
		   $display ("   The negative pulse of the incoming REF clock is too   \n");
		   $display ("   small!  The minimum acceptable pulse width is 350ps.  \n");
		   $display ("   The PLL verilog model will continue to operate, but   \n");
		   $display ("   the current simulation results may not be accurate!   \n");
		   $display ("\n");
		   $display ("   Please check the REF input signal, and rerun the      \n");
		   $display ("   simulation.                                           \n");
		   $display ("\n");
		   $display ("   Simulation time is %t\n", $time);
		   $display ("******************************************************** \n");
		   $display ("\n");
		   neg_pulse_flag <= 1'b1;
		  end

	     end
	last_posedge_ref <= $time;	
	if (period_ref1 !== 0) period_ref2 <= period_ref1;
	if (period_ref !== 0) period_ref1 <= period_ref;
    //
    // ERROR CHECKING to detect possible problems with the FB path
    //
	//for possible problems with feedback path
	if ( (fbi !== 1'b0) && (fbi !== 1'b1) )
	    begin
		if (warning_flag == 1'b1)
		    begin
			$display ("\n");
			$display ("**********************Attention********************** \n");
			$display ("The Feedback path (pin FB) is not properly connected. \n");
			$display ("        Current results may not be accurate!!         \n");
			$display ("\n");
			$display ("   Simulation time is %t\n", $time);
			$display ("***************************************************** \n");
			$display ("\n");
			warning_flag <= 1'b0;	//warned, so turn it off
		    end 
	    end
	if ( (nb_ref_cycles == 100) && (period_fb == 0) && (!RESET) && (!BYPASS) && (fsei == 1'b0) )
	    begin
		$display ("\n");
		$display ("**********************Attention********************** \n");
		$display ("       There may be a problem with the FB pin.        \n");
		$display ("                It may be stuck at %b!                \n", FB);
		$display ("           Please check the feedback path.            \n");
		$display ("        Current results may not be accurate!!         \n");
		$display ("\n");
		$display ("   Simulation time is %t\n", $time);
		$display ("***************************************************** \n");
		$display ("\n");
	    end

	//check if frequency of incoming REF clock is out of spec
	    if (period_ref !== 0)
	      begin
	        if ( (period_ref > `MIN_REF_FREQ) && !rFreq_low_flag )
	          begin
	           $display ("\n");
	           $display ("************************Attention************************\n");
	           $display ("   The frequency of the incoming REF clock is too slow!  \n");
	           $display ("   The frequency is below 10MHz.                         \n");
	           $display ("   The PLL is operating out of spec, therefore the       \n");
	           $display ("   current simulation results may not be accurate!       \n");
	           $display ("\n");
	           $display ("   Please check the REF input signal, and rerun the      \n");
	           $display ("   simulation.                                           \n");
	           $display ("\n");
	           $display ("   Simulation time is %t\n", $time);
	           $display ("******************************************************** \n");
	           $display ("\n");
	           rFreq_low_flag <= 1'b1;
	          end
	        if ( (period_ref < `MAX_REF_FREQ) && !rFreq_high_flag )
	          begin
	           $display ("\n");
	           $display ("************************Attention************************\n");
	           $display ("   The frequency of the incoming REF clock is too fast!  \n");
	           $display ("   The frequency is above 133MHz.                        \n");
	           $display ("   The PLL is operating out of spec, therefore the       \n");
	           $display ("   current simulation results may not be accurate!       \n");
	           $display ("\n");
	           $display ("   Please check the REF input signal, and rerun the      \n");
	           $display ("   simulation.                                           \n");
	           $display ("\n");
	           $display ("   Simulation time is %t\n", $time);
	           $display ("******************************************************** \n");
	           $display ("\n");
	           rFreq_high_flag <= 1'b1;
	          end
	      end

	//check to make sure RESET is initialized at some point, warn user if not
	if ( (nb_ref_cycles == 100) && (reset_init == 1'b0) )
	    begin
		$display ("\n");
		$display ("**********************Attention********************** \n");
		$display ("   The verilog model has not been initialized yet!    \n");
		$display (" Neither the RESET nor BYPASS pin has been asserted.  \n");
		$display ("       Please check the RESET and BYPASS pins.        \n");
		$display ("\n");
		$display ("  The PLL verilog model will not produce an output    \n");
		$display ("  signal until RESET is asserted and de-asserted, or  \n");
		$display ("                 BYPASS is asserted!                  \n");
		$display ("\n");
		$display ("   Simulation time is %t\n", $time);
		$display ("***************************************************** \n");
		$display ("\n");
	    end
    end	

//
// Track minimum positive pulse width
//
always @(negedge ref_ck)
    begin
	if (last_posedge_ref !== 0)
	  begin
	    if ( (($time - last_posedge_ref) < `PULSE_MIN ) && !pos_pulse_flag )
	          begin
	           $display ("\n");
	           $display ("************************Attention************************\n");
	           $display ("   The positive pulse of the incoming REF clock is too   \n");
	           $display ("   small!  The minimum acceptable pulse width is 350ps.  \n");
	           $display ("   The PLL verilog model will continue to operate, but   \n");
	           $display ("   the current simulation results may not be accurate!   \n");
	           $display ("\n");
	           $display ("   Please check the REF input signal, and rerun the      \n");
	           $display ("   simulation.                                           \n");
	           $display ("\n");
	           $display ("   Simulation time is %t\n", $time);
	           $display ("******************************************************** \n");
	           $display ("\n");
	           pos_pulse_flag <= 1'b1;
	          end
	  end
	last_negedge_ref <= $time;
    end

//
// RANGE bit functionality check
//  The RANGE bits are analog, but this will give the user
//  a warning if the RANGE bits do not appear to be set
//  appropriately
//
  always @(posedge divided_ref)
    begin
	case({range2i,range1i,range0i})
	  3'b000:  range_byp <= 1'b1;
	  3'b001:  begin
	             range_byp <= 1'b0;
	             if ( (period_divref !== 0) && (range_warn == 1'b0) )
	               begin
	                 if ( (period_divref > 100_000) || (period_divref < 62_500) )
	                   begin //10-16MHz
	           $display ("\n");
	           $display ("************************Attention************************\n");
	           $display ("   The frequency of the Post-divider Reference Clock is  \n");
	           $display ("   out of range! Either the Range bits are not set cor-  \n");
	           $display ("   rectly, or the DIVR divider is not programmed appro-  \n");
	           $display ("   priately. The model will continue to operate, but     \n");
	           $display ("   simulation results may not be accuate!                \n");
	           $display ("\n");
	           $display ("   Please refer to the Analog Bits provided datasheet    \n");
	           $display ("   for information on correctly programming the RANGE    \n");
	           $display ("   pin values.  \n");
	           $display ("\n");
	           $display ("   Simulation time is %t\n", $time);
	           $display ("******************************************************** \n");
	           $display ("\n");
	           range_warn <= 1'b1;
	                   end
	               end
	           end
	  3'b010:  begin
	             range_byp <= 1'b0;
	             if ( (period_divref !== 0) && (range_warn == 1'b0) )
	               begin
	                 if ( (period_divref > 62_500) || (period_divref < 40_000) )
	                   begin //16-25MHz
	           $display ("\n");
	           $display ("************************Attention************************\n");
	           $display ("   The frequency of the Post-divider Reference Clock is  \n");
	           $display ("   out of range! Either the Range bits are not set cor-  \n");
	           $display ("   rectly, or the DIVR divider is not programmed appro-  \n");
	           $display ("   priately. The model will continue to operate, but     \n");
	           $display ("   simulation results may not be accuate!                \n");
	           $display ("\n");
	           $display ("   Please refer to the Analog Bits provided datasheet    \n");
	           $display ("   for information on correctly programming the RANGE    \n");
	           $display ("   pin values.  \n");
	           $display ("\n");
	           $display ("   Simulation time is %t\n", $time);
	           $display ("******************************************************** \n");
	           $display ("\n");
	           range_warn <= 1'b1;
	                   end
	               end
	           end
	  3'b011:  begin
	             range_byp <= 1'b0;
	             if ( (period_divref !== 0) && (range_warn == 1'b0) )
	               begin
	                 if ( (period_divref > 40_000) || (period_divref < 25_000) )
	                   begin //25-40MHz
	           $display ("\n");
	           $display ("************************Attention************************\n");
	           $display ("   The frequency of the Post-divider Reference Clock is  \n");
	           $display ("   out of range! Either the Range bits are not set cor-  \n");
	           $display ("   rectly, or the DIVR divider is not programmed appro-  \n");
	           $display ("   priately. The model will continue to operate, but     \n");
	           $display ("   simulation results may not be accuate!                \n");
	           $display ("\n");
	           $display ("   Please refer to the Analog Bits provided datasheet    \n");
	           $display ("   for information on correctly programming the RANGE    \n");
	           $display ("   pin values.  \n");
	           $display ("\n");
	           $display ("   Simulation time is %t\n", $time);
	           $display ("******************************************************** \n");
	           $display ("\n");
	           range_warn <= 1'b1;
	                   end
	               end
	           end
	  3'b100:  begin
	             range_byp <= 1'b0;
	             if ( (period_divref !== 0) && (range_warn == 1'b0) )
	               begin
	                 if ( (period_divref > 25_000) || (period_divref < 15_380) )
	                   begin //40-65MHz
	           $display ("\n");
	           $display ("************************Attention************************\n");
	           $display ("   The frequency of the Post-divider Reference Clock is  \n");
	           $display ("   out of range! Either the Range bits are not set cor-  \n");
	           $display ("   rectly, or the DIVR divider is not programmed appro-  \n");
	           $display ("   priately. The model will continue to operate, but     \n");
	           $display ("   simulation results may not be accuate!                \n");
	           $display ("\n");
	           $display ("   Please refer to the Analog Bits provided datasheet    \n");
	           $display ("   for information on correctly programming the RANGE    \n");
	           $display ("   pin values.  \n");
	           $display ("\n");
	           $display ("   Simulation time is %t\n", $time);
	           $display ("******************************************************** \n");
	           $display ("\n");
	           range_warn <= 1'b1;
	                   end
	               end
	           end
	  3'b101:  begin
	             range_byp <= 1'b0;
	             if ( (period_divref !== 0) && (range_warn == 1'b0) )
	               begin
	                 if ( (period_divref > 15_390) || (period_divref < 10_000) )
	                   begin //65-100MHz
	           $display ("\n");
	           $display ("************************Attention************************\n");
	           $display ("   The frequency of the Post-divider Reference Clock is  \n");
	           $display ("   out of range! Either the Range bits are not set cor-  \n");
	           $display ("   rectly, or the DIVR divider is not programmed appro-  \n");
	           $display ("   priately. The model will continue to operate, but     \n");
	           $display ("   simulation results may not be accuate!                \n");
	           $display ("\n");
	           $display ("   Please refer to the Analog Bits provided datasheet    \n");
	           $display ("   for information on correctly programming the RANGE    \n");
	           $display ("   pin values.  \n");
	           $display ("\n");
	           $display ("   Simulation time is %t\n", $time);
	           $display ("******************************************************** \n");
	           $display ("\n");
	           range_warn <= 1'b1;
	                   end
	               end
	           end
	  3'b110:  begin
	             range_byp <= 1'b0;
	             if ( (period_divref !== 0) && (range_warn == 1'b0) )
	               begin
	                 if ( (period_divref > 10_000) || (period_divref < 7_500) )
	                   begin //100-133MHz
	           $display ("\n");
	           $display ("************************Attention************************\n");
	           $display ("   The frequency of the Post-divider Reference Clock is  \n");
	           $display ("   out of range! Either the Range bits are not set cor-  \n");
	           $display ("   rectly, or the DIVR divider is not programmed appro-  \n");
	           $display ("   priately. The model will continue to operate, but     \n");
	           $display ("   simulation results may not be accuate!                \n");
	           $display ("\n");
	           $display ("   Please refer to the Analog Bits provided datasheet    \n");
	           $display ("   for information on correctly programming the RANGE    \n");
	           $display ("   pin values.  \n");
	           $display ("\n");
	           $display ("   Simulation time is %t\n", $time);
	           $display ("******************************************************** \n");
	           $display ("\n");
	           range_warn <= 1'b1;
	                   end
	               end
	           end
	  3'b111:  begin
	             range_byp <= 1'b0;
	             if ( (period_divref !== 0) && (range_warn == 1'b0) )
	               begin
	                 if ( period_divref < 7500 )
	                   begin //over 133MHz
	           $display ("\n");
	           $display ("************************Attention************************\n");
	           $display ("   This is not a valid setting for the RANGE bits. The   \n");
	           $display ("   model will continue to operate, but the simulation    \n");
	           $display ("   results may not be accuate!                           \n");
	           $display ("\n");
	           $display ("   Please refer to the Analog Bits provided datasheet    \n");
	           $display ("   for information on correctly programming the RANGE    \n");
	           $display ("   pin values.                                           \n");
	           $display ("\n");
	           $display ("   Simulation time is %t\n", $time);
	           $display ("******************************************************** \n");
	           $display ("\n");
	           range_warn <= 1'b1;
	                   end
	               end
	           end
	endcase
    end

//
// Calculate FB period (external FB mode only)
//	also checks for FB consistency
//
  always @(posedge fbi)
    begin
	if (fsei == 1'b0)
	    begin
	    if (reseti)
		begin
		  fb_count <= 4'b0000;
		  ff_lock <= 1'b0;
		end
	    else
		begin
		  if ( (period_fb2 !== 0) && (period_fb1 !== 0) && (period_fb !== 0) )
			fb_compare = period_fb1_real / period_fb2_real;
		  if ( (period_fb3 !== 0) && (period_fb2 !== 0) && (period_fb1 !== 0) )
			fb_compare1 <= period_fb2_real / period_fb3_real;
		  if ( (period_fb4 !== 0) && (period_fb3 !== 0) && (period_fb2 !== 0) )
			fb_compare2 <= period_fb3_real / period_fb4_real;
		  if (period_fb4 !== 0)
			fb_comp_skip <= period_fb1_real / period_fb4_real;

		  if( ff_lock == 1'b0)
		    //if we havent locked a frequency yet
		    begin
			if ( (fb_compare < 0.99) || (fb_compare > 1.01) )
			//out of acceptable range
			    begin
				fb_count <= 4'b0000;
				ff_lock <= 1'b0;
			    end		
			else				//w-in range, count accordingly
			    begin
				if (fb_count < 6'b1010)
				    begin
					fb_count <= fb_count + 1'b1;
					ff_lock <= 1'b0;
				    end
				else
					if ((period_divfb !==0) && (period_divref !== 0)) ff_lock <=1'b1;
					//lock signal ONLY goes high when we have non-zero number
					//to calculate external divider
			    end
		    end
		  else //ff_lock = 1
		    //we've locked freq, so we want to make sure we dont unlock for unwanted reasons
		    begin
			if ( ((fb_compare < 0.99) || (fb_compare > 1.01)) &&
			    ((fb_compare1 < 0.99) || (fb_compare1 > 1.01)) &&
			    ((fb_compare2 < 0.99) || (fb_compare2 > 1.01)) )
			//if fb_compare is out of spec for 3 cycles,
			//go ahead and unlock
			    begin
				fb_count <= 4'b0000;
				ff_lock <= 1'b0;
			    end
			else if ( ((fb_compare1 < 0.99) || (fb_compare1 > 1.01)) &&
			          ((fb_compare2 < 0.99) || (fb_compare2 > 1.01)) &&
			          ((fb_comp_skip < 0.99) || (fb_comp_skip > 1.01)) )
			    begin
				fb_count <= 6'b0000;
				ff_lock <= 1'b0;
			    end
		    end
		end
	    end

	if (last_posedge_fb !== 0 && !bypassi) 
	    begin
		period_fb <= $time - last_posedge_fb;
		period_fb_real <=  $time - last_posedge_fb;
		nb_fb_cycles <= nb_fb_cycles +1;
	    end

	last_posedge_fb <= $time;

    //To detect any change in FB period:
	if (period_fb3 !== 0)
	    begin
		period_fb4 <= period_fb3;
		period_fb4_real <= period_fb3_real;
	    end
	if (period_fb2 !== 0)
	    begin
		period_fb3 <= period_fb2;
		period_fb3_real <= period_fb2_real;
	    end
	if (period_fb1 !== 0)
	    begin
		period_fb2 <= period_fb1;
		period_fb2_real <= period_fb1_real;
	    end
	if (period_fb !== 0)
	    begin
		period_fb1 <= period_fb;
		period_fb1_real <= period_fb_real;
	    end

//For external FB, drive divided_fb
	if ( (divider_divf > 1) && (fsei == 0) ) begin
	if ((divf_count == 0) && !bypassi && !reseti)
	    begin
		divided_fb <= 1'b1;
		divf_count <= divider_divf - 1;
	    end
	if ((divf_count !== 0) && !bypassi && !reseti) 
	    begin
		divided_fb <= 1'b0;
		divf_count <= divf_count - 1;
	    end
	if (bypassi || reseti) 
	    begin
		divided_fb <= 1'b0;
		divf_count <= 0;
	    end
	end

    end

//
//For external FB, drive divided_fb
//
always@(fbi)
    begin
	if ((divider_divf == 1) && (fsei == 0))
		divided_fb <= fbi;
    end


//
//Calculate FB and REF periods post-dividers
//
always@(posedge divided_fb)
    begin
	if (last_posedge_divfb !== 0) 
	    begin
		period_divfb <= $time - last_posedge_divfb;
		period_divfb_real <=  $time - last_posedge_divfb;
	    end
	last_posedge_divfb <= $time;
    end

always@(posedge divided_ref)
    begin
	if (last_posedge_divref !== 0) 
	    begin
		period_divref <= $time - last_posedge_divref;
		period_divref_real <=  $time - last_posedge_divref;
	    end
	//error checking: to see if frequency of
	//divided_ref is out of spec
	if (period_divref !== 0)
	  begin
	    if ( (period_divref > `MIN_DREF_FREQ) && !drFreq_low_flag )
	      begin
	       $display ("\n");
	       $display ("************************Attention************************\n");
	       $display ("   The frequency of the divided REF clock is too slow!   \n");
	       $display ("   The frequency is below 10MHz.                         \n");
	       $display ("   The PLL is operating out of spec, therefore the       \n");
	       $display ("   current simulation results may not be accurate!       \n");
	       $display ("\n");
	       $display ("   This is likely due to either the setting of DIVR, or  \n");
	       $display ("   the frequency of REF.  Please check these values and  \n");
	       $display ("   rerun the simulation.                                 \n");
	       $display ("\n");
	       $display ("   Simulation time is %t\n", $time);
	       $display ("******************************************************** \n");
	       $display ("\n");
	       drFreq_low_flag <= 1'b1;
	      end
	    if ( (period_divref < `MAX_DREF_FREQ) && !drFreq_high_flag )
	      begin
	       $display ("\n");
	       $display ("************************Attention************************\n");
	       $display ("   The frequency of the divided REF clock is too fast!   \n");
	       $display ("   The frequency is above 133MHz.                        \n");
	       $display ("   The PLL is operating out of spec, therefore the       \n");
	       $display ("   current simulation results may not be accurate!       \n");
	       $display ("\n");
	       $display ("   This is likely due to either the setting of DIVR, or  \n");
	       $display ("   the frequency of REF.  Please check these values and  \n");
	       $display ("   rerun the simulation.                                 \n");
	       $display ("\n");
	       $display ("   Simulation time is %t\n", $time);
	       $display ("******************************************************** \n");
	       $display ("\n");
	       drFreq_high_flag <= 1'b1;
	      end
	  end
	last_posedge_divref <= $time;
    end

//
// Check for any external dividers/multipliers 
//
always @(posedge ff_lock)
    begin
	if (reseti)
		divider_external = 1;
	else
	begin
	 if (fsei == 1'b0)
	   begin
		if ((period_divref !== 0) && (period_divfb !==0))
		 begin
		     if ( ((period_divfb_real / period_divref_real) < 0.99 ) || ((period_divfb_real / period_divref_real) > 1.01 ) )
			divider_external = ( (period_divfb_real / period_divref_real) );
		 end
	   end
	end
    end

//
// Drive REF and FB after dividers
always
    begin
	if(on_wire)
	    begin
		divided_ref <= 1'b1;
		#high_time_divref;
		divided_ref <= 1'b0;
		#low_time_divref;
		nb_divref_cycles <= nb_divref_cycles + 1;
		// for bypass on same positive edge
		if (bypassi) last_posedge_divref <= 0;
		//Correction
			if ((nb_divref_cycles % (mult_divr_dly) == 0) && (low_time_divref !== 0) && (high_time_divref !== 0))
			    begin
				correction_ref = (period_ref * mult_divr_dly) - ((low_time_divref + high_time_divref));
				if (correction_ref > 0) #correction_ref;
			    end
	    end
	else
	    begin
		divided_ref <= 1'b0;
		wait (on_wire);
	    end
    end

//
//Get post-divider measurements for LOCK
//
always @(posedge divided_ref or posedge divided_fb)
    begin
	if ((period_divref) != 0)
		inner_freq_margin <= ((period_divfb_real)/(period_divref_real));
	else
		inner_freq_margin <= 0;
    end

always @(posedge ref_ck)
    begin
	if (!on_wire)	//resetting
	    begin
		lock_count_reg <= 4'b0000;
		lock_enabled_flag <= 1'b0;
	    end
	else if ((fsei == 1'b0) && (phase_adjust == 1'b0))
	    begin
		if ( ((inner_freq_margin >= 0.99) || (inner_freq_margin <= 1.01)) && (lock_count_reg == 4'b1010) )
		    begin
			//count remains at 10
			lock_enabled_flag <= 1'b1;
		    end
		if ( ((inner_freq_margin >= 0.99) || (inner_freq_margin <= 1.01)) && (lock_count_reg < 4'b1010) )
		    begin
			lock_count_reg <= lock_count_reg + 4'b0001;	//count increments
			lock_enabled_flag <= 1'b0;
		    end
		if ( ((inner_freq_margin < 0.99) || (inner_freq_margin > 1.01)) )	//out of range
		    begin
			lock_count_reg <= 4'b0000;			//count resets to zero
			lock_enabled_flag <= 1'b0;
		    end
	    end
	else if ((fsei == 1'b0) && (phase_adjust == 1'b1))
		    begin
			//remain locked, let phase adjust take effect
			lock_enabled_flag <= 1'b1;
		    end

	else if (fsei == 1'b1)
	    begin
		if (nb_ref_cycles > 2)
			lock_enabled_flag <= 1'b1;
	    end
    end

//
// Drive LOCK
//

always @ (lock_enabled_flag or on_flag)
    begin
	if (on_flag && lock_enabled_flag && reset_init)
		//if not in reset
		pll_lock_reg <= 1'b1;
	else
		//either reset, or not locked
		pll_lock_reg <= 1'b0;
    end


//
// Drive vco_ck
//
always
    begin
	if (on_vco)
	    begin
		vco_ck <= 1'b1;
		if(high_time_vco > (low_time_vco*3/2)) #low_time_vco;
		else #high_time_vco;

		vco_ck <= 1'b0;
		#low_time_vco;
		nb_vco_cycles <= nb_vco_cycles + 1;
		if (bypassi) last_posedge_vco <= 0;
	    end
	else
	    begin
		vco_ck <= 1'b0;
		wait (on_vco);
	    end
    end

//
//  Check frequency of VCO and flag any errors
//  (warning message will display, but simulation will not stop)
always @(posedge vco_ck)
    begin
	if (last_posedge_vco !== 0) 
	  begin
	    period_vco <= $time - last_posedge_vco;
	    if (period_vco !== 0)
	      begin
	        if ( (period_vco > `MIN_VCO_FREQ) && !vco_low_flag && locki )
	          begin
	           $display ("\n");
	           $display ("************************Attention************************\n");
	           $display ("           The frequency of the VCO is too slow!         \n");
	           $display ("   The output frequencies may appear to be within spec,  \n");
	           $display ("   but the VCO frequency is below 266MHz.  The PLL is    \n");
	           $display ("   operating out of spec, therefore the current simula-  \n");
	           $display ("   tion results may not be accurate!                     \n");
	           $display ("\n");
	           $display ("   This is likely due to the setting of the dividers,    \n");
	           $display ("   or the frequency of REF.  Please check these values   \n");
	           $display ("   and rerun the simulation.                             \n");
	           $display ("\n");
	           $display ("   Simulation time is %t\n", $time);
	           $display ("******************************************************** \n");
	           $display ("\n");
	           vco_low_flag <= 1'b1;
	          end
	        if ( (period_vco < `MAX_VCO_FREQ) && !vco_high_flag && locki )
	          begin
	           $display ("\n");
	           $display ("************************Attention************************\n");
	           $display ("           The frequency of the VCO is too fast!         \n");
	           $display ("   The output frequencies may appear to be within spec,  \n");
	           $display ("   but the VCO frequency is above 533MHz.  The PLL is    \n");
	           $display ("   operating out of spec, therefore the current simula-  \n");
	           $display ("   tion results may not be accurate!                     \n");
	           $display ("\n");
	           $display ("   This is likely due to the setting of the dividers,    \n");
	           $display ("   or the frequency of REF.  Please check these values   \n");
	           $display ("   and rerun the simulation.                             \n");
	           $display ("\n");
	           $display ("   Simulation time is %t\n", $time);
	           $display ("******************************************************** \n");
	           $display ("\n");
	           vco_high_flag <= 1'b1;
	          end
	      end
	  end
	last_posedge_vco <= $time;
    end

//
// Drive PLLOUT
// + Correction
//
always
    begin
	if (on_wire)
	    begin
		pllout_ck <= 1'b1;
		if(high_time_pllout > (low_time_pllout*3/2)) #low_time_pllout;
		else #high_time_pllout;

		pllout_ck <= 1'b0;
		#low_time_pllout;
		nb_pllout_cycles <= nb_pllout_cycles + 1;
		if (bypassi) last_posedge_out <= 0;
	// Correction factor for external path - phase adjustment
		if (fsei == 1'b0)
		    begin
			if ((nb_pllout_cycles % (divider_external_dly*divider_divf_dly) == 0) && (low_time_pllout !== 0) && (high_time_pllout !== 0))
			    begin
				correction = (period_ref * mult_divr_dly) - ((low_time_pllout + high_time_pllout) * (divider_external_dly * divider_divf_dly));
				if (correction > 0) #correction;
				if (pll_lock_reg === 1'b1)
				  begin
				  //Additional, FOR PHASE CORRECTION
				  if (last_posedge_divfb > last_posedge_divref) 
				      correction_ph = ( period_divfb - (last_posedge_divfb-last_posedge_divref) );
				  if (last_posedge_divref > last_posedge_divfb) 
				      correction_ph = ( last_posedge_divref - last_posedge_divfb );
				  if (last_posedge_divref == last_posedge_divfb) 
				    begin
				      correction_ph = 0;
				      phase_adjust <= 1'b0;
				      phase_lock <= 1'b1;
				    end
				  if ( (correction_ph > 0) && phase_adjust == 1'b0) //dont want to repeat phase adjust before previous has taken effect
				    begin
				      #correction_ph;
				      phase_adjust <= 1'b1;
				      if (correction_ph > (period_ref * 0.1)) phase_lock <= 1'b0;
				      // large enough to unlock, have to correct and relock
				    end
				  end
			    end
		    end
		else //fsei == 1'b1
		    begin
			if ((nb_pllout_cycles % (mult_divq_dly * divider_divf_dly) == 0) && (low_time_pllout !== 0) && (high_time_pllout !== 0))
			    begin
				correction = (period_ref * mult_divr_dly * mult_divq_dly) - ((low_time_pllout + high_time_pllout) * (divider_divf_dly));
				if (correction > 0) #correction;
			    end
		    end
	    end
	else
	    begin
		pllout_ck <= 1'b0;
		wait (on_wire);
	    end
    end

//
// Check frequency of PLL output and flag any errors
//  (warning message will display, but simulation will not stop)
always@(posedge pllouti)
	//using pllouti instead of pllout_ck - measurement taken at actual point
    begin
	if (last_posedge_out !== 0) 
	  begin
	    period_out <= $time - last_posedge_out;
	    if (period_out !== 0)
	      begin
 	        if ( (period_out > `MIN_OUT_FREQ) && !oFreq_low_flag && locki )
	          begin
	           $display ("\n");
	           $display ("************************Attention************************\n");
	           $display ("   The output frequency of the PLL is too slow!          \n");
	           $display ("   The frequency on the output is below 10MHz. The PLL   \n");
	           $display ("   is operating out of spec, therefore the current simu- \n");
	           $display ("   lation results may not be accurate!                   \n");
	           $display ("\n");
	           $display ("   This is likely due to the setting of the DIVR, DIVF,  \n");
	           $display ("   DIVQ, or the frequency of REF.  Please check these    \n");
	           $display ("   values and rerun the simulation.                      \n");
	           $display ("\n");
	           $display ("   Simulation time is %t\n", $time);
	           $display ("*********************************************************\n");
	           $display ("\n");
	           oFreq_low_flag <= 1'b1;
	          end

	        if ( (period_out < `MAX_OUT_FREQ) && !oFreq_high_flag && locki )
	          begin
	           $display ("\n");
	           $display ("************************Attention************************\n");
	           $display ("   The output frequency of the PLL is too fast!          \n");
	           $display ("   The frequency on the output is above 533MHz. The PLL  \n");
	           $display ("   is operating out of spec, therefore the current simu- \n");
	           $display ("   lation results may not be accurate!                   \n");
	           $display ("\n");
	           $display ("   This is likely due to the setting of the DIVR, DIVF,  \n");
	           $display ("   DIVQ, or the frequency of REF.  Please check these    \n");
	           $display ("   values and rerun the simulation.                      \n");
	           $display ("\n");
	           $display ("   Simulation time is %t\n", $time);
	           $display ("*********************************************************\n");
	           $display ("\n");
	           oFreq_high_flag <= 1'b1;
	          end
	      end
	  end
	last_posedge_out <= $time;
    end

//
// Check for REF period consistency
//   Internal variables are reset when REF period changes
//   Error checking - PLLOUT frequency is within spec
always@(pllout_ck)
    begin
	if ( (period_ref1 !== 0) && (period_ref2 !== 0) && (period_ref !== 0) && 
		((period_ref1 !== period_ref) || (period_ref !== period_ref2) || (period_ref1 !== period_ref2)) )
	ref_freq_chg <= 1'b1;
    end

//
// Reset warning flags if necessary
//
always @(negedge lock_enabled_flag)
    begin
	vco_low_flag <= 1'b0;
	vco_high_flag <= 1'b0;
	rFreq_low_flag <= 1'b0;
	rFreq_high_flag <= 1'b0;
	drFreq_low_flag <= 1'b0;
	drFreq_high_flag <= 1'b0;
	oFreq_low_flag <= 1'b0;
	oFreq_high_flag <= 1'b0;
	pos_pulse_flag <= 1'b0;
	neg_pulse_flag <= 1'b0;
	phase_adjust <= 1'b0;
    end

//
//Check for changing operating conditions
//	input REF frequency changes
//	any of the dividers change value
//
always@(ref_freq_chg or divr3i or divr2i or divr1i or divr0i or divq2i or divq1i or divq0i or divf5i or divf4i or divf3i or divf2i or divf1i or divf0i)
    begin
	ref_freq_chg <= 1'b0;
	nb_ref_cycles <= 0;
	ff_lock <= 1'b0;
	fb_count <= 4'b0000;
	lock_count_reg <= 4'b0000;
	vco_low_flag <= 1'b0;
	vco_high_flag <= 1'b0;
	rFreq_low_flag <= 1'b0;
	rFreq_high_flag <= 1'b0;
	drFreq_low_flag <= 1'b0;
	drFreq_high_flag <= 1'b0;
	oFreq_low_flag <= 1'b0;
	oFreq_high_flag <= 1'b0;
	pos_pulse_flag <= 1'b0;
	neg_pulse_flag <= 1'b0;
	range_warn <= 1'b0;
	lock_enabled_flag <= 1'b0;
	last_posedge_divfb <= 0;
	period_divfb <= 0;
	last_posedge_divref <= 0;
	period_divref <= 0;
	divider_external <= 1;
	phase_lock <= 1'b0;
    end

//
// Reset RANGE warning flags to run RANGE checks again
//
always @(range2i or range1i or range0i or posedge ref_freq_chg)
    begin
	range_warn <= 1'b0;
	if ({range2i,range1i,range0i} === 3'b000)
	    range_byp <= 1'b1;
	    else range_byp <= 1'b0;
    end


//
// VCO turns off with RESET, BYPASS, or change in fsei
//
always@(posedge reseti or posedge bypassi or fsei)
    begin
	ref_freq_chg <= 1'b0;
	on_vco <= 1'b0;
	on_flag <= 1'b0;
	ff_lock <= 1'b0;
	fb_count <= 4'b0000;
	vco_low_flag <= 1'b0;
	vco_high_flag <= 1'b0;
	rFreq_low_flag <= 1'b0;
	rFreq_high_flag <= 1'b0;
	drFreq_low_flag <= 1'b0;
	drFreq_high_flag <= 1'b0;
	oFreq_low_flag <= 1'b0;
	oFreq_high_flag <= 1'b0;
	pos_pulse_flag <= 1'b0;
	neg_pulse_flag <= 1'b0;
	range_warn <= 1'b0;
	lock_enabled_flag <= 1'b0;
	last_posedge_ref <= 0;
	last_negedge_ref <= 0;
	period_ref <= 0;
	period_ref1 <= 0;
	period_ref2 <= 0;
	last_posedge_fb <= 0;
	period_fb <= 0;
	period_fb1 <= 0;
	period_fb2 <= 0;
	period_fb3 <= 0;
	period_fb4 <= 0;
	last_posedge_divfb <= 0;
	period_divfb <= 0;
	last_posedge_divref <= 0;
	period_divref <= 0;
	last_posedge_vco <= 0;
	period_vco <= 0;
	low_time_vco <= 0;
	high_time_vco <= 0;
	last_posedge_out <= 0;
	period_out <= 0;
	low_time_pllout <= 0;
	high_time_pllout <= 0;
	correction <= 0;
	correction_ph <= 0;
	low_time_divref <= 0;
	high_time_divref <= 0;
	correction_ref <= 0;
	period_ref_real <= 0;
	period_fb_real <= 0;
	period_divref_real <= 0;
	period_divfb_real <= 0;
	inner_freq_margin <=0;
	period_fb1_real <= 0;
	period_fb2_real <= 0;
	period_fb3_real <= 0;
	period_fb4_real <= 0;
	fb_comp_skip <= 0;
	divider_external <= 1;
	nb_ref_cycles <= 0;
	nb_fb_cycles <= 0;
	nb_pllout_cycles <= 0;
	nb_divref_cycles <= 0;
	nb_divfb_cycles <= 0;
	phase_lock <= 1'b0;
    end

endmodule // ABIPTBS8
