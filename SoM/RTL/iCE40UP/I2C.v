`timescale 1 ns / 1 ps
module I2C (
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
input  SCLI,
input  SDAI,

output SBDATO7,
output SBDATO6,
output SBDATO5,
output SBDATO4,
output SBDATO3,
output SBDATO2,
output SBDATO1,
output SBDATO0,
output SBACKO,
output I2CIRQ,
output I2CWKUP,
inout SCLO,
output SCLOE,
output SDAO,
output SDAOE);


  parameter I2C_SLAVE_INIT_ADDR = 10'b1111100001;
  parameter BUS_ADDR74 = 4'b0001;
  parameter delay50=50000;
  
  //To keep it 1:1 with Device Model
  parameter I2C_CLK_DIVIDER = 0; 
  parameter SDA_INPUT_DELAYED = 0;
  parameter SDA_OUTPUT_DELAYED = 0;
  parameter FREQUENCY_PIN_SBCLKI = "NONE";
wire master, slave;

I2C_CORE inst (
 	//.SBCLKI(sbClkOut),
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
 	.SCLI(SCLI),
 	//.SDAI(SDAI_D),
 	.SDAI(SDAI),

	.SBDATO7(SBDATO7),
	.SBDATO6(SBDATO6),
	.SBDATO5(SBDATO5),
	.SBDATO4(SBDATO4),
	.SBDATO3(SBDATO3),
	.SBDATO2(SBDATO2),
	.SBDATO1(SBDATO1),
	.SBDATO0(SBDATO0),
	.SBACKO(SBACKO),
	.I2CIRQ(I2CIRQ),
	.I2CWKUP(I2CWKUP),
	.SCLO(SCLO),
	.SCLOE(SCLOE),
	//.SDAO(SDAO_CORE),
	.SDAO(SDAO),
	.SDAOE(SDAOE));
  defparam inst.I2C_SLAVE_INIT_ADDR = I2C_SLAVE_INIT_ADDR;
  defparam inst.BUS_ADDR74 = BUS_ADDR74;

initial begin
	if (BUS_ADDR74!=4'b0001 && BUS_ADDR74!=4'b0011)
$display ("ID:BUS_ADDR74: should be LLC=0b0001 or LRC=0b0011, otherwise there would be an error ");
end
// always @ (SDAI) 
	// begin
		// SDAI_D <= #delay50 SDAI;
	// end	 


endmodule
