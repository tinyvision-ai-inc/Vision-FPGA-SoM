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

module top (

                  // GPIO
                  output logic [2:0] gpio, // @TODO: make this tri-state in the future
                  output logic 	     led_red,
                  output logic 	     led_green,
                  output logic 	     led_blue

                  );

   //================================================================================              
   // Clock and reset blocks
   //================================================================================
   logic 			     clk_10k;
   logic 			     clk_12m;
   
   logic 			     reset_n, reset;
   logic 			     pll_lock;
   
`ifndef SIM
   //10kHz & 48MHz oscillator
   SB_LFOSC SB_LFOSC_inst(.CLKLFEN(1'b1), .CLKLFPU(1'b1), .CLKLF(clk_10k) );
   SB_HFOSC #(.CLKHF_DIV("0b10")) SB_HFOSC_inst(.CLKHFEN(1'b1), .CLKHFPU(1'b1), .CLKHF(clk_12m) );

`else
   initial clk_10k = 0;
   initial clk_12m = 1;
   always #50000 clk_10k = ~clk_10k;
   always #41.67 clk_12m = ~clk_12m;
   
`endif

   // Reset
   ice40_resetn u_reset_n (.clk(clk_12m), .resetn(reset_n));
   assign reset = ~reset_n;

   // Slowly vary the servo pulse width
   logic [21:0] ticker;
   logic tick;
   logic up;
   logic [7:0] servo_pos;
   initial begin 
      ticker = '0;
      up = '0;
      servo_pos = '0;
   end
   always @(posedge clk_12m) ticker <= ticker + 'd1;

   assign tick = (ticker == '1);


   always @(posedge clk_12m) begin
      if (tick)
         if (servo_pos >= 'hFF-'d25)
            up = '0;
         else if (servo_pos <= 'd25)
            up = '1;
   
      if (tick)
         if (up)
            servo_pos <= servo_pos + 'd25;
         else
            servo_pos <= servo_pos - 'd25;
   end
   servo #(.CLK_FREQUENCY(15000000) ) u_servo (.clk(clk_12m), .rst(reset), .pos(servo_pos), .pwm(gpio[0]));   
   
   //================================================================================
   // LED ports have to have a special IO driver: for some reason, the SB_RGBA_DRV
   // doesnt behave properly using the open source toolchain. We use the IO simply as
   // active low IO to drive the LED.
   //================================================================================
   
   SB_RGBA_DRV u_led_driver(
                            .CURREN(1'b1), 
                            .RGBLEDEN(1'b1),
                            .RGB0PWM(1'b0), 
                            .RGB1PWM(1'b0), 
                            .RGB2PWM(1'b0), 
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


