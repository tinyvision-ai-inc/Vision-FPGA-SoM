/****************************************************************************
 * top.v
 ****************************************************************************/

/**
 * Module: top
 * 
 * Simple top level that can blink LED's and source clocks to various devices.
 */
module top (
	// Flash
	output logic mem_sck,
	output logic [3:0] mem_sio,
	output logic flash_ssn,
	output logic sram_ssn,
	
	// Host interface
	input logic host_sck,
	input logic host_ssn,
	input logic host_mosi,
	output logic host_miso, // @TODO: this port should be tri-state...
	output logic host_intr,
	
	// GPIO
	output logic [2:0] gpio, // @TODO: make this tri-state in the future
	
	// SPI master to control imager and IMU
	output logic sensor_sck,
	output logic sensor_mosi,
	input logic sensor_miso,
	output logic imager_ssn,
	
	output logic sensor_clk, // Must be ~6MHz

	// Image sensor data port
	input logic px_clk,
	input logic px_fv,
	input logic px_lv,
	input logic [7:0] pxd,
	output logic sensor_led,
	
	//IMU
	input logic imu_intr,
	
	// Audio
	output logic mic_clk,
	output logic mic_ws,
	input logic mic_dout,
	
	output logic led_red,
	output logic led_green,
	output logic led_blue
		
	);

	//Parameters
	
	// Default output assignments to prevent floating outputs
	assign sensor_mosi = '0;
	assign imager_ssn = '1;
	assign sensor_sck = '0;
	assign mem_sio = '0;
	assign sram_ssn = '1;
	assign host_miso = '0;

	//================================================================================		
	// Clock and reset blocks
	//================================================================================
	logic clk_48m;
	logic reset_n;

	HSOSC #( .CLKHF_DIV ("0b00") ) u_osc (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk_48m));
	
	// Reset
 	ice40_resetn u_reset_n (.clk(clk_48m), .resetn(reset_n));
	
 	logic [27:0] clk_divider;
 	always @(posedge clk_48m) begin
 		if (!reset_n)
 			clk_divider <= 0;
 		else
 			clk_divider <= clk_divider + 1;
 	end

 	// Blink all LED's on the devkit
 	assign host_intr = clk_divider[26];
 	assign gpio = clk_divider[25:23];
 	assign sensor_led = clk_divider[27];

 	// Source clock to the mic and imager
 	assign sensor_clk = clk_divider[2]; // 6MHz clock
 	assign mic_clk = clk_divider[3]; // 3MHz
 	assign mic_ws = clk_divider[3+$clog2(64)]; // mic_clk/64
 	
	//================================================================================
	// LED ports have to have a special IO driver
	//================================================================================
	// LED is too bright, make this dim enough to not hurt eyes!
	logic duty_cycle;
	assign duty_cycle = clk_divider[0] && clk_divider[1];
	RGB u_led_driver(	
					.CURREN(1'b1), 
					.RGBLEDEN(1'b1),
					.RGB0PWM(clk_divider[25] && clk_divider[24] && duty_cycle), 
					.RGB1PWM(clk_divider[25] && ~clk_divider[24] && duty_cycle), 
					.RGB2PWM(~clk_divider[25] && clk_divider[24] && duty_cycle), 
					.RGB0(led_red),
					.RGB1(led_green), 
					.RGB2(led_blue)
					);
	defparam u_led_driver.CURRENT_MODE = 1 ;
	defparam u_led_driver.RGB0_CURRENT = "0b000001";
	defparam u_led_driver.RGB1_CURRENT = "0b000001";
	defparam u_led_driver.RGB2_CURRENT = "0b000001";
	
endmodule


