`timescale 1ps/1ps
module IO_DS (
	PACKAGE_PIN, 
	PACKAGE_PIN_B, 
	LATCH_INPUT_VALUE, 
	CLOCK_ENABLE, 
	INPUT_CLK, 
	OUTPUT_CLK, 
	OUTPUT_ENABLE, 
	D_OUT_1, 
	D_OUT_0, 
	D_IN_1, 
	D_IN_0
 );

parameter PIN_TYPE			= 6'b000000;	  // The default is set to report IO macros that do not define what IO type is used. 
parameter NEG_TRIGGER = 1'b0; // specify the polarity of all FFs in the IO to be falling edge when NEG_TRIGGER = 1, default is rising edge
parameter IO_STANDARD = "SB_LVDS_OUTPUT"; // another supported standard is SB_LVDS_IO 

input D_OUT_1;  		// Input output 1
input D_OUT_0;  		// Input output 0

input CLOCK_ENABLE;    		// Clock enables NEW - common to in/out clocks

output D_IN_1;    		// Output input 1
output D_IN_0;    		// Output input 0

input OUTPUT_ENABLE;   		// Ouput-Enable 
input LATCH_INPUT_VALUE;    		// Input control
input INPUT_CLK;   		// Input clock
input OUTPUT_CLK;  		// Output clock

inout 	PACKAGE_PIN; 		//' User's package pin - 'PAD' output
inout 	PACKAGE_PIN_B; 		//' User's package pin - 'PAD' output


//------------- Main Body of verilog ----------------------------------------------------
wire inclk_, outclk_;
wire inclk, outclk;
reg INCLKE_sync,OUTCLKE_sync;

assign (weak0, weak1) CLOCK_ENABLE =1'b1 ;
assign inclk_ = (INPUT_CLK ^ NEG_TRIGGER); // change the input clock phase
assign outclk_ = (OUTPUT_CLK ^ NEG_TRIGGER); // change the output clock phase
//assign inclk = (inclk_ & CLOCK_ENABLE);
//assign outclk = (outclk_ & CLOCK_ENABLE);


//////// CLKEN sync ///////
always@(inclk_ or CLOCK_ENABLE)
begin 
    if(~inclk_)
	INCLKE_sync = CLOCK_ENABLE; 
end

always@(outclk_ or CLOCK_ENABLE)
begin 
   if(~outclk_) 	
	OUTCLKE_sync = CLOCK_ENABLE; 
end

assign inclk = (inclk_ & INCLKE_sync);
assign outclk = (outclk_ & OUTCLKE_sync);

wire bs_en;   //Boundary scan enable
wire shift;   //Boundary scan shift
wire tclk;    //Boundary scan clock
wire update;  //Boundary scan update
wire sdi;     //Boundary scan serial data in
wire mode;    //Boundary scan mode
wire hiz_b;   //Boundary scan tristate control
wire sdo;     //Boundary scan serial data out

//wire rstio; disabled as this a power on only signal   	//Normal Input reset

assign  bs_en = 1'b0;	//Boundary scan enable
assign  shift = 1'b0;	//Boundary scan shift
assign  tclk = 1'b0;	//Boundary scan clock
assign  update = 1'b0;	//Boundary scan update
assign  sdi = 1'b0;	//Boundary scan serial data in
assign  mode = 1'b0;	//Boundary scan mode
assign  hiz_b = 1'b1;	//Boundary scan Tristate control
  
wire padoen, padout, padin;
assign PACKAGE_PIN = (~padoen) ? padout : 1'bz;
assign PACKAGE_PIN_B = (~padoen) ? ~padout : 1'bz;

assign padin = PACKAGE_PIN ;


//parameter Pin_Type  MUST be defined when instantiated
wire hold, oepin;							  // The required package pin type must be set when io_macro is instantiated.
assign hold = LATCH_INPUT_VALUE;
assign oepin = OUTPUT_ENABLE;
 
 preio_physical preiophysical_i (	//original names unchanged
 	.hold(hold),
	.rstio(1'b0),			//Disabled as this is power on only.
	.bs_en(bs_en),
	.shift(shift),
	.tclk(tclk),
	.inclk(inclk),
	.outclk(outclk),
	.update(update),
	.oepin(oepin),
	.sdi(sdi),
	.mode(mode),
	.hiz_b(hiz_b),
	.sdo(sdo),
	.dout1(D_IN_1),
	.dout0(D_IN_0),
	.ddr1(D_OUT_1),
	.ddr0(D_OUT_0),
	.padin(padin),
	.padout(padout),
	.padoen(padoen),
	.cbit(PIN_TYPE)
	);


endmodule
