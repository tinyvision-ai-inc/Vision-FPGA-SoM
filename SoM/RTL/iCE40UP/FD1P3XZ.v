`timescale 1ns/1ns
module FD1P3XZ(D, SP, CK, SR, Q);

  parameter REGSET = "RESET";
  parameter SRMODE = "CE_OVER_LSR";


  input D;
  input SP;
  input CK;
  input SR;
  output reg Q = 1'b0; 

  //default clock enable
  assign (weak0, weak1) SR = 1'b0;
  assign (weak0, weak1) SP = 1'b1;
  assign (weak0, weak1) D = 1'b0;

  always @ (posedge CK) begin 
    if (SP) begin //Clock enable before LSR 
      if (SR) begin //if local set, reset
        if (SRMODE == "CE_OVER_LSR") begin
          Q <= (REGSET == "RESET")? 1'b0 : SR; //if REGSET = RESET, synchronous reset; else synchronous preset 
        end

      end else begin 
        Q <= (D === 1'bx || D === 1'bz)? 0 : D; //normal reg operation       
      end

    end 
  end 

  always @(*) begin 
    if (SRMODE == "ASYNC" && SR) begin //ASYNC mode. Don't need to wait on CLK or CE
      Q <= (REGSET == "RESET")? 1'b0 : SR; //if REGSET = SET, async reset ; else async preset
    end  
  end
endmodule
