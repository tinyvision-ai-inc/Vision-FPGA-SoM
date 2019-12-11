`timescale 1ps /1ps 
module clkdelay16 (
		dlyin, 
		dlyout, 
		dly_sel 
	);

parameter BUF_DELAY=100;	  	// 100ps +-25 ps 

input 			dlyin;  	// data to delay tap 
input 	[3:0]  		dly_sel;	// dealy adjustment. 0 - Nodelay    
output 			dlyout;      	// Delayed Data Line output   

wire 	[15:0] 	buf_y; 
reg         	delayed_data; 

// 16 tap buffer
assign  		 buf_y[0] = dlyin ; 	   
buf #BUF_DELAY  bufinst1 (buf_y[1],buf_y[0]);   
buf #BUF_DELAY  bufinst2 (buf_y[2],buf_y[1]);   
buf #BUF_DELAY  bufinst3 (buf_y[3],buf_y[2]);   
buf #BUF_DELAY  bufinst4 (buf_y[4],buf_y[3]);   
buf #BUF_DELAY  bufinst5 (buf_y[5],buf_y[4]);   
buf #BUF_DELAY  bufinst6 (buf_y[6],buf_y[5]);   
buf #BUF_DELAY  bufinst7 (buf_y[7],buf_y[6]);   
buf #BUF_DELAY  bufinst8 (buf_y[8],buf_y[7]);   
buf #BUF_DELAY  bufinst9 (buf_y[9],buf_y[8]);   
buf #BUF_DELAY  bufinst10 (buf_y[10],buf_y[9]); 
buf #BUF_DELAY  bufinst11 (buf_y[11],buf_y[10]);
buf #BUF_DELAY  bufinst12 (buf_y[12],buf_y[11]);
buf #BUF_DELAY  bufinst13 (buf_y[13],buf_y[12]);
buf #BUF_DELAY  bufinst14 (buf_y[14],buf_y[13]);
buf #BUF_DELAY  bufinst15 (buf_y[15],buf_y[14]);

// delay_sel mux 
always @*
begin 
	case(dly_sel) 
	4'd0: delayed_data  = buf_y[0];   
	4'd1: delayed_data  = buf_y[1];    
	4'd2: delayed_data  = buf_y[2];  
	4'd3: delayed_data  = buf_y[3];
	4'd4: delayed_data  = buf_y[4];
	4'd5: delayed_data  = buf_y[5];
	4'd6: delayed_data  = buf_y[6];
	4'd7: delayed_data  = buf_y[7];
	4'd8: delayed_data  = buf_y[8];
	4'd9: delayed_data  = buf_y[9];
	4'd10: delayed_data = buf_y[10];
	4'd11: delayed_data = buf_y[11];
	4'd12: delayed_data = buf_y[12];
	4'd13: delayed_data = buf_y[13];
	4'd14: delayed_data = buf_y[14];
	4'd15: delayed_data = buf_y[15];
	endcase
end 

assign dlyout = delayed_data ; 

endmodule
