// Can support some amount of multi toolchain compatiblity, not yet fully developed!
//`define __YOSYS__
`include "../common/synth_helper.sv"
`include "../common/ice40_resetn.v"

module minimal_design (
	// Flash
	output logic mem_sck,
	inout wire [3:0] mem_sio,
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
	inout wire px_clk,
	inout wire px_fv,
	inout wire px_lv,
	inout wire [7:0] pxd,
	inout wire sensor_led,
	
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
	parameter CLOCK_SEL = 24; // 48MHz, 24MHz or 12MHz

    // Following are shared with I2C, keep them floating else power monitoring wont work!
	//assign sensor_mosi = '0;
	//assign sensor_sck = '0;

	// Default output assignments to prevent floating outputs which take more power
	assign imager_ssn = '1;

    // Note that the LSB is an output of the flash chip so should not be assigned low
    assign mem_sio[3:1] = '1;

	assign sram_ssn = '1;
    assign flash_ssn = '1;
	assign host_miso = '0;
    assign host_intr = '0;
    assign sensor_clk = '0;
    //assign sensor_led = '0;
    assign mic_clk = '0;
    assign mic_ws = '0;
    assign gpio = {3'b000};


    wire clk;
    wire reset_n, reset;

    // Select the right clock divider

    `UP_HSOSC #( .CLKHF_DIV ( (CLOCK_SEL==12) ? "0b10" : 
                            ( (CLOCK_SEL==24) ? "0b01" : "0b00" ) ))
    u_osc (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk));

    ice40_resetn u_reset_n (.clk(clk), .resetn(reset_n));

 	logic [27:0] clk_divider;
 	always @(posedge clk) begin
 		if (!reset_n)
 			clk_divider <= 0;
 		else
 			clk_divider <= clk_divider + 1;
 	end
	//================================================================================
	// LED ports have to have a special IO driver
	//================================================================================
	// LED is too bright, make this dim enough to not hurt eyes!
	logic duty_cycle;
	assign duty_cycle = &clk_divider[6:0];
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
	defparam u_led_driver.RGB1_CURRENT = "0b000000";
	defparam u_led_driver.RGB2_CURRENT = "0b000000";
/*  
assign led_blue = 1;
assign led_green = 1;
assign led_red = 1;
*/
endmodule


