`timescale 10ps/1ps 
module IO_PAD_OD ( 
	PACKAGEPIN,
 	DOUT,
	DIN,
	OE	   	
 ); 

input 	DIN;            // Data from core to PAD  
input 	OE;		// Output Data Enable (tristate) 
output 	DOUT;           // Data from PAD to core 
inout 	PACKAGEPIN; 	//' User's package pin - 'PAD' output

assign PACKAGEPIN = ( (~OE) && (~DIN)) ? 1'b0 : 1'bz;
assign DOUT       = PACKAGEPIN ;


endmodule   //IO_PAD_OD
