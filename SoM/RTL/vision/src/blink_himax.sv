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
 * Module:: Top level jumping off point to get pixel data from the camera
 */

 module blink_himax (

    // Host interface
    input logic uart_rx,
    input logic uart_tx,
    
    // GPIO
    output logic [2:0] gpio, // @TODO: make this tri-state in the future
    
    // SPI master to control imager and IMU
    inout wire i2c_scl,
    inout wire i2c_sda,
    
    output logic sensor_clk, // Must be ~6MHz

    // Image sensor data port
    input logic px_clk,
    input logic px_fv,
    input logic px_lv,
    // Himax is setup for DDR, 4 bit output. Note that the bits are reversed for Himax to help with routing!
    input logic [7:4] pxd,
    output logic sensor_led,
    
    output logic led_red,
    output logic led_green,
    output logic led_blue
        
    );

    //Parameters

    logic clk    ;
    logic rst_n, rst;

    // Internal oscillator
    HSOSC #(.CLKHF_DIV("0b01")) u_hfosc (
        .CLKHFEN(1'b1   ),
        .CLKHFPU(1'b1   ),
        .CLKHF  (clk)
    );


    ice40_resetn u_reset_n (.clk(clk), .resetn(rst_n));
    assign rst = ~rst_n;

    logic [27:0] clk_divider;
    always @(posedge clk) begin
        if (rst)
            clk_divider <= 0;
        else
            clk_divider <= clk_divider + 1;
    end

    // Sensor uses its internal clock, no?
    assign sensor_clk = '0;

    // Program the Himax on boot up
    logic w_scl_out, w_sda_out;
    logic init, init_done;

    lsc_i2cm_himax #(.EN_ALT(0), .CONF_SEL("324x324_1fps")) u_lsc_i2cm_himax(
    .clk      (clk   ),
    .init     (init     ),
    .init_done(init_done),
    .scl_in   (i2c_scl    ),
    .sda_in   (i2c_sda    ),
    .scl_out  (w_scl_out  ),
    .sda_out  (w_sda_out  ),
    .resetn   (rst_n     )
);
 
assign i2c_scl = w_scl_out ? 1'bz : 1'b0;
assign i2c_sda = w_sda_out ? 1'bz : 1'b0;

    //================================================================================
    // Capture data and convert to 8 bits wide
    //================================================================================
    logic [7:0] cam_data;
    logic [3:0] pxd_d;
    logic hsync, vsync;
    logic [9:0] pxl_cnt;
    logic pxl_vld;

    always_ff @(posedge px_clk) begin
        pxd_d <= pxd;
        cam_data <= {pxd_d, pxd};
        hsync <= px_lv;
        vsync <= px_fv;
        if (px_lv == '0)
            pxl_cnt <= '0;
        else
            pxl_cnt <= pxl_cnt + 'd1;
    end

    assign pxl_vld = hsync && ~pxl_cnt[0];
    
    //================================================================================
    // LED ports have to have a special IO driver
    //================================================================================
    // LED is too bright, make this dim enough to not hurt eyes!
    logic duty_cycle;
    assign duty_cycle = &clk_divider[6:0];
    RGB u_led_driver (
        .CURREN  (1'b1                                             ),
        .RGBLEDEN(1'b1                                             ),
        .RGB0PWM (clk_divider[25] && clk_divider[24] && duty_cycle ),
        .RGB1PWM (clk_divider[25] && ~clk_divider[24] && duty_cycle),
        .RGB2PWM (~clk_divider[25] && clk_divider[24] && duty_cycle),
        .RGB0    (led_red                                          ),
        .RGB1    (led_green                                        ),
        .RGB2    (led_blue                                         )
    );
    defparam u_led_driver.CURRENT_MODE = "0b0" ;
    defparam u_led_driver.RGB0_CURRENT = "0b000001";
    defparam u_led_driver.RGB1_CURRENT = "0b000000";
    defparam u_led_driver.RGB2_CURRENT = "0b000000";

endmodule



