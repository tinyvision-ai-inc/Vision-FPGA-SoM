`timescale 1ps/1ps
module tSPLL40 (
		REFERENCECLK,
		EXTFEEDBACK,
		DYNAMICDELAY,
		BYPASS,	
		RESETB,		
		
		PLLOUT1,		
		PLLOUT2,		
		LOCK   		
);

//----------------------------------------------------------------------
// Port Declarations
//----------------------------------------------------------------------

// Inputs

input REFERENCECLK;		
input	EXTFEEDBACK;  
input	[7:0] DYNAMICDELAY;  
input	BYPASS;				
input	RESETB;			

// Outputs
output 	PLLOUT1, PLLOUT2;	
output	LOCK;				//Output of PLL

//Feedback
parameter FEEDBACK_PATH = "SIMPLE";	// String  (simple, delay, phase_and_delay, external) 
parameter DELAY_ADJUSTMENT_MODE_FEEDBACK = "FIXED"; 
parameter DELAY_ADJUSTMENT_MODE_RELATIVE = "FIXED"; 
parameter SHIFTREG_DIV_MODE = 2'b00; 	// 00-->Divide by 4, 01-->Divide by 7 , 10 --> invalid , 11 --> Divide by 5 (HDMI).
parameter FDA_FEEDBACK = 4'b0000; 	// Integer. 

//Output 
parameter FDA_RELATIVE = 4'b0000; 		//Integer. 
parameter PLLOUT_SELECT_PORTA = "GENCLK"; 	//
parameter PLLOUT_SELECT_PORTB = "GENCLK"; 	//

//Use the Spreadsheet to populate the values below.
parameter DIVR = 4'b0000; 		//determine a good default value
parameter DIVF = 7'b0000000; 		//determine a good default value
parameter DIVQ = 3'b000; 		//determine a good default value
parameter FILTER_RANGE = 3'b000; 	//determine a good default value


parameter ENABLE_ICEGATE_PORTA = 1'b0;	//Additional cbits
parameter ENABLE_ICEGATE_PORTB = 1'b0;

parameter EXTERNAL_DIVIDE_FACTOR = "NONE";

wire FSEnet;
wire FBnet;
wire finedelayFBin, finedelayFBout;
//wire [5:0] DIVFBus = DIVF; 
wire [6:0] DIVFBus = DIVF; 
wire [3:0] DIVRBus = DIVR; 
wire [2:0] DIVQBus = DIVQ; 
wire [2:0] RANGEBus = FILTER_RANGE; 
wire ABPLLOUT;
reg [1:0] pllout1Sel;
reg [1:0] pllout2Sel;
reg [1:0] delaymuxsel;
reg ABPLLOUTDiv2;

//reg fbout;

initial
begin
  ABPLLOUTDiv2 = 1'b0;
end

always @ (posedge ABPLLOUT)
	ABPLLOUTDiv2 = ~ABPLLOUTDiv2;


initial
begin
 if (PLLOUT_SELECT_PORTA == "SHIFTREG_0deg")
    pllout1Sel = 2'b00;
else if (PLLOUT_SELECT_PORTA == "SHIFTREG_90deg")
    pllout1Sel = 2'b01;
else if (PLLOUT_SELECT_PORTA == "GENCLK_HALF")
    pllout1Sel = 2'b10;
else if (PLLOUT_SELECT_PORTA == "GENCLK")
    pllout1Sel = 2'b11;
else 
   begin
	        $display ("************************SBT : ERROR ****************************");
	        $display ("Parameter PLLOUT_SELECT_PORTA is set to an illegal value.");
	        $display ("Legal values should be one of \"SHIFTREG_0deg\", \"SHIFTREG_90deg\", \"GENCLK_HALF\", \"GENCLK\". ");
	        $display ("Due to incorrect configuration of the PLL, the simulation results are invalid.");
	        $display ("****************************************************************");
	        $finish;
   end
end

initial
begin
 if (PLLOUT_SELECT_PORTB == "SHIFTREG_0deg")
    pllout2Sel = 2'b00;
else if (PLLOUT_SELECT_PORTB == "SHIFTREG_90deg")
    pllout2Sel = 2'b01;
else if (PLLOUT_SELECT_PORTB == "GENCLK_HALF")
    pllout2Sel = 2'b10;
else if (PLLOUT_SELECT_PORTB == "GENCLK")
    pllout2Sel = 2'b11;
else 
   begin
	        $display ("************************SBT : ERROR ****************************");
	        $display ("Parameter PLLOUT_SELECT_PORTB is set to an illegal value.");
	        $display ("Legal values should be one of \"SHIFTREG_0deg\", \"SHIFTREG_90deg\", \"GENCLK_HALF\", \"GENCLK\". ");
	        $display ("Due to incorrect configuration of the PLL, the simulation results are invalid.");
	        $display ("****************************************************************");
	        $finish;
   end
end

assign FSEnet = ((FEEDBACK_PATH == "SIMPLE") && (EXTERNAL_DIVIDE_FACTOR == "NONE")) ? 1'b1 : 1'b0;
assign FBnet = ((FEEDBACK_PATH == "SIMPLE") && (EXTERNAL_DIVIDE_FACTOR == "NONE")) ? 1'b0 : finedelayFBout;


initial
begin

 if (EXTERNAL_DIVIDE_FACTOR == "NONE")
 	begin
	    $display ("************************SBT : Info*****************************");
	    $display ("Note that signal connection to the EXTFEEDBACK port of the PLL must come from INTFBOUT port of PLL.");
	    $display ("***************************************************************");
	   	end
 if (EXTERNAL_DIVIDE_FACTOR != "NONE" )
    begin 
       delaymuxsel = 2'b11;
        if ( (DELAY_ADJUSTMENT_MODE_FEEDBACK != "FIXED") && (DELAY_ADJUSTMENT_MODE_FEEDBACK != "DYNAMIC") )
		begin
	        $display ("************************SBT : ERROR ************************");
	        $display ("Since external feedback is used, DELAY_ADJUSTMENT_MODE_FEEDBACK should be \"FIXED\" or \"DYNAMIC\"");
	        $display ("Due to incorrect configuration of the PLL, the simulation results are invalid.");
	        $display ("***************************************************************");
	        $finish;
		end
		if (PLLOUT_SELECT_PORTA == "SHIFTREG_0deg" || PLLOUT_SELECT_PORTA == "SHIFTREG_90deg"
		    || PLLOUT_SELECT_PORTB == "SHIFTREG_0deg" || PLLOUT_SELECT_PORTB == "SHIFTREG_90deg")  // model divby2 clk, check changed params, compile
		begin
	        $display ("************************ SBT : ERROR **************************");
	        $display ("Since external feedback is used, Phase Adjustment is NOT permitted.");
	        $display ("*************************************************************");
	        $finish;
		end
    end				
 else if (FEEDBACK_PATH == "DELAY")
    begin 
    	delaymuxsel = 2'b00;
        if ( (DELAY_ADJUSTMENT_MODE_FEEDBACK != "FIXED") && (DELAY_ADJUSTMENT_MODE_FEEDBACK != "DYNAMIC") )
		begin
	        $display ("************************ SBT : ERROR **************************");
	        $display ("Since FEEDBACK_PATH=\"DELAY\", DELAY_ADJUSTMENT_MODE_FEEDBACK should be \"FIXED\" or \"DYNAMIC\"");
	        $display ("Due to incorrect configuration of the PLL, the simulation results are invalid.");
	        $display ("***************************************************************");
	        $finish;
		end
		if (PLLOUT_SELECT_PORTA == "SHIFTREG_0deg" || PLLOUT_SELECT_PORTA == "SHIFTREG_90deg"
		    || PLLOUT_SELECT_PORTB == "SHIFTREG_0deg" || PLLOUT_SELECT_PORTB == "SHIFTREG_90deg")  //use PLLOUT_SELECT, model divby2 clk, check changed params, compile
		begin
	        $display ("************************ SBT : ERROR **************************");
	        $display ("Since FEEDBACK_PATH=\"DELAY\", Phase Adjustment is NOT permitted. Please set PLLOUT_SELECT_PORTA/B=\"GENCLK\" or \"GENCLK_HALF\"");
		    $display ("Due to incorrect configuration of the PLL, the simulation results are invalid.");
	        $display ("***************************************************************");
	        $finish;
		end
    end				
 else if (FEEDBACK_PATH == "PHASE_AND_DELAY")
	begin
    	delaymuxsel = 2'b01;
        if ( (DELAY_ADJUSTMENT_MODE_FEEDBACK != "FIXED") && (DELAY_ADJUSTMENT_MODE_FEEDBACK != "DYNAMIC") )
		begin
	        $display ("************************SBT : Attention************************");
	        $display ("Since FEEDBACK_PATH=\"PHASE_AND_DELAY\", DELAY_ADJUSTMENT_MODE_FEEDBACK should be FIXED or DYNAMIC");
	        $display ("***************************************************************");
		end
		if ( (PLLOUT_SELECT_PORTA != "SHIFTREG_0deg") && (PLLOUT_SELECT_PORTA != "SHIFTREG_90deg" )
				&& (PLLOUT_SELECT_PORTB != "SHIFTREG_0deg") && (PLLOUT_SELECT_PORTB != "SHIFTREG_90deg") )
		begin
	        $display ("************************SBT : Attention************************");
	        $display ("FEEDBACK_PATH=\"PHASE_AND_DELAY\", but PLLOUT_SELECT_PORTA/B is not specified correctly");
	        $display ("***************************************************************");
		end
    end				
else if (FEEDBACK_PATH == "SIMPLE")
   begin
		//Ignore DELAY_ADJUSTMENT_MODE_FEEDBACK, FDA_FEEDBACK   
	  $display ("************************SBT : Attention***************************");
	  $display ("Since FEEDBACK_PATH=\"SIMPLE\", the FDA_FEEDBACK value will be ignored");
	  $display ("******************************************************************");


	if (PLLOUT_SELECT_PORTA == "SHIFTREG_0deg" || PLLOUT_SELECT_PORTA == "SHIFTREG_90deg"
		    || PLLOUT_SELECT_PORTB == "SHIFTREG_0deg" || PLLOUT_SELECT_PORTB == "SHIFTREG_90deg")  //use PLLOUT_SELECT, model divby2 clk, check changed params, compile
		begin
	        $display ("************************SBT : Attention***************************");
	        $display ("The PLL output frequency will be divided by 4 or 7 and phase shifted.");
	        $display ("To avoid this, please set PLLOUT_SELECT_PORTA/B = \"GENCLK\" ");
	        $display ("******************************************************************");
		end
	end
 else
 		begin
	        $display ("************************SBT : Attention***************************");
	        $display ("Please set FEEDBACK_PATH to a valid value. Legal settings should be one of \"SIMPLE\", \"DELAY\", \"PHASE_AND_DELAY\"");
	        $display ("******************************************************************");
  end 

	if( SHIFTREG_DIV_MODE == 2'b10) 
		begin
	        $display ("************************ SBT : ERROR **************************");
	        $display ("SHIFTREG_DIV_MODE = 2'b10 is NOT permitted. Please set it 2'b00/2'b01/2'b11");
	        $display ("Due to incorrect configuration of the PLL, the simulation results are invalid.");
	        $display ("***************************************************************");
	        $finish;
		end 
   	
end


ShiftReg427 instShftReg427 (
		.clk (ABPLLOUT),
		.init (RESETB),
		.phase0 (phase0net),
		.phase90 (phase90net)
		);
defparam instShftReg427.SHIFTREG_DIV_MODE = SHIFTREG_DIV_MODE;

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

endmodule //tSPLL
