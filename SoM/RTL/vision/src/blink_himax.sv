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
    input  wire        uart_rx   ,
    output logic       uart_tx   ,
    // GPIO
    output logic [2:0] gpio      ,
    output logic       host_intr ,
    // SPI master to control imager and IMU
    inout  wire        i2c_scl   ,
    inout  wire        i2c_sda   ,
    output logic       sensor_clk, // Must be ~6MHz
    // Image sensor data port
    input  wire        px_clk    ,
    input  wire        px_fv     ,
    input  wire        px_lv     ,
    // Himax is setup for 4 bit output. Note that the bits are reversed for Himax to help with routing!
    input  wire  [3:0] pxd       ,
    output logic       sensor_led,
    output logic       led_red   ,
    output logic       led_green ,
    output logic       led_blue
);


    //Parameters
    parameter UART_PERIOD = 'd104; // To get to 115200 Baud
    //parameter UART_PERIOD = 'd52;  // To get to 230400 Baud
    //parameter UART_PERIOD = 'd26;  // To get to 460800 Baud
    //parameter UART_PERIOD = 'd13;    // To get to 921600 Baud

    logic red, green, blue;

    // UART to communicate with the world
    logic [7:0] uart_rx_data, uart_tx_data;
    logic uart_rx_valid, uart_tx_valid;
    logic uart_empty;
    logic load_fifo;

    // FIFO to hold image data
    logic fifo_in_ready, fifo_out_ready;
    logic [7:0] o_fifo_data;
    logic o_fifo_valid, o_fifo_ready;

    // Image related signals
    logic eof; // Signals end of frame

    logic clk  ;
    logic rst_n, rst;

    // Internal oscillator: 12MHz
    HSOSC #(.CLKHF_DIV("0b10")) u_hfosc (
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

    enum {S_INIT_WAIT, S_PROG, S_WAIT, S_DONE, S_WAIT_UART, S_WAIT_FRAME, S_XXX} s_state, s_next;
    logic [19:0] timer; // Set this to be very low during simulations!
    always_ff @(posedge clk) begin
        if(rst) s_state <= S_DONE; //S_INIT_WAIT;
        else s_state <= s_next;
    end

    always_comb begin
        s_next = S_XXX;
        case (s_state)
            S_INIT_WAIT  : if (&timer) s_next = S_PROG; else s_next = S_INIT_WAIT;
            S_PROG       : s_next = S_WAIT;
            S_WAIT       : if (init_done) s_next = S_DONE; else s_next = S_WAIT;
            S_DONE       : s_next = S_WAIT_UART;
            S_WAIT_UART  : if (uart_rx_valid) s_next = S_WAIT_FRAME; else s_next = S_WAIT_UART;
            S_WAIT_FRAME : if (eof) s_next = S_WAIT_UART; else s_next = S_WAIT_FRAME;
            S_XXX        : s_next = S_XXX;
        endcase // s_state
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            timer <= '0;
            init  <= '0;
        end else begin
            init       <= '0;
            sensor_led <= '0;

            case (s_state)
                S_INIT_WAIT : timer <= timer + 'd1;
                S_PROG      : init <= '1;
                S_WAIT      : timer <= '0;
                S_DONE      : ;
                S_WAIT_UART :
                    // How to enable the IR LED when the camera is exposing the frame?
                    // The camera is set to run on its own clock and stream out frames.
                    sensor_led <= uart_rx_valid;

                S_WAIT_FRAME : timer <= timer + 'd1;
                S_XXX        : ;
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

    // Sensor uses its internal clock except during configuration
    assign sensor_clk = init_done ? 1'b0 : clk;

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
    logic [7:0] pixel_data ;
    logic       pixel_hsync, pixel_vsync;
    logic       pixel_valid;

    // Detect an end of frame by detecting a falling VSYNC. Also need to cross clock domains here!
    logic [1:0] vsync_d;
    always_ff @(posedge clk)
        vsync_d <= {vsync_d[0], vsync};

    assign eof = vsync_d[1] & ~vsync_d[0];

    // Allow the FIFO under UART command and stop it once the EOF is reached
    always_ff @(posedge clk) begin
        if(rst) begin
            load_fifo <= '0;
        end else begin
            if ((s_state == S_WAIT_UART) & uart_rx_valid)
                load_fifo <= '1;
            else if ((s_state == S_WAIT_FRAME & eof))
                load_fifo <= '0;
        end
    end

    // Is it safe to use the load_fifo without a CDC? I think so as its a single bit and doesnt matter
    // if it does jitter a bit. Probably not OK for an ASIC but will do here!
    stream_dual_clock_fifo #(.DW(8), .AW(13)) i_stream_dual_clock_fifo (
        .wr_clk          (px_clk             ),
        .wr_rst          (rst                ),
        .stream_s_data_i (cam_data           ),
        .stream_s_valid_i(pxl_vld & load_fifo),
        .stream_s_ready_o(i_fifo_ready       ),
        .rd_clk          (clk                ),
        .rd_rst          (rst                ),
        .stream_m_data_o (pixel_data         ),
        .stream_m_valid_o(pixel_valid        ),
        .stream_m_ready_i(pixel_ready        )
    );

    // RAM to buffer pixel data


    // UART to trigger and collect data from the camera
    lsc_uart #(
        .PERIOD    (UART_PERIOD)
    ) u_lsc_uart (
        .ref_clk(clk          ),
        .clk    (clk          ),
        .resetn (~rst         ),

        .i_din  (uart_tx_data ),
        .i_valid(uart_tx_valid),
        
        .o_dout (uart_rx_data ),
        .o_valid(uart_rx_valid),
        .o_empty(uart_empty   ),

        .i_rxd  (uart_rx      ),
        .o_txd  (uart_tx      )
    );
    assign pixel_ready2 = uart_empty; // Take bytes only when the UART is ready
    assign uart_tx_data = pixel_data;
    assign uart_tx_valid = pixel_valid & pixel_ready;

/*
    // Incrementing data to test the UART receiver
    assign uart_tx_valid = & (timer[7:0]); // Send a character every once in a while
    always_ff @(posedge clk) begin
        if(rst) begin
            uart_tx_data <= 0;
        end else
            if (uart_tx_valid)
                uart_tx_data <= uart_tx_data + 'd1;
    end
*/  
/*
    // Loopback
    assign uart_tx_data = uart_rx_data;
    assign uart_tx_valid = uart_rx_valid;
*/

    //================================================================================
    // LED ports have to have a special IO driver
    //================================================================================
    // LED is too bright, make this dim enough to not hurt eyes!
    logic duty_cycle;
    assign duty_cycle = '1;//= &clk_divider[1:0];

    logic [7:0] command[0:2] = "rgb";
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

    assign blue = px_fv && duty_cycle;

    assign host_intr = uart_rx_valid;
    assign gpio[0]  = uart_rx;
    assign gpio[1]  = uart_tx;
    assign gpio[2] = uart_rx_valid;

    always_ff @(posedge clk) begin
        if(rst) begin
            red <= '0;
            green <= '0;
        end else
            if (uart_rx_valid) begin
                red   <= (uart_rx_data[0]) ? 1'b1 : 1'b0;
                green <= (uart_rx_data[1]) ? 1'b1 : 1'b0;
            end
    end
/*    assign gpio[0]   = pixel_data[5];
    assign gpio[1]   = pixel_data[6];
    assign gpio[2]   = pixel_data[7];
*/
/*    assign host_intr = px_fv;
    assign gpio[0]   = pxd[0];
    assign gpio[1]   = pxd[1];
    assign gpio[2]   = pxd[2];
*/
endmodule



