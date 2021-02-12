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

    parameter NUM_ROWS       = 30;
    parameter NUM_COLS       = 40;
    parameter UART_PERIOD    = 6 ; // Go fast!
    parameter NUM_HIMAX_CMDS = 1 ; // Bypass all init stuff

    logic       uart_rx        ;
    logic       uart_tx        ;
    logic [2:0] gpio           ;
    logic       host_intr      ;
    tri1        i2c_scl        ;
    tri1        i2c_sda        ;
    logic       sensor_clk     ;
    logic       px_clk     = '0;
    logic       px_fv          ;
    logic       px_lv          ;
    logic [7:0] pxd            ;
    logic       sensor_led     ;
    logic       led_red        ;
    logic       led_green      ;
    logic       led_blue       ;

    blink_himax #(.UART_PERIOD(UART_PERIOD), .NUM_HIMAX_CMDS(NUM_HIMAX_CMDS)) dut (
        .uart_rx   (uart_rx   ),
        .uart_tx   (uart_tx   ),
        .gpio      (gpio      ),
        .host_intr (host_intr),
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

    // I2C slave
    i2c_slave_model #(.I2C_ADR(7'b010_0100) ) i_i2c_slave_model (.scl(i2c_scl), .sda(i2c_sda));

    // Camera source
    camera_model #(.FOUR_BITS("TRUE"), .WIDTH(8), .HOR_BLANK(4), .MAX_ROWS(NUM_ROWS), .MAX_COLS(NUM_COLS)) camera (
        .clk  (px_clk),
        .pixel(pxd   ),
        .vsync(px_fv ),
        .hsync(px_lv )
    );

    // UART stimulus
    logic [7:0] uart_din, uart_dout;
    logic uart_din_valid, uart_dout_valid;
    logic uart_empty;
    lsc_uart #(.PERIOD    (UART_PERIOD)) i_lsc_uart (
        .ref_clk(dut.clk        ),
        .clk    (dut.clk        ),
        .resetn (~dut.rst       ),
        .i_din  (uart_din       ),
        .i_valid(uart_din_valid ),
        .o_empty(               ),
        .o_dout (uart_dout      ),
        .o_valid(uart_dout_valid),
        .i_rxd  (uart_tx        ),
        .o_txd  (uart_rx        )
    );


    always @(posedge uart_dout_valid) begin
        $display("%t:::UART_RX_DATA: 0x%x", $time, uart_dout);
    end

    // UART checker: should receive incrementing pixels, else an error somewhere
    logic [7:0] uart_dout_d;

    always_ff @(posedge dut.clk) begin
        if(uart_dout_valid) begin
            if (uart_dout_d + 'd1 != uart_dout)
                $error("%t::: UART pixels out of sequence! Expected: 0x%x, got: 0x%x", $time, uart_dout_d, uart_dout);

            uart_dout_d <= uart_dout;

        end
    end


    // Camera clock
    always #100000 px_clk = ~px_clk;

    logic [7:0] stimulus[0:NUM_COLS*NUM_ROWS-1];
    initial begin

        wait(~dut.rst)

        // Poke the timer in the DUT so it counts faster
        dut.timer = 'hffff0;

        // Generate the stimulus
        for (int i=0; i<NUM_COLS*NUM_ROWS; i++)
            stimulus[i] = i;

        repeat (2) begin // Do 2 iterations to check for errors
            wait (dut.s_state == dut.S_WAIT_UART);

            uart_din = '1;
            uart_din_valid = '1;
            @(posedge dut.clk);
            uart_din_valid = '0;

            wait(dut.s_state == dut.S_WAIT_FRAME);

            repeat (100) @(posedge px_clk);

            camera.write_frame(NUM_COLS, NUM_ROWS, stimulus);

            $display("Done sending frame...");

            wait (dut.s_state == dut.S_WAIT_UART);
        end
        #10000000;
        $finish;       

    end
endmodule
