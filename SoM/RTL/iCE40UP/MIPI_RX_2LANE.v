`timescale 1ps/1ps
module MIPI_RX_2LANE(
  ENPDESER,
  PU,
  DP0,
  DN0,
  D0RXHSEN,
  D0DTXLPP,
  D0DTXLPN,
  D0TXLPEN,
  D0DRXLPP,
  D0DRXLPN,
  D0RXLPEN,
  D0DCDP,
  D0DCDN,
  D0CDEN,
  D0HSDESEREN,
  D0HSRXDATA,
  D0HSBYTECLKD,
  D0SYNC,
  D0ERRSYNC,
  D0NOSYNC,
  DP1,
  DN1,
  D1RXHSEN,
  D1DRXLPP,
  D1DRXLPN,
  D1RXLPEN,
  D1HSDESEREN,
  D1HSRXDATA,
  D1SYNC,
  D1ERRSYNC,
  D1NOSYNC,
  CKP,
  CKN,
  CLKRXHSEN,
  CLKDRXLPP,
  CLKDRXLPN,
  CLKRXLPEN,
  CLKHSBYTE
  );

// Device pins are DP1,DN1,DP0,DN0,CKP,CKN

//Common Interface Pins
input         ENPDESER;
input 			     PU;
//input				     LBEN;


// DATA0 Interface pins
input				     DP0;
input				     DN0;
input				     D0RXHSEN;
//input				     D0RXHSTHDB;
input 			     D0DTXLPP;
input 			     D0DTXLPN;
input  			    D0TXLPEN;
output 			    D0DRXLPP;
output  			   D0DRXLPN;
input 			     D0RXLPEN;
output 			    D0DCDP;
output			     D0DCDN;
input 			     D0CDEN;
input				     D0HSDESEREN;
output  [7:0]	D0HSRXDATA;
output 			    D0HSBYTECLKD;
output  			   D0SYNC;
output  			   D0ERRSYNC;
output 			    D0NOSYNC;
//output        D0DRXHS;

// DATA1 Interface Pins
input  			    DP1;
input  			    DN1;
input  			    D1RXHSEN;
//input  			    D1RXHSTHDB;
output  			   D1DRXLPP;
output  			   D1DRXLPN;
input  			    D1RXLPEN;
//output  			   D1DCDP;
//output  			   D1DCDN;
//input  			    D1CDEN;
input  			    D1HSDESEREN;
output  [7:0] D1HSRXDATA;
output  			   D1SYNC;
output  			   D1ERRSYNC;
output  			   D1NOSYNC;
//output        D1DRXHS;


// CLOCK Interface Pins
input  			    CKP;
input  			    CKN;
input  			    CLKRXHSEN;
//input  			    CLKRXHSTHDB;
output  			   CLKDRXLPP;
output  			   CLKDRXLPN;
input  			    CLKRXLPEN;
//output  			   CLKDCDP;
//output  			   CLKDCDN;
//input  			    CLKCDEN;

output        CLKHSBYTE;
//output        CLKDRXHS;

X105DSI_RX                  u_mipi_slave_analog(
// Power and Ground Pins
  .VDDA                   (1'b1),
  .VSSA                   (1'b0),
  .DVSS                   (1'b0),
 // Common Interface pins 
  .ENP_DESER              (ENPDESER),
  .PD                     (~PU),
 //Data0 Interface pins
  .DP0                    (DP0),
  .DN0                    (DN0),
  .D0_RXHSEN              (D0RXHSEN),
  .D0_DTXLPP              (D0DTXLPP),
  .D0_DTXLPN              (D0DTXLPN),
  .D0_TXLPEN              (D0TXLPEN),
  .D0_DRXLPP              (D0DRXLPP),
  .D0_DRXLPN              (D0DRXLPN),
  .D0_RXLPEN              (D0RXLPEN),
  .D0_DCDP                (D0DCDP),
  .D0_DCDN                (D0DCDN),
  .D0_CDEN                (D0CDEN),
  .D0_HS_DESER_EN         (D0HSDESEREN),
  .D0_HSRX_DATA           (D0HSRXDATA),
  .D0_HS_BYTE_CLKD        (D0HSBYTECLKD),
  .D0_SYNC                (D0SYNC),
  .D0_ERRSYNC             (D0ERRSYNC),
  .D0_NOSYNC              (D0NOSYNC),
 // DATA1 Interface pins
  .DP1                    (DP1),
  .DN1                    (DN1),
  .D1_RXHSEN              (D1RXHSEN),
  .D1_DRXLPP              (D1DRXLPP),
  .D1_DRXLPN              (D1DRXLPN),
  .D1_RXLPEN              (D1RXLPEN),
  .D1_HS_DESER_EN         (D1HSDESEREN),
  .D1_HSRX_DATA           (D1HSRXDATA),
  .D1_SYNC                (D1SYNC),
  .D1_ERRSYNC             (D1ERRSYNC),
  .D1_NOSYNC              (D1NOSYNC),
 // CLOCK Interface pins
  .CKP                    (CKP),
  .CKN                    (CKN),
  .CLK_RXHSEN             (CLKRXHSEN),
  .CLK_DRXLPP             (CLKDRXLPP),
  .CLK_DRXLPN             (CLKDRXLPN),
  .CLK_RXLPEN             (CLKRXLPEN),
  .CLK_HS_BYTE            (CLKHSBYTE)
  );

  
endmodule
