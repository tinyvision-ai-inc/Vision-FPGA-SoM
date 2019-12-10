`timescale 1ps/100fs
module mipi_deserializer (
   RxDDRClkHS,
   DRXHSP,
   HS_DESER_EN,
   HSRX_DATA,
   HS_BYTE_CLKD,
   SYNC,
   ERRSYNC,
   NOSYNC,
   ENP
);
// inputs
parameter               WIDTH=8;
input                   RxDDRClkHS;  // half-rate clock, from RX clock lane.
input                   HS_DESER_EN; // "pay attension to incoming serial!"
input                   DRXHSP;      // 1-bit serial input.
input                   ENP;         // Enables byteclock when HIGH
// outputs
output [WIDTH-1:0]      HSRX_DATA;    // byte of deserialized data.
output                  HS_BYTE_CLKD;  // pulses high when "HSRX_DATA" contains valid byte.
output                  SYNC;
output                  ERRSYNC;
output                  NOSYNC;

reg  [WIDTH-1:0]        Q; 
reg                     D6I;
wire                    div_en;
reg                     div0;
reg                     div1;  
reg  [WIDTH-1:0]        HSRX_DATA;

wire                     HS_BYTE_CLKD;  // pulses high when "HSRX_DATA" contains valid byte.
wire                     ByteClkI; 
wire                     comp_en;
wire  val_int_0;
wire  val_int_1;
reg  val_int0_0;
reg  val_int1_0;
reg  val_int2_0;
reg  val_int0_1;
reg  val_int1_1;
reg  val_int2_1;
reg  no_sync_ff0;
reg  no_sync_ff1;

wire SYNC;
wire ERRSYNC;
wire NOSYNC;

wire set_val_fb0;
wire set_val_fb1;
wire set_val_0;
wire set_val_1;
wire set_val_fbnosync;
wire set_val_nosync;

wire  [7:0]       one_bit_error;
wire              one_bit_error_in_shift_reg;
wire reser_int;

  always @ (posedge RxDDRClkHS or negedge HS_DESER_EN)
    begin
      if (HS_DESER_EN == 0) 
        D6I <= 1'b0;
      else
        D6I <= DRXHSP;
    end
  always @ (negedge RxDDRClkHS or negedge HS_DESER_EN)
    begin
      if (HS_DESER_EN == 0)
        begin
          Q[7] <= 1'b0;
          Q[6] <= 1'b0;
          Q[5] <= 1'b0;
          Q[4] <= 1'b0;
          Q[3] <= 1'b0;
          Q[2] <= 1'b0;
          Q[1] <= 1'b0;
          Q[0] <= 1'b0;
        end
      else
        begin
          Q[7] <= DRXHSP;
          Q[6] <= D6I;
          Q[5] <= Q[7];
          Q[4] <= Q[6];
          Q[3] <= Q[5];
          Q[2] <= Q[4];
          Q[1] <= Q[3];
          Q[0] <= Q[2];
        end
      end // end of always statement
      
      // Generate ByteClock 
    always @ (posedge RxDDRClkHS or negedge div_en)
      begin
        if (div_en == 0)
          begin
            div0 <= 1'b0;
            div1 <= 1'b0;
          end
        else
          begin
            div0 <= ~div1;
            div1 <=  div0;
          end
       end
    assign ByteClkI     =  div1;
    assign HS_BYTE_CLKD = ~div1;       
   
    always @ (posedge ByteClkI or negedge HS_DESER_EN)   
      begin
        if (HS_DESER_EN == 0)
          HSRX_DATA <= 8'b00000000;
        else
          HSRX_DATA <= Q[7:0];
      end
      
  
    assign val_int_0 = (Q[7:0] == 8'b10111000)& comp_en; 
     
    
    // One-Bit Error
    assign one_bit_error_in_shift_reg = |one_bit_error;
      genvar i;
      generate
        for (i=0; i<8; i=i+1)
          begin: compare_against_sync_token_with_one_wrong_bit
            assign one_bit_error[i]  =       //  token       ^    mask
               (Q[7:0] == (8'b10111000 ^ (1'b1<<i)));
          end
     endgenerate

    assign val_int_1 = one_bit_error_in_shift_reg & comp_en; 
     
    assign reset_int =  (~HS_DESER_EN || NOSYNC);  
    // SYNC and ERRSYNC
   always @ (negedge RxDDRClkHS or posedge reset_int)
      begin  
          if ((HS_DESER_EN == 0) || (NOSYNC == 1))
           begin
             val_int0_0 <= 1'b0;
              val_int0_1 <= 1'b0;
            end
          else
            begin
              val_int0_0 <= val_int_0;
              val_int0_1 <= val_int_1;
            end
        end
        

//      always @ (posedge RxDDRClkHS or  posedge reset_int)
//        begin
//            if ((HS_DESER_EN == 0) || (NOSYNC == 1))
//                set_val_0 = 1'b0;
//            else if (val_int0_0)
//                set_val_0 = 1'b1;
//            else
//                set_val_0 = 1'b0;     
//        end
       
//    always @ (posedge RxDDRClkHS or posedge reset_int)
//        begin
//            if ((HS_DESER_EN == 0) || (NOSYNC == 1))
//                set_val_1 = 1'b0;
//            else if (val_int0_1 || val_int0_0)
//                set_val_1 = 1'b1;
//            else
//                set_val_1 = 1'b0;     
//        end 

assign set_val_fb0 = ~(set_val_0  || val_int0_0);
assign set_val_0   = ~( reset_int || set_val_fb0 );        

assign set_val_fb1 = ~(set_val_1  || (val_int0_0 || val_int0_1) );
assign set_val_1   = ~( reset_int || set_val_fb1 );
             
             always @ (negedge RxDDRClkHS or HS_DESER_EN or NOSYNC)
             begin  
                 if ((HS_DESER_EN == 0) || (NOSYNC == 1))
                  begin
                    val_int1_0 <= 1'b0;
                    val_int1_1 <= 1'b0;         
                  end
                 else
                   begin
                     val_int1_0 <= set_val_0;
                     val_int1_1 <= set_val_1;
                   end
               end 
             
             always @ (posedge RxDDRClkHS or HS_DESER_EN or NOSYNC)
             begin  
                 if ((HS_DESER_EN == 0) || (NOSYNC == 1))
                  begin
                    val_int2_0 <= 1'b0;
                    val_int2_1 <= 1'b0;
                  end
                 else
                   begin
                     val_int2_0 <= val_int1_0;
                     val_int2_1 <= val_int1_1;
                   end
               end
             
      
      assign SYNC    = val_int2_0;
      assign ERRSYNC = val_int2_1 & ~val_int2_0;
      assign comp_en =  ~ (set_val_1 | NOSYNC) & HS_DESER_EN;
      assign div_en  =  (val_int2_1 || ENP);
      
      // NOSYNC
      
      always @ (negedge RxDDRClkHS or negedge HS_DESER_EN)
        begin
          if (HS_DESER_EN == 0)
           begin
             no_sync_ff0 <= 1'b0;
             no_sync_ff1 <= 1'b0;
           end
         else
           begin
             no_sync_ff0 <= (Q[0] | Q[1]);
             no_sync_ff1 <= no_sync_ff0 & ~val_int1_1;
             
           end
         end
     
     
   //      always @ (posedge no_sync_ff1  or  negedge HS_DESER_EN)
   //     begin
   //         if (HS_DESER_EN == 0)
   //             set_val_nosync = 1'b0;
   //         else if (no_sync_ff1)
   //             set_val_nosync = 1'b1;
   //         else
   //             set_val_nosync = 1'b0;   
   //    end 
   assign  set_val_nosync = ~(set_val_fbnosync || ~HS_DESER_EN); 
   assign  set_val_fbnosync   = ~(no_sync_ff1 || set_val_nosync);    
      
      assign NOSYNC = set_val_nosync; 
         
   
          

endmodule // module deserializer
