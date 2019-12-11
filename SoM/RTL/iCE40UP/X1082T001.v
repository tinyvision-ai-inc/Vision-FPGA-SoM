`timescale 1ps/100fs
module    X1082T001(
VDDA,
VSSA,
VDD,
VSS,
DVSS,
//Common Interface Pins
BITCLK,
PD,
LB_EN,
ROUT_CAL,
ENP_DESER,
PDCKG,
// DATA0 Interface pins
DP0,
DN0,
D0_OPMODE, // Input from digital to indicate mode of operation TX or RX
D0_DTXLPP,
D0_DTXLPN,
D0_TXLPEN,
D0_DRXLPP,
D0_DRXLPN,
D0_RXLPEN,
D0_DCDP,
D0_DCDN,
D0_CDEN,
//D0_DTXHS,
D0_TXHSPD,
D0_TXHSEN,
//D0_HS_BYTE_CLKS,  // Byteclk output from clock gen... Commented because we are going to mux it with D0_NOSYNC 
D0_HSTX_DATA,
D0_HS_SER_EN,
D0_RXHSEN,
//D0_RXHSTHDB,
D0_HS_DESER_EN,
D0_HSRX_DATA,
D0_HS_BYTE_CLKD, // Byteclk output from Lane0 deserializer
D0_SYNC,
D0_ERRSYNC,
//D0_NOSYNC,  Commented because we are going to mux it with D0_HS_BYTE_CLKS 
//D0_DRXHS,
D0_HS_BYTE_CLKS_NOSYNC, // This output will be D0_NOSYNC or D0_HS_BYTE_CLKS based on D0_OPMODE

// DATA1 Interface pins
DP1,
DN1,
D1_DTXLPP,
D1_DTXLPN,
D1_TXLPEN,
D1_DRXLPP,
D1_DRXLPN,
D1_RXLPEN,
D1_DCDP,
D1_DCDN,
D1_CDEN,
//D1_DTXHS,
D1_TXHSPD,
D1_TXHSEN,
D1_HSTX_DATA,
D1_HS_SER_EN,
D1_RXHSEN,
//D1_RXHSTHDB,
D1_HS_DESER_EN,
D1_HSRX_DATA,
D1_SYNC,
D1_ERRSYNC,
D1_NOSYNC,
//D1_DRXHS,

// DATA2 Interface pins
DP2,
DN2,
D2_DTXLPP,
D2_DTXLPN,
D2_TXLPEN,
D2_DRXLPP,
D2_DRXLPN,
D2_RXLPEN,
D2_DCDP,
D2_DCDN,
D2_CDEN,
//D2_DTXHS,
D2_TXHSPD,
D2_TXHSEN,
D2_HSTX_DATA,
D2_HS_SER_EN,
D2_RXHSEN,
//D2_RXHSTHDB,
D2_HS_DESER_EN,
D2_HSRX_DATA,
D2_SYNC,
D2_ERRSYNC,
D2_NOSYNC,
//D2_DRXHS,

// DATA3 Interface pins
DP3,
DN3,
D3_DTXLPP,
D3_DTXLPN,
D3_TXLPEN,
D3_DRXLPP,
D3_DRXLPN,
D3_RXLPEN,
D3_DCDP,
D3_DCDN,
D3_CDEN,
//D3_DTXHS,
D3_TXHSPD,
D3_TXHSEN,
D3_HSTX_DATA,
D3_HS_SER_EN,
D3_RXHSEN,
//D3_RXHSTHDB,
D3_HS_DESER_EN,
D3_HSRX_DATA,
D3_SYNC,
D3_ERRSYNC,
D3_NOSYNC,
//D1_DRXHS,

// CLOCK Interface pins
CKP,
CKN,
CLK_DTXLPP,
CLK_DTXLPN,
CLK_TXLPEN,
CLK_DRXLPP,
CLK_DRXLPN,
CLK_RXLPEN,
//CLK_DCDP,
//CLK_DCDN,
//CLK_CDEN,
CLK_TXHSPD,
CLK_TXHSEN,
CLK_TXHSGATE,
//CLK_DTXHS
CLK_RXHSEN,
//CLK_RXHSTHDB,
CLK_HS_BYTE
//CLK_DRXHS 
);
  
input           VDDA;
input           VSSA;
input           VDD;
input           VSS;
input           DVSS;
//Common Interface Pins
input           BITCLK;
input 		PD;
input		LB_EN;
input 	[1:0]	ROUT_CAL;
input 		ENP_DESER;
input           PDCKG;
// DATA0 Interface pins
inout		DP0;
inout		DN0;
input 		D0_OPMODE;
input 		D0_DTXLPP;
input 		D0_DTXLPN;
input  		D0_TXLPEN;
output 		D0_DRXLPP;
output  	D0_DRXLPN;
input 		D0_RXLPEN;
output 		D0_DCDP;
output		D0_DCDN;
input 		D0_CDEN;
//input           D0_DTXHS;
input  		D0_TXHSPD;
input 		D0_TXHSEN;
//output 		D0_HS_BYTE_CLKS; Commented because we are going to mux it with D0_NOSYNC
input    [7:0]  D0_HSTX_DATA;
input  		D0_HS_SER_EN;
input 		D0_RXHSEN;
//input 	  D0_RXHSTHDB;
input  		D0_HS_DESER_EN;
output 	 [7:0]	D0_HSRX_DATA;
output 		D0_HS_BYTE_CLKD;
output 		D0_SYNC;
output 		D0_ERRSYNC;
//output 		D0_NOSYNC; Commented because we are going to mux it with D0_HS_BYTE_CLKS, 
//output          D0_DRXHS;
output          D0_HS_BYTE_CLKS_NOSYNC;
// DATA1 Interface pins
inout		DP1;
inout		DN1;
input 		D1_DTXLPP;
input 		D1_DTXLPN;
input  		D1_TXLPEN;
output 		D1_DRXLPP;
output  	D1_DRXLPN;
input 		D1_RXLPEN;
output 		D1_DCDP;
output		D1_DCDN;
input 		D1_CDEN;
//input           D1_DTXHS;
input  		D1_TXHSPD;
input 		D1_TXHSEN; 
input    [7:0]  D1_HSTX_DATA;
input  		D1_HS_SER_EN;
input 		D1_RXHSEN;
//input 	  D1_RXHSTHDB;
input  		D1_HS_DESER_EN;
output 	 [7:0]	D1_HSRX_DATA;
output 		D1_SYNC;
output 		D1_ERRSYNC;
output 		D1_NOSYNC;
//output          D1_DRXHS;


// DATA2 Interface pins
inout		DP2;
inout		DN2;
input 		D2_DTXLPP;
input 		D2_DTXLPN;
input  		D2_TXLPEN;
output 		D2_DRXLPP;
output  	D2_DRXLPN;
input 		D2_RXLPEN;
output 		D2_DCDP;
output		D2_DCDN;
input 		D2_CDEN;
//input           D2_DTXHS;
input  		D2_TXHSPD;
input 		D2_TXHSEN; 
input    [7:0]  D2_HSTX_DATA;
input  		D2_HS_SER_EN;
input 		D2_RXHSEN;
//input 	  D2_RXHSTHDB;
input  		D2_HS_DESER_EN;
output 	 [7:0]	D2_HSRX_DATA;
output 		D2_SYNC;
output 		D2_ERRSYNC;
output 		D2_NOSYNC;
//output          D2_DRXHS;

// DATA3 Interface pins
inout		DP3;
inout		DN3;
input 		D3_DTXLPP;
input 		D3_DTXLPN;
input  		D3_TXLPEN;
output 		D3_DRXLPP;
output  	D3_DRXLPN;
input 		D3_RXLPEN;
output 		D3_DCDP;
output		D3_DCDN;
input 		D3_CDEN;
//input           D3_DTXHS;
input  		D3_TXHSPD;
input 		D3_TXHSEN; 
input    [7:0]  D3_HSTX_DATA;
input  		D3_HS_SER_EN;
input 		D3_RXHSEN;
//input 	  D3_RXHSTHDB;
input  		D3_HS_DESER_EN;
output 	 [7:0]	D3_HSRX_DATA;
output 		D3_SYNC;
output 		D3_ERRSYNC;
output 		D3_NOSYNC;
//output          D3_DRXHS;

// CLOCK Interface pins
inout		CKP;
inout		CKN;
input 		CLK_DTXLPP;
input 		CLK_DTXLPN;
input  		CLK_TXLPEN;
output  	CLK_DRXLPP;
output  	CLK_DRXLPN;
input  		CLK_RXLPEN;
//output  	  CLK_DCDP;
//output  	  CLK_DCDN;
//input  	  CLK_CDEN;
input  		CLK_TXHSPD;
input 		CLK_TXHSEN;
input           CLK_TXHSGATE;
//input           CLK_DTXHS;
input  		CLK_RXHSEN;
//input  	  CLK_RXHSTHDB;
output          CLK_HS_BYTE;
//output          CLK_DRXHS;

wire          hs_txclk;
wire          hs_ser_ld;
wire          hs_byte_clks;
wire          hs_rxclk;
wire          clk_dtxhs;
wire	      clk_drxhs;
wire          D0_HS_BYTE_CLKS;
wire          hs_txclk_int;
wire          hs_ser_ld_int;
wire          hs_byte_clks_int;
wire          clk_dtxhs_int; 

 MIPI_DATA_UNIV		        i_mipi_data0(
  .DP				          (DP0),
  .DN				          (DN0),
  .DTXLPP			          (D0_DTXLPP),
  .DTXLPN			          (D0_DTXLPN),
  .TXLPEN			          (D0_TXLPEN),
  .DRXLPP			          (D0_DRXLPP),
  .DRXLPN			          (D0_DRXLPN),
  .RXLPEN			          (D0_RXLPEN),
  .DCDP			                  (D0_DCDP),
  .DCDN			                  (D0_DCDN),
  .CDEN			                  (D0_CDEN),
  .DTXHS                                  (D1_DRXHS),
  .TXHSPD     		                  (D0_TXHSPD),
  .TXHSEN      		                  (D0_TXHSEN),
  .HS_BYTE_CLKS                           (hs_byte_clks),
  .HS_TXCLK                               (hs_txclk),
  .HSTX_DATA                              (D0_HSTX_DATA),
  .HS_SER_EN                              (D0_HS_SER_EN),
  .HS_SER_LD                              (hs_ser_ld),
  .RXHSEN			          (D0_RXHSEN),
//.RXHSTHDB			          (D0_RXHSTHDB),
  .HS_DESER_EN	      		          (D0_HS_DESER_EN),
  .HS_RXCLK			          (hs_rxclk),
  .HSRX_DATA		                  (D0_HSRX_DATA),
  .HS_BYTE_CLKD		                  (D0_HS_BYTE_CLKD),
  .SYNC			                  (D0_SYNC),
  .ERRSYNC			          (D0_ERRSYNC),
  .NOSYNC			          (D0_NOSYNC),
  .DRXHS             	                  (D0_DRXHS),
  .ENP                                    (ENP_DESER),
  .ROUT_CAL                               (ROUT_CAL),
  .LB_EN			          (LB_EN)
  ); 
 
 
  MIPI_DATA_UNIV		        i_mipi_data1(
  .DP				          (DP1),
  .DN				          (DN1),
  .DTXLPP			          (D1_DTXLPP),
  .DTXLPN			          (D1_DTXLPN),
  .TXLPEN			          (D1_TXLPEN),
  .DRXLPP			          (D1_DRXLPP),
  .DRXLPN			          (D1_DRXLPN),
  .RXLPEN			          (D1_RXLPEN),
  .DCDP			                  (D1_DCDP),
  .DCDN			                  (D1_DCDN),
  .CDEN			                  (D1_CDEN),
  .DTXHS                                  (D0_DRXHS),
  .TXHSPD     		                  (D1_TXHSPD),
  .TXHSEN      		                  (D1_TXHSEN),
  .HS_BYTE_CLKS                           (hs_byte_clks),
  .HS_TXCLK                               (hs_txclk),
  .HSTX_DATA                              (D1_HSTX_DATA),
  .HS_SER_EN                              (D1_HS_SER_EN),
  .HS_SER_LD                              (hs_ser_ld),
  .RXHSEN			          (D1_RXHSEN),
//.RXHSTHDB			          (D1_RXHSTHDB),
  .HS_DESER_EN	      		          (D1_HS_DESER_EN),
  .HS_RXCLK			          (hs_rxclk),
  .HSRX_DATA		                  (D1_HSRX_DATA),
  .HS_BYTE_CLKD  			  (),
  .SYNC			                  (D1_SYNC),
  .ERRSYNC			          (D1_ERRSYNC),
  .NOSYNC			          (D1_NOSYNC),
  .DRXHS             	                  (D1_DRXHS),
  .ENP                                    (ENP_DESER),
  .ROUT_CAL                               (ROUT_CAL),
  .LB_EN			          (LB_EN)
  ); 

  MIPI_DATA_UNIV		        i_mipi_data2(
  .DP				          (DP2),
  .DN				          (DN2),
  .DTXLPP			          (D2_DTXLPP),
  .DTXLPN			          (D2_DTXLPN),
  .TXLPEN			          (D2_TXLPEN),
  .DRXLPP			          (D2_DRXLPP),
  .DRXLPN			          (D2_DRXLPN),
  .RXLPEN			          (D2_RXLPEN),
  .DCDP			                  (D2_DCDP),
  .DCDN			                  (D2_DCDN),
  .CDEN			                  (D2_CDEN),
  .DTXHS                                  (D3_DRXHS),
  .TXHSPD     		                  (D2_TXHSPD),
  .TXHSEN      		                  (D2_TXHSEN),
  .HS_BYTE_CLKS                           (hs_byte_clks),
  .HS_TXCLK                               (hs_txclk),
  .HSTX_DATA                              (D2_HSTX_DATA),
  .HS_SER_EN                              (D2_HS_SER_EN),
  .HS_SER_LD                              (hs_ser_ld),
  .RXHSEN			          (D2_RXHSEN),
//.RXHSTHDB			          (D2_RXHSTHDB),
  .HS_DESER_EN	      		          (D2_HS_DESER_EN),
  .HS_RXCLK			          (hs_rxclk),
  .HSRX_DATA		                  (D2_HSRX_DATA),
  .HS_BYTE_CLKD  			  (),
  .SYNC			                  (D2_SYNC),
  .ERRSYNC			          (D2_ERRSYNC),
  .NOSYNC			          (D2_NOSYNC),
  .DRXHS             	                  (D2_DRXHS),
  .ENP                                    (ENP_DESER),
  .ROUT_CAL                               (ROUT_CAL),
  .LB_EN			          (LB_EN)
  );
  
  MIPI_DATA_UNIV		        i_mipi_data3(
  .DP				          (DP3),
  .DN				          (DN3),
  .DTXLPP			          (D3_DTXLPP),
  .DTXLPN			          (D3_DTXLPN),
  .TXLPEN			          (D3_TXLPEN),
  .DRXLPP			          (D3_DRXLPP),
  .DRXLPN			          (D3_DRXLPN),
  .RXLPEN			          (D3_RXLPEN),
  .DCDP			                  (D3_DCDP),
  .DCDN			                  (D3_DCDN),
  .CDEN			                  (D3_CDEN),
  .DTXHS                                  (D2_DRXHS),
  .TXHSPD     		                  (D3_TXHSPD),
  .TXHSEN      		                  (D3_TXHSEN),
  .HS_BYTE_CLKS                           (hs_byte_clks),
  .HS_TXCLK                               (hs_txclk),
  .HSTX_DATA                              (D3_HSTX_DATA),
  .HS_SER_EN                              (D3_HS_SER_EN),
  .HS_SER_LD                              (hs_ser_ld),
  .RXHSEN			          (D3_RXHSEN),
//.RXHSTHDB			          (D3_RXHSTHDB),
  .HS_DESER_EN	      		          (D3_HS_DESER_EN),
  .HS_RXCLK			          (hs_rxclk),
  .HSRX_DATA		                  (D3_HSRX_DATA),
  .HS_BYTE_CLKD  			  (),
  .SYNC			                  (D3_SYNC),
  .ERRSYNC			          (D3_ERRSYNC),
  .NOSYNC			          (D3_NOSYNC),
  .DRXHS             	                  (D3_DRXHS),
  .ENP                                    (ENP_DESER),
  .ROUT_CAL                               (ROUT_CAL),
  .LB_EN			          (LB_EN)
  );
 
  MIPI_CLOCK_UNIV 		        i_mipi_clock(
  .DP				          (CKP),
  .DN				          (CKN),
  .DTXLPP			          (CLK_DTXLPP),
  .DTXLPN			          (CLK_DTXLPN),
  .TXLPEN			          (CLK_TXLPEN),
  .DRXLPP			          (CLK_DRXLPP),
  .DRXLPN			          (CLK_DRXLPN),
  .RXLPEN			          (CLK_RXLPEN),
  //.DCDP			            (CLK_DCDP),
  //.DCDN			            (CLK_DCDN),
  //.CDEN			            (CLK_CDEN), 
  .DTXHS              	                  (),
  .DTXHS_RS           	                  (clk_dtxhs),  
  .TXHSPD                                 (CLK_TXHSPD),
  .TXHSEN                                 (CLK_TXHSEN),  
  .TXHSGATE                               (CLK_TXHSGATE),
  .RXHSEN			          (CLK_RXHSEN),
  //.RXHSTHDB			          (CLK_RXHSTHDB),
  .HS_DESER_EN		                  (1'b0),
  .DRXHS			          (clk_drxhs),
  .HS_RXCLK			          (hs_rxclk),
  .HSRX_DATA		                  (),
  .SYNC			                  (),
  .ERRSYNC			          (),
  .NOSYNC			          (),
  .BYTECLK            	          	  (CLK_HS_BYTE),
  .ENP                	          	  (1'b1),  
  .ROUT_CAL           	          	  (ROUT_CAL),
  .LB_EN              	          	  (1'b0)
  );

CLOCKGEN      		       i_clock_gen(
  .CLKIN			          (BITCLK),
  .BitClk			          (hs_txclk_int),
  .ByteClk			          (hs_byte_clks_int),
  .DDRClk              	          	  (clk_dtxhs_int),			
  .Load             	  		  (hs_ser_ld_int)
);

assign D0_HS_BYTE_CLKS = ~hs_byte_clks_int;
// Gate outputs of clockgen with PDCKG signal, but keep D0_HS_BYTE_CLKS going to digital
assign hs_txclk = ~PDCKG & hs_txclk_int;
assign hs_byte_clks = ~PDCKG & hs_byte_clks_int;
assign clk_dtxhs = ~PDCKG & clk_dtxhs_int;
assign hs_ser_ld = ~PDCKG & hs_ser_ld_int;
assign hs_rxclk =  clk_drxhs;
// We are in TX mode when D0_OPMODE is zero
assign D0_HS_BYTE_CLKS_NOSYNC = D0_OPMODE ? D0_NOSYNC : D0_HS_BYTE_CLKS;
endmodule // 
