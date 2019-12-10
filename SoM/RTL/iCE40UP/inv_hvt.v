`timescale 1ns/1ns
module inv_hvt (Y, A);
    output Y;
    input A;

	assign Y = !A;

endmodule
