`timescale 1 ns / 1 ps
module I2C_FIFO_CORE (
  CLKI,
  CSI,
  WEI,
  STBI,
  ADRI3,
  ADRI2,
  ADRI1,
  ADRI0,
  DATI0,
  DATI1,
  DATI2,
  DATI3,
  DATI4,
  DATI5,
  DATI6,
  DATI7,
  DATI8,
  DATI9,
  SCLI,
  SDAI,
  FIFORST,

 DATO0,
 DATO1,
 DATO2,
 DATO3,
 DATO4,
 DATO5,
 DATO6,
 DATO7,
 DATO8,
 DATO9,
 ACKO,
 I2CIRQ,
 I2CWKUP,
 SCLO,
 SCLOE,
 SDAO,
 SDAOE,
 SRWO,
	TXFIFOAEMPTY,
	TXFIFOEMPTY,
	TXFIFOFULL,
	RXFIFOAFULL,
	RXFIFOFULL,
	RXFIFOEMPTY,
 MRDCMPL
);
input  CLKI;
input  CSI;
input  WEI;
input  STBI;
input  ADRI3;
input  ADRI2;
input  ADRI1;
input  ADRI0;
input  DATI0;
input  DATI1;
input  DATI2;
input  DATI3;
input  DATI4;
input  DATI5;
input  DATI6;
input  DATI7;
input  DATI8;
input  DATI9;
input  SCLI;
input  SDAI;
input  FIFORST;

output DATO0;
output DATO1;
output DATO2;
output DATO3;
output DATO4;
output DATO5;
output DATO6;
output DATO7;
output DATO8;
output DATO9;
output ACKO;
output I2CIRQ;
output I2CWKUP;
output SCLO;
output SCLOE;
output SDAO;
output SDAOE;
output SRWO;
output	TXFIFOAEMPTY;
output	TXFIFOEMPTY;
output	TXFIFOFULL;
output	RXFIFOAFULL;
output	RXFIFOFULL;
output	RXFIFOEMPTY;
output MRDCMPL;

  parameter I2C_SLAVE_ADDR = "0b1111100001";
  //parameter BUS_ADDR74 = "0b0001";

wire [3:0] adr_i = {ADRI3, ADRI2, ADRI1, ADRI0};
wire [9:0] dat_i = {DATI9, DATI8,DATI7, DATI6, DATI5, DATI4, DATI3, DATI2, DATI1, DATI0};
wire [9:0] dat_o;
assign {DATO9, DATO8,DATO7, DATO6, DATO5, DATO4,DATO3, DATO2, DATO1, DATO0} = dat_o;
wire scan_test_mode = 1'b0;
reg i2c_rst_async;

initial
begin
   i2c_rst_async = 1'b1;
#100
   i2c_rst_async = 1'b0;
end

function [4:1] str2bin_4 (input [(4+2)*8-1:0] binstr);
   integer i, j;
   reg [1:8] ch;
   begin
      for (i=4; i>=1; i=i-1)
      begin
      for (j=1; j<=8; j=j+1)
         ch[j] = binstr[i*8-j];
      case (ch)
         "0" : str2bin_4[i] = 1'b0;
         "1" : str2bin_4[i] = 1'b1;
         default: str2bin_4[i] = 1'bx;
      endcase
      end
    end
  endfunction

function [10:1] str2bin_10 (input [(10+2)*8-1:0] binstr);
   integer i, j;
   reg [1:8] ch;
   begin
      for (i=10; i>=1; i=i-1)
      begin
      for (j=1; j<=8; j=j+1)
         ch[j] = binstr[i*8-j];
      case (ch)
         "0" : str2bin_10[i] = 1'b0;
         "1" : str2bin_10[i] = 1'b1;
         default: str2bin_10[i] = 1'bx;
      endcase
      end
    end
  endfunction

wire [9:0] slave_init_addr = str2bin_10(I2C_SLAVE_ADDR);
//wire [3:0] SB_ID = str2bin_4(BUS_ADDR74);

wire [7:0] I2CCR1, I2CCMDR, I2CBRLSB, I2CBRMSB, I2CSR, I2CTXDR;
wire [7:0] I2CRXDR, I2CGCDR, I2CINTCR, I2CINTSR, I2CSADDR;
wire [9:0] I2CFIFOTHRESHOLD,I2CFIFOTXCNT, I2CFIFORXCNT;
assign I2CCR1 = i2c_ip_inst.i2cfifo_sci_inst.i2ccr1;
assign I2CCMDR = i2c_ip_inst.i2cfifo_sci_inst.i2ccmdr;
assign I2CBRLSB = i2c_ip_inst.i2cfifo_sci_inst.i2cbrlsb;
assign I2CBRMSB = i2c_ip_inst.i2cfifo_sci_inst.i2cbrmsb;
assign I2CSR = i2c_ip_inst.i2cfifo_sci_inst.i2csr;
assign I2CTXDR = i2c_ip_inst.i2cfifo_sci_inst.i2ctxdr;
assign I2CRXDR = i2c_ip_inst.i2cfifo_sci_inst.i2crxdr;
assign I2CGCDR = i2c_ip_inst.i2cfifo_sci_inst.i2cgcdr;
assign I2CINTCR = i2c_ip_inst.i2cfifo_sci_inst.i2cintcr;
assign I2CINTSR = i2c_ip_inst.i2cfifo_sci_inst.i2cintsr_rd;
assign I2CSADDR = i2c_ip_inst.i2cfifo_sci_inst.i2csaddr;
assign I2CFIFOTHRESHOLD = i2c_ip_inst.i2cfifo_sci_inst.i2cfifothreshold;
//assign I2CFIFOTXCNT = i2c_ip_inst.i2cfifo_sci_inst.i2cfifotxcnt;
//assign I2CFIFORXCNT = i2c_ip_inst.i2cfifo_sci_inst.i2cfiforxcnt;


i2cfifo_ip i2c_ip_inst (
  .cs_i(CSI),
  .sda_out(SDAO),
  .sda_oe(SDAOE),
  .scl_out(SCLO),
  .scl_oe(SCLOE),
  .dat_o(dat_o),
  .ack_o(ACKO),
  .irq(I2CIRQ),
  .i2c_wkup(I2CWKUP),
 // .ID(ID),
  .ADDR_LSB_USR(slave_init_addr[1:0]),
  .i2c_rst_async(i2c_rst_async),
  .sda_in(SDAI),
  .scl_in(SCLI),
  .del_clk(CLKI),
  .clk_i(CLKI),
  .we_i(WEI),
  .stb_i(STBI),
  .adr_i(adr_i),
  .dat_i(dat_i),
  .scan_test_mode(scan_test_mode),
  .fifo_rst(FIFORST),
  .txfifo_ae(TXFIFOAEMPTY),
  .txfifo_e(TXFIFOEMPTY),
  .txfifo_f(TXFIFOFULL),
  .rxfifo_e(RXFIFOEMPTY),
  .rxfifo_af(RXFIFOAFULL),
  .rxfifo_f(RXFIFOFULL),
  .mrdcmpl(MRDCMPL),
  .srdwr(SRWO)
  );

endmodule
