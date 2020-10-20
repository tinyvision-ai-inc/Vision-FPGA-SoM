/* 
 Copyright (c) 2020 tinyVision.ai Inc.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 3. Neither the name of the copyright holder nor the names of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission.

 4. The Software/Firmware is used solely in conjunction with devices provided by
 tinyVision.ai Inc. 

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.

 For a license to use on non-tinyVision.ai Inc. hardware, please contact license@tinyvision.ai
 */

`timescale 1ns/1ns

module tb_top;
   
   parameter debug = 0;
   
   logic               clk = 1'b0;
   logic               rst, rst_in;
   logic		led_blue;
   logic		led_green;
   logic		led_red;
   logic [2:0] gpio;   
   
   top #(/*AUTOINSTPARAM*/)
   dut 
   (/*AUTOINST*/
    // Outputs
    .gpio				(gpio[2:0]),
    .led_red				(led_red),
    .led_green				(led_green),
    .led_blue				(led_blue)
   );   

   // Stimulus
   always #10 clk = ~clk;

   initial begin
      $display("Starting simulation");
      $dumpfile("tb_top.vcd");
      $dumpvars;
      
      // Log the memories
      //for (int i=0; i<32; i++) $dumpvars(0, dut.image_mem[i]);
      
      #50000000;
      $display("Finishing simulation");
      $finish;
      
   end
   
   
endmodule // tb_spi_slave
