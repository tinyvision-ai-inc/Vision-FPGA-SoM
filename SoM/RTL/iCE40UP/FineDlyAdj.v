`timescale 1ps/1ps
module FineDlyAdj (DlyAdj, signalin, delayedout);
	input signalin;
	input [3:0] DlyAdj;
	output delayedout;
	parameter FIXED_DELAY_ADJUSTMENT = 4'b0000;
	parameter DELAY_ADJUSTMENT_MODE = "FIXED";
	wire delayedout;
	wire l2muxout;

	parameter BUF_DELAY = 150;
	parameter MUXINV_DELAY = 0; //100; Modified to make consistent with STA

wire [3:0] fixed_delay_adj = FIXED_DELAY_ADJUSTMENT;
wire [3:0] bufcntselector = (DELAY_ADJUSTMENT_MODE == "DYNAMIC")? DlyAdj : fixed_delay_adj;

initial
begin
  if (DELAY_ADJUSTMENT_MODE == "FIXED" && (FIXED_DELAY_ADJUSTMENT > 15 || FIXED_DELAY_ADJUSTMENT < 0))
     begin
	    $display ("************************SBT: ERROR ****************************");
	    $display ("Valid values for FIXED_DELAY_ADJUSTMENT parameter are 4'b0000 through 4'b1111");
	    $display ("Due to incorrect configuration of the PLL, the simulation results are invalid.");
	    $display ("**************************************************************");
	    $display ("Exiting simulation");
	    $finish;
	 end
    if ((DELAY_ADJUSTMENT_MODE == "DYNAMIC" && FIXED_DELAY_ADJUSTMENT != 0))
	 begin
	    $display ("************************SBT: Info*****************************");
	    $display ("Since DELAY_ADJUSTMENT_MODE=\"DYNAMIC\", parameter FIXED_DELAY_ADJUSTMENT will be ignored.");
	    $display ("Set FIXED_DELAY_ADJUSTMENT=0 to disable this message.");
	    $display ("**************************************************************");
	 end
end

Delay4Buf delay4bufinst1 (.a(signalin), .s(bufcntselector[1:0]), .delay4bufout(delay4bufout1), .muxinvout(muxinvout1));
defparam delay4bufinst1.BUF_DELAY = BUF_DELAY;
defparam delay4bufinst1.MUXINV_DELAY = MUXINV_DELAY;

Delay4Buf delay4bufinst2 (.a(delay4bufout1), .s(bufcntselector[1:0]), .delay4bufout(delay4bufout2), .muxinvout(muxinvout2));
defparam delay4bufinst2.BUF_DELAY = BUF_DELAY;
defparam delay4bufinst2.MUXINV_DELAY = MUXINV_DELAY;

Delay4Buf delay4bufinst3 (.a(delay4bufout2), .s(bufcntselector[1:0]), .delay4bufout(delay4bufout3), .muxinvout(muxinvout3));
defparam delay4bufinst3.BUF_DELAY = BUF_DELAY;
defparam delay4bufinst3.MUXINV_DELAY = MUXINV_DELAY;

Delay4Buf delay4bufinst4 (.a(delay4bufout3), .s(bufcntselector[1:0]), .delay4bufout(delay4bufout4), .muxinvout(muxinvout4));
defparam delay4bufinst4.BUF_DELAY = BUF_DELAY;
defparam delay4bufinst4.MUXINV_DELAY = MUXINV_DELAY;

mux4to1 level2muxinst (.a(muxinvout1), .b(muxinvout2), .c(muxinvout3), .d(muxinvout4), .select(bufcntselector[3:2]), .o(l2muxout));
not # MUXINV_DELAY level2invinst(delayedout, l2muxout);

endmodule	//FineDlyAdj
