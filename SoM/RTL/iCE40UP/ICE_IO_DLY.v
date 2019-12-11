`timescale 10ps/1ps
module ICE_IO_DLY (
	PACKAGEPIN, 
	LATCHINPUTVALUE, 
	CLOCKENABLE, 
	INPUTCLK, 
	OUTPUTCLK, 
	OUTPUTENABLE, 
	DOUT1, 
	DOUT0, 
	DIN1, 
	DIN0,
	SCLK,
	SDI,
	CRSEL,
	SDO
 );


parameter NEG_TRIGGER 	= 1'b0; 	   // When set to 1'b1 the polarity of all FFs in the IO is set work at falling edge, default is rising edge Flops
parameter PIN_TYPE      = 6'b000000;       // The required package pin type must be set when io_macro is instantiated.
parameter PULLUP 	= 1'b0;	
parameter IO_STANDARD 	= "SB_LVCMOS";     
parameter INDELAY_VAL   = 6'b000000;       // Set input  line delay value 
parameter OUTDELAY_VAL  = 6'b000000;       // Set output line delay value 


inout 	PACKAGEPIN; 		//' User's package pin - 'PAD' output
input 	CLOCKENABLE;    	// Clock enables in & out clocks
input 	LATCHINPUTVALUE;    	// Input Latch data control
input	INPUTCLK;   		// Input clock
input 	OUTPUTCLK;  		// Output clock


output 	DIN1;    		// Data to Core from PAD     - input 1   (ddrin1)
output	DIN0;    		// Data to Core from PAD     - input 0   (ddrin0)

input 	DOUT1;  		// Data to PAD from core - output 1 (ddrout1)
input 	DOUT0;  		// Data to PAD from core - output 0 (ddrout0)  
input 	OUTPUTENABLE;   	// Ouput-Enable 

input  SCLK;			// Delay serial register clock  
input  SDI;                     // Serial data input to serial delay registers  
input  CRSEL;                 //'0' selects IN/OUT static delay parameters, '1' selects serial register data 
output SDO;                     // Serial data out from serial registers 


//------------- Main Body of verilog ----------------------------------------------------
wire inclk_, outclk_;
wire inclk, outclk;
reg INCLKE_sync,OUTCLKE_sync;

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
wire padinout_delayed; 
assign PACKAGEPIN = (~padoen) ? padinout_delayed : 1'bz;
assign padin = PACKAGEPIN ;

wire hold, oepin;							  
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
	.padin(padinout_delayed),
	.padout(padout),
	.padoen(padoen),
	.cbit(PIN_TYPE)
	);

   inoutdly64 iodly64_i ( 
	// dynamic delay test thru sdi,sdo pins are disabled // 
	.sclk(),
        .serialreg_rst(),
        .sdi(),
        .c_r_sel(),
        .in_datain(padin),
        .out_datain(padout),
        .delay_direction(padoen),
        .delayed_dataout(padinout_delayed),
        .sdo()
	); 
   defparam iodly64_i.INDELAY  =INDELAY_VAL; 
   defparam iodly64_i.OUTDELAY =OUTDELAY_VAL; 
    	        


endmodule
