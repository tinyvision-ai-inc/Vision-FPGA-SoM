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

`define expect_h(name,expectedVal,actualVal) if ((expectedVal) !== (actualVal)) begin $display("[ERROR] %m %t %s expected='h%X actual='h%X", ($time), (name), (expectedVal), (actualVal)); #1000; $finish; end else begin $display("[PASS] %s='h%X", (name), (actualVal)); end

// Move this to a package
parameter
    SPI_READ_ID        = 'h90,
    SPI_READ_STATUS    = 'h05,
    SPI_WRITE_STATUS   = 'h01,
    SPI_READ           = 'h0B,
    SPI_WRITE          = 'h02,
    SPI_POWERDOWN      = 'hB9,
    SPI_EXIT_POWERDOWN = 'hAB,
    SPI_ARM_RESET      = 'h66,
    SPI_FIRE_RESET     = 'h99
    ;
//
// Sends a byte to logic over spi, gets byte back
//

//
// Call before doing any multi-byte SPI transmission
//
task spiTxStart;
    begin
        spi_clk = 1'b0;
        #100;
        
        spi_ss = 0;
        #100;
    end
endtask

//
// Call after doing a multi-byte SPI transmission
task spiTxStop;
    begin
        #100;
        spi_clk = 1'b0;
        #100;
        spi_ss = 1;
        #100;
    end
endtask

task spiExchByte;
    input  [7:0] byteToSend;
    output [7:0] recvByte;
    reg [7:0]    recvByte;
    integer      bitIndex;
    begin
        

        //$display("Sending byte via spi: 8'h%02X", byteToSend);
        bitIndex = 8;
        while (bitIndex > 0) begin
            bitIndex = bitIndex - 1;  
            spi_mosi = byteToSend[bitIndex];
            recvByte[bitIndex] = spi_miso;
            //#1; // Settling time
            spi_clk = 1'b1;
            
            #200
            //$display("Sending bit[%0d] via spi: %b", 
            //         bitIndex, byteToSend[bitIndex]);

            spi_clk = 1'b0;
            
            #200;
            
        end
    end
endtask

//
// Sends a byte to vSPI, but not receive anything
//
task spiSendByte;
    input [7:0] byteToSend;
    reg [7:0]   recvByte;
    begin
        spiExchByte(byteToSend, recvByte);
    end
endtask

//
// Receives a byte from vSPI, but does not send anything
//
task spiRecvByte;
    output [7:0] recvByte;
    reg [7:0]    recvByte;
    begin
        spiExchByte(8'h00, recvByte);
    end
endtask
/*
 * Send the address
 */
task  spiSendAddr;
    input [23:0] address;
    spiSendByte(address[23:16]);
    if (debug) $display(" %x ", address[23:16]);
    spiSendByte(address[15:8]);
    if (debug) $display(" %x ", address[15:8]);
    spiSendByte(address[7:0]);
    if (debug) $display("%x ", address[7:0]);
endtask


/*
 * Send a SPI command
 */
task spiWriteStart;
    input [23:0] address;
    if (debug) $display("%t Writing to %x", $time, address);
    spiTxStart();
    spiSendByte(SPI_WRITE);
    spiSendAddr(address);
endtask

task spiWriteNext;
    input [7:0] data;
    if (debug) $display("%t Wrote %x", $time, data);
    spiSendByte(data);
endtask

task spiWriteEnd;
    spiTxStop();
endtask

task spiWriteReg;
    input [23:0] address;
    input [7:0] data;
    spiWriteStart(address);
    if (debug) $display("%t Wrote %x", $time, data);
    spiSendByte(data);
    spiWriteEnd();
endtask

task spiReadStart;
    input [23:0] address;
    reg [7:0]   regValue;
    if (debug) $display("%t Reading from %x", $time, address);
    spiTxStart();
    spiSendByte(SPI_READ);
    spiSendAddr(address);
    spiRecvByte(regValue); //Dummy read
    spiRecvByte(regValue); //Dummy read

endtask

task spiReadNext;
    output [7:0] regValue;
    reg [7:0]    regValue;
    spiRecvByte(regValue);
    if (debug) $display("%t read %2x", $time, regValue);

endtask

task spiReadEnd;
    spiTxStop();
endtask

task spiReadReg;
    input [23:0] address;
    output reg [7:0]   regValue;
    reg [7:0]          temp;
    
    spiReadStart(address); // Address with dummy read
    spiReadNext(regValue);
    spiReadEnd();
endtask


/*
 * Send a reset command
 */
task spiSendReset;
        spiTxStart();
        spiSendByte(SPI_ARM_RESET);
        spiTxStop();
        #10;
        spiTxStart();
        spiSendByte(SPI_FIRE_RESET);
        spiTxStop();
endtask

/*
 * Get SPI ID
 */
task spiGetID;
        output reg [7:0] id;
    output reg [7:0] status;
        spiTxStart();
    spiRecvByte(id);
    spiRecvByte(status);
        spiTxStop();
endtask

/*
 * Get SPI status
 */
task spiGetStatus;
        output reg [7:0]   regValue;
        spiTxStart();
        spiSendByte(SPI_READ_STATUS);
    spiRecvByte(regValue); //Dummy read
        spiRecvByte(regValue);
        spiTxStop();
endtask
