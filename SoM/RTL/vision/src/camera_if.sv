/**
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


 * Module: camera_if
 * 
 * Converts the incoming camera data stream to 32 bit words and creates RAM accesses
 * Note that we DO cross clock domains in this block using a simple clock edge detector!
 * This assumes that the pixel clock is significantly slower than the bus clock.
 */

module camera_if 
        #(
        parameter ROWS = 120,
        parameter COLS = 160
        )
        (
        input logic 		     clk,
        input logic 		     rst,

        // Camera Interface
        input logic 		     pixel_clk,
        input logic [7:0]	     pixel_dat,
        input logic 		     frame_vld,
        input logic 		     line_vld,
      
        // Pixel stream output
        output logic sof,	// Start of Frame
        output logic eof,	// End of frame
        output logic [7:0] 	o_dat,	// Packed pixel data
        output logic o_vld,	// Data valid only when valid is high
     
        // Status outputs
        output logic [$clog2(COLS):0] num_cols,
        output logic [$clog2(ROWS):0] num_rows
         
        );

    // Various flags
    logic [1:0]                      pixel_clk_d;
    logic                            pixel_clk_vld;
    
    logic                            pixel_vld;
    logic                            frame_vld_1d, line_vld_1d;
    logic                            sol, eol;

    logic [$clog2(COLS):0] col_count;
    logic [$clog2(ROWS):0] row_count;
            
    // Figure out SoF, SoL, EoL signals, unused signals should synthesize away
    assign sof = frame_vld & (~frame_vld_1d) & pixel_clk_vld;
    assign sol = line_vld & (~line_vld_1d) & pixel_clk_vld;
    assign eol = (~line_vld) & line_vld_1d & pixel_clk_vld;
    assign eof = (~frame_vld) & frame_vld_1d & pixel_clk_vld;

    // Edge detect the pixel clock
    assign pixel_clk_vld = ~pixel_clk_d[0] & pixel_clk_d[1];
    
    assign pixel_vld = line_vld & frame_vld & pixel_clk_vld;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pixel_clk_d <= '0;
        
        end else begin

            // Demet the pixel clock: assumes a fast clk
            pixel_clk_d <= {pixel_clk_d[0], pixel_clk};

            // Pipeline framing signals to allow for edge detection
            if (pixel_clk_vld) begin
                frame_vld_1d <= frame_vld;
                line_vld_1d <= line_vld;
                o_dat <= pixel_dat;
            end

            o_vld <= line_vld & frame_vld & pixel_clk_vld;

            // Column counter
            if (sof)
                col_count <= '0;
            else if (eol) begin
                col_count <= '0;
                num_cols <= col_count;
            end else if (pixel_vld)
                col_count <= col_count + 'd1;

            // Row counter
            if (sof)
                row_count <= '0;
            else if (eol)
                row_count <= row_count + 'd1;

            if (eof) num_rows <= row_count;
            
        end
    end

endmodule

