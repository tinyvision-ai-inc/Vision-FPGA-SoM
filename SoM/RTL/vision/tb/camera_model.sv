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
*/

    /*
     Send out a single frame of known data for verification
     Assumes ROWS, COLS as defined constants
     */

/********************************************************************/
/*  Copyright (c) 2020 tinyVision.ai Inc.

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
/********************************************************************/

module camera_model #(
  parameter FOUR_BITS  = "FALSE",
  parameter WIDTH      = 8  ,
  parameter MAX_COLS   = 1000,
  parameter MAX_ROWS   = 1000,
  parameter HOR_BLANK  = 4   ,
  parameter VERT_BLANK = 6
) (
  input                    clk  ,
  output logic [WIDTH-1:0] pixel,
  output logic             vsync,
  output logic             hsync
);

  initial begin
    vsync = 1'b0;
    hsync = 1'b0;
    pixel = '0;
  end

  // Add a prefix to the frame: this is when VSYNC goes active.
  task vert_blank_start;
    begin
      #1 vsync = '0;
      hsync = '0;
      repeat(VERT_BLANK) @(posedge clk);
      #1 vsync = '1;
    end
  endtask

  task vert_blank_end;
    begin
      #1 vsync = '1;
      hsync = '0;
      repeat(VERT_BLANK) @(posedge clk);
      #1 vsync = '0;
    end
  endtask

task hor_blank;
    begin
        #1 vsync = '1;
        hsync = '0;
        pixel = '0;
        repeat(HOR_BLANK) @(posedge clk);
    end
endtask

task write_pixel;
    input [WIDTH-1:0] pxl;
    begin
        vsync = '1;
        hsync = '1;
        #1 pixel = pxl;
        @(posedge clk);
    end
endtask

task write_pixel_4bits;
    input [WIDTH-1:0] pxl;
    begin
        vsync = '1;
        hsync = '1;
        #1 pixel = '0;
           pixel[WIDTH/2-1:0] = pxl[WIDTH-1:WIDTH/2];
        @(posedge clk);
           pixel[WIDTH/2-1:0] = pxl[WIDTH/2-1:0];
        @(posedge clk);
    end
endtask

task write_frame;
    input integer num_cols;
    input integer num_rows;
    input logic [WIDTH-1:0] data_i [0:MAX_COLS*MAX_ROWS-1];
    begin
        integer row_cnt;
        row_cnt = 0;
        //$display("Starting: cols: %02d, rows:%02d", num_cols, num_rows);

        vert_blank_start();

        for (int r=0; r<num_rows; r++) begin
            hor_blank();

            // Pixel data
            for (int c=0; c<num_cols; c++) begin
                if (FOUR_BITS == "FALSE")
                    write_pixel(data_i[r*num_cols+c]);
                else
                    write_pixel_4bits(data_i[r*num_cols+c]);
            end

            // End the frame
            hor_blank();
            vert_blank_end();
            //$display("EOF\n");

        end
    end
endtask

endmodule

/*
task send_incr_frame;
    
        begin
            
            frame_vld = '0;
            line_vld = '0;
            pixel_dat = '0;
            $display("Starting image transfer");
            
            repeat (10) @(posedge pixel_clk);
            frame_vld = '1;
            
            repeat (5) @(posedge pixel_clk);
            
            repeat (ROWS) begin
                line_vld = '0;
                repeat (5) @(posedge pixel_clk);
                line_vld = '1;
                repeat (COLS) begin
                    pixel_dat = pixel_dat + 'd1;
                    @(posedge pixel_clk);
                end
                
                line_vld = '0;
                
            end
            repeat (10) @(posedge pixel_clk);
            frame_vld = '0;
        end
        
endtask // send_incr_frame
*/