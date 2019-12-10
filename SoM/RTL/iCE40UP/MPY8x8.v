`timescale 1ns / 1ps
module MPY8x8(csa_a,csa_b,multiplicand,multiplier,signed_MPD,signed_MPR);
input	[7:0]multiplicand;
input	[7:0]multiplier;
input	signed_MPD, signed_MPR;

output [15:0] csa_a;
output [15:0] csa_b;

wire	[4:0]booth_single;
wire	[4:0]booth_double;
wire	[4:0]booth_negtive;
wire	[4:0]pp_sign;

wire	[44:0]pp_out;
wire	[8:0] PP0,PP1,PP2,PP3,PP4;

assign {PP4, PP3, PP2, PP1, PP0} = pp_out;

booth_encoder booth_encoder
(
.booth_single(booth_single), 
.booth_double(booth_double), 
.booth_negtive(booth_negtive), 
.multiplier(multiplier),
.signed_mpy(signed_MPR)
);


booth_selector booth_selector
(
.pp_out(pp_out),
.booth_single(booth_single), 
.booth_double(booth_double), 
.booth_negtive(booth_negtive),
.multiplicand(multiplicand),
.signed_mpy(signed_MPD)
);

wire	current_MPD_sign;
assign current_MPD_sign = multiplicand[7] & signed_MPD;
//assign pp_sign[0] = (booth_negtive[0] ^ current_MPD_sign) & (booth_single[0] | booth_double[0] | booth_negtive[0]) | (~booth_single[0] & ~booth_double[0] & booth_negtive[0]);
//assign pp_sign[1] = (booth_negtive[1] ^ current_MPD_sign) & (booth_single[1] | booth_double[1] | booth_negtive[1]) | (~booth_single[1] & ~booth_double[1] & booth_negtive[1]);
//assign pp_sign[2] = (booth_negtive[2] ^ current_MPD_sign) & (booth_single[2] | booth_double[2] | booth_negtive[2]) | (~booth_single[2] & ~booth_double[2] & booth_negtive[2]);
//assign pp_sign[3] = (booth_negtive[3] ^ current_MPD_sign) & (booth_single[3] | booth_double[3] | booth_negtive[3]) | (~booth_single[3] & ~booth_double[3] & booth_negtive[3]);
//assign pp_sign[4] = (booth_negtive[4] ^ current_MPD_sign) & (booth_single[4] | booth_double[4] | booth_negtive[4]) | (~booth_single[4] & ~booth_double[4] & booth_negtive[4]);

integer j;
reg [4:0] booth_single_b, booth_double_b, booth_negtive_b;

always @(booth_single or booth_double or booth_negtive)
begin
	for (j=0; j<=4; j=j+1)
	begin
		booth_single_b[j] = ~booth_single[j];
		booth_double_b[j] = ~booth_double[j];
		booth_negtive_b[j] = ~booth_negtive[j];
	end
end 

assign pp_sign[0] = (booth_negtive[0] ^ current_MPD_sign) & ~(booth_single_b[0] & booth_double_b[0] & booth_negtive_b[0]) | (booth_single_b[0] & booth_double_b[0] & booth_negtive[0]);
assign pp_sign[1] = (booth_negtive[1] ^ current_MPD_sign) & ~(booth_single_b[1] & booth_double_b[1] & booth_negtive_b[1]) | (booth_single_b[1] & booth_double_b[1] & booth_negtive[1]);
assign pp_sign[2] = (booth_negtive[2] ^ current_MPD_sign) & ~(booth_single_b[2] & booth_double_b[2] & booth_negtive_b[2]) | (booth_single_b[2] & booth_double_b[2] & booth_negtive[2]);
assign pp_sign[3] = (booth_negtive[3] ^ current_MPD_sign) & ~(booth_single_b[3] & booth_double_b[3] & booth_negtive_b[3]) | (booth_single_b[3] & booth_double_b[3] & booth_negtive[3]);
assign pp_sign[4] = (booth_negtive[4] ^ current_MPD_sign) & ~(booth_single_b[4] & booth_double_b[4] & booth_negtive_b[4]) | (booth_single_b[4] & booth_double_b[4] & booth_negtive[4]);
// Wallace CSA step#1

wire	FA1_R00C14_C, FA1_R00C14_S;
wire	FA1_R00C13_C, FA1_R00C13_S;
wire	FA1_R00C12_C, FA1_R00C12_S;

wire	FA1_R00C11_C, FA1_R00C11_S;
wire	HA1_R03C11_C, HA1_R03C11_S;

wire	FA1_R00C10_C, FA1_R00C10_S;
wire	HA1_R03C10_C, HA1_R03C10_S;

wire	FA1_R00C09_C, FA1_R00C09_S;
wire	HA1_R03C09_C, HA1_R03C09_S;

wire	FA1_R00C08_C, FA1_R00C08_S;
wire	FA1_R03C08_C, FA1_R03C08_S;

wire	FA1_R00C07_C, FA1_R00C07_S;
wire	FA1_R00C06_C, FA1_R00C06_S;
wire	HA1_R03C06_C, HA1_R03C06_S;

wire	FA1_R00C05_C, FA1_R00C05_S;
wire	FA1_R00C04_C, FA1_R00C04_S;

wire	FA1_R00C02_C, FA1_R00C02_S;


fa FA1_R00C14(.Cout(FA1_R00C14_C), .Sum(FA1_R00C14_S), .A(1'b1), .B(PP3[8]), .C(PP4[6]));

fa FA1_R00C13(.Cout(FA1_R00C13_C), .Sum(FA1_R00C13_S), .A(~pp_sign[2]), .B(PP3[7]), .C(PP4[5]));

fa FA1_R00C12(.Cout(FA1_R00C12_C), .Sum(FA1_R00C12_S), .A(1'b1), .B(PP2[8]), .C(PP3[6]));

fa FA1_R00C11(.Cout(FA1_R00C11_C), .Sum(FA1_R00C11_S), .A(~pp_sign[0]), .B(~pp_sign[1]), .C(PP2[7]));
ha HA1_R03C11(.Cout(HA1_R03C11_C), .Sum(HA1_R03C11_S), .A(PP3[5]), .B(PP4[3]));

fa FA1_R00C10(.Cout(FA1_R00C10_C), .Sum(FA1_R00C10_S), .A(pp_sign[0]), .B(PP1[8]), .C(PP2[6]));
ha HA1_R03C10(.Cout(HA1_R03C10_C), .Sum(HA1_R03C10_S), .A(PP3[4]), .B(PP4[2]));

fa FA1_R00C09(.Cout(FA1_R00C09_C), .Sum(FA1_R00C09_S), .A(pp_sign[0]), .B(PP1[7]), .C(PP2[5]));
ha HA1_R03C09(.Cout(HA1_R03C09_C), .Sum(HA1_R03C09_S), .A(PP3[3]), .B(PP4[1]));

fa FA1_R00C08(.Cout(FA1_R00C08_C), .Sum(FA1_R00C08_S), .A(PP0[8]), .B(PP1[6]), .C(PP2[4]));
fa FA1_R03C08(.Cout(FA1_R03C08_C), .Sum(FA1_R03C08_S), .A(PP3[2]), .B(PP4[0]), .C(booth_negtive[4]));

fa FA1_R00C07(.Cout(FA1_R00C07_C), .Sum(FA1_R00C07_S), .A(PP0[7]), .B(PP1[5]), .C(PP2[3]));
fa FA1_R00C06(.Cout(FA1_R00C06_C), .Sum(FA1_R00C06_S), .A(PP0[6]), .B(PP1[4]), .C(PP2[2]));
ha HA1_R03C06(.Cout(HA1_R03C06_C), .Sum(HA1_R03C06_S), .A(PP3[0]), .B(booth_negtive[3]));

fa FA1_R00C05(.Cout(FA1_R00C05_C), .Sum(FA1_R00C05_S), .A(PP0[5]), .B(PP1[3]), .C(PP2[1]));
fa FA1_R00C04(.Cout(FA1_R00C04_C), .Sum(FA1_R00C04_S), .A(PP0[4]), .B(PP1[2]), .C(PP2[0]));

fa FA1_R00C02(.Cout(FA1_R00C02_C), .Sum(FA1_R00C02_S), .A(PP0[2]), .B(PP1[0]), .C(booth_negtive[1]));

// Wallace CSA step#2

wire	FA2_R00C15_C, FA2_R00C15_S;
wire	HA2_R00C14_C, HA2_R00C14_S;
wire	HA2_R00C13_C, HA2_R00C13_S;

wire	FA2_R00C12_C, FA2_R00C12_S;
wire	FA2_R00C11_C, FA2_R00C11_S;
wire	FA2_R00C10_C, FA2_R00C10_S;
wire	FA2_R00C09_C, FA2_R00C09_S;
wire	FA2_R00C08_C, FA2_R00C08_S;
wire	FA2_R00C07_C, FA2_R00C07_S;
wire	FA2_R00C06_C, FA2_R00C06_S;

wire	FA2_R00C03_C, FA2_R00C03_S;


fa FA2_R00C15(.Cout(FA2_R00C15_C), .Sum(FA2_R00C15_S), .A(~pp_sign[3]), .B(PP4[7]), .C(FA1_R00C14_C));

ha HA2_R00C14(.Cout(HA2_R00C14_C), .Sum(HA2_R00C14_S), .A(FA1_R00C14_S), .B(FA1_R00C13_C));
ha HA2_R00C13(.Cout(HA2_R00C13_C), .Sum(HA2_R00C13_S), .A(FA1_R00C13_S), .B(FA1_R00C12_C));

fa FA2_R00C12(.Cout(FA2_R00C12_C), .Sum(FA2_R00C12_S), .A(FA1_R00C12_S), .B(FA1_R00C11_C), .C(HA1_R03C11_C));
fa FA2_R00C11(.Cout(FA2_R00C11_C), .Sum(FA2_R00C11_S), .A(FA1_R00C11_S), .B(FA1_R00C10_C), .C(HA1_R03C11_S));
fa FA2_R00C10(.Cout(FA2_R00C10_C), .Sum(FA2_R00C10_S), .A(FA1_R00C10_S), .B(FA1_R00C09_C), .C(HA1_R03C10_S));
fa FA2_R00C09(.Cout(FA2_R00C09_C), .Sum(FA2_R00C09_S), .A(FA1_R00C09_S), .B(FA1_R00C08_C), .C(HA1_R03C09_S));
fa FA2_R00C08(.Cout(FA2_R00C08_C), .Sum(FA2_R00C08_S), .A(FA1_R00C08_S), .B(FA1_R00C07_C), .C(FA1_R03C08_S));
fa FA2_R00C07(.Cout(FA2_R00C07_C), .Sum(FA2_R00C07_S), .A(FA1_R00C07_S), .B(FA1_R00C06_C), .C(HA1_R03C06_C));
fa FA2_R00C06(.Cout(FA2_R00C06_C), .Sum(FA2_R00C06_S), .A(FA1_R00C06_S), .B(FA1_R00C05_C), .C(HA1_R03C06_S));

fa FA2_R00C03(.Cout(FA2_R00C03_C), .Sum(FA2_R00C03_S), .A(PP0[3]), .B(PP1[1]), .C(FA1_R00C02_C));

// Wallace CSA step#3
wire	HA3_R00C15_C, HA3_R00C15_S;
wire	HA3_R00C14_C, HA3_R00C14_S;
wire	HA3_R00C13_C, HA3_R00C13_S;
wire	FA3_R00C12_C, FA3_R00C12_S;
wire	FA3_R00C11_C, FA3_R00C11_S;
wire	FA3_R00C10_C, FA3_R00C10_S;
wire	FA3_R00C09_C, FA3_R00C09_S;

wire	HA3_R00C08_C, HA3_R00C08_S;
wire	FA3_R00C07_C, FA3_R00C07_S;

wire	HA3_R00C05_C, HA3_R00C05_S;
wire	FA3_R00C04_C, FA3_R00C04_S;


ha HA3_R00C15(.Cout(HA3_R00C15_C), .Sum(HA3_R00C15_S), .A(FA2_R00C15_S), .B(HA2_R00C14_C));
ha HA3_R00C14(.Cout(HA3_R00C14_C), .Sum(HA3_R00C14_S), .A(HA2_R00C14_S), .B(HA2_R00C13_C));
ha HA3_R00C13(.Cout(HA3_R00C13_C), .Sum(HA3_R00C13_S), .A(HA2_R00C13_S), .B(FA2_R00C12_C));
fa FA3_R00C12(.Cout(FA3_R00C12_C), .Sum(FA3_R00C12_S), .A(FA2_R00C12_S), .B(FA2_R00C11_C), .C(PP4[4]));
fa FA3_R00C11(.Cout(FA3_R00C11_C), .Sum(FA3_R00C11_S), .A(FA2_R00C11_S), .B(FA2_R00C10_C), .C(HA1_R03C10_C));
fa FA3_R00C10(.Cout(FA3_R00C10_C), .Sum(FA3_R00C10_S), .A(FA2_R00C10_S), .B(FA2_R00C09_C), .C(HA1_R03C09_C));
fa FA3_R00C09(.Cout(FA3_R00C09_C), .Sum(FA3_R00C09_S), .A(FA2_R00C09_S), .B(FA2_R00C08_C), .C(FA1_R03C08_C));

ha HA3_R00C08(.Cout(HA3_R00C08_C), .Sum(HA3_R00C08_S), .A(FA2_R00C08_S), .B(FA2_R00C07_C));
fa FA3_R00C07(.Cout(FA3_R00C07_C), .Sum(FA3_R00C07_S), .A(FA2_R00C07_S), .B(FA2_R00C06_C), .C(PP3[1]));

ha HA3_R00C05(.Cout(HA3_R00C05_C), .Sum(HA3_R00C05_S), .A(FA1_R00C05_S), .B(FA1_R00C04_C));
fa FA3_R00C04(.Cout(FA3_R00C04_C), .Sum(FA3_R00C04_S), .A(FA1_R00C04_S), .B(booth_negtive[2]), .C(FA2_R00C03_C));


assign csa_a[0] = PP0[0];
assign csa_b[0] = booth_negtive[0];
assign csa_a[1] = PP0[1];
assign csa_b[1] = 1'b0;
assign csa_a[2] = FA1_R00C02_S;
assign csa_b[2] = 1'b0;
assign csa_a[3] = FA2_R00C03_S;
assign csa_b[3] = 1'b0;

assign csa_a[4] = FA3_R00C04_S;
assign csa_b[4] = 1'b0;

assign csa_a[5] = HA3_R00C05_S;
assign csa_b[5] = FA3_R00C04_C;
assign csa_a[6] = FA2_R00C06_S;
assign csa_b[6] = HA3_R00C05_C;
assign csa_a[7] = FA3_R00C07_S;
assign csa_b[7] = 1'b0;
assign csa_a[8] = HA3_R00C08_S;
assign csa_b[8] = FA3_R00C07_C;
assign csa_a[9] = FA3_R00C09_S;
assign csa_b[9] = HA3_R00C08_C;
assign csa_a[10] = FA3_R00C10_S;
assign csa_b[10] = FA3_R00C09_C;
assign csa_a[11] = FA3_R00C11_S;
assign csa_b[11] = FA3_R00C10_C;
assign csa_a[12] = FA3_R00C12_S;
assign csa_b[12] = FA3_R00C11_C;
assign csa_a[13] = HA3_R00C13_S;
assign csa_b[13] = FA3_R00C12_C;
assign csa_a[14] = HA3_R00C14_S;
assign csa_b[14] = HA3_R00C13_C;
assign csa_a[15] = HA3_R00C15_S;
assign csa_b[15] = HA3_R00C14_C;

endmodule // MPY8x8
