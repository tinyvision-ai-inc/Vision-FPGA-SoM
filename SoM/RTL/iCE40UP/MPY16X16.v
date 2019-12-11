`include "defines1.v"
`timescale 1ns / 1ps
module MPY16X16(
clk,

IHRST,
ILRST,

FSEL,
GSEL,
HSEL,
JKSEL,
MPY_8X8_MODE,

ASGND,
BSGND,

A,
B,

OH_8X8,
OL_8X8,
O_16X16
);

input clk;

input IHRST;
input ILRST;

input FSEL;
input GSEL;
input HSEL;
input JKSEL;
input MPY_8X8_MODE;

input ASGND;
input BSGND;

input	[15:0]A;
input	[15:0]B;

output [15:0] OH_8X8;
output [15:0] OL_8X8;
output [31:0] O_16X16;


reg 	[31:0]csa_rega, csa_regb;
wire	[152:0]pp_out;

wire	[7:0] MPYG_mpd, MPYG_mpr;
wire	[7:0] MPYJ_mpd, MPYJ_mpr;
wire	[7:0] MPYF_mpd, MPYF_mpr;
wire	[7:0] MPYK_mpd, MPYK_mpr;

wire	MPYG_MPD_sign, MPYG_MPR_sign;
wire	MPYJ_MPD_sign, MPYJ_MPR_sign;
wire	MPYF_MPD_sign, MPYF_MPR_sign;
wire	MPYK_MPD_sign, MPYK_MPR_sign;

assign MPYG_mpd = A[7:0];
assign MPYG_mpr = B[7:0];
assign MPYG_MPD_sign = MPY_8X8_MODE ? ASGND : `UNSIGNED_DATA;
assign MPYG_MPR_sign = MPY_8X8_MODE ? BSGND : `UNSIGNED_DATA;

assign MPYJ_mpd = A[7:0];
assign MPYJ_mpr = B[15:8];
assign MPYJ_MPD_sign = `UNSIGNED_DATA;
assign MPYJ_MPR_sign = BSGND;

assign MPYF_mpd = A[15:8];
assign MPYF_mpr = B[15:8];
assign MPYF_MPD_sign = ASGND;
assign MPYF_MPR_sign = BSGND;

assign MPYK_mpd = A[15:8];
assign MPYK_mpr = B[7:0];
assign MPYK_MPD_sign = ASGND;
assign MPYK_MPR_sign = `UNSIGNED_DATA;

wire	[15:0] MPYG_csa_a, MPYG_csa_b;
wire	[15:0] MPYJ_csa_a, MPYJ_csa_b;
wire	[15:0] MPYF_csa_a, MPYF_csa_b;
wire	[15:0] MPYK_csa_a, MPYK_csa_b;

wire	[15:0] MPYG_o, MPYG_out;
wire	[15:0] MPYJ_o, MPYJ_out;
wire	[15:0] MPYF_o, MPYF_out;
wire	[15:0] MPYK_o, MPYK_out;
reg		[15:0] MPYG_oreg, MPYJ_oreg;
reg		[15:0] MPYF_oreg, MPYK_oreg;

wire	MPYJ_out_sign, MPYK_out_sign;
wire	MPYJK_g, MPYJK_p;

assign MPYJ_out_sign = BSGND ? MPYJ_out[15] : `UNSIGNED_DATA;
assign MPYK_out_sign = ASGND ? MPYK_out[15] : `UNSIGNED_DATA;

assign MPYJK_g = MPYJ_out_sign & MPYK_out_sign;
assign MPYJK_p = MPYJ_out_sign ^ MPYK_out_sign;


MPY8x8 MPY_G(.csa_a(MPYG_csa_a),.csa_b(MPYG_csa_b),.multiplicand(MPYG_mpd),.multiplier(MPYG_mpr),.signed_MPD(MPYG_MPD_sign),.signed_MPR(MPYG_MPR_sign));
MPY8x8 MPY_J(.csa_a(MPYJ_csa_a),.csa_b(MPYJ_csa_b),.multiplicand(MPYJ_mpd),.multiplier(MPYJ_mpr),.signed_MPD(MPYJ_MPD_sign),.signed_MPR(MPYJ_MPR_sign));
MPY8x8 MPY_F(.csa_a(MPYF_csa_a),.csa_b(MPYF_csa_b),.multiplicand(MPYF_mpd),.multiplier(MPYF_mpr),.signed_MPD(MPYF_MPD_sign),.signed_MPR(MPYF_MPR_sign));
MPY8x8 MPY_K(.csa_a(MPYK_csa_a),.csa_b(MPYK_csa_b),.multiplicand(MPYK_mpd),.multiplier(MPYK_mpr),.signed_MPD(MPYK_MPD_sign),.signed_MPR(MPYK_MPR_sign));



wire	[15:0] MPYG_cla_ina, MPYG_cla_inb;

assign MPYG_cla_ina = MPYG_csa_a;
assign MPYG_cla_inb = MPYG_csa_b;

wire	CLA16_G_g, CLA16_G_p, MPYG_ci;
assign MPYG_ci = 1'b0;

wire dangle_g_nodeJ, dangle_p_nodeJ; 
wire dangle_g_nodeF, dangle_p_nodeF; 
wire dangle_g_nodeK, dangle_p_nodeK; 



fcla16 CLA16_G(
.Sum(MPYG_o[15:0]),
.A(MPYG_cla_ina[15:0]),
.B(MPYG_cla_inb[15:0]), 
.G(CLA16_G_g),
.P(CLA16_G_p),
.Cin(MPYG_ci)
);



fcla16 CLA16_J(
.Sum(MPYJ_o[15:0]),
.A(MPYJ_csa_a[15:0]),
.B(MPYJ_csa_b[15:0]), 
.Cin(1'b0),
.G(dangle_g_nodeJ),
.P(dangle_p_nodeJ)
);



fcla16 CLA16_F(
.Sum(MPYF_o[15:0]),
.A(MPYF_csa_a[15:0]),
.B(MPYF_csa_b[15:0]), 
.Cin(1'b0),
.G(dangle_g_nodeF),
.P(dangle_p_nodeF)
);


fcla16 CLA16_K(
.Sum(MPYK_o[15:0]),
.A(MPYK_csa_a[15:0]),
.B(MPYK_csa_b[15:0]), 
.Cin(1'b0),
.G(dangle_g_nodeK), 
.P(dangle_p_nodeK)
);



always @(posedge clk or posedge IHRST)
begin
  if (IHRST)
    MPYF_oreg <= 0;		//#1 0;
  else
    MPYF_oreg <= MPYF_o; 	//#1 MPYF_o;
end

always @(posedge clk or posedge IHRST)
begin
  if (IHRST)
    MPYJ_oreg <=0; 		//#1 0;
  else if (MPY_8X8_MODE)
    MPYJ_oreg <=MPYJ_oreg;	//#1 MPYJ_oreg;
  else
    MPYJ_oreg <=MPYJ_o;  	//#1 MPYJ_o;
end

always @(posedge clk or posedge ILRST)
begin
  if (ILRST)
    MPYK_oreg <=0; 		//#1 0;
  else if (MPY_8X8_MODE)
    MPYK_oreg <=MPYK_oreg; 	//#1 MPYK_oreg;
  else
    MPYK_oreg <=MPYK_o; 	//#1 MPYK_o;
end

always @(posedge clk or posedge ILRST)
begin
  if (ILRST)
    MPYG_oreg <= 0; 		//#1 0;
  else
    MPYG_oreg <= MPYG_o; 	//#1 MPYG_o;
end

 assign MPYG_out = GSEL ? MPYG_oreg : MPYG_o;
 assign MPYJ_out = JKSEL ? MPYJ_oreg : MPYJ_o;

 assign MPYF_out = JKSEL ? MPYF_oreg : MPYF_o;
 assign MPYK_out = FSEL ? MPYK_oreg : MPYK_o;

wire [23:0] csa_oc;
wire [23:0] csa_os;
wire MPYJK_g_b;
assign MPYJK_g_b = ~MPYJK_g;

assign csa_os[23] = MPYJK_p ^ MPYF_out[15];
assign csa_oc[23] = ~(MPYJK_g_b & ~(MPYJK_p & MPYF_out[15]));
assign csa_os[22] = MPYJK_p ^ MPYF_out[14];
assign csa_oc[22] = ~(MPYJK_g_b & ~(MPYJK_p & MPYF_out[14]));
assign csa_os[21] = MPYJK_p ^ MPYF_out[13];
assign csa_oc[21] = ~(MPYJK_g_b & ~(MPYJK_p & MPYF_out[13]));
assign csa_os[20] = MPYJK_p ^ MPYF_out[12];
assign csa_oc[20] = ~(MPYJK_g_b & ~(MPYJK_p & MPYF_out[12]));
assign csa_os[19] = MPYJK_p ^ MPYF_out[11];
assign csa_oc[19] = ~(MPYJK_g_b & ~(MPYJK_p & MPYF_out[11]));
assign csa_os[18] = MPYJK_p ^ MPYF_out[10];
assign csa_oc[18] = ~(MPYJK_g_b & ~(MPYJK_p & MPYF_out[10]));
assign csa_os[17] = MPYJK_p ^ MPYF_out[9];
assign csa_oc[17] = ~(MPYJK_g_b & ~(MPYJK_p & MPYF_out[9]));
assign csa_os[16] = MPYJK_p ^ MPYF_out[8];
assign csa_oc[16] = ~(MPYJK_g_b & ~(MPYJK_p & MPYF_out[8]));

fa FA1_R00C15(.Cout(csa_oc[15]), .Sum(csa_os[15]), .A(MPYJ_out[15]), .B(MPYK_out[15]), .C(MPYF_out[7]));
fa FA1_R00C14(.Cout(csa_oc[14]), .Sum(csa_os[14]), .A(MPYJ_out[14]), .B(MPYK_out[14]), .C(MPYF_out[6]));
fa FA1_R00C13(.Cout(csa_oc[13]), .Sum(csa_os[13]), .A(MPYJ_out[13]), .B(MPYK_out[13]), .C(MPYF_out[5]));
fa FA1_R00C12(.Cout(csa_oc[12]), .Sum(csa_os[12]), .A(MPYJ_out[12]), .B(MPYK_out[12]), .C(MPYF_out[4]));
fa FA1_R00C11(.Cout(csa_oc[11]), .Sum(csa_os[11]), .A(MPYJ_out[11]), .B(MPYK_out[11]), .C(MPYF_out[3]));
fa FA1_R00C10(.Cout(csa_oc[10]), .Sum(csa_os[10]), .A(MPYJ_out[10]), .B(MPYK_out[10]), .C(MPYF_out[2]));
fa FA1_R00C09(.Cout(csa_oc[9]),  .Sum(csa_os[9]),  .A(MPYJ_out[9]),  .B(MPYK_out[9]),  .C(MPYF_out[1]));
fa FA1_R00C08(.Cout(csa_oc[8]),  .Sum(csa_os[8]),  .A(MPYJ_out[8]),  .B(MPYK_out[8]),  .C(MPYF_out[0]));

fa FA1_R00C07(.Cout(csa_oc[7]), .Sum(csa_os[7]), .A(MPYG_out[15]), .B(MPYJ_out[7]), .C(MPYK_out[7]));
fa FA1_R00C06(.Cout(csa_oc[6]), .Sum(csa_os[6]), .A(MPYG_out[14]), .B(MPYJ_out[6]), .C(MPYK_out[6]));
fa FA1_R00C05(.Cout(csa_oc[5]), .Sum(csa_os[5]), .A(MPYG_out[13]), .B(MPYJ_out[5]), .C(MPYK_out[5]));
fa FA1_R00C04(.Cout(csa_oc[4]), .Sum(csa_os[4]), .A(MPYG_out[12]), .B(MPYJ_out[4]), .C(MPYK_out[4]));
fa FA1_R00C03(.Cout(csa_oc[3]), .Sum(csa_os[3]), .A(MPYG_out[11]), .B(MPYJ_out[3]), .C(MPYK_out[3]));
fa FA1_R00C02(.Cout(csa_oc[2]), .Sum(csa_os[2]), .A(MPYG_out[10]), .B(MPYJ_out[2]), .C(MPYK_out[2]));
fa FA1_R00C01(.Cout(csa_oc[1]), .Sum(csa_os[1]), .A(MPYG_out[9]),  .B(MPYJ_out[1]), .C(MPYK_out[1]));
fa FA1_R00C00(.Cout(csa_oc[0]), .Sum(csa_os[0]), .A(MPYG_out[8]),  .B(MPYJ_out[0]), .C(MPYK_out[0]));


wire 	[23:0] cla_ina;
wire 	[23:0] cla_inb;

wire 	[23:0] cla_o;
wire	cla24_g0, cla24_p0;
wire	cla24_g1, cla24_p1;

wire	cla24_cin, cla24_16_cout;

assign cla_ina = csa_os;
assign cla_inb = {csa_oc[22:0],1'b0};
assign cla24_cin = 1'b0 ;


fcla16 CLA24_16(
.Sum(cla_o[15:0]),
.G(cla24_g0),
.P(cla24_p0), 
.A(cla_ina[15:0]),
.B(cla_inb[15:0]), 
.Cin(cla24_cin)
);
assign cla24_16_cout = ~(~cla24_g0 & ~(cla24_p0 & cla24_cin));



fcla8 CLA24_8(
.Sum(cla_o[23:16]),
.G(cla24_g1),
.P(cla24_p1), 
.A(cla_ina[23:16]),
.B(cla_inb[23:16]), 
.Cin(cla24_16_cout)
);

reg 	[31:0]mpy16_reg;

always @(posedge clk or posedge ILRST)
begin
  if (ILRST)
    mpy16_reg <= 0; 		//#1 0;
  else if (MPY_8X8_MODE)
    mpy16_reg <=  mpy16_reg; 	//#1 mpy16_reg;
  else
    mpy16_reg <={cla_o,MPYG_out[7:0]}; 	//#1 {cla_o,MPYG_out[7:0]};
end

assign O_16X16[31:0] = HSEL ? mpy16_reg : {cla_o,MPYG_out[7:0]};

assign OH_8X8 = MPYF_out[15:0];
assign OL_8X8 = MPYG_out[15:0];

endmodule // MPY16x16
