`timescale 1ns/1ns
module SP256K(AD, DI, MASKWE, WE, CS, CK, STDBY, SLEEP, PWROFF_N, DO); // synthesis syn_black_box

    (* \desc = "Read/write address" *)
    input [13:0] AD;
    (* \desc = "Data input" *)
    input [15:0] DI;
    (* \desc = "Write enable mask. Each bit corresponds to one nibble of the data input" *)
    input [3:0] MASKWE;
    (* \desc = "Write enable, active high" *)
    input WE;
    (* \desc = "Chip select, active high" *)
    input CS;
    (* \desc = "Read/write clock" *)
    input CK;
    (* \desc = "Enable low leakage mode, with no change in the output state. Active high" *)
    input STDBY;
    (* \desc = "Enable sleep mode, with the data outputs pulled low. Active high" *)
    input SLEEP;
    (* \desc = "Enable power off mode, with no memory content retention. Active low." *) 
    input PWROFF_N;
    (* \desc = "Data output" *)
    output [15:0] DO;

    wire gnd;
    VLO vlo_inst(.Z(gnd));

    VFB_B vfb_b_inst
        (.ADDRESS13(AD[13]),
        .ADDRESS12(AD[12]),
        .ADDRESS11(AD[11]),
        .ADDRESS10(AD[10]),
        .ADDRESS9(AD[9]),
        .ADDRESS8(AD[8]),
        .ADDRESS7(AD[7]),
        .ADDRESS6(AD[6]),
        .ADDRESS5(AD[5]),
        .ADDRESS4(AD[4]),
        .ADDRESS3(AD[3]),
        .ADDRESS2(AD[2]),
        .ADDRESS1(AD[1]),
        .ADDRESS0(AD[0]),
        .DATAIN15(DI[15]),
        .DATAIN14(DI[14]),
        .DATAIN13(DI[13]),
        .DATAIN12(DI[12]),
        .DATAIN11(DI[11]),
        .DATAIN10(DI[10]),
        .DATAIN9(DI[9]),
        .DATAIN8(DI[8]),
        .DATAIN7(DI[7]),
        .DATAIN6(DI[6]),
        .DATAIN5(DI[5]),
        .DATAIN4(DI[4]),
        .DATAIN3(DI[3]),
        .DATAIN2(DI[2]),
        .DATAIN1(DI[1]),
        .DATAIN0(DI[0]),
        .MASKWREN3(MASKWE[3]),
        .MASKWREN2(MASKWE[2]),
        .MASKWREN1(MASKWE[1]),
        .MASKWREN0(MASKWE[0]),
        .WREN(WE),
        .CHIPSELECT(CS),
        .CLOCK(CK),
        .RDMARGINEN(gnd),
        .RDMARGIN3(gnd),
        .RDMARGIN2(gnd),
        .RDMARGIN1(gnd),
        .RDMARGIN0(gnd),
        .STANDBY(STDBY),
        .SLEEP(SLEEP),
        .POWEROFF_N(PWROFF_N),
        .TEST(gnd),
        .DATAOUT15(DO[15]),
        .DATAOUT14(DO[14]),
        .DATAOUT13(DO[13]),
        .DATAOUT12(DO[12]),
        .DATAOUT11(DO[11]),
        .DATAOUT10(DO[10]),
        .DATAOUT9(DO[9]),
        .DATAOUT8(DO[8]),
        .DATAOUT7(DO[7]),
        .DATAOUT6(DO[6]),
        .DATAOUT5(DO[5]),
        .DATAOUT4(DO[4]),
        .DATAOUT3(DO[3]),
        .DATAOUT2(DO[2]),
        .DATAOUT1(DO[1]),
        .DATAOUT0(DO[0]));

endmodule
