`timescale 1ns/1ns
module OB(I, O); // synthesis syn_black_box black_box_pad_pin="O"
    (* \desc = "Data from fabric" *)
    input I;
    (* \desc = "Data to pad" *)
    output O;

    wire vcc;
    VHI vhi_inst(.Z(vcc));
	
    BB_B bb_inst(.B(O), .T_N(vcc), .I(I), .O());
endmodule
