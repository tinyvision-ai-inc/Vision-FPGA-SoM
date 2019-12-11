`timescale 1ps/1ps 	
module inoutdly64 (
		sclk,
		serialreg_rst,
		sdi,
		c_r_sel,
		in_datain, 
		out_datain, 
		delay_direction, 
		delayed_dataout,
		sdo 
);

parameter 	INDELAY  = 6'b000000;
parameter 	OUTDELAY = 6'b000000;

localparam	BUF_DELAY=100;	  	// 100ps +-25 ps 
localparam     	CBITS_DELAY ={OUTDELAY,INDELAY};  

input	sclk;		// shiftreg serial clock 
input	serialreg_rst; 	// delay register reset 
input	sdi;          	// serial data in 
input	c_r_sel; 	// Select Cbits or ShiftRegister Value for Delay    
input 	in_datain;  	// padin  data to delay tap 
input 	out_datain;      // padout data to delay tap 
input 	delay_direction;      // delay tap direction. 0 -Apply delay on output data to PAD, 1 -Apply delay on input data from PAD. 
			// delay_direction is controlled by oen of PRE_IO model.  
output	sdo;            // serial data out.
output	delayed_dataout;	// delayed data output   

reg  [11:0] cbits; 
reg  [11:0] serial_data;  
wire [5:0]  delay_sel; 
wire 	    data_in; 

wire [63:1] buf_y; 
reg         delayed_data; 

integer i; 

initial 
begin
 for(i=0 ; i<12 ; i=i+1) 
 begin 
  cbits[i]	=CBITS_DELAY[i]; 	// initialize cbits value 	
 end
 serial_data =12'b0; 
end 

// serial dynamic delay data  
always@(posedge sclk or posedge serialreg_rst) 
begin 
	if(serialreg_rst ==1'b1) 
		serial_data <= 12'b0; 
//	else  						// left shift 
//		serial_data <= {serial_data[10:0],sdi};
	else						// right shift 
		serial_data <= {sdi,serial_data[11:1]}; 
end
assign	sdo = serial_data[0]; 

// SDI, SDO dynamic delay test sections is not required. Delays are static and based on the in out delay parameters.  
//assign delay_sel = (delay_direction == 1'b0)?(c_r_sel ==1'b0)? cbits[11:6]:serial_data[11:6] : (c_r_sel ==1'b0)? cbits[5:0]:serial_data[5:0]; 

assign delay_sel = (delay_direction == 1'b0) ? OUTDELAY    : INDELAY; 
assign data_in   = (delay_direction == 1'b0) ? out_datain  : in_datain ; 

// 63 buf tap  
buf #BUF_DELAY  bufinst1 (buf_y[1],data_in );   
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
buf #BUF_DELAY  bufinst16 (buf_y[16],buf_y[15]);
buf #BUF_DELAY  bufinst17 (buf_y[17],buf_y[16]); 
buf #BUF_DELAY  bufinst18 (buf_y[18],buf_y[17]); 
buf #BUF_DELAY  bufinst19 (buf_y[19],buf_y[18]); 
buf #BUF_DELAY  bufinst20 (buf_y[20],buf_y[19]); 

buf #BUF_DELAY  bufinst21 (buf_y[21],buf_y[20] );
buf #BUF_DELAY  bufinst22 (buf_y[22],buf_y[21]); 
buf #BUF_DELAY  bufinst23 (buf_y[23],buf_y[22]); 
buf #BUF_DELAY  bufinst24 (buf_y[24],buf_y[23]); 
buf #BUF_DELAY  bufinst25 (buf_y[25],buf_y[24]); 
buf #BUF_DELAY  bufinst26 (buf_y[26],buf_y[25]); 
buf #BUF_DELAY  bufinst27 (buf_y[27],buf_y[26]); 
buf #BUF_DELAY  bufinst28 (buf_y[28],buf_y[27]); 
buf #BUF_DELAY  bufinst29 (buf_y[29],buf_y[28]); 
buf #BUF_DELAY  bufinst30 (buf_y[30],buf_y[29]); 

buf #BUF_DELAY  bufinst31 (buf_y[31],buf_y[30]); 
buf #BUF_DELAY  bufinst32 (buf_y[32],buf_y[31]); 
buf #BUF_DELAY  bufinst33 (buf_y[33],buf_y[32]); 
buf #BUF_DELAY  bufinst34 (buf_y[34],buf_y[33]); 
buf #BUF_DELAY  bufinst35 (buf_y[35],buf_y[34]); 
buf #BUF_DELAY  bufinst36 (buf_y[36],buf_y[35]); 
buf #BUF_DELAY  bufinst37 (buf_y[37],buf_y[36]); 
buf #BUF_DELAY  bufinst38 (buf_y[38],buf_y[37]); 
buf #BUF_DELAY  bufinst39 (buf_y[39],buf_y[38]); 
buf #BUF_DELAY  bufinst40 (buf_y[40],buf_y[39]); 

buf #BUF_DELAY  bufinst41 (buf_y[41],buf_y[40]); 
buf #BUF_DELAY  bufinst42 (buf_y[42],buf_y[41]); 
buf #BUF_DELAY  bufinst43 (buf_y[43],buf_y[42]); 
buf #BUF_DELAY  bufinst44 (buf_y[44],buf_y[43]); 
buf #BUF_DELAY  bufinst45 (buf_y[45],buf_y[44]); 
buf #BUF_DELAY  bufinst46 (buf_y[46],buf_y[45]); 
buf #BUF_DELAY  bufinst47 (buf_y[47],buf_y[46]); 
buf #BUF_DELAY  bufinst48 (buf_y[48],buf_y[47]); 
buf #BUF_DELAY  bufinst49 (buf_y[49],buf_y[48]); 
buf #BUF_DELAY  bufinst50 (buf_y[50],buf_y[49]); 

buf #BUF_DELAY  bufinst51 (buf_y[51],buf_y[50]); 
buf #BUF_DELAY  bufinst52 (buf_y[52],buf_y[51]); 
buf #BUF_DELAY  bufinst53 (buf_y[53],buf_y[52]); 
buf #BUF_DELAY  bufinst54 (buf_y[54],buf_y[53]); 
buf #BUF_DELAY  bufinst55 (buf_y[55],buf_y[54]); 
buf #BUF_DELAY  bufinst56 (buf_y[56],buf_y[55]); 
buf #BUF_DELAY  bufinst57 (buf_y[57],buf_y[56]); 
buf #BUF_DELAY  bufinst58 (buf_y[58],buf_y[57]); 
buf #BUF_DELAY  bufinst59 (buf_y[59],buf_y[58]); 
buf #BUF_DELAY  bufinst60 (buf_y[60],buf_y[59]); 

buf #BUF_DELAY  bufinst61 (buf_y[61],buf_y[60]); 
buf #BUF_DELAY  bufinst62 (buf_y[62],buf_y[61]);   
buf #BUF_DELAY  bufinst63 (buf_y[63],buf_y[62]);   

// delay_sel mux 
always @*
begin 
	case(delay_sel) 
	6'd0: delayed_data  = data_in;   
	6'd1: delayed_data  = buf_y[1];    
	6'd2: delayed_data  = buf_y[2];  
	6'd3: delayed_data  = buf_y[3];
	6'd4: delayed_data  = buf_y[4];
	6'd5: delayed_data  = buf_y[5];
	6'd6: delayed_data  = buf_y[6];
	6'd7: delayed_data  = buf_y[7];
	6'd8: delayed_data  = buf_y[8];
	6'd9: delayed_data  = buf_y[9];
	6'd10: delayed_data = buf_y[10 ];

	6'd11: delayed_data = buf_y[11];
	6'd12: delayed_data = buf_y[12];
	6'd13: delayed_data = buf_y[13];
	6'd14: delayed_data = buf_y[14];
	6'd15: delayed_data = buf_y[15];
	6'd16: delayed_data = buf_y[16];
	6'd17: delayed_data = buf_y[17];
	6'd18: delayed_data = buf_y[18];
	6'd19: delayed_data = buf_y[19];
	6'd20: delayed_data = buf_y[20];

	6'd21: delayed_data = buf_y[21];
	6'd22: delayed_data = buf_y[22];
	6'd23: delayed_data = buf_y[23];
	6'd24: delayed_data = buf_y[24];
	6'd25: delayed_data = buf_y[25];
	6'd26: delayed_data = buf_y[26];
	6'd27: delayed_data = buf_y[27];
	6'd28: delayed_data = buf_y[28];
	6'd29: delayed_data = buf_y[29];
	6'd30: delayed_data = buf_y[30];

	6'd31: delayed_data = buf_y[31];
	6'd32: delayed_data = buf_y[32];
	6'd33: delayed_data = buf_y[33];
	6'd34: delayed_data = buf_y[34];
	6'd35: delayed_data = buf_y[35];
	6'd36: delayed_data = buf_y[36];
	6'd37: delayed_data = buf_y[37];
	6'd38: delayed_data = buf_y[38];
	6'd39: delayed_data = buf_y[39];
	6'd40: delayed_data = buf_y[40];

	6'd41: delayed_data = buf_y[41];
	6'd42: delayed_data = buf_y[42];
	6'd43: delayed_data = buf_y[43];
	6'd44: delayed_data = buf_y[44];
	6'd45: delayed_data = buf_y[45];
	6'd46: delayed_data = buf_y[46];
	6'd47: delayed_data = buf_y[47];
	6'd48: delayed_data = buf_y[48];
	6'd49: delayed_data = buf_y[49];
	6'd50: delayed_data = buf_y[50];

	6'd51: delayed_data = buf_y[51];
	6'd52: delayed_data = buf_y[52];
	6'd53: delayed_data = buf_y[53];
	6'd54: delayed_data = buf_y[54];
	6'd55: delayed_data = buf_y[55];
	6'd56: delayed_data = buf_y[56];
	6'd57: delayed_data = buf_y[57];
	6'd58: delayed_data = buf_y[58];
	6'd59: delayed_data = buf_y[59];
	6'd60: delayed_data = buf_y[60];

	6'd61: delayed_data = buf_y[61];
	6'd62: delayed_data = buf_y[62];
	6'd63: delayed_data = buf_y[63];
	endcase
end 

assign delayed_dataout = delayed_data ; 

endmodule
