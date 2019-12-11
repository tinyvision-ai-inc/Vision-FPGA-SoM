`timescale 1ps/1ps
module I2C_FIFO (
input  CLKI,
input  CSI,
input  WEI,
input  STBI,
input  ADRI3,
input  ADRI2,
input  ADRI1,
input  ADRI0,
input  DATI0,
input  DATI1,
input  DATI2,
input  DATI3,
input  DATI4,
input  DATI5,
input  DATI6,
input  DATI7,
input  DATI8,
input  DATI9,
input  SCLI,
input  SDAI,
input  FIFORST,

output DATO0,
output DATO1,
output DATO2,
output DATO3,
output DATO4,
output DATO5,
output DATO6,
output DATO7,
output DATO8,
output DATO9,
output ACKO,
output I2CIRQ,
output I2CWKUP,
inout SCLO,
output SCLOE,
output SDAO,
output SDAOE,
output SRWO,
output	TXFIFOAEMPTY,
output	TXFIFOEMPTY,
output	TXFIFOFULL,
output	RXFIFOAFULL,
output	RXFIFOFULL,
output	RXFIFOEMPTY,
output MRDCMPL);


  parameter I2C_SLAVE_ADDR = "0b1111100001";
  //parameter BUS_ADDR74 = "0b0001";


wire master, slave;
assign (weak0, weak1) DATI0 =1'b0 ;
assign (weak0, weak1) DATI1 =1'b0 ;
assign (weak0, weak1) DATI2 =1'b0 ;
assign (weak0, weak1) DATI3 =1'b0 ;
assign (weak0, weak1) DATI4 =1'b0 ;
assign (weak0, weak1) DATI5 =1'b0 ;
assign (weak0, weak1) DATI6 =1'b0 ;
assign (weak0, weak1) DATI7 =1'b0 ;
assign (weak0, weak1) DATI8 =1'b0 ;
assign (weak0, weak1) DATI9 =1'b0 ;



I2C_FIFO_CORE inst (
 	.CLKI(CLKI),
	.CSI(CSI),
 	.WEI(WEI),
 	.STBI(STBI),
 	.ADRI3(ADRI3),
 	.ADRI2(ADRI2),
 	.ADRI1(ADRI1),
 	.ADRI0(ADRI0),
	.DATI9(DATI9),
 	.DATI8(DATI8),
 	.DATI7(DATI7),
 	.DATI6(DATI6),
 	.DATI5(DATI5),
 	.DATI4(DATI4),
 	.DATI3(DATI3),
 	.DATI2(DATI2),
 	.DATI1(DATI1),
 	.DATI0(DATI0),
 	.SCLI(SCLI),
 	.SDAI(SDAI),
	.FIFORST(FIFORST),

	.DATO9(DATO9),
	.DATO8(DATO8),
	.DATO7(DATO7),
	.DATO6(DATO6),
	.DATO5(DATO5),
	.DATO4(DATO4),
	.DATO3(DATO3),
	.DATO2(DATO2),
	.DATO1(DATO1),
	.DATO0(DATO0),
	.ACKO(ACKO),
	.I2CIRQ(I2CIRQ),
	.I2CWKUP(I2CWKUP),
	.SCLO(SCLO),
	.SCLOE(SCLOE),
	.SDAO(SDAO),
	.SDAOE(SDAOE),
	.SRWO(SRWO),
  .TXFIFOAEMPTY(TXFIFOAEMPTY),
  .TXFIFOEMPTY(TXFIFOEMPTY),
  .TXFIFOFULL(TXFIFOFULL),
  .RXFIFOEMPTY(RXFIFOEMPTY),
  .RXFIFOAFULL(RXFIFOAFULL),
  .RXFIFOFULL(RXFIFOFULL),
	.MRDCMPL(MRDCMPL));
  defparam inst.I2C_SLAVE_ADDR = I2C_SLAVE_ADDR;

  //defparam inst.BUS_ADDR74 = BUS_ADDR74;

// initial begin
	// if (BUS_ADDR74!="0b0001" && BUS_ADDR74!="0b0011")
// $display ("ID:BUS_ADDR74: should be LLC=0b0001 or LRC=0b0011, otherwise there would be an error ");
// end



endmodule
