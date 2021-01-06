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

/**
 * Module: camera_if
 * 
 * Converts the incoming camera data stream to 32 bit words and creates RAM accesses
 */
 
module wb_camera_if #(
    parameter ADR_WIDTH = 15 ,
    parameter ROWS      = 120,
    parameter COLS      = 160
) (
    input  logic                  clk          ,
    input  logic                  rst          ,
    // Camera Interface
    input  logic                  pixel_clk    ,
    input  logic [           7:0] pixel_dat    ,
    input  logic                  frame_vld    ,
    input  logic                  line_vld     ,
    // Configuration
    input  logic [ ADR_WIDTH-1:0] wr_addr_start, //Starting address in memory
    input  logic [          31:0] timestamp    , // Timestamp to write as the first address
    // Status
    output logic [$clog2(COLS):0] num_cols     ,
    output logic [$clog2(ROWS):0] num_rows     ,
    output logic                  overrun      ,
    // Master WB
    output logic                  m_wb_cyc     ,
    output logic                  m_wb_stb     ,
    output logic [ ADR_WIDTH-1:0] m_wb_adr     ,
    output logic [          31:0] m_o_wb_dat   ,
    output logic                  m_wb_we      ,
    input  logic                  m_wb_ack
);


    logic                            wb_adr_incr;
    logic [ADR_WIDTH-1:0] wb_adr;
    logic sof, eof;
    logic [7:0] px_dat;
    logic px_vld;
    
    // Hook up the Pixel interface
    camera_if #(.COLS(COLS), .ROWS(ROWS))
        u_camera_if (
            .clk(clk), .rst(rst),
            .o_dat(px_dat), .o_vld(px_vld),
            .*
        );
    
    // State machine to handle the Wishbone master
    enum {WB_IDLE='d0, WB_REQ='d1, WB_WAIT='d2, WB_XXX='d3} wb_curr, wb_next;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_wb_adr <= '0;
            wb_curr <= '0;
        
        end else begin

            // Address incrementer
            if (sof) begin
                m_wb_adr <= wr_addr_start;
                
            end else begin
                m_wb_adr <= m_wb_adr + {wb_adr_incr, 2'b0}; // 32 bit aligned address increment
                
            end

            // Wishbone state machine
            wb_curr <= wb_next;

        end
        
    end

    assign m_wb_we = '1; // Always write
    
    // Capture 4 pixels before initiating a WB access to pack the data into 32 bits
    logic [7:0] pixel_buffer[0:2];
    logic [1:0] pixel_ctr;
    logic send_wb;
    
    always @(posedge clk) begin
        if (rst) begin
            pixel_ctr <= '0;
            send_wb <= 0;
        end else begin

            send_wb <= sof;
            
            if (sof)
                m_o_wb_dat <= timestamp;
            
            else if (px_vld) begin
            
                if (pixel_ctr == 2'd3) begin
                    pixel_ctr <= '0;
                    send_wb <= 1'b1;
                    m_o_wb_dat <= {px_dat, pixel_buffer[2], pixel_buffer[1], pixel_buffer[0]};
                end else begin
                    pixel_ctr <= pixel_ctr + 'd1;
                    pixel_buffer[pixel_ctr] <= px_dat;
                end
            end
        end
    end
    
    // Wishbone master state machine
    always @* begin
        wb_next = WB_XXX;
        wb_adr_incr = '0;
        m_wb_cyc = '0;
        m_wb_stb = '0;
        
        case (wb_curr)
          
            WB_IDLE: begin
                if (send_wb) begin
                    wb_next = WB_REQ;
                    m_wb_cyc = '1;
                    m_wb_stb = '1;
                  
                end
                else wb_next = WB_IDLE;
            end
          
            WB_REQ: begin
                m_wb_cyc = '1;
                m_wb_stb = '1;
                if (m_wb_ack) begin
                    wb_next = WB_IDLE;
                    wb_adr_incr = '1;
                end
                else begin
                    wb_next = WB_WAIT;
                end
            end

            WB_WAIT: begin
                if (m_wb_ack) begin
                    wb_next = WB_IDLE;
                    wb_adr_incr = '1;
                end
                else begin
                    m_wb_cyc = '1;
                    wb_next = WB_WAIT;
                end
            end
          
        endcase
        
        // Override reset of the SM
        if (rst) begin
            wb_next = WB_IDLE;
        end
    end

    // Error condition if the Wishbone hasnt acked and a new pixel comes along. Make this sticky so its easily caught
    always @ (posedge clk)
        if (rst) 
            overrun <= '0;
        else if (overrun == 1'b0) 
            overrun <= (wb_curr==WB_WAIT) & px_vld;      
    
endmodule

