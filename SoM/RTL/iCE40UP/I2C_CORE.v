`timescale 1 ns / 1 ps
module I2C_CORE (
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
output SCLO,
output SCLOE,
output SDAO,
output SDAOE);


  parameter I2C_SLAVE_INIT_ADDR = 10'b1111100001;
  parameter BUS_ADDR74 = 4'b0001;

wire [7:0] sb_adr_i = {SBADRI7, SBADRI6, SBADRI5, SBADRI4, SBADRI3, SBADRI2, SBADRI1, SBADRI0};
wire [7:0] sb_dat_i = {SBDATI7, SBDATI6, SBDATI5, SBDATI4, SBDATI3, SBDATI2, SBDATI1, SBDATI0};
wire [7:0] sb_dat_o;
assign {SBDATO7, SBDATO6, SBDATO5, SBDATO4, SBDATO3, SBDATO2, SBDATO1, SBDATO0} = sb_dat_o;
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

//wire [9:0] slave_init_addr = str2bin_10(I2C_SLAVE_INIT_ADDR);
wire [9:0] slave_init_addr = I2C_SLAVE_INIT_ADDR;
//wire [3:0] SB_ID = str2bin_4(BUS_ADDR74);
wire [3:0] SB_ID = BUS_ADDR74;

wire [7:0] I2CCR1, I2CCMDR, I2CBRLSB, I2CBRMSB, I2CSR, I2CTXDR;
wire [7:0] I2CRXDR, I2CGCDR, I2CINTCR, I2CINTSR, I2CSADDR;

assign I2CCR1 = i2c_ip_inst.i2c_sci_inst.i2ccr1;
assign I2CCMDR = i2c_ip_inst.i2c_sci_inst.i2ccmdr;
assign I2CBRLSB = i2c_ip_inst.i2c_sci_inst.i2cbrlsb;
assign I2CBRMSB = i2c_ip_inst.i2c_sci_inst.i2cbrmsb;
assign I2CSR = i2c_ip_inst.i2c_sci_inst.i2csr;
assign I2CTXDR = i2c_ip_inst.i2c_sci_inst.i2ctxdr;
assign I2CRXDR = i2c_ip_inst.i2c_sci_inst.i2crxdr;
assign I2CGCDR = i2c_ip_inst.i2c_sci_inst.i2cgcdr;
assign I2CINTCR = i2c_ip_inst.i2c_sci_inst.i2cintcr;
//assign I2CINTSR = i2c_ip_inst.i2c_sci_inst.i2cintsr;
assign I2CINTSR = {{4{1'b0}},i2c_ip_inst.i2c_sci_inst.irq_arbl,i2c_ip_inst.i2c_sci_inst.irq_trrdy,i2c_ip_inst.i2c_sci_inst.irq_troe,i2c_ip_inst.i2c_sci_inst.irq_hgc};
assign I2CSADDR = i2c_ip_inst.i2c_sci_inst.i2csaddr;


i2c_ip i2c_ip_inst (
  .sda_out(SDAO),
  .sda_oe(SDAOE),
  .scl_out(SCLO),
  .scl_oe(SCLOE),
  .sb_dat_o(sb_dat_o),
  .sb_ack_o(SBACKO),
  .i2c_irq(I2CIRQ),
  .i2c_wkup(I2CWKUP),
  .SB_ID(SB_ID),
  .ADDR_LSB_USR(slave_init_addr[1:0]),
  .i2c_rst_async(i2c_rst_async),
  .sda_in(SDAI),
  .scl_in(SCLI),
  .del_clk(SBCLKI),
  .sb_clk_i(SBCLKI),
  .sb_we_i(SBRWI),
  .sb_stb_i(SBSTBI),
  .sb_adr_i(sb_adr_i),
  .sb_dat_i(sb_dat_i),
  .scan_test_mode(scan_test_mode)
  );

endmodule
