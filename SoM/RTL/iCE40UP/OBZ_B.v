`timescale 1ns/1ns
module OBZ_B(I, T_N, O); // synthesis syn_black_box black_box_pad_pin="O"
    (* \desc = "Data from fabric" *)
    input I;
    (* \desc = "Tri-state control, active low meaning T = 0 --> O = Z" *)
    input T_N;
    (* \desc = "Data to pad" *)
    output O;
	
	wire vcc;
    VHI vhi_inst(.Z(vcc));

    BB_B bb_inst(.B(O), .T_N(T_N), .I(I), .O());
endmodule
