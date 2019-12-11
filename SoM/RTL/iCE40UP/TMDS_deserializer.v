`timescale 1ps/1ps
module TMDS_deserializer(
                                //TMDS input interface
  input TMDSch0p,             //TMDS ch 0 differential input pos
  input TMDSch0n,             //TMDS ch 0 differential input neg
  input TMDSch1p,             //TMDS ch 1 differential input pos
  input TMDSch1n,             //TMDS ch 1 differential input neg
  input TMDSch2p,             //TMDS ch 2 differential input pos
  input TMDSch2n,             //TMDS ch 2 differential input neg
  input TMDSclkp,             //TMDS clock differential input pos
  input TMDSclkn,             //TMDS clock differential input neg
                                
                                //Receive controller interface
  input RSTNdeser,             //Reset deserailzier logics- active low
  input RSTNpll,               //Reset deserializer PLL- active low
  input EN,                     //Enable deserializer- active high
  input [3:0] PHASELch0,       //Clock phase delay compensation select for ch 0
  input [3:0] PHASELch1,       //Clock phase delay compensation select for ch 1
  input [3:0] PHASELch2,       //Clock phase delay compensation select for ch 2
  output PLLlock,              //PLL lock signal- active high
  output PLLOUTGLOBALclkx1,    //PLL output on global n/w 
  output PLLOUTCOREclkx1,    	//PLL output on global n/w 
  output PLLOUTGLOBALclkx5,    //PLL output on global n/w 
  output PLLOUTCOREclkx5,    	//PLL output on global n/w
  output [9:0] RAWDATAch0,     //Recovered ch 0 10-bit data 
  output [9:0] RAWDATAch1,     //Recovered ch 1 10-bit data
  output [9:0] RAWDATAch2,      //Recovered ch 2 10-bit data
  input	EXTFEEDBACK,  			//Driven by core logic. Not required HDMI mode.
  input	[7:0] DYNAMICDELAY,  	//Driven by core logic. Not required for HDMI mode.
  input	BYPASS,				//Driven by core logic. Not required for HDMI mode.
  input	LATCHINPUTVALUE, 	//iCEGate signal. Not required for HDMI mode
//Test Pins
  output	SDO,				//Output of PLL
  input	SDI,				//Driven by core logic
  input	SCLK				//Driven by core logic
  );

parameter FEEDBACK_PATH = "PHASE_AND_DELAY";	
parameter DELAY_ADJUSTMENT_MODE_FEEDBACK = "FIXED"; 
parameter DELAY_ADJUSTMENT_MODE_RELATIVE = "FIXED"; 
parameter SHIFTREG_DIV_MODE = 2'b11; 	//Divide by 5.
parameter FDA_FEEDBACK = 4'b0000; 		//Integer 
parameter FDA_RELATIVE = 4'b0000; 		//Integer 
parameter PLLOUT_SELECT_PORTA = "GENCLK"; // Clkx5
parameter PLLOUT_SELECT_PORTB = "SHIFTREG_0deg"; // Clkx1

//Frequency Parameters: Current defaults are for TMDS Clk = 30-40MHz
parameter DIVR = 4'b0000; 	
parameter DIVF = 7'b0000000; 		// 7'b0000100; 
parameter DIVQ = 3'b010; 	
parameter FILTER_RANGE = 3'b011; 	

//Additional cbits
parameter ENABLE_ICEGATE_PORTA = 1'b0;
parameter ENABLE_ICEGATE_PORTB = 1'b0;

//Test Mode parameter
parameter TEST_MODE = 1'b0;
parameter EXTERNAL_DIVIDE_FACTOR = 1; //Not used by model. Added for PLL Config GUI.


    	wire clk1xout_global, clk5xout_global;  
    	wire clk1xout_core, clk5xout_core; 
  
  	wire ch0_clk5xin; 
  	wire ch1_clk5xin; 
  	wire ch2_clk5xin; 					
  
  PLL40_2F_PAD_DS  dviphyPLL_i (
		.PACKAGEPIN(TMDSclkp),		
		.PACKAGEPINB(TMDSclkn),		
		.PLLOUTCOREA(clk5xout_core),		
		.PLLOUTGLOBALA(clk5xout_global),	
       		.PLLOUTCOREB(clk1xout_core),	
		.PLLOUTGLOBALB(clk1xout_global),	
		.EXTFEEDBACK(),  		
		.DYNAMICDELAY(),	
		.LOCK(PLLlock),			
		.BYPASS(1'b0),				
		.RESETB(RSTNpll),				
		.SDI(SDI),				
		.SDO(SDO),				
		.SCLK(SCLK),			
		.LATCHINPUTVALUE(1'b0)
	);

	defparam dviphyPLL_i.FEEDBACK_PATH = FEEDBACK_PATH ;   
	defparam dviphyPLL_i.DELAY_ADJUSTMENT_MODE_FEEDBACK = DELAY_ADJUSTMENT_MODE_FEEDBACK ; 
	defparam dviphyPLL_i.DELAY_ADJUSTMENT_MODE_RELATIVE = DELAY_ADJUSTMENT_MODE_RELATIVE ; 
	defparam dviphyPLL_i.SHIFTREG_DIV_MODE = SHIFTREG_DIV_MODE ; 
	defparam dviphyPLL_i.FDA_FEEDBACK = FDA_FEEDBACK ; 
	defparam dviphyPLL_i.FDA_RELATIVE = FDA_RELATIVE ;  
	defparam dviphyPLL_i.PLLOUT_SELECT_PORTA = PLLOUT_SELECT_PORTA ; 
	defparam dviphyPLL_i.PLLOUT_SELECT_PORTB = PLLOUT_SELECT_PORTB ; 
	defparam dviphyPLL_i.DIVR = DIVR ; 
	defparam dviphyPLL_i.DIVF = DIVF ; 
	defparam dviphyPLL_i.DIVQ = DIVQ ; 
	defparam dviphyPLL_i.FILTER_RANGE  = FILTER_RANGE ; 
	defparam dviphyPLL_i.ENABLE_ICEGATE_PORTA = ENABLE_ICEGATE_PORTA ; 
	defparam dviphyPLL_i.ENABLE_ICEGATE_PORTB = ENABLE_ICEGATE_PORTB ; 
	defparam dviphyPLL_i.TEST_MODE = TEST_MODE ; 
	defparam dviphyPLL_i.EXTERNAL_DIVIDE_FACTOR = EXTERNAL_DIVIDE_FACTOR ; 
	
	
	assign PLLOUTGLOBALclkx1 =  clk1xout_global ;  
	assign PLLOUTCOREclkx1   =  clk1xout_core; 
	assign PLLOUTGLOBALclkx5 =  clk5xout_global; 
	assign PLLOUTCOREclkx5   =  clk5xout_core; 
	
	//  -- channel 0  	
	clkdelay16  clkdelay16_ch0_i (
		.dlyin(clk5xout_global), 
		.dlyout(ch0_clk5xin), 
		.dly_sel(PHASELch0) 
	);
	
	dvi_deserializer deserializer_ch0_i (
		.en(EN),							
		.rstn(RSTNdeser), 	 
		.din(TMDSch0p), 
		.clkx5in(ch0_clk5xin),	
		.clkx1in(TMDSclkp),
		.rawdata(RAWDATAch0) 
	); 
	// -- channel 1 	
	clkdelay16  clkdelay16_ch1_i (
		.dlyin(clk5xout_global), 
		.dlyout(ch1_clk5xin), 
		.dly_sel(PHASELch1) 
	);								
	
	dvi_deserializer deserializer_ch1_i (
		.en(EN),							
		.rstn(RSTNdeser), 	 
		.din(TMDSch1p), 
		.clkx5in(ch1_clk5xin),	
		.clkx1in(TMDSclkp),
		.rawdata(RAWDATAch1) 
	); 
	
	// -- Channel 2 
	clkdelay16  clkdelay16_ch2_i (
		.dlyin(clk5xout_global), 
		.dlyout(ch2_clk5xin), 
		.dly_sel(PHASELch2) 
	);
	
	dvi_deserializer deserializer_ch2_i (
		.en(EN),							
		.rstn(RSTNdeser), 	 
		.din(TMDSch2p), 
		.clkx5in(ch2_clk5xin),	
		.clkx1in(TMDSclkp),
		.rawdata(RAWDATAch2) 
	); 



	
endmodule  
