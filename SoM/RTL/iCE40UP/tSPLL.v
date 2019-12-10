`timescale 1ps/1ps	
module tSPLL (
		REFERENCECLK,
		EXTFEEDBACK,
		DYNAMICDELAY,
		BYPASS,	
		RESET,		
		
		PLLOUT,		
		LOCK   		
);

//----------------------------------------------------------------------
// Port Declarations
//----------------------------------------------------------------------

// Inputs

input REFERENCECLK;		//Driven by core logic
input	EXTFEEDBACK;  			//Driven by core logic
input	[3:0] DYNAMICDELAY;  	//Driven by core logic
input	BYPASS;				//Driven by core logic
input	RESET;				//Driven by core logic

// Outputs
output 	PLLOUT;		//PLL output to core logic
output	LOCK;				//Output of PLL

//Frequency Specification
//parameter REFERENCE_CLK_FREQUENCY = 100; 		//Floating Point
//parameter PLLOUT_FREQUENCY = 100;			//Floating Point

//Feedback
parameter FEEDBACK_PATH = "SIMPLE";	//String  (simple, delay, phase_and_delay, external) (3 cbits, not 2)
			// If "external" check for signal connectivity on EXTFEEDBACK port.
parameter DELAY_ADJUSTMENT_MODE = "NONE"; //String. If FEEDBACK_SELECT="external",
				// specify DELAY_ADJUSTMENT_MODE as DYNAMIC or FIXED 
				// Check for signal connectivity on DYNAMIC_DELAY[3:0] 
				// && EXTFEEDBACK port
parameter FIXED_DELAY_ADJUSTMENT = 4'b0000; 		//Integer. Specify only if 
				//FEEDBACK_SELECT_MODE="external" && DELAY_ADJUSTMENT_MODE = "fixed". 

//Phase shifted or direct output (3 cbits)
parameter PLLOUT_PHASE = "NONE"; //0deg,90deg,180deg,270deg,none

//Use the Spreadsheet to populate the values below.
parameter DIVR = 4'b0000; 	//determine a good default value
parameter DIVF = 6'b000000; //determine a good default value
parameter DIVQ = 3'b000; 	//determine a good default value
parameter FILTER_RANGE = 3'b000; 	//determine a good default value

//Additional cbits
parameter ENABLE_ICEGATE = 1'b0;

wire ABPLLOUT;
wire phaseShiftMuxOutNet;
wire FSEnet;
wire FBnet;
wire finedelayin, finedelayout;
wire [5:0] DIVFBus = DIVF; 
wire [3:0] DIVRBus = DIVR; 
wire [2:0] DIVQBus = DIVQ; 
wire [2:0] RANGEBus = FILTER_RANGE; 

reg [1:0] phasesel;
reg [1:0] delaymuxsel;
//reg fbout;

initial
begin
 if (PLLOUT_PHASE == "0deg")
    phasesel = 2'b00;
else if (PLLOUT_PHASE == "90deg")
    phasesel = 2'b01;
else if (PLLOUT_PHASE == "180deg")
    phasesel = 2'b10;
else if (PLLOUT_PHASE == "270deg")
    phasesel = 2'b11;
else if (PLLOUT_PHASE != "NONE")
   begin
	        $display ("************************SBT : ERROR ****************************");
	        $display ("Parameter PLLOUT_PHASE is set to an illegal value.");
	        $display ("Legal values should be one of \"NONE\", \"0deg\", \"90deg\", \"180deg\", \"270deg\". ");
	        $display ("Due to incorrect configuration of the PLL, the simulation results are invalid.");
	        $display ("***************************************************************");
	        $finish;
   end
end


assign PLLOUT = (BYPASS == 1'b1) ? REFERENCECLK : ((PLLOUT_PHASE == "NONE") ? ABPLLOUT : phaseShiftMuxOutNet);
assign FSEnet = (FEEDBACK_PATH == "SIMPLE") ? 1'b1 : 1'b0;
assign FBnet = (FEEDBACK_PATH == "SIMPLE") ? 1'b0 : finedelayout;


initial
begin

 if (FEEDBACK_PATH != "EXTERNAL")
 	begin
	    $display ("************************SBT : Info*****************************");
	    $display ("Note that any signal connection to the EXTFEEDBACK port of the PLL will be ignored");
	    $display ("***************************************************************");
	   	end
 if (FEEDBACK_PATH == "EXTERNAL")
    begin 
       delaymuxsel = 2'b11;
        if ( (DELAY_ADJUSTMENT_MODE != "FIXED") && (DELAY_ADJUSTMENT_MODE != "DYNAMIC") )
		begin
	        $display ("************************SBT : ERROR ************************");
	        $display ("Since FEEDBACK_PATH=\"EXTERNAL\", DELAY_ADJUSTMENT_MODE should be \"FIXED\" or \"DYNAMIC\"");
	        $display ("Due to incorrect configuration of the PLL, the simulation results are invalid.");
	        $display ("***************************************************************");
	        $finish;
		end
		if (PLLOUT_PHASE != "NONE")
		begin
	        $display ("************************ SBT : ERROR **************************");
	        $display ("Since FEEDBACK_PATH=\"EXTERNAL\", Phase Adjustment is NOT permitted. Please set PLLOUT_PHASE=\"NONE\"");
	        $display ("*************************************************************");
	        $finish;
		end
    end				
 else if (FEEDBACK_PATH == "DELAY")
    begin 
    	delaymuxsel = 2'b00;
        if ( (DELAY_ADJUSTMENT_MODE != "FIXED") && (DELAY_ADJUSTMENT_MODE != "DYNAMIC") )
		begin
	        $display ("************************ SBT : ERROR **************************");
	        $display ("Since FEEDBACK_PATH=\"DELAY\", DELAY_ADJUSTMENT_MODE should be \"FIXED\" or \"DYNAMIC\"");
	        $display ("Due to incorrect configuration of the PLL, the simulation results are invalid.");
	        $display ("***************************************************************");
	        $finish;
		end
		if (PLLOUT_PHASE != "NONE")
		begin 
	        $display ("************************ SBT : ERROR **************************");
	        $display ("Since FEEDBACK_PATH=\"DELAY\", Phase Adjustment is NOT permitted. Please set PLLOUT_PHASE=\"NONE\"");
		     $display ("Due to incorrect configuration of the PLL, the simulation results are invalid.");
	        $display ("***************************************************************");
	        $finish;
		end
    end				
 else if (FEEDBACK_PATH == "PHASE_AND_DELAY")
	begin
    	delaymuxsel = 2'b01;
        if ( (DELAY_ADJUSTMENT_MODE != "FIXED") && (DELAY_ADJUSTMENT_MODE != "DYNAMIC") )
		begin
	        $display ("************************SBT : Attention************************");
	        $display ("Since FEEDBACK_PATH=\"PHASE_AND_DELAY\", DELAY_ADJUSTMENT_MODE should be FIXED or DYNAMIC");
	        $display ("***************************************************************");
		end
		if ( (PLLOUT_PHASE != "0deg") && (PLLOUT_PHASE != "90deg" )
				&& (PLLOUT_PHASE != "180deg") && (PLLOUT_PHASE != "270deg") )
		begin
	        $display ("************************SBT : Attention************************");
	        $display ("FEEDBACK_PATH=\"PHASE_AND_DELAY\", but PLLOUT_PHASE is not specified correctly");
	        $display ("***************************************************************");
		end
    end				
else if (FEEDBACK_PATH == "SIMPLE")
   begin
		//Ignore DELAY_ADJUSTMENT_MODE, FIXED_DELAY_ADJUSTMENT   
	  $display ("************************SBT : Attention***************************");
	  $display ("Since FEEDBACK_PATH=\"SIMPLE\", the FIXED_DELAY_ADJUSTMENT value will be ignored");
	  $display ("******************************************************************");


    if (PLLOUT_PHASE != "NONE")
		begin
	        $display ("************************SBT : Attention***************************");
	        $display ("The PLL output frequency will be divided by 4 and phase shifted.");
	        $display ("To avoid this, please set PLLOUT_PHASE = \"NONE\" ");
	        $display ("******************************************************************");
		end
	end
 else
 		begin
	        $display ("************************SBT : Attention***************************");
	        $display ("Please set FEEDBACK_PATH to a valid value. Legal settings should be one of \"SIMPLE\", \"DELAY\", \"PHASE_AND_DELAY\", \"EXTERNAL\"");
	        $display ("******************************************************************");
  end 
end


mux4to1 instShftRegOutSelMux (
      .a (phase0net),
      .b (phase90net),
      .c (phase180net),
      .d (phase270net),
      .select (phasesel[1:0]),
      .o (phaseShiftMuxOutNet)
		);

ShiftReg instShftReg (
		.clk (ABPLLOUT),
		.init (RESET),
		.phase0 (phase0net),
		.phase90  (phase90net),
		.phase180 (phase180net),
		.phase270 (phase270net)
		);

mux4to1 instDlyAdjInMux (
		.a (ABPLLOUT),
		.b (phase0net),
		.c (phase0net),
		.d (EXTFEEDBACK),
		.select (delaymuxsel[1:0]),
		.o (finedelayin)
		);


FineDlyAdj instFineDlyAdj (
		.DlyAdj (DYNAMICDELAY),
		.signalin (finedelayin),
		.delayedout (finedelayout)
		);
defparam instFineDlyAdj.FIXED_DELAY_ADJUSTMENT = FIXED_DELAY_ADJUSTMENT;
defparam instFineDlyAdj.DELAY_ADJUSTMENT_MODE = DELAY_ADJUSTMENT_MODE;


 //buf #1750 (finedelayout, finedelayin);

ABIPTBS8 instABitsPLL (
		.REF (REFERENCECLK),
		.FB (FBnet),
		.FSE (FSEnet),
		.BYPASS (BYPASS),
		.RESET (RESET),
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
