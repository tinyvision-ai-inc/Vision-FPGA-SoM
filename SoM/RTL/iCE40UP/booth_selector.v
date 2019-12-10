`timescale 1ns / 1ps 
module booth_selector(pp_out,booth_single, booth_double, booth_negtive,multiplicand, signed_mpy);
input	[7:0]multiplicand;
input	[4:0]booth_single;
input	[4:0]booth_double;
input	[4:0]booth_negtive;
output	[44:0] pp_out;
integer	j;

reg		[8:0] pp0,pp1,pp2,pp3,pp4;

input	signed_mpy;
wire	sign_ext;
assign sign_ext=(signed_mpy==1'b1)?{multiplicand[7]} : 1'b0;


assign pp_out ={pp4, pp3, pp2, pp1, pp0};

wire	[9:0]bs_in;

assign  bs_in={sign_ext ,multiplicand[7:0],1'b0};


always @(booth_negtive or booth_single or bs_in or booth_double)

begin
	for (j=0; j<=8; j=j+1)
	begin
		pp0[j] = (booth_negtive[0]^ ~(~(booth_single[0] & bs_in[j+1]) & ~(booth_double[0] & bs_in[j])));
		pp1[j] = (booth_negtive[1]^ ~(~(booth_single[1] & bs_in[j+1]) & ~(booth_double[1] & bs_in[j])));
		pp2[j] = (booth_negtive[2]^ ~(~(booth_single[2] & bs_in[j+1]) & ~(booth_double[2] & bs_in[j])));
		pp3[j] = (booth_negtive[3]^ ~(~(booth_single[3] & bs_in[j+1]) & ~(booth_double[3] & bs_in[j])));
		pp4[j] = (booth_negtive[4]^ ~(~(booth_single[4] & bs_in[j+1]) & ~(booth_double[4] & bs_in[j])));
	end

end 

endmodule // booth_selector
