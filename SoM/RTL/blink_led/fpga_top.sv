/****************************************************************************
 * top.v
 ****************************************************************************/

/**
 * Module: top
 * 
 * TODO: Add module documentation
 */
module top (
	// Flash
	output logic mem_sck,
	output logic flash_ssn,
	output logic sram_ssn,
	output logic [3:0] mem_sio,
	
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
	output logic imager_ssn,
	output logic imu_ssn,
	output logic sensor_mosi,
	input logic sensor_miso,
	
	output logic sensor_clk, // Must be ~6MHz

	// Image sensor data port
	input logic px_clk,
	input logic px_fv,
	input logic px_lv,
	input logic [7:0] pxd,
	
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
	assign mic_clk = '0;
	assign mic_ws = '0;
	assign sensor_mosi = '0;
	assign imager_ssn = '1;
	assign imu_ssn = '1;
	assign sensor_sck = '0;
	assign flash_sck = '0;
	assign flash_ssn = '1;
	assign sram_ssn = '1;
	assign flash_mosi = '0;
	assign host_miso = '0;
	assign host_intr = reset_n; // @TBD: prevent synthesis from ripping out the design
	assign gpio = '0;

	//================================================================================		
	// Start with clock and reset blocks
	//================================================================================
	logic clk_48m;
	logic reset_n;

	HSOSC
		#( .CLKHF_DIV ("0b00") ) OSCInst_48M (
			.CLKHFPU (1'b1),  		// I
			.CLKHFEN (1'b1),  		// I
			.CLKHF   (clk_48m)   	// O
		);
	
	// Create a local reset
    logic [7:0] reset_n_counter = '0; // FPGA will always reset to '0
    assign reset_n = &reset_n_counter;

    always @(posedge clk_48m) begin
            if (!reset_n)
                    reset_n_counter <= reset_n_counter + 1;
    end
	
	//================================================================================
	// Sensor control
	//================================================================================
	assign sensor_reset_n = '0;

// Clock divide by 8 for sensor clock (Nominally 6MHz)
    logic [2:0] sensor_div_counter;
    assign sensor_clk = sensor_div_counter[2];
	
    always @(posedge clk_48m) begin
		if (!reset_n)
			sensor_div_counter <= '0;
		else
			sensor_div_counter <= sensor_div_counter + 'd1;
    end
	
	//================================================================================
	// LED ports have to have a special IO driver
	//================================================================================

	logic [27:0] led_counter;

    always @(posedge clk_48m) begin
		if (!reset_n)
			led_counter <= '0;
		else
			led_counter <= led_counter + 'd1;
    end
	// LED is too bright, make this dim enough to not hurt eyes!
	logic duty_cycle;
	assign duty_cycle = led_counter[0] && led_counter[1];
	
	RGB ir_driver(	
					.CURREN(1'b1), 
					.RGBLEDEN(1'b1), 
					//.RGB0PWM('1),
					//.RGB1PWM('1),
					//.RGB2PWM('1),
					.RGB0PWM(led_counter[25] && led_counter[24] && duty_cycle), 
					.RGB1PWM(led_counter[25] && ~led_counter[24] && duty_cycle), 
					.RGB2PWM(~led_counter[25] && led_counter[24] && duty_cycle), 
					.RGB0(led_red),
					.RGB1(led_green), 
					.RGB2(led_blue)
					);
	defparam ir_driver.CURRENT_MODE = 1 ;
	defparam ir_driver.RGB0_CURRENT = "0b000001";
	defparam ir_driver.RGB1_CURRENT = "0b000001";
	defparam ir_driver.RGB2_CURRENT = "0b000001";
	
endmodule


