`timescale 1 ns / 1 ps
module SPI_CORE (
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
output SCKO,
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

wire [7:0] sb_adr_i = {SBADRI7, SBADRI6, SBADRI5, SBADRI4, SBADRI3, SBADRI2, SBADRI1, SBADRI0};
wire [7:0] sb_dat_i = {SBDATI7, SBDATI6, SBDATI5, SBDATI4, SBDATI3, SBDATI2, SBDATI1, SBDATI0};
wire [7:0] sb_dat_o;
assign {SBDATO7, SBDATO6, SBDATO5, SBDATO4, SBDATO3, SBDATO2, SBDATO1, SBDATO0} = sb_dat_o;
wire MCSNO7;
wire MCSNO6;
wire MCSNO5;
wire MCSNO4;
wire MCSNOE7;
wire MCSNOE6;
wire MCSNOE5;
wire MCSNOE4;
wire [7:0] mcsn_o;
assign {MCSNO7, MCSNO6, MCSNO5, MCSNO4, MCSNO3, MCSNO2, MCSNO1, MCSNO0} = mcsn_o;
wire [7:0] mcsn_oe;
assign {MCSNOE7, MCSNOE6, MCSNOE5, MCSNOE4, MCSNOE3, MCSNOE2, MCSNOE1, MCSNOE0} = mcsn_oe;
wire scan_test_mode = 1'b0;
reg spi_rst_async;
wire unused;

initial
begin
   spi_rst_async = 1'b1;
#100
   spi_rst_async = 1'b0;
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

//wire [3:0] SB_ID = str2bin_4(BUS_ADDR74);
wire [3:0] SB_ID = BUS_ADDR74; //conversion done at SPIA level 
wire [7:0] SPICR0, SPICR1, SPICR2, SPIBR, SPISR, SPITXDR, SPIRXDR;
wire [7:0] SPICSR, SPIINTCR, SPIINTSR;

initial begin
  if (SB_ID!=4'b0000 && SB_ID!=4'b0010) begin
    $display ("Warning! In module SPI_CORE. Expected converted attribute BUS_ADDR74 to actual binary number (0 or 2). Instantiate SPIA rather than calling SPI.");
  end 
end


assign SPICR0 = spi_ip_inst.spi_sci_inst.spicr0;
assign SPICR1 = spi_ip_inst.spi_sci_inst.spicr1;
assign SPICR2 = spi_ip_inst.spi_sci_inst.spicr2;
assign SPIBR = spi_ip_inst.spi_sci_inst.spibr;
assign SPISR = spi_ip_inst.spi_sci_inst.spisr;
assign SPITXDR = spi_ip_inst.spi_sci_inst.spitxdr;
assign SPIRXDR = spi_ip_inst.spi_sci_inst.spirxdr;
assign SPICSR = spi_ip_inst.spi_sci_inst.spicsr;
assign SPIINTCR = spi_ip_inst.spi_sci_inst.spiintcr;
//assign SPIINTSR = spi_ip_inst.spi_sci_inst.spiintsr;
assign SPIINTSR ={{3{1'b0}},spi_ip_inst.spi_sci_inst.irq_trdy,spi_ip_inst.spi_sci_inst.irq_rrdy,spi_ip_inst.spi_sci_inst.irq_toe,spi_ip_inst.spi_sci_inst.irq_roe,spi_ip_inst.spi_sci_inst.irq_mdf};
spi_ip spi_ip_inst (
  .mclk_o(SCKO),
  .mclk_oe(SCKOE),
  .mosi_o(MO),
  .mosi_oe(MOE),
  .miso_o(SO),
  .miso_oe(SOE),
  //.mcsn_cfg_2d(unused),
  .mcsn_o(mcsn_o),
  .mcsn_oe(mcsn_oe),
  .sb_dat_o(sb_dat_o),
  .sb_ack_o(SBACKO),
  .spi_irq(SPIIRQ),
  .spi_wkup(SPIWKUP),
  .SB_ID(SB_ID),
  .spi_rst_async(spi_rst_async),
  .sck_tcv(SCKI),
  .mosi_i(SI),
  .miso_i(MI),
  .scsn_usr(SCSNI),
  .sb_clk_i(SBCLKI),
  .sb_we_i(SBRWI),
  .sb_stb_i(SBSTBI),
  .sb_adr_i(sb_adr_i),
  .sb_dat_i(sb_dat_i),
  .scan_test_mode(scan_test_mode)
);

endmodule
