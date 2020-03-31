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

module tb_wb_spi_slave;
   
   parameter debug = 0;
   
   logic               clk = 1'b0;                  // To dut of wb_spi_slave.v
   logic               rst, rst_in;                  // To dut of wb_spi_slave.v
   
   logic               i_wb_ack;               // To dut of wb_spi_slave.v
   logic [7:0] 	       i_wb_dat;               // To dut of wb_spi_slave.v
   logic [23:0]        o_wb_adr;               // From dut of wb_spi_slave.v
   logic               o_wb_cyc;               // From dut of wb_spi_slave.v
   logic [7:0] 	       o_wb_dat;               // From dut of wb_spi_slave.v
   logic               o_wb_stb;               // From dut of wb_spi_slave.v
   logic               o_wb_we;                // From dut of wb_spi_slave.v
   
   logic               spi_mosi;                   // To dut of wb_spi_slave.v
   logic               spi_miso;               // From dut of wb_spi_slave.v
   logic               spi_clk;                    // To dut of wb_spi_slave.v
   logic               spi_ss;                    // To dut of wb_spi_slave.v

   logic 	       reset_out;
   logic [7:0] 	       spi_id;
   logic [7:0] 	       spi_status;
   
   logic [31:0]        recvWord;
   int                 i;

`include "tb_spi_helper.sv"
   assign rst_in = rst || reset_out;

   wb_spi_slave dut
     (
      .clk                             (clk),
      .rst                             (rst_in),

      .sck                               (spi_clk),
      .ssn                               (spi_ss),
      .mosi                              (spi_mosi),
      .miso                              (spi_miso),
      .*);

   // Implement a memory for testing
   logic [7:0] 	       mem[1023:0];
   
   always @(posedge clk) begin
      i_wb_ack <= o_wb_stb;

      if (o_wb_stb) begin
         if (o_wb_we)
           mem[o_wb_adr] <= o_wb_dat;
         else
           i_wb_dat <= mem[o_wb_adr];
      end
      
   end

   initial begin
      $monitor("%t:: Reset wiggled, current state: %b", $time, reset_out);
   end
   logic [7:0] temp1, temp2;

   // Stimulus
   always #10 clk = ~clk;

   initial begin
      $display("Starting simulation");
      $dumpfile("tb_spi_slave.vcd");
      $dumpvars;
      
      // Log the memories
      //for (int i=0; i<32; i++) $dumpvars(0, dut.image_mem[i]);
      
      spi_ss = '1;
      spi_mosi = '0;
      spi_clk = '0;
      spi_id = 'hde;
      spi_status = 'hba;
      
      #100 rst = '1;
      #100 rst = '0;
      #100;
      $display("You should see reset wiggling here...");
      
      spiSendReset();
      #100;
      
      spiGetID(temp1, temp2);
      `expect_h("SPI ID: ", spi_id, temp1);
      `expect_h("SPI STATUS: ", spi_status, temp2);

      spiWriteStart(24'h10);
      for (int i=0; i<16; i++)
        spiWriteNext(255-i);
      spiWriteEnd();
      
      #100;
      
      spiReadStart(24'h10);
      for (int i=0; i<16; i++) begin
         spiReadNext(recvWord);
         `expect_h("SPI read: ", 255-i, recvWord);
      end
      spiReadEnd();
      
      
      #10000;
      $display("Finishing simulation");
      $finish;
      
   end
   
   
endmodule // tb_spi_slave
// Local Variables:
// verilog-library-flags:("-y ../src")
// End:
