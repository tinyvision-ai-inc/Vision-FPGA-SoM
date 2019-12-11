`timescale 1ps/100fs
module mipi_serializer (
  HS_BYTE_CLKS,
  HS_TXCLK,
  HSTX_DATA,
  HS_SER_EN,
  HS_SER_LD,
  TXHSPD,
  DTXHS
);
// inputs
parameter               WIDTH=8;
input                   HS_BYTE_CLKS;    
input                   HS_TXCLK;
input [WIDTH-1:0]       HSTX_DATA;
input                   HS_SER_EN;  // shift out the loaded value.
input                   HS_SER_LD;  // loads data value into register
input                   TXHSPD;     // NOT USED 
// outputs
output                  DTXHS;

// internal
reg  [WIDTH-1:0]        shift_reg;
reg  [WIDTH-1:0]        shift_ff;
reg                     DTXHS;


  // shift_reg takes the byte into the HS_TXCLKP domain
  //  and shifts the bits out.
  always @ (posedge HS_BYTE_CLKS)
    begin
    if (HS_SER_EN)
      shift_ff <= HSTX_DATA;
    else
      shift_ff <= {WIDTH{1'b0}}; // not enabled, register is cleared.
    end
  
  always @ (posedge HS_TXCLK)
    begin
      if (HS_SER_EN)
      begin
        if (HS_SER_LD)
          shift_reg <= shift_ff;
        else
          shift_reg <= {1'b0,shift_reg[WIDTH-1:1]};
      end
      else    // not enabled; clear register.
          shift_reg <= {WIDTH{1'b0}}; // any old value will due.
    end

//  assign DTXHS  = shift_reg[0];
  // a registered DTXHS helps with timing.
   always @ (posedge HS_TXCLK)
    begin
        if (HS_SER_EN)
          DTXHS <= shift_reg[0];
        else
          DTXHS <= 1'b0;
    end

endmodule // module hstx_serializer
