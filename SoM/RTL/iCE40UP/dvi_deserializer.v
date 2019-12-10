`timescale 1ns /1ps 
module dvi_deserializer (
	en,							
	rstn, 	 
	din, 
	clkx5in,	
	clkx1in,
	rawdata 
	); 

///---------------------------------------------------------/// 		
output reg  [9:0] rawdata ;		  // 10 bit raw data output 
input  rstn ;					  // Active low  deserializer reset 						  	
input  clkx5in ;				  // 5x clk input 
input  din ;					  // input stream 
input  clkx1in ;				 // 1x clk input 
input  en ;						 // global - clock enable 
///-----------------------------------------------------------///
wire 		clkx1 , clkx5 ; 
reg  		din_n0, din_n1;
reg 		din_p0; 
reg	[9:0] 	datain; 
wire [9:0]  mem_rdout;

assign 	clkx1 = clkx1in & en ; 
assign 	clkx5 = clkx5in & en ; 

/// ------------ Data Sampling Section  --------------- 
always@(negedge clkx5) 
begin
   if(en == 1'b1) 
	din_n0 <= din; 
end 

always@(posedge clkx5) 
begin 
	din_n1    <= ~din_n0;
	datain[8] <= din_n1; 
	datain[6] <= datain[8]; 
	datain[4] <= datain[6]; 
	datain[2] <= datain[4]; 
	datain[0] <= datain[2]; 
end 

always@(posedge clkx5) 
begin 
	din_p0 <= din; 
end 

always@(posedge clkx5) 
begin 
	datain[9] <= ~din_p0; 
	datain[7] <= datain[9]; 	
	datain[5] <= datain[7]; 
	datain[3] <= datain[5]; 
	datain[1] <= datain[3]; 
end 
	
reg [9:0]  datain_q;

always@(posedge clkx5) 	  
	begin 
	datain_q<=datain; 
end 
	
  reg 	[2:0]  	n_state; 
  reg 	[2:0]	p_state; 


  parameter ST0 = 3'b000;
  parameter ST1 = 3'b001;
  parameter ST2 = 3'b010;
  parameter ST3 = 3'b011;
  parameter ST4 = 3'b100;
  
  
  always@(p_state or rstn ) 
  begin 
	  case(p_state)
		  ST0 : begin  
		  		if (rstn==1'b1) n_state <= ST1; else n_state <= ST0;
		  		end  
		  ST1 : begin  
		  		if (rstn==1'b1) n_state <= ST2; else n_state <= ST1;
		  		end  	   
		  
		  ST2 : begin  
		  		if (rstn==1'b1) n_state <= ST3; else n_state <= ST2;
		  		end  
		  ST3 : begin  
		  		if (rstn==1'b1) n_state <= ST4; else n_state <= ST2;
		  		end  
		  default: n_state <=ST0; 
	  endcase
  end 
  
  always@(posedge clkx5 or negedge rstn) 
  begin 
	  if(rstn == 1'b0) 
		  p_state <= ST0; 
	  else if(en ==1'b1)
		  p_state <= n_state; 
 end 
 
 wire pulse_5cnt;
 reg sync_wren;
 
 assign pulse_5cnt = (p_state == ST3);	  
 
 always@(posedge clkx5) 
 begin 
	sync_wren <= pulse_5cnt;  
 end 
 				   
 // syncronous read , write reset signal gen 
  reg  rstsync_w, rstsync_r , wa_rst , ra_rst;						
  
  always@(posedge clkx5)
  begin 
	  rstsync_w <= rstn; 
	  rstsync_r <= rstsync_w; 
	  wa_rst    <= rstsync_r;				 
  //	  ra_rst 	<= wa_rst; 
  end 
 

  reg [3:0]  sync_rden; 

  
  always@(posedge clkx5)  // delay ra_rst 
  begin 
	sync_rden[0] <= rstsync_r;   
  	sync_rden[1] <= sync_rden[0];
	sync_rden[2] <= sync_rden[1];
	sync_rden[3] <= sync_rden[2];
	ra_rst <= sync_rden[3]; 
  end 
 
  //Address Generation Logics 
  reg [1:0] wa; 
  reg [1:0] ra; 
  
  always@(posedge clkx5 or negedge wa_rst)
  begin 
	  if(wa_rst == 1'b0) 
		  wa <= 2'b0;
	else if (sync_wren == 1'b1) 
		wa <= wa +1 ;     
  end 
		
  always @(posedge clkx1 or negedge ra_rst )
  begin 								   
	  if(ra_rst == 1'b0) 
		  ra <= 2'b0; 
	  else 
  	 	ra <= ra +1;  
  end  	    
  
  mem4x10  mem4x10_i 
  (
  .WDATAIN(datain_q),
  .WCLK(clkx5),
  .WE(sync_wren),
  .WADDR(wa),
  .RADDR(ra), 
  .RDATAOUT(mem_rdout)
  ); 
  
 always @ (posedge clkx1) begin
    rawdata<=mem_rdout;
 end		  
  
endmodule  
