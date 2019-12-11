`timescale 1ns/1ns
module IB(I, O); // synthesis syn_black_box black_box_pad_pin="I"
    (* \desc = "Data from pad" *)
    input I;
    (* \desc = "Data to fabric" *)
    output O;

    wire gnd;

    VLO vlo_inst(.Z(gnd));
    BB_B bb_inst(.B(I), .O(O), .T_N(gnd), .I());
endmodule
