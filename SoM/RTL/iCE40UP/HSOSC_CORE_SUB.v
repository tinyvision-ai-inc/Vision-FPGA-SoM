`timescale 1 ns / 1 ps
module HSOSC_CORE_SUB (ENACLKM, CLKM);

  input  ENACLKM;
  output CLKM;

  reg OSCm;
  realtime half_clk;
  reg ena_q1, ena_q2, last_OSCb;
  wire OSCb, osc_en, ena_d2;

  initial
  begin
     OSCm = 1'b0;
     ena_q1 = 1'b0;
     ena_q2 = 1'b0;
     half_clk = 41.66;
     last_OSCb = 1'b0;
  end

  always @ (OSCb)
  begin
     last_OSCb <= OSCb;
  end

  always @(OSCb)
  begin
     if (OSCb === 1'b1 && last_OSCb === 1'b0)
        ena_q1 <= ENACLKM;
  end

  always @(OSCb)
  begin
     if (OSCb === 1'b0 && last_OSCb === 1'b1)
        ena_q2 <= ena_d2;
  end

assign osc_en = ena_q2 | ENACLKM;
assign ena_d2 = ENACLKM | ena_q1;

  always @ (osc_en, OSCm)
  begin
     if (~osc_en)
     begin
        OSCm <= 1'b0;
     end
     else
     begin
        #(half_clk)
        OSCm <= ~OSCm;
     end
  end

assign OSCb = OSCm & osc_en;
assign CLKM = OSCb;

endmodule
