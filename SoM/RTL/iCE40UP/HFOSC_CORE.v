`timescale 1 ns / 1 ps
module HFOSC_CORE (CLKHF_PU,CLKHF_EN, CLKHF);
  
  input  CLKHF_PU,CLKHF_EN;
  output CLKHF;
  parameter CLKHF_DIV = 2'b00;
  reg OSCm;
  realtime half_clk;
  reg ena_q1, ena_q2, last_OSCb;
  wire OSCb, osc_en, ena_d2;
  reg div2, div4, div8, div1;
  initial
  begin
     OSCm = 1'b0;
     ena_q1 = 1'b0;
     ena_q2 = 1'b0;
     half_clk = 10.416;
     last_OSCb = 1'b0;
	 div2 = 0;
     div4 = 0;
     div8 = 0;
     div1 = 0;
  end

  always @ (OSCb)
  begin
     last_OSCb <= OSCb;
  end

  always @(OSCb)
  begin
     if (OSCb === 1'b1 && last_OSCb === 1'b0)
        ena_q1 <= CLKHF_PU;
  end

  always @(OSCb)
  begin
     if (OSCb === 1'b0 && last_OSCb === 1'b1)
        ena_q2 <= ena_d2;
  end

assign osc_en = ena_q2 | CLKHF_PU;
assign ena_d2 = CLKHF_PU | ena_q1;

  always @ (osc_en, OSCm)
  begin
     if (~osc_en)
     begin
        OSCm <= 1'b0;
		div1 <=1'b0;
     end
     else
     begin
        #(half_clk)
        OSCm <= ~OSCm;
		div1<=~div1;
     end
  end

assign OSCb = OSCm & osc_en;

assign CLKHF = (CLKHF_EN==1'b0)? 1'b0 : (CLKHF_DIV==2'b00)? div1:	(CLKHF_DIV==2'b01)? div2: (CLKHF_DIV==2'b10)? div4 : (CLKHF_DIV==2'b11)? div8: 1'b0;



always @(posedge OSCb, negedge osc_en)
begin
   if (osc_en == 1'b0)
      div2 <= 1'b0;
   else
      div2 <= ~div2;
end

always @(posedge div2, negedge osc_en)
begin
   if (osc_en == 1'b0)
      div4 <= 1'b0;
   else
      div4 <= ~div4;
end

always @(posedge div4, negedge osc_en)
begin
   if (osc_en == 1'b0)
      div8 <= 1'b0;
   else
      div8 <= ~div8;
end


endmodule
