`timescale 1ps/100fs
module    X105DSI_RX(
  // Power and Ground Pins
  VDDA,
  VSSA,
  DVSS,
  // Common Interface pins 
  ENP_DESER,
  PD,
 // LB_EN,
 //Data0 Interface pins
  DP0,
  DN0,
  D0_RXHSEN,
  D0_DTXLPP,
  D0_DTXLPN,
  D0_TXLPEN,
  D0_DRXLPP,
  D0_DRXLPN,
  D0_RXLPEN,
  D0_DCDP,
  D0_DCDN,
  D0_CDEN,
  D0_HS_DESER_EN,
  D0_HSRX_DATA,
  D0_HS_BYTE_CLKD,
  D0_SYNC,
  D0_ERRSYNC,
  D0_NOSYNC,
  //D0_DRXHS,
// DATA1 Interface pins
  DP1,
  DN1,
  D1_RXHSEN,
  //D1_RXHSTHDB,
  D1_DRXLPP,
  D1_DRXLPN,
  D1_RXLPEN,
  //D1_DCDP,
  //D1_DCDN,
  //D1_CDEN,
  D1_HS_DESER_EN,
  D1_HSRX_DATA,
  D1_SYNC,
  D1_ERRSYNC,
  D1_NOSYNC,
  //D1_DRXHS,
// CLOCK Interface pins
  CKP,
  CKN,
  CLK_RXHSEN,
  //CLK_RXHSTHDB,
  CLK_DRXLPP,
  CLK_DRXLPN,
  CLK_RXLPEN,
  //CLK_DCDP,
  //CLK_DCDN,
  //CLK_CDEN,
  CLK_HS_BYTE
  //CLK_DRXHS
  );
  
input        VDDA;
input        VSSA;
input        DVSS;
//Common Interface Pins
input         ENP_DESER;
input 			     PD;
//input				     LB_EN;


// DATA0 Interface pins
inout				     DP0;
inout				     DN0;
input				     D0_RXHSEN;
//input				     D0_RXHSTHDB;
input 			     D0_DTXLPP;
input 			     D0_DTXLPN;
input  			    D0_TXLPEN;
output 			    D0_DRXLPP;
output  			   D0_DRXLPN;
input 			     D0_RXLPEN;
output 			    D0_DCDP;
output			     D0_DCDN;
input 			     D0_CDEN;
input				     D0_HS_DESER_EN;
output  [7:0]	D0_HSRX_DATA;
output 			    D0_HS_BYTE_CLKD;
output  			   D0_SYNC;
output  			   D0_ERRSYNC;
output 			    D0_NOSYNC;
//output        D0_DRXHS;

// DATA1 Interface Pins
input  			    DP1;
input  			    DN1;
input  			    D1_RXHSEN;
//input  			    D1_RXHSTHDB;
output  			   D1_DRXLPP;
output  			   D1_DRXLPN;
input  			    D1_RXLPEN;
//output  			   D1_DCDP;
//output  			   D1_DCDN;
//input  			    D1_CDEN;
input  			    D1_HS_DESER_EN;
output  [7:0] D1_HSRX_DATA;
output  			   D1_SYNC;
output  			   D1_ERRSYNC;
output  			   D1_NOSYNC;
//output        D1_DRXHS;


// CLOCK Interface Pins
input  			    CKP;
input  			    CKN;
input  			    CLK_RXHSEN;
//input  			    CLK_RXHSTHDB;
output  			   CLK_DRXLPP;
output  			   CLK_DRXLPN;
input  			    CLK_RXLPEN;
//output  			   CLK_DCDP;
//output  			   CLK_DCDN;
//input  			    CLK_CDEN;

output        CLK_HS_BYTE;
//output        CLK_DRXHS;

wire          hs_rxclk;
wire          CLK_DRXHS;

 MIPI_DATA0_SLAVE 		        i_mipi_data0(
  .DP				             (DP0),
  .DN				             (DN0),
  .RXHSEN			          (D0_RXHSEN),
  //.RXHSTHDB			        (D0_RXHSTHDB),
  .DTXLPP			          (D0_DTXLPP),
  .DTXLPN			          (D0_DTXLPN),
  .TXLPEN			          (D0_TXLPEN),
  .DRXLPP			          (D0_DRXLPP),
  .DRXLPN			          (D0_DRXLPN),
  .RXLPEN			          (D0_RXLPEN),
  .DCDP			            (D0_DCDP),
  .DCDN			            (D0_DCDN),
  .CDEN			            (D0_CDEN),
  .HS_DESER_EN	      	(D0_HS_DESER_EN),
  .HS_RXCLK			        (hs_rxclk),
  .HSRX_DATA		        (D0_HSRX_DATA),
  .HS_BYTE_CLKD		     (D0_HS_BYTE_CLKD),
  .SYNC			            (D0_SYNC),
  .ERRSYNC			         (D0_ERRSYNC),
  .NOSYNC			          (D0_NOSYNC),
 // .DRXHS              (D0_DRXHS),
 // .LB_EN			           (LB_EN),
  .ENP                (ENP_DESER),
  .RXHSTHDB            (RXHSTHDB)
  ); 
 
 MIPI_DATA1_SLAVE 		        i_mipi_data1(
  .DP				             (DP1),
  .DN			             	(DN1),
  .RXHSEN			          (D1_RXHSEN),
  .RXHSTHDB			        (D1_RXHSTHDB),
  .DRXLPP			          (D1_DRXLPP),
  .DRXLPN			          (D1_DRXLPN),
  .RXLPEN			          (D1_RXLPEN),
 // .DCDP			            (D1_DCDP),
 // .DCDN			            (D1_DCDN),
 // .CDEN			            (D1_CDEN),
  .HS_DESER_EN		      (D1_HS_DESER_EN),
//  .DRXHS   			        (D1_DRXHS),
  .HS_RXCLK			        (hs_rxclk),
  .HSRX_DATA		        (D1_HSRX_DATA),
  .SYNC			            (D1_SYNC),
  .ERRSYNC			         (D1_ERRSYNC),
  .NOSYNC			          (D1_NOSYNC),
  .ENP                (ENP_DESER)
   ); 
 
 
   
 MIPI_CLOCK_SLAVE 	         i_mipi_clock(
  .DP				             (CKP),
  .DN				             (CKN),
  .RXHSEN			          (CLK_RXHSEN),
  .RXHSTHDB			        (CLK_RXHSTHDB),
  .DRXLPP			          (CLK_DRXLPP),
  .DRXLPN			          (CLK_DRXLPN),
  .RXLPEN			          (CLK_RXLPEN),
 // .DCDP			            (CLK_DCDP),
 // .DCDN			            (CLK_DCDN),
 // .CDEN			            (CLK_CDEN),
  .HS_DESER_EN		      (1'b0),
  .DRXHS			           (CLK_DRXHS),
  .HS_RXCLK			        (hs_rxclk),
  .HSRX_DATA		        (),
  .SYNC			            (),
  .ERRSYNC			         (),
  .NOSYNC			          (),
  .BYTECLK            (CLK_HS_BYTE),
  .ENP                (1'b1)
   );    


assign hs_rxclk =  CLK_DRXHS;

     
endmodule 
