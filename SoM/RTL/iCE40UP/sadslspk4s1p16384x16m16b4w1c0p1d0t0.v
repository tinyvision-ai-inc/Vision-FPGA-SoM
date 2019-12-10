`include "defines7.v"
`timescale 1 ns / 1 ps 
module sadslspk4s1p16384x16m16b4w1c0p1d0t0 ( Q, ADR, D, WEM, WE, ME, CLK, TEST1, RME, RM, LS, DS, SD);

// Input/Output Ports Declaration
output  [15:0] Q;
input  [13:0] ADR;
input  [15:0] D;
input  [15:0] WEM;
input WE;
input ME;
input CLK;
input TEST1;
input RME;
input  [3:0] RM;
input LS;
input DS;
input SD;


// Local registers, wires, etc
`ifdef MEM_CHECK_OFF
parameter MES_CNTRL = "OFF";
`else
parameter MES_CNTRL = "ON";
`endif
`ifndef MES_CNTRL_DEL_BEGIN
  `define MES_CNTRL_DEL_BEGIN 0
`endif

`ifndef MES_CNTRL_DEL_END
  `define MES_CNTRL_DEL_END 0
`endif
parameter MesCntrl_Begin = `MES_CNTRL_DEL_BEGIN;
parameter MesCntrl_End = `MES_CNTRL_DEL_END;


reg disp_LS_msg;
reg disp_DS_msg;
reg disp_SD_msg;

reg en_msg_cntrl, mes_all_valid_old;
real msg_start_lmt, msg_end_lmt;
reg disp_LS_msg_old;
reg disp_DS_msg_old;
reg disp_SD_msg_old;
initial
begin
  en_msg_cntrl = 1'b0;
  mes_all_valid_old = 1'b0;
  disp_LS_msg_old = 1'b1;
  disp_DS_msg_old = 1'b1;
  disp_SD_msg_old = 1'b1;
  if (MesCntrl_Begin < 0)
    msg_start_lmt = 0;
  else
    msg_start_lmt = MesCntrl_Begin;
  if (MesCntrl_End < 0)
    msg_end_lmt = 0;
  else
    msg_end_lmt = MesCntrl_End;
  
  if (msg_end_lmt > msg_start_lmt)
  begin
    en_msg_cntrl <= #(msg_start_lmt) 1'b1;
    en_msg_cntrl <= #(msg_end_lmt) 1'b0;
  end
end

`ifdef MES_CNTRL_PIN
always @(`MES_CNTRL_PIN)
begin
  if (msg_start_lmt == 0 && msg_end_lmt == 0)
  begin
    if (`MES_CNTRL_PIN  === `MES_CNTRL_PIN_VAL)
    begin
      en_msg_cntrl = 1;
    end
    else
    begin
      en_msg_cntrl = 0;
    end
  end
end
`endif

always @( en_msg_cntrl )
begin
  if (en_msg_cntrl == 1'b1 )
  begin
    mes_all_valid_old = uut.mes_all_valid;
    assign uut.mes_all_valid = 0;
    disp_LS_msg_old = disp_LS_msg;
    assign disp_LS_msg = 0;
    disp_DS_msg_old = disp_DS_msg;
    assign disp_DS_msg = 0;
    disp_SD_msg_old = disp_SD_msg;
    assign disp_SD_msg = 0;
  end
  else
  begin
    deassign uut.mes_all_valid ;
    uut.mes_all_valid = mes_all_valid_old;
    deassign disp_LS_msg;
    disp_LS_msg = disp_LS_msg_old;
    deassign disp_DS_msg;
    disp_DS_msg = disp_DS_msg_old;
    deassign disp_SD_msg;
    disp_SD_msg = disp_SD_msg_old;
  end
end




`ifndef VIRAGE_IGNORE_SD_HAZARD
reg ds_sd_buf;

initial
begin
 ds_sd_buf = 1'b0;
end

always @(posedge SD)
begin
  if (DS === 1'b1)
  begin
    ds_sd_buf <= 1'b1;
  end
end

always @(SD)
begin
  if (SD === 1'b0)
  begin
    ds_sd_buf <= 1'b0;
  end
end
`endif

wire sel_pwr;
`ifndef VIRAGE_IGNORE_SD_HAZARD
wire sel_pwr_ds_sd;
assign sel_pwr_ds_sd = DS || SD;
assign sel_pwr = ( ds_sd_buf === 1'b0) ? sel_pwr_ds_sd : 1'bx;
`else
assign sel_pwr = DS || SD;
`endif

wire sel_pwr1,inv_sel_pwr1;
assign sel_pwr1 = ((CLK === 1'b0) ? sel_pwr : ((CLK === 1'b1) ? sel_pwr1 : (sel_pwr | sel_pwr1)));
assign CLK_mout = CLK && inv_sel_pwr1;
assign inv_sel_pwr1 = !(sel_pwr1);

reg ME_latch;
always @ (negedge CLK or ME )
begin
  if (CLK === 1'b0)
    ME_latch =  ME;
end
always @ ( negedge DS or negedge SD)
begin
  if (DS !== 1'b1 && SD !== 1'b1)
  begin
    if ( (CLK === 1'bX || CLK === 1'bZ ) && ME_latch !== 1'b0)
    begin
      uut.Q <= 16'bX;
      uut.corrupt_all_loc(`True);
    end
  end
end
always @(DS or SD)
begin
  if (DS === 1'b1 || SD === 1'b1)
     uut.pwr_dwn = 1'b1;
  else
     uut.pwr_dwn = 1'b0;
end

reg flag_sel_tmp_pwr;
always @ (sel_pwr)
begin
  if ( (DS === 1'b1) || (SD === 1'b1) )
  begin
    flag_sel_tmp_pwr = 1'b1;
`ifndef VIRAGE_IGNORE_SD_HAZARD
    if (ds_sd_buf == 1'b1)
   begin
    uut.Q <= 16'bX;
    end
`endif
  end
  else if ( sel_pwr === 1'bX )
  begin
    flag_sel_tmp_pwr = 1'b0;
  end
  else if ( (DS === 1'b0) && (SD === 1'b0) && flag_sel_tmp_pwr && (CLK !== 1'bx && CLK !== 1'bz))
  begin
    uut.Q <= 16'b0;
  end
end
wire [15:0] Q_mem;
wire [15:0] Q_tmp;
reg  [15:0] Q_buf;
`ifndef VIRAGE_IGNORE_SD_HAZARD
assign Q_tmp = (sel_pwr === 1'b1 )?16'b0:((sel_pwr === 1'bX) ? 16'bX : Q_mem);
`else
assign Q_tmp = (sel_pwr)?16'b0:Q_mem;
`endif
always @ ( posedge DS or posedge SD )
begin
  if ( (SD !== 1'bX) && (DS !== 1'bX) )
    uut.Q <= 16'b0;
end

always @ ( Q_tmp )
begin
  Q_buf <= Q_tmp;
end

assign Q = Q_buf;

initial
begin
disp_LS_msg = 1'b1;
disp_DS_msg = 1'b1;
disp_SD_msg = 1'b1;
end

// Display the warning when LS is 1.

always @ ( negedge LS )
begin
  disp_LS_msg = 1'b1;
  disp_LS_msg_old = 1'b1;
end

always @ (posedge LS or posedge CLK)
begin : blk_ls_0
  if (LS === 1'b1 && ME_latch !== 1'b0 && DS === 1'b0 && SD === 1'b0)
  begin
    if( (MES_CNTRL=="ON" || MES_CNTRL=="WARN") && disp_LS_msg === 1'b1 )
    begin
      $display("<<VIRL_MEM_WARNING:  No Operation as Memory is in Light Sleep mode.>> time=%0t instance=%m", $time);
      disp_LS_msg = 1'b0;
    end
  end // if LS = 1
end // end of always block blk_ls_0

// Display the warning when DS is 1.

always @ ( negedge DS )
begin
  disp_DS_msg = 1'b1;
  disp_DS_msg_old = 1'b1;
end

always @ (posedge DS or posedge CLK)
begin : blk_ds_0
  if (DS === 1'b1 && ME_latch !== 1'b0 && SD === 1'b0)
  begin
    if( (MES_CNTRL=="ON" || MES_CNTRL=="WARN") && disp_DS_msg === 1'b1 )
    begin
      $display("<<VIRL_MEM_WARNING:  No Operation as Memory is in Deep Sleep mode.>> time=%0t instance=%m", $time);
      disp_DS_msg = 1'b0;
    end
  end // if DS = 1
end // end of always block blk_ds_0

// Display the warning when SD is 1.

always @ ( negedge SD )
begin
  disp_SD_msg = 1'b1;
  disp_SD_msg_old = 1'b1;
end

always @ (posedge SD or posedge CLK)
begin : blk_sd_0
  if (SD === 1'b1 && ME_latch !== 1'b0)
  begin
    if( (MES_CNTRL=="ON" || MES_CNTRL=="WARN") && disp_SD_msg === 1'b1 )
    begin
      $display("<<VIRL_MEM_WARNING:  No Operation as Memory is in ShutDown mode.>> time=%0t instance=%m", $time);
      disp_SD_msg = 1'b0;
    end
  end // if SD = 1
end // end of always block blk_sd_0

generic_behav_sadslspk4s1p16384x16m16b4w1c0p1d0t0 #( MES_CNTRL) uut ( .Q(Q_mem), .ADR(ADR), .D(D), .WEM(WEM), .WE(WE), .ME(ME), .CLK(CLK_mout), .LS(LS), .DS(DS), .SD(SD) );

endmodule
