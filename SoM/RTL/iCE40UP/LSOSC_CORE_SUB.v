`timescale 1 ns / 1 ps
module LSOSC_CORE_SUB (ENACLKK, CLKK);

  input  ENACLKK;
  output CLKK;

  reg OSCm;
  realtime half_clk;
  reg ena_q1, ena_q2;
  wire OSCb, osc_en, ena_d2;
  reg div2, div4, div8, div16, div32, div64, div128, last_div64;

  initial
  begin
     OSCm = 1'b0;
     ena_q1 = 1'b0;
     ena_q2 = 1'b0;
     half_clk = 781.2;
     div2 = 0;
     div4 = 0;
     div8 = 0;
     div16 = 0;
     div32 = 0;
     div64 = 0;
     div128 = 0;
     last_div64 = 0;
  end

  always @ (div64)
  begin
     last_div64 <= div64;
  end

  always @(div64)
  begin
     if (div64 === 1'b1 && last_div64 === 1'b0)
        ena_q1 <= ENACLKK;
  end

  always @(div64)
  begin
     if (div64 === 1'b0 && last_div64 === 1'b1)
        ena_q2 <= ena_d2;
  end

assign osc_en = ena_q2 | ENACLKK;
assign ena_d2 = ENACLKK | ena_q1;

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
assign CLKK = div64;

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

always @(posedge div8, negedge osc_en)
begin
   if (osc_en == 1'b0)
      div16 <= 1'b0;
   else
      div16 <= ~div16;
end

always @(posedge div16, negedge osc_en)
begin
   if (osc_en == 1'b0)
      div32 <= 1'b0;
   else
      div32 <= ~div32;
end

always @(posedge div32, negedge osc_en)
begin
   if (osc_en == 1'b0)
      div64 <= 1'b0;
   else
      div64 <= ~div64;
end

always @(posedge div64, negedge osc_en)
begin
   if (osc_en == 1'b0)
      div128 <= 1'b0;
   else
      div128 <= ~div128;
end

endmodule
