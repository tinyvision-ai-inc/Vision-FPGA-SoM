`timescale 10ps/1ps
module ICE_IO (
	PACKAGEPIN, 
	LATCHINPUTVALUE, 
	CLOCKENABLE, 
	INPUTCLK, 
	OUTPUTCLK, 
	OUTPUTENABLE, 
	DOUT1, 
	DOUT0, 
	DIN1, 
	DIN0
 );

parameter PIN_TYPE			= 6'b000000;	  // The default is set to report IO macros that do not define what IO type is used. 
parameter PULLUP = 1'b0; // by default the IO will have NO pullup, this parameter is used only on bank 0, 1, and 2. Will be ignored when it is placed at bank 3
parameter NEG_TRIGGER = 1'b0; // specify the polarity of all FFs in the IO to be falling edge when NEG_TRIGGER = 1, default is rising edge
parameter IO_STANDARD = "SB_LVCMOS"; // more standards are supported in bank 3 only: SB_SSTL2_CLASS_2, SB_SSTL2_CLASS_1, SB_SSTL18_FULL, SB_SSTL18_HALF
						 // SB_MDDR10, SB_MDDR8, SB_MDDR4, SB_MDDR2

input DOUT1;  		// Input output 1
input DOUT0;  		// Input output 0

input CLOCKENABLE;    		// Clock enables NEW - common to in/out clocks

output DIN1;    		// Output input 1
output DIN0;    		// Output input 0

input OUTPUTENABLE;   		// Ouput-Enable 
input LATCHINPUTVALUE;    		// Input control
input INPUTCLK;   		// Input clock
input OUTPUTCLK;  		// Output clock

inout 	PACKAGEPIN; 		//' User's package pin - 'PAD' output

//------------- Main Body of verilog ----------------------------------------------------
wire inclk_, outclk_;
wire inclk, outclk;
reg INCLKE_sync, OUTCLKE_sync; 

assign (weak0, weak1) CLOCKENABLE =1'b1 ;
assign inclk_ = (INPUTCLK ^ NEG_TRIGGER); // change the input clock phase
assign outclk_ = (OUTPUTCLK ^ NEG_TRIGGER); // change the output clock phase
//assign inclk = (inclk_ & CLOCKENABLE);
//assign outclk = (outclk_ & CLOCKENABLE);


////// CLKEN sync ////// 
always@(inclk_ or CLOCKENABLE)
begin 
    if(~inclk_)
	INCLKE_sync =CLOCKENABLE;
end

always@(outclk_ or CLOCKENABLE)
begin 
	if(~outclk_)
	OUTCLKE_sync =CLOCKENABLE;
end 

assign inclk =(inclk_ & INCLKE_sync); 
assign outclk =(outclk_ & OUTCLKE_sync); 


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
assign PACKAGEPIN = (~padoen) ? padout : 1'bz;
assign padin = PACKAGEPIN ;


//parameter Pin_Type  MUST be defined when instantiated
wire hold, oepin;							  // The required package pin type must be set when io_macro is instantiated.
assign hold = LATCHINPUTVALUE;
assign oepin = OUTPUTENABLE;
 
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
	.dout1(DIN1),
	.dout0(DIN0),
	.ddr1(DOUT1),
	.ddr0(DOUT0),
	.padin(padin),
	.padout(padout),
	.padoen(padoen),
	.cbit(PIN_TYPE)
	);


endmodule
