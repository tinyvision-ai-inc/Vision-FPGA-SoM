`timescale 10ps/1ps 
module IO_PAD ( 
	PACKAGEPIN,
 	DOUT,
	DIN,
	OE	   	
 ); 

parameter PULLUP = 1'b0; // by default the IO will have NO pullup, 
			//  this parameter is used only on bank 0, 1, and 2. Will be ignored when it is placed at bank 3
parameter IO_STANDARD = "SB_LVCMOS"; 
				// bank 0,1,2 supports SB_LVCMOS standard only 
				// bank 3 supports :SB_LVCMOS,SB_SSTL2_CLASS_2, SB_SSTL2_CLASS_1, SB_SSTL18_FULL, SB_SSTL18_HALF

input 	DIN;            // Data from core to PAD  
input 	OE;		// Output Data Enable (tristate) 
output 	DOUT;           // Data from PAD to core 
inout 	PACKAGEPIN; 	//' User's package pin - 'PAD' output

assign PACKAGEPIN = (~OE)? DIN : 1'bz;
assign DOUT       = PACKAGEPIN ;


endmodule   //IO_PAD 
