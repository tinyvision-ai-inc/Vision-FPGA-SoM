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
    // Audio
    output logic       mic_clk   ,
    output logic       mic_ws    ,
    input  logic       mic_dout  ,
    // LED's
    output logic       sensor_led,
    output logic       led_red   ,
    output logic       led_green ,
    output logic       led_blue
);


    //Parameters
    //parameter UART_PERIOD = 'd104; // To get to 115200 Baud
    //parameter UART_PERIOD = 'd52;  // To get to 230400 Baud
    parameter UART_PERIOD = 'd26; // To get to 460800 Baud

    parameter HIMAX_INIT_FILE = "ram256x16_himax_162x162.mem";
    //parameter HIMAX_INIT_FILE = "ram256x16_himax_324x324.mem";
    parameter NUM_HIMAX_CMDS = 7'd80; // Parameterized so sims can be run faster

    logic red, green, blue;

    // UART to communicate with the world
    logic [7:0] uart_rx_data, uart_tx_data;
    logic       uart_rx_valid, uart_tx_valid;
    logic       uart_tx_empty;
    logic       load_fifo    ;

    // FIFO to hold image data
    logic       fifo_in_ready, fifo_out_ready;
    logic [7:0] o_fifo_data  ;
    logic       o_fifo_valid, o_fifo_ready;

    // Image related signals
    logic [ 7:0] pixel_data ;
    logic        pixel_valid, pixel_ready;
    logic        pixel_eof  ; // Signals end of frame
    logic [17:0] num_pixels ;

    logic clk  ;
    logic rst_n, rst;

    // Internal oscillator: 12MHz
    HSOSC #(.CLKHF_DIV("0b10")) u_hfosc (
        .CLKHFEN(1'b1),
        .CLKHFPU(1'b1),
        .CLKHF  (clk )
    );

    // Generate a reset for various blocks on power up
    ice40_resetn u_reset_n (.clk(clk), .resetn(rst_n));
    assign rst = ~rst_n;

    // Clcok divider for various things as needed
    logic [27:0] clk_divider;
    always @(posedge clk) begin
        if (rst)
            clk_divider <= 0;
        else
            clk_divider <= clk_divider + 1;
    end

    // Audio clock and word select
    assign mic_clk = clk_divider[1]; // 12MHz system clock/4 = 3MHz
    assign mic_ws  = clk_divider[1+$clog2(64)]; // mic_clk/64

    // State machine to deal with initialization and frame capture/readout
    logic        init, init_done;
    logic [19:0] timer; // Set this to be very low during simulations!

    enum {
        S_POR,          // Wait for POR time for the Flash/SRAM and other devices
        S_PROG,         // Kick off programming the Himax sensor
        S_WAIT_INIT,    // Wait for sensor to get the programmed
        S_WAIT_UART,    // Wait for a UART command and kick off frame capture
        S_WAIT_FRAME,   // Wait for the frame capture to complete
        S_WAIT_UART_TX, // Wait for the UART to complete sending data
        S_PAUSE_UART,   // UART filling up, pause sending data
        S_XXX           // Default trap
    } s_state, s_next;

    always_ff @(posedge clk) begin
        if(rst) s_state <= S_POR;
        else s_state <= s_next;
    end

    always_comb begin
        s_next = S_XXX;
        case (s_state)
            S_POR          : if (&timer) s_next = S_PROG; else s_next = S_POR;
            S_PROG         : s_next = S_WAIT_INIT;
            S_WAIT_INIT    : if (init_done) s_next = S_WAIT_UART; else s_next = S_WAIT_INIT;
            S_WAIT_UART    : if (uart_rx_valid) s_next = S_WAIT_FRAME; else s_next = S_WAIT_UART;
            S_WAIT_FRAME   : if (pixel_eof) s_next = S_WAIT_UART_TX; else s_next = S_WAIT_FRAME;
            S_WAIT_UART_TX :
                begin
                    if (num_pixels == '0)
                        s_next = S_WAIT_UART;
                    else
                        if (~uart_tx_empty)
                            s_next = S_PAUSE_UART;
                    else
                        s_next = S_WAIT_UART_TX;
                end
            S_PAUSE_UART : if (uart_tx_empty) s_next = S_WAIT_UART_TX; else s_next = S_PAUSE_UART;
            S_XXX        : s_next = S_XXX;
        endcase // s_state
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            timer <= '0;
            init  <= '0;
        end else begin
            init <= '0;

            case (s_state)
                S_POR        : timer <= timer + 'd1;
                S_PROG       : init <= '1;
                S_WAIT_INIT  : timer <= '0;
                S_WAIT_UART  : timer <= '0;
                S_WAIT_FRAME : ; //timer <= timer + 'd1; // Uncomment if testing the UART incrementing pattern
                S_WAIT_UART_TX, S_PAUSE_UART : ;
                S_XXX        : ;
            endcase // s_state
        end
    end

    // How to enable the IR LED when the camera is exposing the frame?
    // The camera is set to run on its own clock and stream out frames.
    // @TBD: Qualify this with UART data so this kicks off only with a specific command
    // The sensor LED signal is an input to the Himax camera and kicks off a frame capture
    // Potentially keep the sensor_led signal high until the entire frame is read out (EOF) to
    // sync up the IR LED with exposure.
    always_ff @(posedge clk) begin
        if(rst) begin
            sensor_led <= 0;
        end else begin
            if (uart_rx_valid)
                sensor_led <= '1;
            else if (pixel_valid)
                sensor_led <= '0;
        end
    end

    //================================================================================
    // Himax camera needs initialization at startup over I2C. The register settings are
    // stored in a mem file as: <address> <data> on separate lines.
    //================================================================================
    logic w_scl_out, w_sda_out;
    lsc_i2cm_himax #(
        .NUM_CMD  (NUM_HIMAX_CMDS ),
        .INIT_FILE(HIMAX_INIT_FILE)
    ) u_lsc_i2cm_himax (
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

    // Sensor uses its internal clock except during configuration. Switchover to the
    // internal clock is automatic in the sensor
    assign sensor_clk = init_done ? 1'b0 : clk;



    //================================================================================
    // Capture 4 bit camera data and convert to 8 bits wide
    // @TBD: Instantiate IO cells on the cam_data for good timing
    //================================================================================
    logic [7:0] cam_data;
    logic [3:0] pxd_d   ;
    logic       hsync, vsync;
    logic [9:0] pxl_cnt ;
    logic       pxl_vld ;
    logic [3:0] pxd_n, pxd_p;

    // Add IO buffers to improve timing
    IOL_B
        #(
            .LATCHIN ("NONE_DDR"),
            .DDROUT  ("NO")
        ) u_io_pxd[3:0] (
            .PADDI  (pxd[3:0]),
            .DO1    (1'b0),
            .DO0    (1'b0),
            .CE     (1'b1),
            .IOLTO  (1'b1),
            .HOLD   (1'b0),
            .INCLK  (px_clk),
            .OUTCLK (px_clk),
            .PADDO  (),
            .PADDT  (),
            .DI1    (pxd_n[3:0]),
            .DI0    (pxd_p[3:0])
        );

    logic px_fv_p;
/*
IOL_B
#(
    .LATCHIN ("NONE_REG"),
    .DDROUT  ("NO")
) u_io_fv (
    .PADDI  (px_fv),  // I
    .DO1    (1'b0),  // I
.DO0    (1'b0),  // I
    .CE     (1'b1),  // I - clock enabled
    .IOLTO  (1'b1),  // I - tristate enabled
    .HOLD   (1'b0),  // I - hold disabled
    .INCLK  (px_clk),  // I
    .OUTCLK (px_clk),  // I
    .PADDO  (),  // O
    .PADDT  (),  // O
    .DI1    (px_fv_n),  // O
    .DI0    (px_fv_p)   // O
);
*/
    assign px_fv_p = px_fv;

    logic px_lv_p, px_lv_n;
    IOL_B #(
        .LATCHIN("NONE_DDR"),
        .DDROUT ("NO"      )
    ) u_io_lv (
        .PADDI (px_lv  ), // I
        .DO1   (1'b0   ), // I
        .DO0   (1'b0   ), // I
        .CE    (1'b1   ), // I - clock enabled
        .IOLTO (1'b1   ), // I - tristate enabled
        .HOLD  (1'b0   ), // I - hold disabled
        .INCLK (px_clk ), // I
        .OUTCLK(px_clk ), // I
        .PADDO (       ), // O
        .PADDT (       ), // O
        .DI1   (px_lv_n), // O
        .DI0   (px_lv_p)  // O
    );



    always_ff @(posedge px_clk) begin
        pxd_d    <= pxd_p;
        cam_data <= {pxd_d, pxd_p};
        hsync    <= px_lv_p;
        vsync    <= px_fv_p;
        if (px_lv_p == '0)
            pxl_cnt <= '0;
        else
            pxl_cnt <= pxl_cnt + 'd1;
    end

    assign pxl_vld = hsync && ~pxl_cnt[0];

    // Cross the clock domain into the local clock using an async FIFO

    // Is it safe to use the load_fifo without a CDC? I think so as its a single bit and doesnt matter
    // if it does jitter a bit. Probably not OK for an ASIC but will do here!
    // Note that the minimum AW for this component is 2, else fails.
    stream_dual_clock_fifo #(.DW(8), .AW(4)) i_stream_dual_clock_fifo (
        .wr_clk          (px_clk             ),
        .wr_rst          (rst                ),
        .stream_s_data_i (cam_data           ),
        .stream_s_valid_i(pxl_vld & load_fifo),
        .stream_s_ready_o(                   ), // @TBD: if deasserted, this is an error!
        .rd_clk          (clk                ),
        .rd_rst          (rst                ),
        .stream_m_data_o (pixel_data         ),
        .stream_m_valid_o(pixel_valid        ),
        .stream_m_ready_i(pixel_ready        )
    );

    // Dont hold off the FIFO, ever!
    assign pixel_ready = '1;

    // Detect an end of frame by detecting a falling VSYNC.
    logic [1:0] vsync_d;
    logic       eof    ;
    always_ff @(posedge px_clk)
        vsync_d <= {vsync_d[0], vsync};

    assign eof = vsync_d[1] & ~vsync_d[0];

    // Demet the EOF to the clk domain & rising edge detect it
    logic [1:0] eof_d;
    always_ff @(posedge clk)
        eof_d <= {eof_d[0], eof};

    assign pixel_eof = ~eof_d[1] & eof_d[0];

    // Allow the FIFO under UART command and stop it once the EOF is reached
    always_ff @(posedge clk) begin
        if(rst) begin
            load_fifo <= '0;
        end else begin
            if ((s_state == S_WAIT_UART) & uart_rx_valid)
                load_fifo <= '1;
            else if ((s_state == S_WAIT_FRAME) & eof)
                load_fifo <= '0;
        end
    end

    // RAM to buffer pixel data
    logic [16:0] ram_addr    ;
    logic        ram_cs, ram_wr_en;
    logic        ram_rd_valid;
    logic [ 7:0] ram_wr_data ;
    logic [ 7:0] ram_rd_data ;
    ice40_spram_128kx8 i_ice40_spram_128kx8 (
        .clk    (clk        ),
        .rst    (rst        ),
        .cs     (ram_cs     ),
        .addr   (ram_addr   ),
        .wr_en  (ram_wr_en  ),
        .wr_data(ram_wr_data),
        .rd_data(ram_rd_data)
    );

    // Write pixels into the RAM as they come from the camera
    assign ram_wr_en   = pixel_valid & (s_state == S_WAIT_FRAME);
    assign ram_cs      = (pixel_valid & (s_state == S_WAIT_FRAME) ) | (uart_tx_empty & (s_state == S_WAIT_UART_TX));
    assign ram_wr_data = pixel_data;

    always_ff @(posedge clk) begin
        if(rst) begin
            ram_addr   <= '0;
            num_pixels <= '0;
        end else begin

            // RAM has a 1 cycle read delay
            ram_rd_valid <= ram_cs & ~ram_wr_en;

            // RAM data goes invalid for a cycle after the UART ack's it
            //uart_tx_valid <= (s_state == S_WAIT_UART_TX) & ram_rd_valid & ~uart_tx_ack;
            //uart_tx_valid <= (s_state == S_WAIT_UART_TX) & ram_rd_valid & uart_tx_empty;

            case (s_state)
                S_POR, S_PROG, S_WAIT_INIT :;
                S_WAIT_UART  : ram_addr <= '0;
                S_WAIT_FRAME : begin
                    num_pixels <= num_pixels + pixel_valid; // Count up the pixels
                    if (eof)
                        ram_addr <= '0;
                    else
                        ram_addr <= ram_addr + pixel_valid;
                end
                S_WAIT_UART_TX : begin
                    num_pixels <= num_pixels - uart_tx_empty; // Count down number of pixels
                    ram_addr   <= ram_addr + uart_tx_empty;
                end

                S_PAUSE_UART : ;
                S_XXX        : ;
            endcase
        end
    end

    assign uart_tx_valid = ram_rd_valid;
    assign uart_tx_data  = ram_rd_data;

    lsc_uart #(.PERIOD(UART_PERIOD)) u_lsc_uart (
        .ref_clk(clk          ),
        .clk    (clk          ),
        .resetn (~rst         ),
        
        .i_din  (uart_tx_data ),
        .i_valid(uart_tx_valid),
        .o_empty(uart_tx_empty),
        
        .o_dout (uart_rx_data ),
        .o_valid(uart_rx_valid),
        
        .i_rxd  (uart_rx      ),
        .o_txd  (uart_tx      )
    );
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

    assign red   = ~clk_divider[22] && clk_divider[21] && duty_cycle;
    assign green = clk_divider[22] && ~clk_divider[21] && duty_cycle;
    assign blue  = clk_divider[22] && clk_divider[21] && duty_cycle;

    assign gpio[0]   = clk_divider[23];
    assign gpio[1]   = clk_divider[22];
    assign gpio[2]   = clk_divider[21];
    assign host_intr = clk_divider[20];

endmodule



