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

/**
 * Module: spi_slave_core
 *      Converts SPI to parallel data bus of configurable address/data widths. Uses a dual Tx buffer.
 *      
 * Assumptions: 
 *  Byte oriented protocol, address and data bits are multiples of 8
 *      SSN is active low, data is clocked in (MOSI) on the rising edge and clocked out (MOSI) on the falling edge
 *      Data bus width <= address bus width
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
 *      
 * Todo:
 *      - Optimizations:
 *      - Assertions:
 *      - Address and data widths must be multiple of 8
 */
`default_nettype none

module spi_slave_core
  (
   // SPI signals (SCK domain!)
   input logic         ssn,
   input logic         sck,
   input logic         mosi,
   output logic        miso,

   // Internal address/data bus (clk domain!)
   input logic         clk,
   input logic         rst,
  
   //output logic command,
   output logic [7:0]  rx_data,
   output logic [23:0] address,
   output logic        we,
   output logic        rx_valid, // Asserts for 1 clock cycle when new data is available

   input logic         tx_valid,
   input logic [7:0]   tx_data, // Data is grabbed when valid asserts!

   input logic [7:0]   spi_id,
   input logic [7:0]   spi_status,

   output logic        reset_out,
  
   output logic        busy
   );

   // SPI commands:
   parameter
     SPI_READ           = 8'h0B,
     SPI_WRITE          = 8'h02,
     SPI_POWERDOWN      = 8'hB9,
     SPI_EXIT_POWERDOWN = 8'hAB,
     SPI_ARM_RESET      = 8'h66,
     SPI_FIRE_RESET     = 8'h99
			  ;

   // Following are in the SPI SCK domain!
   logic [7:0]         rx_buffer;
   logic [1:0]         addr_counter;
   logic               valid_toggle; // Toggles at every data xaction
   logic               reset_armed;

   logic [1:0]         tx_valid_demet;
   logic [7:0]         tx_buffer[1:0]; // Ping pong Tx buffer
   logic               tx_buf_sel;
   
   // Following signals are in the clk domain
   logic [1:0]         valid_toggle_meta;

   // Block is busy if the Slave select is active
   assign busy = ~ssn;
   
   // Sync the write strobe to the clk domain and generate the valid signal
   always @(posedge clk, posedge rst)
     if (rst) begin
        valid_toggle_meta <= '0;
        rx_valid <= '0;
     end else begin
        valid_toggle_meta <= {valid_toggle_meta[0], valid_toggle};
        
        // Edge detect the toggle
        if (valid_toggle_meta[1] != valid_toggle_meta[0])
          rx_valid <= '1;
        else
          rx_valid <= '0;
     end

   
   // Rx logic: receive on the rising edge
   logic [2:0] bit_index;
   logic [7:0] spi_rx_byte;
   assign spi_rx_byte = {rx_buffer[7:1], mosi};
   assign rx_data = spi_rx_byte; // Valid qualifies this anyway, save some registers!
   
   enum        logic [3:0] {
                            S_CMD='d0, 
                            S_ADDR='d1, 
                            S_DATA_0='d2, 
                            S_DATA_INCR='d3, 
                            S_ARM_RESET = 'd6,
                            S_FIRE_RESET = 'd7,
                            S_XXX = 'x
                            } state, next;

   // Current to next state register
   always @(posedge sck, posedge ssn)
     if (ssn) state <= S_CMD;
     else     state <= next;

   // Next state computation
   always @* begin
      if (ssn)
        next = S_CMD;
      else begin
         case (state)
           S_CMD: 
             if (bit_index == 0) begin
                case(spi_rx_byte)
                  SPI_READ, SPI_WRITE: next = S_ADDR;
                  SPI_ARM_RESET: next = S_ARM_RESET;
                  default: next = S_CMD;
                endcase
             end else
               next = S_CMD;

           S_ADDR: if (bit_index==0 && addr_counter == 0) next = S_DATA_0; else next = S_ADDR;
           S_DATA_0: if (bit_index == 0) next = S_DATA_INCR; else next = S_DATA_0;
           S_DATA_INCR: next = S_DATA_INCR; // Streaming access
           S_ARM_RESET: next = S_ARM_RESET;
           default: next = S_CMD;
         endcase
      end
   end

   // SM Outputs
   always @(posedge sck or posedge ssn or posedge rst) begin
      if (rst) begin 
         valid_toggle <= '0;
         reset_out <= '0;
         bit_index <= 'd7;
         rx_buffer <= '0;
         we <= '0;
         addr_counter <= 'd2;
         tx_buf_sel <= '0;
      end       else if (ssn) begin
         reset_out <= '0;
         bit_index <= 'd7;
         rx_buffer <= '0;
         we <= '0;
         addr_counter <= 'd2;
         tx_buf_sel <= '0;
         
      end       else begin
         if(bit_index == 0) begin
            bit_index <= 'd7;

            // Ping pong Tx buffer. Note this is on the posedge of sck and used on the negedge of sck. Will drive timing for the block.
            tx_buf_sel <= ~tx_buf_sel;

            case(state)
              S_CMD: // Command word
                begin
                   
                   case (spi_rx_byte)
                     SPI_WRITE: we <= 1'b1;
                     SPI_ARM_RESET: reset_armed <= '1;
                     SPI_FIRE_RESET: reset_out <= reset_armed ? 1'b1: 1'b0;
                   endcase

                end

              S_ADDR:  // Read address
                begin
                   addr_counter <= addr_counter - 'd1;
                   case(addr_counter)
                     2: address[23:16] <= spi_rx_byte;
                     1: address[15: 8] <= spi_rx_byte;
                     0: address[ 7: 0] <= spi_rx_byte;
                   endcase
                end
              
              S_DATA_0:  // Read first byte of data
                begin
                   bit_index <= 7;
                   valid_toggle <= ~valid_toggle;
                end
              
              S_DATA_INCR:  // Read data and increment address
                begin
                   address <= address + 'd1;
                   bit_index <= 7;
                   valid_toggle <= ~valid_toggle;
                end
              
            endcase
         end
         else begin
            rx_buffer[bit_index] <= mosi;
            bit_index <= bit_index - 1;
         end
      end
   end

   // Handle transmission:
   logic tx_buf_sel_ne;
   logic tx_valid_d;
   assign miso = tx_buffer[tx_buf_sel_ne][7];
   logic [7:0] dbg_tx_buf_0, dbg_tx_buf_1;
   
   // Bring the tx_valid into the sck domain using a one-shot
   always @(negedge sck or posedge ssn or posedge tx_valid) begin
      if (tx_valid) 
         tx_valid_d <= 1'b1;
      else if (ssn)
         tx_valid_d <= 1'b0;
      else if (tx_valid_d) 
         tx_valid_d <= 1'b0;
   end


   always @(negedge sck or posedge ssn) begin
      if (ssn) begin
         // Default values: Every transaction is no less than 2 words long, can send this 
         // data for free with every SPI xaction with a bit of extra logic.
         tx_buffer[0] <= spi_id;
         tx_buffer[1] <= spi_status;
         tx_buf_sel_ne <= '0;
         tx_valid_demet <= '0;
      end else begin
         // Demet the incoming valid signal as its in the clk domain. Means we lose a max of 3 clocks!
         // Should have 5 SPI clocks left for the data to come back from the upper layers
         tx_valid_demet <= {tx_valid_demet[0], tx_valid_d};

         // Cross from posedge to negedge using a flop for timing
         tx_buf_sel_ne <= tx_buf_sel;

         // MSB shift of the Ping buffer
         tx_buffer[tx_buf_sel_ne] <= {tx_buffer[tx_buf_sel_ne][6:0], 1'b0};

         // Load the Pong buffer
         if (tx_valid_demet[1])
           tx_buffer[~tx_buf_sel_ne] <= tx_data;

      end
   end

   assign dbg_tx_buf_0 = tx_buffer[0];
   assign dbg_tx_buf_1 = tx_buffer[1];

endmodule
