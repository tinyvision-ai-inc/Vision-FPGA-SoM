`timescale 1ns / 1ps
module booth_encoder(booth_single, booth_double, booth_negtive, multiplier, signed_mpy);
input	[7:0]multiplier;
output	[4:0]booth_single;
output	[4:0]booth_double;
output	[4:0]booth_negtive;
input	signed_mpy;

wire	[10:0]booth_in;
wire	[1:0]sign_ext;
assign sign_ext=(signed_mpy==1'b1)?{2{multiplier[7]}} : 2'b00;

assign booth_in={sign_ext ,multiplier[7:0],1'b0};


assign  booth_negtive[0]=booth_in[2];
assign  booth_negtive[1]=booth_in[4];
assign  booth_negtive[2]=booth_in[6];
assign  booth_negtive[3]=booth_in[8];
assign  booth_negtive[4]=booth_in[10];

assign  booth_single[0]=booth_in[0]^booth_in[1];
assign  booth_single[1]=booth_in[2]^booth_in[3];
assign  booth_single[2]=booth_in[4]^booth_in[5];
assign  booth_single[3]=booth_in[6]^booth_in[7];
assign  booth_single[4]=booth_in[8]^booth_in[9];


assign  booth_double[0]=~(~(booth_in[0] & booth_in[1] & ~booth_in[2]) & ~(~booth_in[0] & ~booth_in[1] & booth_in[2]));
assign  booth_double[1]=~(~(booth_in[2] & booth_in[3] & ~booth_in[4]) & ~(~booth_in[2] & ~booth_in[3] & booth_in[4]));
assign  booth_double[2]=~(~(booth_in[4] & booth_in[5] & ~booth_in[6]) & ~(~booth_in[4] & ~booth_in[5] & booth_in[6]));
assign  booth_double[3]=~(~(booth_in[6] & booth_in[7] & ~booth_in[8]) & ~(~booth_in[6] & ~booth_in[7] & booth_in[8]));
assign  booth_double[4]=~(~(booth_in[8] & booth_in[9] & ~booth_in[10]) & ~(~booth_in[8] & ~booth_in[9] & booth_in[10]));

endmodule // booth_encoder
