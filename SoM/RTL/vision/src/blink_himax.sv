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
    input  logic       uart_rx   ,
    output logic       uart_tx   ,
    // GPIO
    output logic [2:0] gpio      ,
    output logic       host_intr ,
    // SPI master to control imager and IMU
    inout  logic       i2c_scl   ,
    inout  logic       i2c_sda   ,
    output logic       sensor_clk, // Must be ~6MHz
    // Image sensor data port
    input  logic       px_clk    ,
    input  logic       px_fv     ,
    input  logic       px_lv     ,
    // Himax is setup for 4 bit output. Note that the bits are reversed for Himax to help with routing!
    input  logic [3:0] pxd       ,
    output logic       sensor_led,
    output logic       led_red   ,
    output logic       led_green ,
    output logic       led_blue
);


    //Parameters

    logic clk  ;
    logic rst_n, rst;

    // Internal oscillator
    HSOSC #(.CLKHF_DIV("0b01")) u_hfosc (
        .CLKHFEN(1'b1),
        .CLKHFPU(1'b1),
        .CLKHF  (clk )
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


    // Program the Himax on boot up

    // Simple state machine to deal with initialization etc.
    logic init, init_done;

    enum {S_INIT_WAIT, S_PROG, S_WAIT, S_DONE, S_XXX} s_state, s_next;
    logic [20:0] timer;
    always_ff @(posedge clk) begin
        if(rst) s_state <= S_INIT_WAIT;
        else s_state <= s_next;
    end

    always_comb begin
        s_next = S_XXX;
        case (s_state)
            S_INIT_WAIT : if (timer == '1) s_next = S_PROG; else s_next = S_INIT_WAIT;
            S_PROG      : s_next = S_WAIT;
            S_WAIT      : if (init_done) s_next = S_DONE; else s_next = S_WAIT;
            S_DONE      : s_next = S_DONE;
            S_XXX       : s_next = S_XXX;
        endcase // s_state
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            timer <= '0;
            init  <= '0;
        end else begin
            init <= '0;

            case (s_state)
                S_INIT_WAIT : timer <= timer + 'd1;
                S_PROG      : init <= '1;
                S_WAIT      : timer <= '0;
                S_DONE      : ;
                S_XXX       : ;
            endcase // s_state
        end
    end


    logic w_scl_out, w_sda_out;
    lsc_i2cm_himax #(.EN_ALT(0), .INIT_FILE("ram256x16_himax.mem")) u_lsc_i2cm_himax (
        .clk      (clk      ),
        .init     (init     ),
        .init_done(init_done),
        .scl_in   (i2c_scl  ),
        .sda_in   (i2c_sda  ),
        .scl_out  (w_scl_out),
        .sda_out  (w_sda_out),
        .resetn   (rst_n    )
    );

    assign i2c_scl = w_scl_out ? 1'bz : 1'b0;
    assign i2c_sda = w_sda_out ? 1'bz : 1'b0;

    // Sensor uses its internal clock except during cnofiguration
    assign sensor_clk = init_done ? 1'b0 : clk;

    // @TBD!
    assign sensor_led = '1;

    //================================================================================
    // Capture data and convert to 8 bits wide
    //================================================================================
    logic [7:0] cam_data;
    logic [3:0] pxd_d   ;
    logic       hsync, vsync;
    logic [9:0] pxl_cnt ;
    logic       pxl_vld ;

    always_ff @(posedge px_clk) begin
        pxd_d    <= pxd;
        cam_data <= {pxd_d, pxd};
        hsync    <= px_lv;
        vsync    <= px_fv;
        if (px_lv == '0)
            pxl_cnt <= '0;
        else
            pxl_cnt <= pxl_cnt + 'd1;
    end

    assign pxl_vld = hsync && ~pxl_cnt[0];

    // Cross the clock domain into the local clock
    logic [7:0] pixel_data;
    logic       pixel_vld ;
    cc561 #(.DW(8)) i_cc561 (
        .aclk (px_clk    ),
        .arst (rst       ),
        .adata(cam_data  ),
        .aen  (pxl_vld   ),
        .bclk (clk       ),
        .bdata(pixel_data),
        .ben  (pixel_vld )
    );

    //================================================================================
    // LED ports have to have a special IO driver
    //================================================================================
    // LED is too bright, make this dim enough to not hurt eyes!
    logic duty_cycle;
    assign duty_cycle = &clk_divider[6:0];
    logic red, green, blue;

    RGB u_led_driver (
        .CURREN  (1'b1     ),
        .RGBLEDEN(1'b1     ),
        .RGB0PWM (red      ),
        .RGB1PWM (green    ),
        .RGB2PWM (blue     ),
        .RGB0    (led_red  ),
        .RGB1    (led_green),
        .RGB2    (led_blue )
    );
    defparam u_led_driver.CURRENT_MODE = "1" ;
    defparam u_led_driver.RGB0_CURRENT = "0b000001";
    defparam u_led_driver.RGB1_CURRENT = "0b000001";
    defparam u_led_driver.RGB2_CURRENT = "0b000001";

    assign green = px_fv && duty_cycle;

    assign host_intr = pixel_vld;
    assign gpio[0]   = pixel_data[0];
    assign gpio[1]   = pixel_data[2];
    assign gpio[2]   = pixel_data[7];

endmodule



