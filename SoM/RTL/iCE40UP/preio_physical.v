`timescale 1ps/1ps
module preio_physical 	(hold, rstio, bs_en, shift, tclk, inclk, outclk, update, oepin, sdi, mode, 
			hiz_b, sdo, dout1, dout0, ddr1, ddr0, padin, padout, padoen, cbit);

input bs_en;   //JTAG enable
input shift;   //JTAG shift
input tclk;    //JTAG clock
input update;  //JTAG update
input sdi;     //JTAG serial data in
input mode;    //JTAG mode
input hiz_b;   //JTAG high X control
output sdo;    //JTAG serial data out

output dout1;  //Normal Input cell output 1
output dout0;  //Normal Input cell output 0
input ddr1;    //Normal Output cell input 1
input ddr0;    //Normal Output cell input 0
input oepin;   //Normal Ouput-Enable 
input hold;    //Normal Input cell control
input rstio;   //Normal Input cell reset
input inclk;   //Normal Input cell clock
input outclk;  //Normal Output cell clock

input [5:0] cbit; //Configurion bits

input 	padin;   //PAD input
output 	padout;  //PAD output
output	padoen;  //PAD output enable




//Signals declaration
wire padin_n1;
wire inclk_n2;
wire padin_n3;
reg  in_MUX_n4 = 0;
wire hold_AND2;
wire dout0;

wire ddr0_n11;
wire outclk_n12;
wire ddr1_n13;
wire n14;
wire dout_reg_0_n;

wire Reg_or_Wire_N17;
wire n18;
//wire n19;
reg n19; 

wire tristate;
wire outclk_n22;
wire n26;

reg  oen_n_n24 = 0;
wire jtag_update_n30;

reg din_reg_0 = 0;
reg din_reg_1 = 0;
reg dout_reg_0 = 0;
reg dout_reg_1 = 0;
reg tristate_q = 0;
reg jtag_oe_reg = 0;

					
// Miscc logics
//---------------------

assign jtag_update_n30 = ~( bs_en & (~update ) );

//---------------------------------------------------------------------------
//
//	Assign output
//
//---------------------------------------------------------------------------
assign sdo = din_reg_0;
assign dout1 = din_reg_1;

//---------------------------------------------------------------------------
//
//	Input logic
//
//---------------------------------------------------------------------------

assign padin_n1 = (shift) ? dout_reg_0  : padin;

assign inclk_n2 = (bs_en) ? tclk : inclk;

always @(posedge inclk_n2 or posedge rstio)
   if (rstio) din_reg_0 <= 1'b0 ; //#1 1'b0;
   else din_reg_0 <= padin_n1;    //#1 padin_n1;

assign padin_n3 = (bs_en) ? din_reg_0 : padin;

always @(negedge inclk_n2 or posedge rstio)
   if (rstio) din_reg_1 <= 1'b0 ; // #1 1'b0;
   else if (jtag_update_n30) din_reg_1 <= padin_n3; //  #1 padin_n3;

assign hold_AND2 = cbit[1] & hold;

// 	Input MUX
always @(hold_AND2, cbit[0], dout0, padin, din_reg_0) begin 
   case ({hold_AND2, cbit[0]})
      2'b00 : 	in_MUX_n4 = din_reg_0;
      2'b01 : 	in_MUX_n4 = padin;
      2'b10 : 	in_MUX_n4 = dout0;
      2'b11 : 	in_MUX_n4 = dout0;
      default : in_MUX_n4 = 1'b0;
      endcase
 end     
 
assign dout0 = (mode) ? din_reg_1 : in_MUX_n4;


// Output Register
always @(posedge outclk_n12 or posedge rstio)
   if (rstio) dout_reg_0 <=  1'b0 ; //#1 1'b0;
   else dout_reg_0 <=  ddr0_n11 ; // #1 ddr0_n11;

// Muxes for Output registers
assign dout_reg_0_n = ~dout_reg_0;
assign Reg_or_Wire_N17 = cbit[2] ? dout_reg_0_n : ddr0;
assign n18 = n19 ? dout_reg_1 : dout_reg_0;
//assign n19 = ~(outclk_n12 || cbit[2]);

always@(outclk_n12,cbit[2])
begin 
	n19<= ~(outclk_n12 || cbit[2]);
end 


assign n14 = cbit[3] ? Reg_or_Wire_N17 : n18;
assign padout = mode ? dout_reg_1 : n14;

// JTAG Assigns
assign ddr0_n11 = (shift) ? tristate_q  : ddr0;

assign outclk_n12 = (bs_en) ? tclk : outclk;
assign ddr1_n13 = (bs_en) ? dout_reg_0 : ddr1;

// JTAG register 
always @(negedge outclk_n12 or posedge rstio)
   if (rstio) dout_reg_1 <=  1'b0 ; //#1 1'b0;
   else if (jtag_update_n30) dout_reg_1 <= ddr1_n13; //  #1 ddr1_n13;

//---------------------------------------------------------------------------
//
//	Output Enable Logic
//
//---------------------------------------------------------------------------

// OE Tristate Register
assign tristate = (shift) ? sdi  : oepin;
always @(posedge outclk_n22 or posedge rstio)
   if (rstio) tristate_q <= 1'b0;	// #1 1'b0;
   else tristate_q <= tristate;

// JTAG register
assign outclk_n22 = (bs_en) ? tclk : outclk;
always @(negedge outclk_n22 or posedge rstio)
   if (rstio) jtag_oe_reg <=  1'b0 ; // #1 1'b0;
   else if (jtag_update_n30) jtag_oe_reg <= padin_n3;

always @(cbit[5],cbit[4], oepin, tristate_q)  begin 
   case ({cbit[5],cbit[4]})
      2'b00 : oen_n_n24 = 1'b0;
      2'b01 : oen_n_n24 = 1'b1;
      2'b10 : oen_n_n24 = oepin;
      2'b11 : oen_n_n24 = tristate_q;
 
   endcase
end      
		

assign n26 = (mode) ? jtag_oe_reg : oen_n_n24;

assign padoen = ~(hiz_b & n26);

endmodule //preio_physical
