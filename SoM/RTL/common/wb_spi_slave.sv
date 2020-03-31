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

/* * Module: spi_slave_core
 *      Implements a SPI slave to Wishbone master bridge
 *      
 * Assumptions: 
 *  Byte oriented protocol, address and data bits are multiples of 8
 *      SSN is active low, data is clocked in (MOSI) on the rising edge and clocked out (MOSI) on the falling edge
 *      Data bus width <= address bus width
*
 *      Protocol: <Command byte> <Data bytes>
 *        SPI_READ: 0x0B
 *        SPI_WRITE: 0x02
 *        SPI_POWERDOWN: 0xB9
 *        SPI_EXIT_POWERDOWN: 0xAB
 *        SPI_ARM_RESET: 0x66
 *        SPI_FIRE_RESET: 0x99
 *
 *        WRITE: A write command looks like this:
 *            <SPI_WRITE, 3 Address bytes, Data bytes>
 *        READ: A Read command looks like this:
 *            <SPI_READ, 3 Address bytes, Dummy Byte, Data bytes>
 *        Soft Reset: A soft reset can be issued to the core by following the sequence below:
 *            <SPI_ARM_RESET>
 *            <SPI_FIRE_RESET>
 */
`default_nettype none

module wb_spi_slave (
		input logic         clk,
		input logic         rst,
                  
		// SPI lines
		input logic         sck,
		input logic         ssn,
		input logic         mosi,
		output logic        miso,
                  
		// Bus interface
		output logic        o_wb_cyc,
		//output logic      o_wb_sel,
		output logic        o_wb_stb,

		output logic [23:0] o_wb_adr,
		output logic [7:0]  o_wb_dat,
		output logic        o_wb_we,
                  
		input logic         i_wb_ack,
		input logic [7:0]   i_wb_dat,
		
		// Control/status to/from SPI slave
		output logic reset_out,
		input logic [7:0] spi_id,
		input logic [7:0] spi_status                  
		);
   

	// SPI serializer & deserializer and clock domain crossing
	logic spi_busy, spi_rx_vld;
	logic [7:0] spi_tx_data;
	logic spi_tx_valid;

	spi_slave_core u_spi_slave_core
		(
			.sck                             (sck),
			.ssn                             (ssn),
			.mosi                            (mosi),
			.miso                            (miso),

			.clk (clk),
			.rst (rst),

			.address(o_wb_adr),
			.we(o_wb_we),
			.rx_data(o_wb_dat),
			.rx_valid(spi_rx_vld),

			.tx_data(spi_tx_data),
			.tx_valid(spi_tx_valid),
			
			.reset_out(reset_out),
			.spi_id(spi_id),
			.spi_status(spi_status),
			.busy(spi_busy)
		);


	// State machine to handle the Wishbone master
	enum {WB_IDLE='d0, WB_REQ='d1, WB_WAIT='d2, WB_XXX='d3} wb_curr, wb_next;
    
	// Wishbone master state machine
	always @* begin
		wb_next = WB_XXX;
		o_wb_cyc = '0;
		o_wb_stb = '0;

		case (wb_curr)
          
			WB_IDLE: begin
				if (spi_rx_vld) begin
					wb_next = WB_REQ;
					o_wb_cyc = '1;
					o_wb_stb = '1;
                  
				end
				else wb_next = WB_IDLE;
			end
          
			WB_REQ: begin
				o_wb_cyc = '1;
				o_wb_stb = '1;
				if (i_wb_ack) begin
					wb_next = WB_IDLE;
				end
				else begin
					wb_next = WB_WAIT;
				end
			end

			WB_WAIT: begin
				if (i_wb_ack) begin
					wb_next = WB_IDLE;
				end
				else begin
					o_wb_cyc = '1;
					wb_next = WB_WAIT;
				end
			end
          
		endcase
    
		// Override reset of the SM
		if (rst) begin
			wb_next = WB_IDLE;
		end
	end

	// Wishbone SM 
	always @(posedge clk, posedge rst) begin
		if (rst) wb_curr <= WB_IDLE;
		else  	 wb_curr <= wb_next;
	end

	// Capture the WB xaction
	always @(posedge clk) begin
		if (i_wb_ack && ~o_wb_we) begin
			spi_tx_data <= i_wb_dat; 
			spi_tx_valid <= '1;
		end else begin
			spi_tx_valid <= '0;
		end
	end

    
endmodule
