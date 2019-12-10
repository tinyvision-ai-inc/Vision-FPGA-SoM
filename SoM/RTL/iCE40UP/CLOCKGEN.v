`timescale 1ps/100fs
module CLOCKGEN (
  CLKIN,
  BitClk,
  ByteClk,
  DDRClk,
  Load
);
input     CLKIN;
output    BitClk;
output    ByteClk;
output    Load;
output    DDRClk;

reg                 q0;
reg                 q1;
reg                 q2;
reg                 q3;
reg                 cnt;
reg                 DDRClk;
reg                 DDRClki;

wire                Load;
wire                BitClkb;

initial
  begin
    q0  = 1'b0;
    q1  = 1'b0;
    q2  = 1'b0;
    q3  = 1'b0;
  end



assign BitClk  = CLKIN;
assign BitClkb = ~CLKIN;

// Byte clock and Load
always @ (posedge BitClkb)
  begin
    q0 <= ~q3;
    q1 <=  q0;
    q2 <=  q1;
    q3 <=  q2;
  end
  
  assign Load = q0 & q3;
  assign ByteClk = q0;

// DDR Clock
always @ (posedge Load)
  begin
    cnt <= 1'b1;
  end
always @ (posedge BitClkb)
  begin
    if (cnt == 1'b1)
      begin
          DDRClki <= ~DDRClki;
          DDRClk  <= DDRClki;
      end
    else 
      begin 
        DDRClki = 0;
        DDRClk  = 0;
      end
  end  
  
endmodule
