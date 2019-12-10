/****************************************************************************
 * top.v
 ****************************************************************************/

/**
 * Module: top
 * 
 * Simple top level that can blink LED's and source clocks to various devices.
 */
 
//`define __YOSYS__
`include "../common/synth_helper.sv"
`include "../common/uart.v"
`include "../common/ice40_resetn.v"

module blink_led (
	// Flash
	output logic mem_sck,
	output logic [3:0] mem_sio,
	output logic flash_ssn,
	output logic sram_ssn,
	
	// Host interface
	input logic host_sck_uart_rx,
	input logic host_ssn,
	input logic host_mosi_uart_tx,
	output logic host_miso, // @TODO: this port should be tri-state...
	output logic host_intr,
	
	// GPIO
	output logic [2:0] gpio, // @TODO: make this tri-state in the future
	
	// SPI master to control imager and IMU
	inout wire sensor_sck, // Also shared with I2C SCK
	inout wire sensor_mosi, // Also shared with I2C SDA
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
	parameter CLOCK_SEL = 24; // 24MHz or 12MHz
	
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
	logic clk_48m;
	logic reset_n, reset;

	// Select the right clock divider
	`UP_HSOSC #( .CLKHF_DIV ((CLOCK_SEL==12) ? "0b10" : "0b01") ) u_osc (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk_48m));
	
	// Reset
 	ice40_resetn u_reset_n (.clk(clk_48m), .resetn(reset_n));
	assign reset = ~reset_n;

	//
		// Add a PLL to to test that this locks
	logic pll_clk, pll_lock, pll_fb;
	//SB_PLL40_CORE // Yosys compatible version isnt done yet!
	PLL_B
		#(.FEEDBACK_PATH("SIMPLE"), .DIVR(4'b0001), .DIVF(7'b1000010), .DIVQ(3'b011), .FILTER_RANGE(3'b001) ) 
		my_pll 
		(.REFERENCECLK(clk_48m),	.OUTCORE(pll_clk), .INTFBOUT(pll_fb), .FEEDBACK(pll_fb), .LOCK(pll_lock), .RESET_N(reset_n), .BYPASS(1'b0));
	
 	logic [27:0] clk_divider;
 	always @(posedge clk_48m) begin
 		if (!reset_n)
 			clk_divider <= 0;
 		else
 			clk_divider <= clk_divider + 1;
 	end

 	// Blink all LED's on the devkit
 	assign host_intr = clk_divider[26];
 	assign gpio = {uart_rx_data[0], pll_clk, pll_lock};
 	assign sensor_led = clk_divider[27];

 	// Source clock to the mic and imager
 	assign sensor_clk = (CLOCK_SEL == 24) ? clk_divider[0] : clk_divider[1]; // 6MHz clock
 	assign mic_clk = (CLOCK_SEL == 24) ? clk_divider[2] : clk_divider[1]; // 3MHz
 	assign mic_ws = clk_divider[3+$clog2(64)]; // mic_clk/64

	// UART to test FTDI
	logic uart_rx_vld, uart_tx_vld, uart_rx_busy, uart_tx_busy;
	logic [7:0] uart_rx_data, uart_tx_data;
	logic uart_recv_err;
/*	uart #(.CLOCK_DIVIDE(1250) ) // clock rate (48Mhz) / (baud rate (9600) * 4)
	my_uart (.clk(clk_48m), .rst(reset), 
		.rx(host_sck_uart_rx ), .received(uart_rx_vld), .rx_byte(uart_rx_data), .is_receiving(uart_rx_busy), 
		.tx(host_mosi_uart_tx), .transmit(uart_tx_vld), .tx_byte(uart_tx_data), .is_transmitting(uart_tx_busy), 
		.recv_error(uart_recv_err));
	// Loopback
	assign uart_tx_data = uart_rx_data;
	assign uart_tx_vld = uart_rx_vld;
*/
	//================================================================================
	// LED ports have to have a special IO driver
	//================================================================================
	// LED is too bright, make this dim enough to not hurt eyes!
	logic duty_cycle;
	assign duty_cycle = clk_divider[0] && clk_divider[1];
	`UP_RGB u_led_driver(	
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


