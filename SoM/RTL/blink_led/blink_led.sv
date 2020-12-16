/*
 *-----------------------------------------------------------------------------
 * File          : blink_led.sv
 *-----------------------------------------------------------------------------
 * Description :
 *   Exercises the common stuff in the SoM, good jumping off place for 
 *   experiments...
 *-----------------------------------------------------------------------------
 * Copyright (c) 2020 by tinyVision.ai Inc.
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

`default_nettype none

module blink_led (
   // Flash
   output logic       mem_sck          ,
   output logic [3:0] mem_sio          ,
   output logic       flash_ssn        ,
   output logic       sram_ssn         ,
                                         // Host interface
   input  logic       host_sck_uart_rx ,
   input  logic       host_ssn         ,
   inout  logic       host_mosi_uart_tx,
   output logic       host_miso        , // @TODO: this port should be tri-state...
   output logic       host_intr        ,
                                         // GPIO
   output logic [2:0] gpio             , // @TODO: make this tri-state in the future
                                         // SPI master to control imager and IMU
   inout  wire        sensor_sck       , // Also shared with I2C SCK
   inout  wire        sensor_mosi      , // Also shared with I2C SDA
   input  logic       sensor_miso      ,
   output logic       imager_ssn       ,
   output logic       sensor_clk       , // Must be ~6MHz for Pixart
                                         // Image sensor data port
   input  logic       px_clk           ,
   input  logic       px_fv            ,
   input  logic       px_lv            ,
   input  logic [7:0] pxd              ,
   output logic       sensor_led       ,
                                         //IMU
   input  logic       imu_intr         ,
                                         // Audio
   output logic       mic_clk          ,
   output logic       mic_ws           ,
   input  logic       mic_dout         ,
   output logic       led_red          ,
   output logic       led_green        ,
   output logic       led_blue
);

   // Default output assignments to prevent floating outputs
   //assign sensor_mosi = '0;
   assign imager_ssn = '1;
   //assign sensor_sck = '0;
   assign mem_sio = '0;
   assign sram_ssn = '1;
   assign host_miso = '0;

   //================================================================================              
   // Clock and reset blocks
   //================================================================================
   logic                             clk_48m;
   logic 			     clk_10k;
   logic 			     clk_24m;
   
   logic 			     reset_n, reset;
   logic [27:0] 		     counter_fast, counter_slow;
   logic  			     toggle_fast, toggle_slow;
   logic 			     pll_lock;
   
//`ifndef SIM
   //10kHz & 48MHz oscillator
   SB_LFOSC SB_LFOSC_inst(.CLKLFEN(1'b1), .CLKLFPU(1'b1), .CLKLF(clk_10k) );
   SB_HFOSC SB_HFOSC_inst(.CLKHFEN(1'b1), .CLKHFPU(1'b1), .CLKHF(clk_48m) );

//`else
//   always #1000 clk_10k = ~clk_10k;
//   always #10 clk_48m = ~clk_48m;
//   
//`endif

   // PLL: cannot be placed as this BEL conflicts with px_clk which is an input.
   // Should change this pin to something else on the next rev of the SoM...
   pll u_pll(.clock_in(clk_48m), .clock_out(clk_24m), .locked(pll_lock) );
   
   // Reset
   ice40_resetn u_reset_n (.clk(clk_10k), .resetn(reset_n));
   assign reset = ~reset_n;

   always @(posedge clk_48m) begin
      counter_fast <= counter_fast + 1'b1;
   end
   assign toggle_fast = counter_fast[22];
   
   always @(posedge clk_10k) begin
      counter_slow <= counter_slow + 1'b1;
   end
   assign toggle_slow = counter_slow[11];
   

   // Blink all LED's on the devkit
   assign host_intr = toggle_slow;
   assign gpio = {uart_rx_data[0], toggle_slow, toggle_fast};
   assign sensor_led = toggle_fast;

   // Source clock to the mic and imager
   assign sensor_clk = counter_fast[1]; // 6MHz clock
   assign mic_clk = counter_fast[3]; // 3MHz
   assign mic_ws = counter_fast[3+$clog2(64)]; // mic_clk/64

   // UART to test FTDI
   logic uart_rx_vld, uart_tx_vld, uart_rx_busy, uart_tx_busy;
   logic [7:0] uart_rx_data, uart_tx_data;
   logic       uart_recv_err;
/*

   uart #(.CLOCK_DIVIDE(1250) ) // clock rate (48Mhz) / (baud rate (9600) * 4)
   my_uart (.clk(clk_48m), .rst(reset), 
	    .rx(host_sck_uart_rx ), .received(uart_rx_vld), .rx_byte(uart_rx_data), .is_receiving(uart_rx_busy), 
	    .tx(host_mosi_uart_tx), .transmit(uart_tx_vld), .tx_byte(uart_tx_data), .is_transmitting(uart_tx_busy), 
	    .recv_error(uart_recv_err));
   // Loopback
   assign uart_tx_data = uart_rx_data;
   assign uart_tx_vld = uart_rx_vld;
*/
   assign host_mosi_uart_tx = host_sck_uart_rx;
   
   //================================================================================
   // LED ports have to have a special IO driver: for some reason, the SB_RGBA_DRV
   // doesnt behave properly using the open source toolchain. We use the IO simply as
   // active low IO to drive the LED.
   //================================================================================
   logic       duty_cycle;
   assign duty_cycle = ~& counter_fast[3:0];
   
   SB_RGBA_DRV u_led_driver(
                            .CURREN(1'b1), 
                            .RGBLEDEN(1'b1),
                            .RGB0PWM(toggle_slow), 
                            .RGB1PWM(toggle_fast), 
                            .RGB2PWM(~toggle_fast), 
                            .RGB0(led_red),
                            .RGB1(led_green), 
                            .RGB2(led_blue)
                            );
   defparam u_led_driver.CURRENT_MODE = "0b0" ;
   defparam u_led_driver.RGB0_CURRENT = "0b000001";
   defparam u_led_driver.RGB1_CURRENT = "0b000001";
   defparam u_led_driver.RGB2_CURRENT = "0b000001";
   
   // The LED's are blinding! Cut their intensity down...

//   assign led_red = toggle_fast;
//   assign led_green = toggle_slow;
//   assign led_blue = 1'b1;
   
//    assign led_red = toggle_fast | duty_cycle;
//    assign led_green = toggle_slow | duty_cycle;
//    assign led_blue = 1'b1;
    
   
endmodule


