`timescale 1ns / 1ps
module ACCUM_ADDER (
	A ,
	B ,
	ADDSUB ,
	CI ,
	SUM ,
	COCAS ,
	CO
	);
//parameter A_width =16;
input [15:0] A ;
input [15:0] B ;
input ADDSUB ;
input CI ;
output [15:0] SUM ;
output COCAS, CO;

wire	CLA16_g, CLA16_p;
reg		CO;

wire [15:0] CLA16_SUM;
reg	[15:0] CLA16_A, SUM;
integer j;

always@(ADDSUB or COCAS or A or CLA16_SUM)
begin
	if (ADDSUB)
		begin
		   CO = ~COCAS;
           for (j=0; j<=15; j=j+1)
			begin
			 CLA16_A[j] = ~A[j];
			 SUM[j] = ~CLA16_SUM[j];
			end 
		end   
		else
		begin
		   CO = COCAS;
		   CLA16_A[15:0] = A[15:0];
		   SUM[15:0] = CLA16_SUM[15:0];
		end
end

fcla16 CLA16_ADDER(
.Sum(CLA16_SUM[15:0]),
.A(CLA16_A[15:0]),
.B(B[15:0]), 
.G(CLA16_g),
.P(CLA16_p),
.Cin(CI)
);
assign COCAS= ~(~CLA16_g & ~(CLA16_p & CI));


endmodule
