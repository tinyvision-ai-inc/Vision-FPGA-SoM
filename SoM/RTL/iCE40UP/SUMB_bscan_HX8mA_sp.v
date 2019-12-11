`timescale 1ns / 10ps 
module SUMB_bscan_HX8mA_sp ( DI, PAD, DO, REN, IE, VDDIO, OEN, PGATE, nor_in,
BSEN, POC );

  input DO;
  input OEN;
  output DI;
  input nor_in;
  input POC;
  input REN;
  input BSEN;
  input VDDIO;
  inout PAD;
  output PGATE;
  input IE;
  
  parameter PullTime = 100000 ;
 
  reg lastPAD, pull;
  //bufif1 (weak0,weak1) (C_buf, 1'b1, pull); //yn
  not    (RE, REN);
  //bufif0 (PAD, DO, OEN); //disable pullup here //yn
  nor (DO_OEN, DO, OEN); //yn
  bufif1 (PAD, 1'b0, DO_OEN); //yn
  pmos   (C_buf, PAD, 1'b0); //act as poly resistor

  buf    (PGATE, C_buf);
  or     (IE_BSEN, IE, BSEN);
  and     (C_buf1, C_buf, IE_BSEN);
  or     (DI, C_buf1, nor_in);
 
  always @(PAD or RE) begin

    if (PAD === 1'bx && !$test$plusargs("bus_conflict_off") &&
        $countdrivers(PAD))
       $display("%t ++BUS CONFLICT++ : %m", $realtime);

    if (PAD === 1'bz && RE) begin
       if (lastPAD === 1'b1) pull=1;
       else pull <= #PullTime 1;
    end
    else pull=0;

    lastPAD=PAD;

  end

  specify
    (DO => PAD)=(0, 0);
    (OEN => PAD)=(0, 0, 0, 0, 0, 0);
    (PAD => DI)=(0, 0);

    (PAD => PGATE)=(0, 0);
    (nor_in => DI)=(0, 0);
    (IE => DI)=(0, 0, 0, 0, 0, 0);
  endspecify

endmodule
