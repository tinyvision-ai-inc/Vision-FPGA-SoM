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

 * tb_camera_if: A simple testbench for the camera interface
 ****************************************************************************/

//`default_nettype none
`timescale 1ns/1ps

module tb_camera_if;


    parameter ROWS = 12;
    parameter COLS = 16;
        
    logic              clk=0;
    logic              rst;

    // Camera Interface
    logic       pixel_clk = 0;
    logic [7:0] pixel_dat    ;
    logic       frame_vld    ;
    logic       line_vld     ;

    // Pixel stream output
    logic       sof  ;
    logic       eof  ;
    logic [7:0] o_dat;
    logic       o_vld;

    `include "camera_model.sv"

    // Status outputs
    logic [$clog2(COLS):0] num_rows;
    logic [$clog2(ROWS):0] num_cols;

    // Camera interface: connect all default ports
    camera_if #(.COLS(COLS), .ROWS(ROWS)) u_camera_if (.*);
    
    // Generate clocks
    always #10 clk = ~clk;
    always #50 pixel_clk = ~pixel_clk;

    initial begin
        $display("Starting simulation");
        $dumpfile("tb_camera_if.vcd");
        $dumpvars(0, tb_camera_if);
         
        #100;
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;

        repeat (5) @(posedge clk);
        send_incr_frame;
        
        #1000;
        $display("Number of rows: %d", num_rows);
        $display("Number of cols: %d", num_cols);
        $display("Ending simulation");
        
        $finish;
    end
    
endmodule


