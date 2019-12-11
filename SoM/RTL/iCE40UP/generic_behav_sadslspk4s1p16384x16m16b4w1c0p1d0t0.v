`include "defines7.v"
`timescale 1 ns / 1 ps 
module generic_behav_sadslspk4s1p16384x16m16b4w1c0p1d0t0 (  Q, ADR, D, WEM, WE, ME, CLK, LS, DS, SD );

parameter MES_CNTRL = "ON";
parameter words = 16384, bits = 16, addrbits = 14, wembits=16;

output [bits-1:0] Q;
input [addrbits-1:0] ADR;
input [bits-1:0] D;
input [wembits-1:0] WEM;
input WE;
input ME;
input CLK;
input LS;
input DS;
input SD;

reg [bits-1:0] Q;

reg MElatched;


reg flag_clk_valid;
reg mes_all_valid;

wire [1:0] ADR_valid;
reg [15:0] mem_core_array [0:16383];

parameter DataX = { bits { 1'bx } };

// -------------------------------------------------------------------
// Common tasks
// -------------------------------------------------------------------

// Task to report unknown messages
reg pwr_dwn;

initial
begin
  pwr_dwn = 1'b0;
end

task report_unknown;
input [8*5:1] signal;
  begin
  if ( (pwr_dwn === 1'b0) || (pwr_dwn === 1'b1 && ( signal == "DS" || signal == "SD" )) )
  begin
      if( (MES_CNTRL=="ON" || MES_CNTRL=="ERR") && $realtime != 0 && mes_all_valid )
      begin
        $display("<<VIRL_MEM_ERR:%0s unknown>> at time=%t; instance=%m (RAMS1H)",signal,$realtime);
      end
   end
 end
endtask


task corrupt_all_loc;
 input flag_range_ok;
 integer addr_index;
 begin
   if( flag_range_ok == `True)
   begin
   for( addr_index = 0; addr_index < words; addr_index = addr_index + 1)
   begin
     mem_core_array[ addr_index] = DataX;
   end
  end
 end
endtask



initial 
begin
  flag_clk_valid = `False;
  mes_all_valid = 1'b0;
end 

assign ADR_valid = (( ^ADR === 1'bx ) ? 2'b01 : ( ( ADR > 14'b11111111111111 ) ? 2'b10 : 2'b00 ));

always @ ( negedge CLK )
begin : blk_negedge_clk_0
  if ( CLK !== 1'bx && CLK !== 1'bz )
  begin
    flag_clk_valid = `True;
  end // end if CLK != X
  else
  begin
    report_unknown("CLK");
    flag_clk_valid = `False;
    Q = DataX;
    corrupt_all_loc(`True);
  end // end of else of CLK != X
end // end of block blk_negedge_clk_0

always @ ( posedge CLK )
begin : blk_posedge_clk_0
  MElatched = ME;
  if ( (SD !== 1'b0) || (DS === 1'b1) || (DS === 1'b0 && LS === 1'b1 && MElatched !== 1'bx) )
  begin
    MElatched = 1'b0;
  end
  if ( LS === 1'bX && MElatched !== 1'b0 )
  begin
    report_unknown("LS");
    corrupt_all_loc(`True);
    Q = 16'bx;
  end
  else if ( DS === 1'bX )
  begin
    corrupt_all_loc(`True);
    Q = 16'bx;
  end
  else
  begin
    if ( flag_clk_valid )
    begin
      if ( CLK === 1'b1)
      begin
        if ( MElatched === 1'b1) 
        begin
          if ( WE === 1'b1) 
          begin
            WritePort;
          end // end of Write
          else if ( WE === 1'b0 )
          begin
            ReadPort;
          end // end of Read
          else
          begin
            report_unknown("WE");
            mem_core_array[ADR] = mem_core_array[ADR] ^ ( WEM & DataX );
            if ( ADR_valid === 2'b00 ) 
            begin
              if ( ^WEM === 1'bx )
              begin
                report_unknown("WEM");
                mem_core_array[ADR] = mem_core_array[ADR] ^ ( WEM & DataX );
              end
              Q = DataX;
            end // end of if ADR_valid = 2'b00
            else if ( ADR_valid === 2'b01 ) 
            begin
              Q = DataX;
             `ifdef virage_ignore_read_addx
              if ( WEM !== {wembits {1'b0}} )
                corrupt_all_loc(`True);
              `else
                corrupt_all_loc(`True);
              `endif
            end // end of else of ADR_valid = 2'b01
          end // end of else of WE = X
        end // end of MElatched = 1
        else
        begin
          if ( MElatched === 1'bx ) 
          begin
            report_unknown("ME");
            `ifdef virage_ignore_read_addx
              if ( WE === 1'b1 )
              begin
                corrupt_all_loc(`True);
              end
              else
              begin
                Q = 16'bx;
              end
            `else
              begin
                corrupt_all_loc(`True);
                if ( WE !== 1'b1 )
                  Q = 16'bx;
              end
            `endif
          end // end of if MElatched = X
        end // end of else of MElatched = 1
      end // end of if CLK = 1
      else 
      begin
        if ( CLK === 1'bx || CLK === 1'bz ) 
        begin
          report_unknown("CLK");
          Q = DataX;
          corrupt_all_loc(`True);
        end // end of if CLK = 1'bx
      end // end of else of CLK = 1
    end // end of if flag_clk_valid = 1
    else 
    begin
      Q = DataX;
      corrupt_all_loc(`True);
    end // end of else of flag_clk_valid = 1
  end // end of else of LS = 1
end // end of block blk_posedge_clk_0


task WritePort;
begin : blk_WritePort
  if ( ADR_valid === 2'b00 )
  begin
    mem_core_array[ADR] = (( mem_core_array[ADR] & ~WEM ) | ( D & WEM ) ^ ( WEM ^ WEM ));
    if ( !mes_all_valid )
       mes_all_valid = 1'b1;
    if ( ^WEM === 1'bx )
    begin
      report_unknown("WEM");
    end
    if ( ^((D^D) & WEM) === 1'bx )
    begin
      report_unknown("D");
    end
  end // end of if ADR_valid = 2'b00
  else if (ADR_valid === 2'b10 )
  begin
    if ( (MES_CNTRL == "ON" || MES_CNTRL == "WARN") && $realtime != 0 && mes_all_valid )
    begin
      $display("<<VIRL_MEM_WARNING:address is out of range\n RANGE:0 to 16383>> at time=%t; instance=%m (RAMS1H)",$realtime);
    end // end of if mes_all_valid 
  end // end of else of ADR_valid = 2'b10
  else 
  begin
    report_unknown("ADR");
    `ifdef virage_ignore_read_addx
       if ( WEM !== {wembits {1'b0}} )
         corrupt_all_loc(`True);
    `else
       corrupt_all_loc(`True);
    `endif
  end // end of else of ADR_valid = 2'b01
end // end of block blk_WritePort
endtask

task ReadPort;
begin : blk_ReadPort
  if ( ADR_valid === 2'b00 )
  begin
    Q = mem_core_array[ADR];
  end // end of if ADR_valid = 2'b00
  else if ( ADR_valid === 2'b10 )
  begin
    Q = DataX;
    if ( (MES_CNTRL == "ON" || MES_CNTRL == "WARN") && $realtime != 0 && mes_all_valid )
    begin
      $display("<<VIRL_MEM_WARNING:address is out of range\n RANGE:0 to 16383>> at time=%t; instance=%m (RAMS1H)",$realtime);
    end // end of if mes_all_valid
  end // end of else of ADR_valid = 2'b10
  else 
  begin
    report_unknown("ADR");
    Q = DataX;
    `ifdef virage_ignore_read_addx
      if ( WE === 1'b1 )
        corrupt_all_loc(`True);
    `else
        corrupt_all_loc(`True);
    `endif
  end // end of else of ADR_valid = 2'b01
end // end of block blk_ReadPort
endtask

always @ ( DS )
begin :blk_DS
  if ( DS === 1'bX )
  begin
    report_unknown("DS");
    Q = 16'bX;
  end // end id DS = X
end // end blk_DS

always @ (posedge SD )
begin : blk_SD
  corrupt_all_loc(`True);
  if ( SD === 1'bX )
  begin
    report_unknown("SD");
    Q = 16'bX;
  end
end // end blk_SD
endmodule
