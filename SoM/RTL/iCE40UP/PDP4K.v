`timescale 1ns/1ns
module PDP4K(DI, ADW, ADR, CKW, CKR, CEW, CER, RE, WE, MASK_N, DO); // synthesis syn_black_box
    (* \desc = "data in" *)
    input [15:0] DI;
    (* \desc = "write address" *)
    input [10:0] ADW;
    (* \desc = "read address" *)
    input [10:0] ADR;
    (* \desc = "write clock" *)
    input CKW;
    (* \desc = "read clock" *)
    input CKR;
    (* \desc = "write clock enable, active high" *)
    input CEW;
    (* \desc = "read clock enable, active high" *)
    input CER;
    (* \desc = "read enable, active high" *)
    input RE;
    (* \desc = "write enable, active high" *)
    input WE;
    (* \desc = "per-bit write enable mask, active low" *)
    input [15:0] MASK_N;
    (* \desc = "data output" *)
    output [15:0] DO;

    parameter INITVAL_0 = "0x0000000000000000000000000000000000000000000000000000000000000000";
    parameter INITVAL_1 = "0x0000000000000000000000000000000000000000000000000000000000000000";
    parameter INITVAL_2 = "0x0000000000000000000000000000000000000000000000000000000000000000";
    parameter INITVAL_3 = "0x0000000000000000000000000000000000000000000000000000000000000000";
    parameter INITVAL_4 = "0x0000000000000000000000000000000000000000000000000000000000000000";
    parameter INITVAL_5 = "0x0000000000000000000000000000000000000000000000000000000000000000";
    parameter INITVAL_6 = "0x0000000000000000000000000000000000000000000000000000000000000000";
    parameter INITVAL_7 = "0x0000000000000000000000000000000000000000000000000000000000000000";
    parameter INITVAL_8 = "0x0000000000000000000000000000000000000000000000000000000000000000";
    parameter INITVAL_9 = "0x0000000000000000000000000000000000000000000000000000000000000000";
    parameter INITVAL_A = "0x0000000000000000000000000000000000000000000000000000000000000000";
    parameter INITVAL_B = "0x0000000000000000000000000000000000000000000000000000000000000000";
    parameter INITVAL_C = "0x0000000000000000000000000000000000000000000000000000000000000000";
    parameter INITVAL_D = "0x0000000000000000000000000000000000000000000000000000000000000000";
    parameter INITVAL_E = "0x0000000000000000000000000000000000000000000000000000000000000000";
    parameter INITVAL_F = "0x0000000000000000000000000000000000000000000000000000000000000000";
    (* \desc = "Write data width", \otherValues = "{4, 8, 16}" *)
    parameter DATA_WIDTH_W = "2";
    (* \desc = "Read data width", \otherValues = "{4, 8, 16}" *)
    parameter DATA_WIDTH_R = "2";

    EBR_B ebr_inst(.RADDR10(ADR[10]),
                   .RADDR9(ADR[9]),
                   .RADDR8(ADR[8]),
                   .RADDR7(ADR[7]),
                   .RADDR6(ADR[6]),
                   .RADDR5(ADR[5]),
                   .RADDR4(ADR[4]),
                   .RADDR3(ADR[3]),
                   .RADDR2(ADR[2]),
                   .RADDR1(ADR[1]),
                   .RADDR0(ADR[0]),
                   .WADDR10(ADW[10]),
                   .WADDR9(ADW[9]),
                   .WADDR8(ADW[8]),
                   .WADDR7(ADW[7]),
                   .WADDR6(ADW[6]),
                   .WADDR5(ADW[5]),
                   .WADDR4(ADW[4]),
                   .WADDR3(ADW[3]),
                   .WADDR2(ADW[2]),
                   .WADDR1(ADW[1]),
                   .WADDR0(ADW[0]),
                   .MASK_N15(MASK_N[15]),
                   .MASK_N14(MASK_N[14]),
                   .MASK_N13(MASK_N[13]),
                   .MASK_N12(MASK_N[12]),
                   .MASK_N11(MASK_N[11]),
                   .MASK_N10(MASK_N[10]),
                   .MASK_N9(MASK_N[9]),
                   .MASK_N8(MASK_N[8]),
                   .MASK_N7(MASK_N[7]),
                   .MASK_N6(MASK_N[6]),
                   .MASK_N5(MASK_N[5]),
                   .MASK_N4(MASK_N[4]),
                   .MASK_N3(MASK_N[3]),
                   .MASK_N2(MASK_N[2]),
                   .MASK_N1(MASK_N[1]),
                   .MASK_N0(MASK_N[0]),
                   .WDATA15(DI[15]),
                   .WDATA14(DI[14]),
                   .WDATA13(DI[13]),
                   .WDATA12(DI[12]),
                   .WDATA11(DI[11]),
                   .WDATA10(DI[10]),
                   .WDATA9(DI[9]),
                   .WDATA8(DI[8]),
                   .WDATA7(DI[7]),
                   .WDATA6(DI[6]),
                   .WDATA5(DI[5]),
                   .WDATA4(DI[4]),
                   .WDATA3(DI[3]),
                   .WDATA2(DI[2]),
                   .WDATA1(DI[1]),
                   .WDATA0(DI[0]),
                   .RCLKE(CER),
                   .RCLK(CKR),
                   .RE(RE),
                   .WCLKE(CEW),
                   .WCLK(CKW),
                   .WE(WE),
                   .RDATA15(DO[15]),
                   .RDATA14(DO[14]),
                   .RDATA13(DO[13]),
                   .RDATA12(DO[12]),
                   .RDATA11(DO[11]),
                   .RDATA10(DO[10]),
                   .RDATA9(DO[9]),
                   .RDATA8(DO[8]),
                   .RDATA7(DO[7]),
                   .RDATA6(DO[6]),
                   .RDATA5(DO[5]),
                   .RDATA4(DO[4]),
                   .RDATA3(DO[3]),
                   .RDATA2(DO[2]),
                   .RDATA1(DO[1]),
                   .RDATA0(DO[0])
                  );
    defparam ebr_inst.INIT_0 = INITVAL_0; 
    defparam ebr_inst.INIT_1 = INITVAL_1; 
    defparam ebr_inst.INIT_2 = INITVAL_2; 
    defparam ebr_inst.INIT_3 = INITVAL_3; 
    defparam ebr_inst.INIT_4 = INITVAL_4; 
    defparam ebr_inst.INIT_5 = INITVAL_5; 
    defparam ebr_inst.INIT_6 = INITVAL_6; 
    defparam ebr_inst.INIT_7 = INITVAL_7; 
    defparam ebr_inst.INIT_8 = INITVAL_8; 
    defparam ebr_inst.INIT_9 = INITVAL_9; 
    defparam ebr_inst.INIT_A = INITVAL_A; 
    defparam ebr_inst.INIT_B = INITVAL_B; 
    defparam ebr_inst.INIT_C = INITVAL_C; 
    defparam ebr_inst.INIT_D = INITVAL_D; 
    defparam ebr_inst.INIT_E = INITVAL_E; 
    defparam ebr_inst.INIT_F = INITVAL_F; 
    defparam ebr_inst.DATA_WIDTH_W = DATA_WIDTH_W;
    defparam ebr_inst.DATA_WIDTH_R = DATA_WIDTH_R;
                
endmodule
