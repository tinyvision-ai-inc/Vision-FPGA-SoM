`timescale        1ns/1ps
module IR_IP_CORE(             
			 CLKI,
			 IRIN,
             ADRI3,
             ADRI2,
             ADRI1,
             ADRI0,
             CSI,
             DENI,
             EXE,
             LEARN,
             RST,
             WEI,

// *** Outputs from UUT ***
             IROUT,
             BUSY,
             DRDY,
             ERR,
             RDATA0,
             RDATA1,
             RDATA2,
             RDATA3,
             RDATA4,
             RDATA5,
             RDATA6,
             RDATA7,


             WDATA0,
             WDATA1,
             WDATA2,
             WDATA3,
             WDATA4,
             WDATA5,
             WDATA6,
             WDATA7);
// *** Input to UUT ***					
 input 			  CLKI;
 input            IRIN;
 input            ADRI3;
 input            ADRI2;
 input            ADRI1;
 input            ADRI0;
 input            CSI;
 input            DENI;
 input            EXE;
 input            LEARN;
 input            RST;
 input            WEI;

// *** Outputs from UUT ***
 output            IROUT;
 output            BUSY;
 output            DRDY;
 output            ERR;
 output            RDATA0;
 output            RDATA1;
 output            RDATA2;
 output            RDATA3;
 output            RDATA4;
 output            RDATA5;
 output            RDATA6;
 output            RDATA7;


 input            WDATA0;
 input            WDATA1;
 input            WDATA2;
 input            WDATA3;
 input            WDATA4;
 input            WDATA5;
 input            WDATA6;
 input            WDATA7;


wire [7:0] wdata ={ WDATA7,WDATA6,WDATA5,WDATA4,WDATA3,WDATA2,WDATA1,WDATA0}; 
//wire [7:0] rdata ={ RDATA7,RDATA6,RDATA5,RDATA4,RDATA3,RDATA2,RDATA1,RDATA0}; 
wire [7:0] rdata; 
assign {RDATA7,RDATA6,RDATA5,RDATA4,RDATA3,RDATA2,RDATA1,RDATA0} = rdata; 
wire [3:0] adri ={ADRI3,ADRI2,ADRI1,ADRI0}; 
reg irtcv_rst_async;
initial begin
irtcv_rst_async = 1'b1;
#100
irtcv_rst_async = 1'b0;
end
//** Instantiate the  module **
irtcv_ip     irtcv_ip_inst     (.irtcv_clk (CLKI),
                           .ir_in (IRIN),
                           .irtcv_adr (adri),
                           .irtcv_cs (CSI),
                           .irtcv_den (DENI),
                           .irtcv_exe (EXE),
                           .irtcv_learn (LEARN),
                           .irtcv_rst_async (irtcv_rst_async),
                           .irtcv_wdat (wdata),
                           .irtcv_we (WEI),

                           .ir_out (IROUT),
                           .irtcv_busy (BUSY),
                           .irtcv_drdy (DRDY),
                           .irtcv_err (ERR),
                           .irtcv_rdat (rdata));


endmodule
