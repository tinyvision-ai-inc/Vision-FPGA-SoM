`timescale 1ps/1ps
module PLL_CORE (
		REFERENCECLK,		//Driven by core logic
		PLLOUTCORE,		//PLL output to core logic
		PLLOUTGLOBAL,	   	//PLL output to global network
		EXTFEEDBACK,  			//Driven by core logic
		DYNAMICDELAY,		//Driven by core logic
		LOCK,				//Output of PLL
		BYPASS,				//Driven by core logic
		RESET,				//Driven by core logic
		SDI,				//Driven by core logic. Test Pin
		SDO,				//Output to RB Logic Tile. Test Pin
		SCLK,				//Driven by core logic. Test Pin
		LATCHINPUTVALUE 	//iCEGate signal
);
input 	REFERENCECLK;		//Driven by core logic
output 	PLLOUTCORE;		//PLL output to core logic
output	PLLOUTGLOBAL;	   	//PLL output to global network
input	EXTFEEDBACK;  			//Driven by core logic
input	[3:0] DYNAMICDELAY;  	//Driven by core logic
output	LOCK;				//Output of PLL
input	BYPASS;				//Driven by core logic
input	RESET;				//Driven by core logic
input	LATCHINPUTVALUE; 	//iCEGate signal
//Test Pins
output	SDO;				//Output of PLL
input	SDI;				//Driven by core logic
input	SCLK;				//Driven by core logic

//Frequency Specification
//parameter REFERENCE_CLK_FREQUENCY = 100; 		//Floating Point
//parameter PLLOUT_FREQUENCY = 100;			//Floating Point
//parameter REFERENCE_CLK_DIVIDE_BY = 1;  		//Integer  Hide these for now
//parameter REFERENCE_CLK_MULTIPLY_BY = 1; 		//Integer  Hide these for now

//Feedback
parameter FEEDBACK_PATH = "SIMPLE";	//String  (simple, delay, phase_and_delay, external) (3 cbits, not 2)
parameter DELAY_ADJUSTMENT_MODE = "DYNAMIC"; 
parameter FIXED_DELAY_ADJUSTMENT = 0; 		//Integer. 
parameter PLLOUT_PHASE = "NONE"; //0deg,90deg,180deg,270deg,none

//Use the Spreadsheet to populate the values below.
parameter DIVR = 4'b0000; 	//determine a good default value
parameter DIVF = 6'b000000; //determine a good default value
parameter DIVQ = 3'b000; 	//determine a good default value
parameter FILTER_RANGE = 3'b000; 	//determine a good default value

//Additional cbits
parameter ENABLE_ICEGATE = 1'b0;

//Test Mode parameter
parameter TEST_MODE = 1'b0;
parameter EXTERNAL_DIVIDE_FACTOR = 1; //Not used by model. Added for PLL Config GUI.


tSPLL insttSPLL (
		.REFERENCECLK (REFERENCECLK),		//Driven by core logic
		.EXTFEEDBACK (EXTFEEDBACK),  			//Driven by core logic
		.DYNAMICDELAY (DYNAMICDELAY),		//Driven by core logic
		.BYPASS (BYPASS),				//Driven by core logic
		.RESET (~RESET),				//Driven by core logic
		
		.PLLOUT (SPLLOUTnet),		//PLL output to core logic
		.LOCK (LOCK)   		//Output of PLL

);
defparam insttSPLL.DIVR = DIVR;	
defparam insttSPLL.DIVF = DIVF;
defparam insttSPLL.DIVQ = DIVQ;
defparam insttSPLL.FILTER_RANGE = FILTER_RANGE;
defparam insttSPLL.FEEDBACK_PATH = FEEDBACK_PATH;
defparam insttSPLL.DELAY_ADJUSTMENT_MODE = DELAY_ADJUSTMENT_MODE;
defparam insttSPLL.FIXED_DELAY_ADJUSTMENT = FIXED_DELAY_ADJUSTMENT; 
defparam insttSPLL.PLLOUT_PHASE = PLLOUT_PHASE;


assign PLLOUTCORE = ((ENABLE_ICEGATE != 0) && LATCHINPUTVALUE) ? PLLOUTCORE : SPLLOUTnet;
assign PLLOUTGLOBAL = ((ENABLE_ICEGATE != 0) && LATCHINPUTVALUE)  ? PLLOUTGLOBAL : SPLLOUTnet;


endmodule // PLL_CORE
