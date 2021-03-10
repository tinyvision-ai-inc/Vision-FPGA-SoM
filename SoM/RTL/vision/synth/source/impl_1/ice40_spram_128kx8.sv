/****************************************************************************
 Copyright (c) 2021 tinyVision.ai Inc.

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
 * Module:: 128KB byte wide memory using 4x SPRAM blocks.
 * TBD: Add in power controls to put the RAM to sleep when it isnt active
 */

module ice40_spram_128kx8 (
    input  wire       clk    ,
    input  wire        rst    ,
    input  wire        cs     ,
    input  wire [16:0] addr   ,
    input  wire        wr_en  ,
    input  wire [ 7:0] wr_data,
    output wire [ 7:0] rd_data
);


    // SRAM signals
    logic [ 3:0] mask          ;
    logic [ 3:0] we            ;
    logic [ 3:0] ram_cs        ;
    logic [15:0] dout     [0:3];
    logic [15:0] bank_dout     ;
    logic addr0_d;

    // The RAM bank consists of four 16k x 16 RAM's. The interface is 8 bits so we need to add local muxes
    // to deal with this.
    
    // Store the byte select to align with data coming out of the RAM on a read
    always_ff @(posedge clk)
        if (cs & ~wr_en)
            addr0_d <= addr[0];

    // RAM's support nibble access, want only byte level access
    assign mask = addr[0] ? 4'b1100 : 4'b0011;

    generate
        for (genvar i=0; i<4; i++) begin

            // Generate the write enable
            assign we[i]     = wr_en && (addr[16:15] == i);
            assign ram_cs[i] = cs && (addr[16:15] == i);

            // Instantiate the 4 banks of SPRAM
            SP256K i_spram16k_16 (
                .CK      (clk               ),
                .CS      (ram_cs[i]         ),
                .AD      (addr[14:1]        ),
                .DI      ({wr_data, wr_data}),
                .MASKWE  (mask              ),
                .WE      (we[i]             ),
                .DO      (dout[i]           ),
                .STDBY   (1'b0              ),
                .SLEEP   (1'b0              ),
                .PWROFF_N(1'b1              )
            );
        end
    endgenerate

    // Mux the read data
    assign bank_dout =
        (addr[16:15] == 2'b00) ? dout[0] :
        (addr[16:15] == 2'b01) ? dout[1] :
        (addr[16:15] == 2'b10) ? dout[2] :
        dout[3];

    // Demux the data
    assign rd_data = addr0_d ? bank_dout[15:8] : bank_dout[7:0];

endmodule

