`timescale 10ps/1ps
module IO_DLY (
	PACKAGE_PIN, 
	LATCH_INPUT_VALUE, 
	CLOCK_ENABLE, 
	INPUT_CLK, 
	OUTPUT_CLK, 
	OUTPUT_ENABLE, 
	D_OUT_1, 
	D_OUT_0, 
	D_IN_1, 
	D_IN_0,
	SCLK,
	SDI,
	C_R_SEL,
	SDO
 );


parameter NEG_TRIGGER 	= 1'b0; 	   // When set to 1'b1 the polarity of all FFs in the IO is set work at falling edge, default is rising edge Flops
parameter PIN_TYPE      = 6'b000000;       // The required package pin type must be set when io_macro is instantiated.
parameter PULLUP 	= 1'b0;	
parameter IO_STANDARD 	= "SB_LVCMOS";     
parameter INDELAY_VAL   = 6'b000000;       // Set input  line delay value 
parameter OUTDELAY_VAL  = 6'b000000;       // Set output line delay value 


inout 	PACKAGE_PIN; 		//' User's package pin - 'PAD' output
input 	CLOCK_ENABLE;    	// Clock enables in & out clocks
input 	LATCH_INPUT_VALUE;    	// Input Latch data control
input	INPUT_CLK;   		// Input clock
input 	OUTPUT_CLK;  		// Output clock


output 	D_IN_1;    		// Data to Core from PAD     - input 1   (ddrin1)
output	D_IN_0;    		// Data to Core from PAD     - input 0   (ddrin0)

input 	D_OUT_1;  		// Data to PAD from core - output 1 (ddrout1)
input 	D_OUT_0;  		// Data to PAD from core - output 0 (ddrout0)  
input 	OUTPUT_ENABLE;   	// Ouput-Enable 

input  SCLK;			// Delay serial register clock  
input  SDI;                     // Serial data input to serial delay registers  
input  C_R_SEL;                 //'0' selects IN/OUT static delay parameters, '1' selects serial register data 
output SDO;                     // Serial data out from serial registers 


//------------- Main Body of verilog ----------------------------------------------------
wire inclk_, outclk_;
wire inclk, outclk;
reg INCLKE_sync, OUTCLKE_sync;

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
wire padinout_delayed; 
assign PACKAGE_PIN = (~padoen) ? padinout_delayed : 1'bz;
assign padin = PACKAGE_PIN ;

wire hold, oepin;							  
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
	.padin(padinout_delayed),
	.padout(padout),
	.padoen(padoen),
	.cbit(PIN_TYPE)
	);

   inoutdly64 iodly64_i ( 
	// dynamic delay test logic thru sdi , sdo pins disabled // 
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
