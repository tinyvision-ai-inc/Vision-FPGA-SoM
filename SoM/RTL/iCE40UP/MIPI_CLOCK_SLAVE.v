`timescale 1ps/100fs
module MIPI_CLOCK_SLAVE (
  DP,
  DN,
  RXHSEN,
  //RXHSTHDB,
  DRXLPP,
  DRXLPN,
  RXLPEN,
  //DCDP,
  //DCDN,
 // CDEN,
  HS_DESER_EN,
  DRXHS,
  HS_RXCLK,
  HSRX_DATA,
  SYNC,
  ERRSYNC,
  NOSYNC,
  BYTECLK,
  ENP,
  RXHSTHDB
 // LB_EN
  );

  inout 	             DP;	          // Positive Data signal, bidirectional.
  inout 	             DN;	          // Negative Data signal, bidirectional.
  
  // HS-RX
  input 	             RXHSEN;       // High Speed Receiver Enable Signal.
  //input               RXHSTHDB;
  
  // Deserializer
  parameter           WIDTH=8;  
  output [WIDTH-1:0]  HSRX_DATA;    // 8-bit high speed data received.
  output              SYNC;         // High speed SoT leader properly synchronized.
  output              ERRSYNC;      // High speed SoT leader synchronized with single bit error.
  output              NOSYNC;       // High speed SoT leader is corrupted and synchronization not achieved.
  input               HS_DESER_EN;  // Deserializer enable. Active high.
  output              DRXHS; // When high polarity of RX signal is swapped. Default is low.
  input               HS_RXCLK;     // High speed RX clock.
  // LP-RX
  output              DRXLPP;       // Low Power Receiver Positive Data Output.
  input 	             RXLPEN;       // Low Power Receiver Enable Signal.
  output              DRXLPN;       // Low Power Receiver Negative Data Output.
  // LP-CD
  //output              DCDP;	        // Low Power Contention Detector Positive Output.
  //input 	             CDEN;         // Low Power Contention Detector Enable Signal.
 // output              DCDN;	        // Low Power Contention Detector Negative Output.
  
  output              BYTECLK; // Byteclk for Slave CIL 
  
  input               ENP;
  output              RXHSTHDB;
 // input               LB_EN;
 
  wire		DP;
  wire		DN;
  wire		DRXHSP;
  wire		DRXHSN;
  wire  DRXHS;
  wire		DRXLPP;
  wire		DRXLPN;
  wire		DCDP;
  wire		DCDN;
  
  //reg   clkd2;
  //reg   clkd4;
  wire  enp_int;
  reg        diff_mode;
  reg [5:0]  shift_reg;
  wire       COMPARE;
  wire       stop;
  wire       RXHSTHDB;
  wire       CDEN;
  reg        rx_hs_tem;

  assign CDEN = ~RXHSEN;
  
  always @ (negedge DCDN or posedge DRXLPP)
  begin
    if (DRXLPP)
      rx_hs_tem <= 1'b0;
    else
      rx_hs_tem <= 1'b1;
  end
  
  assign RXHSTHDB = ~rx_hs_tem;

  
 // always @ ( stop or DP or DN or DCDN)
//  begin
//    if (stop)
//      rx_hs_tem = 1'b0;
//    else if (~diff_mode)
//      rx_hs_tem = ~DCDN;
//  end 
  
//  assign RXHSTHDB = ~rx_hs_tem;
  
  // HS-RX
  assign	 DRXHSP =  (RXHSEN & ~RXHSTHDB)  ? DP : 1'b0;
  assign	 DRXHSN =  (RXHSEN & ~RXHSTHDB)  ? DN : 1'b1;

   // LP-RX
  assign 	DRXLPP =  (RXLPEN & ~diff_mode)  ? DP : 1'b0;
  assign 	DRXLPN =  (RXLPEN & ~diff_mode)  ? DN : 1'b0;
  
  initial
    begin
    diff_mode = 1'b0;
  end

  always @(RXLPEN or DP or DN )
    begin
      if (DP & DN)
        shift_reg = 6'b000011;
      else
        shift_reg <= {shift_reg[3:0], DP, DN};
    end 
  assign COMPARE = (shift_reg == 6'b110100);
  
  assign stop = (~(DP ^ DN)) & DP & DN;
  
  always @(posedge COMPARE or posedge stop)
    begin 
      if (DP & DN)
        diff_mode = 1'b0;
      else 
        diff_mode = 1'b1;
    end
    
  // LP-CD
  assign	 DCDP   =  CDEN & (DP !== 1'bX) & DP;
  assign 	DCDN   =  CDEN & (DN !== 1'bX) & DN;
  
  assign  DRXHS  =  DRXHSP;

assign enp_int = ENP & RXHSEN;
mipi_deserializer       deserializer(
   .RxDDRClkHS            (HS_RXCLK),
   .DRXHSP                (DRXHSP),
   .HS_DESER_EN           (HS_DESER_EN),
   .HSRX_DATA             (HSRX_DATA),
   .HS_BYTE_CLKD          (HS_BYTE_CLKD),
   .SYNC                  (SYNC),
   .ERRSYNC               (ERRSYNC),
   .NOSYNC                (NOSYNC),
   .ENP                   (enp_int) 
);

assign BYTECLK = HS_BYTE_CLKD;
//assign BYTECLK = clkd4;
//  always @ (posedge DRXHSP or negedge RXHSEN )
//    begin
//      if (~RXHSEN)
//         clkd2 <= 1'b0;
//      else
//          clkd2 <= ~clkd2;
//    end
//   
//    always @ (posedge clkd2 or negedge RXHSEN )
//    begin
//      if (~RXHSEN)
//         clkd4 <= 1'b0;
//      else
//          clkd4 <= ~clkd4;
//    end

endmodule // MIPI_DATA1
