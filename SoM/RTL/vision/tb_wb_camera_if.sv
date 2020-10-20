/****************************************************************************
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

 * tb_camera_if: A simple testbench for the Wishbone camera interface
 ****************************************************************************/

`default_nettype none
`timescale 1ns/1ps

`include "wb_camera_if.sv"

module tb;


    parameter ROWS = 12;
    parameter COLS = 16;
    parameter ADR_WIDTH = 10;
    
    logic              clk=0;
    logic              rst;

    // Camera Interface
    logic              pixel_clk=0;
    logic [7:0]        pixel_dat;
    logic              frame_vld;
    logic              line_vld;
      
    // Wishbone
    logic             m_wb_cyc;
    logic             m_wb_stb;
    logic [ADR_WIDTH-1:0]    m_wb_adr;
    logic [31:0]     m_o_wb_dat;
    logic             m_wb_we;
    logic              m_wb_ack;
    // Status outputs
    logic [$clog2(COLS):0] num_rows;
    logic [$clog2(ROWS):0] num_cols;
    logic overrun;
    
    // Configuration
    logic [ADR_WIDTH-1:0]       wr_addr_start;        
    logic [31:0] timestamp;
        
    // Testbench model
    `include "camera_model.sv"


    // Camera interface: connect all default ports
    wb_camera_if #(.ADR_WIDTH(ADR_WIDTH), .COLS(COLS), .ROWS(ROWS)) u_wb_camera_if (.*);
    
    // Generate clocks
    always #10 clk = ~clk;
    always #50 pixel_clk = ~pixel_clk;

    // Always ack on the Wishbone
    assign m_wb_ack = m_wb_cyc & m_wb_stb;
    
    initial begin
        $display("Starting simulation, dumping to tb_wb_camera_if.vcd");
        $dumpfile("tb_wb_camera_if.vcd");
        $dumpvars(0, tb);
         
        #100;
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
        wr_addr_start= 'h1234;
        timestamp = 'hdeadbabe;
        
        repeat (5) @(posedge clk);
        send_incr_frame;
        
        #1000;
        $display("Number of rows: %d", num_rows);
        $display("Number of cols: %d", num_cols);
        $display("Ending simulation");
        
        $finish;
    end
    
endmodule


