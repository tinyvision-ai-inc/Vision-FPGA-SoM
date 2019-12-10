`timescale 1ps/1ps
module PLL_2_PAD (
		PACKAGEPIN,		//Driven by core logic
		PLLOUTCOREA,		//DIN0 output to core logic
		PLLOUTGLOBALA,	   	//GLOBALOUTPUTBUFFER
        PLLOUTCOREB,		//PLL output to core logic
		PLLOUTGLOBALB,	   	//PLL output to global network
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
inout 	PACKAGEPIN;		//Driven by core logic
output  PLLOUTCOREA;		//PLL output to core logic
output	PLLOUTGLOBALA;	   	//PLL output to global network
output  PLLOUTCOREB;		//PLL output to core logic
output	PLLOUTGLOBALB;	   	//PLL output to global network
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
//parameter PLLOUT_FREQUENCY_PORTB = 100;			//Floating Point

//Feedback
parameter FEEDBACK_PATH = "SIMPLE";	//simple, delay, phase_and_delay, external 
parameter DELAY_ADJUSTMENT_MODE = "DYNAMIC"; //Fixed, Dynamic 
parameter FIXED_DELAY_ADJUSTMENT = 0; 		// 0-15 
parameter PLLOUT_PHASE = "NONE"; //0deg,90deg,180deg,270deg,none

//Use the Spreadsheet to populate the values below.
parameter DIVR = 4'b0000; 	//determine a good default value
parameter DIVF = 6'b000000; //determine a good default value
parameter DIVQ = 3'b000; 	//determine a good default value
parameter FILTER_RANGE = 3'b000; 	//determine a good default value

//Additional cbits
parameter ENABLE_ICEGATE_PORTA = 1'b0;
parameter ENABLE_ICEGATE_PORTB = 1'b0;

//Test Mode parameter
parameter TEST_MODE = 1'b0;
parameter EXTERNAL_DIVIDE_FACTOR = 1; //Not used by model. Added for PLL Config GUI.

tSPLL insttSPLL (
		.REFERENCECLK (PACKAGEPIN),		//Driven by core logic
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


assign PLLOUTCOREA = ((ENABLE_ICEGATE_PORTA != 0) && LATCHINPUTVALUE) ? PLLOUTCOREA : PACKAGEPIN;
assign PLLOUTGLOBALA = ((ENABLE_ICEGATE_PORTA != 0) && LATCHINPUTVALUE)  ? PLLOUTGLOBALA : PACKAGEPIN;
assign PLLOUTCOREB = ((ENABLE_ICEGATE_PORTB != 0) && LATCHINPUTVALUE) ? PLLOUTCOREB : SPLLOUTnet;
assign PLLOUTGLOBALB = ((ENABLE_ICEGATE_PORTB != 0) && LATCHINPUTVALUE)  ? PLLOUTGLOBALB : SPLLOUTnet;


endmodule // PLL_2_PAD
