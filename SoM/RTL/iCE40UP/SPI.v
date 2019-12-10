`timescale 1 ns / 1 ps
module SPI (
input  SBCLKI,
input  SBRWI,				   
input  SBSTBI,
input  SBADRI7,
input  SBADRI6,
input  SBADRI5,
input  SBADRI4,
input  SBADRI3,
input  SBADRI2,
input  SBADRI1,
input  SBADRI0,
input  SBDATI7,
input  SBDATI6,
input  SBDATI5,
input  SBDATI4,
input  SBDATI3,
input  SBDATI2,
input  SBDATI1,
input  SBDATI0,
input  MI,
input  SI,
input  SCKI,
input  SCSNI,

output SBDATO7,
output SBDATO6,
output SBDATO5,
output SBDATO4,
output SBDATO3,
output SBDATO2,
output SBDATO1,
output SBDATO0,
output SBACKO,
output SPIIRQ,
output SPIWKUP,
output SO,
output SOE,
output MO,
output MOE,
inout SCKO,
output SCKOE,
output MCSNO3,
output MCSNO2,
output MCSNO1,
output MCSNO0,
output MCSNOE3,
output MCSNOE2,
output MCSNOE1,
output MCSNOE0);

parameter BUS_ADDR74 = 4'b0000;
parameter SPI_CLK_DIVIDER = 0;
parameter FREQUENCY_PIN_SBCLKI = "NONE";

reg sbClkOut;
reg counter;


initial begin
        if (SBCLKI === 1'b1 || SBCLKI === 1'b0) begin
            sbClkOut = SBCLKI;
        end else begin
            sbClkOut = 1'b0;
        end
        counter = 0;
end


always @(posedge SBCLKI) begin
        counter <= counter + 1;
        if (counter === SPI_CLK_DIVIDER) begin
                counter <= 0;
                sbClkOut <= !sbClkOut;
        end

end

SPI_CORE inst (
	.SBCLKI(SBCLKI),
	.SBRWI(SBRWI),
	.SBSTBI(SBSTBI),
	.SBADRI7(SBADRI7),
	.SBADRI6(SBADRI6),
	.SBADRI5(SBADRI5),
	.SBADRI4(SBADRI4),
	.SBADRI3(SBADRI3),
	.SBADRI2(SBADRI2),
	.SBADRI1(SBADRI1),
	.SBADRI0(SBADRI0),
	.SBDATI7(SBDATI7),
	.SBDATI6(SBDATI6),
	.SBDATI5(SBDATI5),
	.SBDATI4(SBDATI4),
	.SBDATI3(SBDATI3),
	.SBDATI2(SBDATI2),
	.SBDATI1(SBDATI1),
	.SBDATI0(SBDATI0),
	.MI(MI),
	.SI(SI),
	.SCKI(SCKI),
	.SCSNI(SCSNI),

	.SBDATO7(SBDATO7),
	.SBDATO6(SBDATO6),
	.SBDATO5(SBDATO5),
	.SBDATO4(SBDATO4),
	.SBDATO3(SBDATO3),
	.SBDATO2(SBDATO2),
	.SBDATO1(SBDATO1),
	.SBDATO0(SBDATO0),
	.SBACKO(SBACKO),
	.SPIIRQ(SPIIRQ),
	.SPIWKUP(SPIWKUP),
	.SO(SO),
	.SOE(SOE),
	.MO(MO),
	.MOE(MOE),
	.SCKO(SCKO),
	.SCKOE(SCKOE),
	.MCSNO3(MCSNO3),
	.MCSNO2(MCSNO2),
	.MCSNO1(MCSNO1),
	.MCSNO0(MCSNO0),
	.MCSNOE3(MCSNOE3),
	.MCSNOE2(MCSNOE2),
	.MCSNOE1(MCSNOE1),
	.MCSNOE0(MCSNOE0));
defparam inst.BUS_ADDR74 = BUS_ADDR74;

initial begin
	if (BUS_ADDR74!=4'b0000 && BUS_ADDR74!=4'b0010)
$display ("ID:BUS_ADDR74: should be LLC=0b0000 or LRC=0b0010, otherwise there would be an error ");
end

endmodule
