`timescale 1ps/1ps
module PLL40  (
		PLLIN,				//Input from IO PAD associtaed with PAD PLL. 
		PLLOUTCORE,			//PLL output to core logic
		PLLOUTGLOBAL,	   		//PLL output to global network
		EXTFEEDBACK,  			//Driven by core logic
		DYNAMICDELAY,			//Driven by core logic
		LOCK,				//Output of PLL
		BYPASS,				//Driven by core logic
		RESETB,				//Driven by core logic
		SDI,				//Driven by core logic. Test Pin
		SDO,				//Output to RB Logic Tile. Test Pin
		SCLK,				//Driven by core logic. Test Pin
		LATCHINPUTVALUE 		//iCEGate signal
);
input  	PLLIN;		
output 	PLLOUTCORE;				//PLL output to core logic
output	PLLOUTGLOBAL;	   			//PLL output to global network
input	EXTFEEDBACK;  				//Driven by core logic
input	[7:0] DYNAMICDELAY;  			//Driven by core logic
output	LOCK;					//Output of PLL
input	BYPASS;					//Driven by core logic
input	RESETB;					//Driven by core logic
input	LATCHINPUTVALUE; 			//iCEGate signal
//Test/Dynamic PLL configuration Pins
output	SDO;					//Output of PLL to core logic 
input	SDI;					//Driven by core logic
input	SCLK;					//Driven by core logic
wire SPLLOUT1net;

// Parameters 
parameter FEEDBACK_PATH = "SIMPLE";		//String  (simple, delay, phase_and_delay, external) 
parameter DELAY_ADJUSTMENT_MODE_FEEDBACK = "FIXED"; 
parameter DELAY_ADJUSTMENT_MODE_RELATIVE = "FIXED"; 
parameter SHIFTREG_DIV_MODE = 2'b00; 		//0-->Divide by 4, 1-->Divide by 7, 3 -->Divide by 5
parameter FDA_FEEDBACK = 4'b0000; 		//Integer. 

parameter FDA_RELATIVE = 4'b0000; 		//Integer. 
parameter PLLOUT_SELECT = "GENCLK"; 		

//Use the Spreadsheet to populate the values below.
parameter DIVR = 4'b0000; 			//determine a good default value
parameter DIVF = 7'b0000000; 			//determine a good default value
parameter DIVQ = 3'b000; 			//determine a good default value
parameter FILTER_RANGE = 3'b000; 		//determine a good default value


parameter ENABLE_ICEGATE = 1'b0;		//Additional cbits
parameter TEST_MODE = 1'b0;			//Test Mode parameter.Used for test/Dynamic PLL configuration.  
parameter EXTERNAL_DIVIDE_FACTOR = 1; 		//Not used by model. Added for PLL Config GUI.	 


generate
if (TEST_MODE==1'b1) begin

	t_DS_PLL40 insttSPLL (
		.CORE_REF_CLK (),
        	.PACKAGEPIN (PLLIN),
		.EXTFEEDBACK (EXTFEEDBACK),  	
		.DYNAMICDELAY (DYNAMICDELAY),		
		.BYPASS (BYPASS),
		.RESETB (~RESETB),	
		.PLL_SCK(SCLK),
	        .PLL_SDI(SDI),
        	.PLL_SDO(SDO),
		.PLLOUT1 (SPLLOUT1net),	
		.PLLOUT2 (SPLLOUT2net),		
		.LOCK (LOCK)   	

	);	   
	defparam insttSPLL.DIVR = DIVR;	
	defparam insttSPLL.DIVF = DIVF;
	defparam insttSPLL.DIVQ = DIVQ;
	defparam insttSPLL.FILTER_RANGE = FILTER_RANGE;
	defparam insttSPLL.FEEDBACK_PATH = FEEDBACK_PATH;
	defparam insttSPLL.DELAY_ADJUSTMENT_MODE_RELATIVE = DELAY_ADJUSTMENT_MODE_RELATIVE;
	defparam insttSPLL.DELAY_ADJUSTMENT_MODE_FEEDBACK = DELAY_ADJUSTMENT_MODE_FEEDBACK;
	defparam insttSPLL.SHIFTREG_DIV_MODE = SHIFTREG_DIV_MODE;
	defparam insttSPLL.FDA_RELATIVE = FDA_RELATIVE; 
	defparam insttSPLL.FDA_FEEDBACK = FDA_FEEDBACK; 
	defparam insttSPLL.PLLOUT_SELECT_PORTA = PLLOUT_SELECT;
	defparam insttSPLL.PLLOUT_SELECT_PORTB = "GENCLK";
	defparam insttSPLL.TEST_MODE = TEST_MODE;

end else begin

	tSPLL40 insttSPLL (
		.REFERENCECLK (PLLIN),
		.EXTFEEDBACK (EXTFEEDBACK),  	
		.DYNAMICDELAY (DYNAMICDELAY),		
		.BYPASS (BYPASS),
		.RESETB (~RESETB),			
		.PLLOUT1 (SPLLOUT1net),	
		.PLLOUT2 (SPLLOUT2net),		
		.LOCK (LOCK)   	
	);	  

	defparam insttSPLL.DIVR = DIVR;	
	defparam insttSPLL.DIVF = DIVF;
	defparam insttSPLL.DIVQ = DIVQ;
	defparam insttSPLL.FILTER_RANGE = FILTER_RANGE;
	defparam insttSPLL.FEEDBACK_PATH = FEEDBACK_PATH;
	defparam insttSPLL.DELAY_ADJUSTMENT_MODE_RELATIVE = DELAY_ADJUSTMENT_MODE_RELATIVE;
	defparam insttSPLL.DELAY_ADJUSTMENT_MODE_FEEDBACK = DELAY_ADJUSTMENT_MODE_FEEDBACK;
	defparam insttSPLL.SHIFTREG_DIV_MODE = SHIFTREG_DIV_MODE;
	defparam insttSPLL.FDA_RELATIVE = FDA_RELATIVE; 
	defparam insttSPLL.FDA_FEEDBACK = FDA_FEEDBACK; 
	defparam insttSPLL.PLLOUT_SELECT_PORTA = PLLOUT_SELECT;
	defparam insttSPLL.PLLOUT_SELECT_PORTB = "GENCLK";
	//defparam insttSPLL.TEST_MODE = TEST_MODE;

end

endgenerate

assign PLLOUTCORE = ((ENABLE_ICEGATE != 0) && LATCHINPUTVALUE) ? PLLOUTCORE : SPLLOUT1net;
assign PLLOUTGLOBAL = ((ENABLE_ICEGATE != 0) && LATCHINPUTVALUE)  ? PLLOUTGLOBAL : SPLLOUT1net;


endmodule // PLL40
