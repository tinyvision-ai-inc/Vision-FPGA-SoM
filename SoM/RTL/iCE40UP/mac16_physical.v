`timescale 1ns / 1ps
module mac16_physical  (
	 CLK ,
	 IHRST,
	 ILRST,
	 OHRST,
	 OLRST,
	 
	 A ,
	 B ,
	 C ,
	 D ,
	 
	 CBIT,
	 
	 AHLD,
	 BHLD,
	 CHLD,
	 DHLD,
	 OHHLD,
	 OLHLD,

 
	 OHADS,
	 OLADS,
	 OHLDA,
	 OLLDA,
	 
	 CICAS,
	 CI,
	 SIGNEXTIN,
	 SIGNEXTOUT,

	 COCAS,
	 CO,
	 O
    );

	 input CLK ;
	 input IHRST;
	 input ILRST;
	 input OHRST;
	 input OLRST;
	 
	 input [15:0] A ;
	 input [15:0] B ;
	 input [15:0] C ;
	 input [15:0] D ;
	 
	 input [24:0] CBIT;
	 
	 input AHLD;
	 input BHLD;
	 input CHLD;
	 input DHLD;
	 input OHHLD;
	 input OLHLD;

 
	 input OHADS;
	 input OLADS;
	 input OHLDA;
	 input OLLDA;
	 
	 input CICAS;
	 input CI;
	 input SIGNEXTIN;
	 output SIGNEXTOUT;
	 
	 output COCAS;
	 output CO;
	 output [31:0] O;
	
	
wire AENA, BENA, CENA, DENA, OHENA, OLENA;
assign AENA = ~AHLD;
assign BENA = ~BHLD;
assign CENA = ~CHLD;
assign DENA = ~DHLD;

assign OHENA = ~OHHLD;
assign OLENA = ~OLHLD;


wire ASEL, BSEL, CSEL, DSEL, FSEL, JKSEL, GSEL, HSEL;
wire OHADDA_SEL, OLADDA_SEL, MPY_8X8_MODE, ASGND, BSGND;
wire [1:0] OHOMUX_SEL, OLOMUX_SEL, OHADDB_SEL, OLADDB_SEL, OHCARRYMUX_SEL, OLCARRYMUX_SEL;

assign ASEL = CBIT[1];
assign BSEL = CBIT[2];
assign CSEL = CBIT[0];
assign DSEL = CBIT[3];

assign FSEL = CBIT[4];
assign JKSEL = CBIT[6];
assign GSEL = CBIT[5];
assign HSEL = CBIT[7];

assign OHOMUX_SEL[1:0] = CBIT[9:8];	
assign OLOMUX_SEL[1:0] = CBIT[16:15];	
assign OHADDA_SEL = CBIT[12];
assign OLADDA_SEL = CBIT[19];
assign OHADDB_SEL[1:0] = CBIT[11:10];	
assign OLADDB_SEL[1:0] = CBIT[18:17];	
assign OHCARRYMUX_SEL[1:0] = CBIT[14:13];
assign OLCARRYMUX_SEL[1:0] = CBIT[21:20];
assign MPY_8X8_MODE = CBIT[22];
assign ASGND = CBIT[23];
assign BSGND = CBIT[24];

wire [15:0] REG_A ;
wire [15:0] REG_B ;
wire [15:0] REG_C ;
wire [15:0] REG_D ;

wire [15:0] OH_8X8;
wire [15:0] OL_8X8;
wire [31:0] O_16X16;

wire MAC16_SIGNOUT_L, MAC16_SIGNOUT_H;

assign SIGNEXTOUT = MAC16_SIGNOUT_H;

REG_BYPASS_MUX  A_REG (
	.D(A) ,
	.Q(REG_A) ,
	.ENA(AENA) ,
	.CLK(CLK) ,
	.RST(IHRST) ,
	.SELM(ASEL) 
); 

REG_BYPASS_MUX  B_REG (
	.D(B) ,
	.Q(REG_B) ,
	.ENA(BENA) ,
	.CLK(CLK) ,
	.RST(ILRST) ,
	.SELM(BSEL) 
); 

REG_BYPASS_MUX  C_REG (
	.D(C) ,
	.Q(REG_C) ,
	.ENA(CENA) ,
	.CLK(CLK) ,
	.RST(IHRST) ,
	.SELM(CSEL) 
); 

REG_BYPASS_MUX  D_REG (
	.D(D) ,
	.Q(REG_D) ,
	.ENA(DENA) ,
	.CLK(CLK) ,
	.RST(ILRST) ,
	.SELM(DSEL) 
); 

MULT_ACCUM HI_MAC (
	.DIRECT_INPUT(REG_C),
	.MULT_INPUT(REG_A),
	.MULT_8x8(OH_8X8[15:0]),
	.MULT_16x16(O_16X16[31:16]),
	.ADDSUB(OHADS),
	.CLK(CLK),
	.CICAS(COCAS_L),
	.CI(CO_L),
	.SIGNEXTIN(MAC16_SIGNOUT_L) ,
	.SIGNEXTOUT(MAC16_SIGNOUT_H) ,
	.LDA(OHLDA),
	.RST(OHRST),
	.ENA(OHENA),
	.COCAS(COCAS),
	.CO(CO),
	.O(O[31:16]),
	.OUTMUX_SEL(OHOMUX_SEL[1:0]),
	.ADDER_A_IN_SEL(OHADDA_SEL),
	.ADDER_B_IN_SEL(OHADDB_SEL[1:0]),
	.CARRYMUX_SEL(OHCARRYMUX_SEL[1:0])
    );

MULT_ACCUM LO_MAC (
	.DIRECT_INPUT(REG_D),
	.MULT_INPUT(REG_B),
	.MULT_8x8(OL_8X8[15:0]),
	.MULT_16x16(O_16X16[15:0]),
	.ADDSUB(OLADS),
	.CLK(CLK),
	.CICAS(CICAS),
	.CI(CI),
	.SIGNEXTIN(SIGNEXTIN) ,
	.SIGNEXTOUT(MAC16_SIGNOUT_L) ,
	.LDA(OLLDA),
	.RST(OLRST),
	.ENA(OLENA),
	.COCAS(COCAS_L),
	.CO(CO_L),
	.O(O[15:0]),
	.OUTMUX_SEL(OLOMUX_SEL[1:0]),
	.ADDER_A_IN_SEL(OLADDA_SEL),
	.ADDER_B_IN_SEL(OLADDB_SEL[1:0]),
	.CARRYMUX_SEL(OLCARRYMUX_SEL[1:0])
    );
	 
MPY16X16 MULTIPLER (
	.clk(CLK),
	.IHRST(IHRST),
	.ILRST(ILRST),
	.FSEL(FSEL),
	.GSEL(GSEL),
	.HSEL(HSEL),
	.JKSEL(JKSEL),
	.MPY_8X8_MODE(MPY_8X8_MODE),
	.ASGND(ASGND),
	.BSGND(BSGND),
	.A(REG_A[15:0]),
	.B(REG_B[15:0]),
	.OH_8X8(OH_8X8[15:0]),
	.OL_8X8(OL_8X8[15:0]),
	.O_16X16(O_16X16[31:0])
);

endmodule
