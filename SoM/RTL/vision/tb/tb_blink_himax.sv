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
 * Module:: Testbench for the Himax top level
 */

module tb_blink_himax;

    parameter NUM_ROWS = 30;
    parameter NUM_COLS = 40;

    logic       uart_rx   ;
    logic       uart_tx   ;
    logic [2:0] gpio      ;
    wire        i2c_scl   ;
    wire        i2c_sda   ;
    logic       sensor_clk;
    logic       px_clk = '0    ;
    logic       px_fv     ;
    logic       px_lv     ;
    logic [7:0] pxd       ;
    logic       sensor_led;
    logic       led_red   ;
    logic       led_green ;
    logic       led_blue  ;

    blink_himax dut (
        .uart_rx   (uart_rx   ),
        .uart_tx   (uart_tx   ),
        .gpio      (gpio      ),
        .i2c_scl   (i2c_scl   ),
        .i2c_sda   (i2c_sda   ),
        .sensor_clk(sensor_clk),
        .px_clk    (px_clk    ),
        .px_fv     (px_fv     ),
        .px_lv     (px_lv     ),
        .pxd       (pxd[3:0]  ),
        .sensor_led(sensor_led),
        .led_red   (led_red   ),
        .led_green (led_green ),
        .led_blue  (led_blue  )
    );

    // Camera source
    camera_model #(.FOUR_BITS("TRUE"), .WIDTH(8), .HOR_BLANK(4), .MAX_ROWS(NUM_ROWS), .MAX_COLS(NUM_COLS)) camera (
        .clk  (px_clk),
        .pixel(pxd   ),
        .vsync(px_fv ),
        .hsync(px_lv )
    );

    // Camera clock
    always #50000 px_clk = ~px_clk;

    logic [7:0] stimulus[0:NUM_COLS*NUM_ROWS-1];
    initial begin

        // Generate the stimulus
        for (int i=0; i<NUM_COLS*NUM_ROWS; i++)
            stimulus[i] = i;

        wait (dut.rst_n);
        repeat (10) @(posedge px_clk);

        camera.write_frame(NUM_COLS, NUM_ROWS, stimulus);

        $display("Done sending frame...");

        #1000; $finish;       

    end
endmodule
