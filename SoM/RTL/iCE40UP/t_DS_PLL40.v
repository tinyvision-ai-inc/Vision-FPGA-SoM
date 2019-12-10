`timescale 1ps/1ps 
module t_DS_PLL40 (
		PACKAGEPIN,		//Driven by IO clock
		CORE_REF_CLK,	//Driven by core logic
		EXTFEEDBACK,
		DYNAMICDELAY,
		BYPASS,	
		RESETB,		
		
		PLL_SCK,
		PLL_SDI,
		PLL_SDO,
		
		PLLOUT1,		
		PLLOUT2,		
		LOCK   		
);

//----------------------------------------------------------------------
// Port Declarations
//----------------------------------------------------------------------

// Inputs

input PACKAGEPIN;		//Driven by IO clock
input CORE_REF_CLK;		//Driven by core logic
input	EXTFEEDBACK;  
input	[7:0] DYNAMICDELAY;  
input	BYPASS;				
input	RESETB;			

input	PLL_SCK;			
input	PLL_SDI;			
// Outputs
output 	PLLOUT1, PLLOUT2;	
output	LOCK;				//Output of PLL
output	PLL_SDO;			

//----------------------------------------------------------------------
// ALL the parameter definitions here are just for STA timing analysis presume user will use those settings in the shift registers
//----------------------------------------------------------------------
//Parameters 
parameter FEEDBACK_PATH = "SIMPLE";		//String  (simple, delay, phase_and_delay, external) 
parameter DELAY_ADJUSTMENT_MODE_FEEDBACK = "FIXED"; 
parameter DELAY_ADJUSTMENT_MODE_RELATIVE = "FIXED"; 
parameter SHIFTREG_DIV_MODE = 2'b00; 		//00-->Divide by 4, 01-->Divide by 7 , 10 --> invalid , 11 --> Divide by 5 (HDMI).
//parameter SHIFTREG_DIV_MODE = 1'b0; 		//0-->Divide by 4, 1-->Divide by 7.
parameter FDA_FEEDBACK = 4'b0000; 		//Integer. 
//Output 
parameter FDA_RELATIVE = 4'b0000; 		//Integer. 
parameter PLLOUT_SELECT_PORTA = "GENCLK"; 	//
parameter PLLOUT_SELECT_PORTB = "GENCLK"; 	//
//Use the Spreadsheet to populate the values below.
parameter DIVR = 4'b0000; 			//determine a good default value
parameter DIVF = 7'b0000000; 			//determine a good default value
parameter DIVQ = 3'b000; 			//determine a good default value
parameter FILTER_RANGE = 3'b000; 		//determine a good default value
parameter ENABLE_ICEGATE_PORTA = 1'b0;		//Additional cbits 
parameter ENABLE_ICEGATE_PORTB = 1'b0; 
parameter TEST_MODE = 1'b1;			//Test Mode parameter, the TEST_MODE has to be set to "1" for PLL dynamic setting 

wire  [26:0] PLLCFG_SREG;
wire FSEnet = PLLCFG_SREG[25];
wire FBnet;
wire finedelayFBin, finedelayFBout;
// change for shift register dynamic PLL setting 
wire [6:0] DIVFBus = PLLCFG_SREG[10:4];		//DIVF; 
wire [3:0] DIVRBus = PLLCFG_SREG[3:0];		//DIVR; 
wire [2:0] DIVQBus = PLLCFG_SREG[13:11];	//DIVQ; 
wire [2:0] RANGEBus = PLLCFG_SREG[16:14];	//FILTER_RANGE; 
wire ABPLLOUT;
wire [1:0] pllout1Sel = PLLCFG_SREG[24:23];
wire [1:0] pllout2Sel = PLLCFG_SREG[20:19];
wire [1:0] shiftregister_div_mode_sel;		//SHIFTREG_DIV_MODE
// change for shift register dynamic PLL setting 
wire [1:0] delaymuxsel = PLLCFG_SREG[18:17];
reg ABPLLOUTDiv2;
wire REFERENCECLK;		

assign shiftregister_div_mode_sel =	{PLLCFG_SREG[26],PLLCFG_SREG[21]};	
assign FBnet = (FSEnet) ? 1'b0 : finedelayFBout;
assign PLL_SDO = PLLCFG_SREG[26];
assign REFERENCECLK = (PLLCFG_SREG[22]) ? CORE_REF_CLK : PACKAGEPIN;
//reg fbout;

reg [4:0] DS_POSCLK_COUNTER, DS_NEGCLK_COUNTER;
wire DS_NEGCLK_COUNTER_CLEAR;

initial
begin
	DS_POSCLK_COUNTER <=5'd27;
	DS_NEGCLK_COUNTER <=5'd27;
end

always @(negedge RESETB) 
begin
	DS_POSCLK_COUNTER <=5'd27;
	DS_NEGCLK_COUNTER <=5'd27;
end

always @(posedge PLL_SCK) 
begin
	if (DS_POSCLK_COUNTER == 5'b0)
	begin
        $display ("************************SBT : PLL_DS ERROR ****************************");
        $display ("Once the 27 cycles are completed, SCLK needs to stop.");
        $display ("****************************************************************");
        $finish;
	end
	else DS_POSCLK_COUNTER <= DS_POSCLK_COUNTER - 5'd1;
end

always @(negedge PLL_SCK) 
begin
	if (DS_NEGCLK_COUNTER == 5'b0)
	begin
        $display ("************************SBT : PLL_DS ERROR ****************************");
        $display ("Once the 27 cycles are completed, SCLK needs to stop.");
        $display ("****************************************************************");
        $finish;
	end
	else DS_NEGCLK_COUNTER <= DS_NEGCLK_COUNTER - 5'd1;
end

assign DS_NEGCLK_COUNTER_CLEAR = (DS_NEGCLK_COUNTER[4:0] == 5'b0);

always @(posedge PLL_SCK or negedge PLL_SCK) 
	if (RESETB == 0)
	begin
        $display ("************************SBT : PLL_DS ERROR ****************************");
        $display ("PLL RESETB needs to be held low while the data is shifted into the register by PLL_SCK clock.");
        $display ("****************************************************************");
        $finish;
	end

always @(posedge RESETB) 
	if ((DS_POSCLK_COUNTER != 5'b0) | (DS_NEGCLK_COUNTER != 5'b0))
	begin
        $display ("************************SBT : PLL_DS ERROR ****************************");
        $display ("Exactly 27 full clock cycles are needed to shift SDI data into the register.");
        $display ("****************************************************************");
        $finish;
	end

always @(posedge DS_NEGCLK_COUNTER_CLEAR) 
	begin
		# 10;
		if (RESETB == 1)
		begin
			$display ("************************SBT : PLL_DS ERROR ****************************");
			$display ("Release RESETB greater than 10ns once SCLK is stopped.");
			$display ("****************************************************************");
			$finish;
		end
	end

	
initial
begin
  ABPLLOUTDiv2 = 1'b0;
end

always @ (posedge ABPLLOUT)
	ABPLLOUTDiv2 = ~ABPLLOUTDiv2;


pllcfg_dynamicsetting_shiftreg instPLLCFG_DS_SReg(
		.pll_sck(PLL_SCK),
		.pll_sdi(PLL_SDI), 
		.q(PLLCFG_SREG)
		);

//shiftregister_div_mode_sel
//		00-->Divide by 4, 01-->Divide by 7 , 10 --> invalid , 11 --> Divide by 5 (HDMI).
ShiftReg427_DS instShftReg427 (
		.clk (ABPLLOUT),
		.init (RESETB),
		.phase0 (phase0net),
		.phase90 (phase90net),
		.shiftregister_div_mode_sel(shiftregister_div_mode_sel)
		);

mux4to1 instFBDlyAdjInMux (
		.a (ABPLLOUT),
		.b (phase0net),
		.c (phase0net),
		.d (EXTFEEDBACK),
		.select (delaymuxsel[1:0]),
		.o (finedelayFBin)
		);


mux4to1 instPLLOUT2SelMux (
		.a (phase0net),
		.b (phase90net),
		.d(ABPLLOUT),
		.c (ABPLLOUTDiv2),
		.select (pllout2Sel[1:0]),
		.o (pllout2Muxnet)
		);
assign PLLOUT2 = (BYPASS == 1'b1) ? REFERENCECLK : pllout2Muxnet;

mux4to1 instPLLOUT1SelMux (
		.a (phase0net),
		.b (phase90net),
		.d (ABPLLOUT),
		.c (ABPLLOUTDiv2),
		.select (pllout1Sel[1:0]),
		.o (pllout1Muxnet)
		);
assign fdaRelInput = (BYPASS == 1'b1) ? REFERENCECLK : pllout1Muxnet;


FineDlyAdj instFineDlyAdjFB (
		.DlyAdj (DYNAMICDELAY[3:0]),
		.signalin (finedelayFBin),
		.delayedout (finedelayFBout)
		);
defparam instFineDlyAdjFB.FIXED_DELAY_ADJUSTMENT = FDA_FEEDBACK;
defparam instFineDlyAdjFB.DELAY_ADJUSTMENT_MODE = DELAY_ADJUSTMENT_MODE_FEEDBACK;

FineDlyAdj instFineDlyAdjRel (
		.DlyAdj (DYNAMICDELAY[7:4]),
		.signalin (fdaRelInput),
		.delayedout (PLLOUT1)
		);
defparam instFineDlyAdjRel.FIXED_DELAY_ADJUSTMENT = FDA_RELATIVE;
defparam instFineDlyAdjRel.DELAY_ADJUSTMENT_MODE = DELAY_ADJUSTMENT_MODE_RELATIVE;


ABIWTCZ4 instABitsPLL (
		.REF (REFERENCECLK),
		.FB (FBnet),
		.FSE (FSEnet),
		.BYPASS (BYPASS),
		.RESET (RESETB),
		.DIVF6 (DIVFBus[6]),
		.DIVF5 (DIVFBus[5]),
		.DIVF4 (DIVFBus[4]),
		.DIVF3 (DIVFBus[3]),
		.DIVF2 (DIVFBus[2]),
		.DIVF1 (DIVFBus[1]),
		.DIVF0 (DIVFBus[0]),
		.DIVQ2 (DIVQBus[2]),
		.DIVQ1 (DIVQBus[1]),
		.DIVQ0 (DIVQBus[0]),
		.DIVR3 (DIVRBus[3]),
		.DIVR2 (DIVRBus[2]),
		.DIVR1 (DIVRBus[1]),
		.DIVR0 (DIVRBus[0]),
		.RANGE2 (RANGEBus[2]),
		.RANGE1 (RANGEBus[1]),
		.RANGE0 (RANGEBus[0]),
		.LOCK (LOCK),
		.PLLOUT (ABPLLOUT)
		);

endmodule //Sbt_DS_PLL
