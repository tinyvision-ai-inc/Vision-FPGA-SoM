`timescale 1ns/1ns
module RGB1P8V (CURREN, RGBLEDEN, RGB0PWM, RGB1PWM, RGB2PWM, RGB2, RGB1, RGB0);

  //Port Type List [Expanded Bus/Bit]
      (* \desc = "Enable reference current to IR drivers. Enabling the drivers takes 100us to reach a stable reference current value. Active high" *)
  input CURREN;
      (* \desc = "Enable the RGB driver. Active high" *)
  input RGBLEDEN;
      (* \desc = "Input data to drive RGB0 LED pin" *)
  input RGB0PWM;
      (* \desc = "Input data to drive RGB1 LED pin" *)
  input RGB1PWM;
      (* \desc = "Input data to drive RGB2 LED pin" *)
  input RGB2PWM;
      (* \desc = "RGB LED output" *)
  output RGB2;
      (* \desc = "RGB LED output" *)
  output RGB1;
      (* \desc = "RGB LED output" *)
  output RGB0;

	//Wires and Registers
	wire gnd;
	wire vcc;

	VLO vlo_inst(.Z(gnd));
	VHI vhi_inst(.Z(vcc));

  //IP Ports Tied Off for Simulation
  //Attribute List
      (* \desc = "0b0 = full current, 0b1 = half current", \otherValues = "{0b1}" *)
  parameter CURRENT_MODE = "0";
      (* \desc = "0b000000 = 0mA, 0b000001 = 4mA, 0b000011 = 8mA, 0b000111 = 12mA, 0b001111 = 16mA, 0b011111 = 20mA, 0b111111 = 24mA. Divide by 2 for half current mode", \otherValues = "{0b000001, 0b000011, 0b000111, 0b001111, 0b011111, 0b111111}" *)
  parameter RGB0_CURRENT = "0b000000";
      (* \desc = "0b000000 = 0mA, 0b000001 = 4mA, 0b000011 = 8mA, 0b000111 = 12mA, 0b001111 = 16mA, 0b011111 = 20mA, 0b111111 = 24mA. Divide by 2 for half current mode", \otherValues = "{0b000001, 0b000011, 0b000111, 0b001111, 0b011111, 0b111111}" *)
  parameter RGB1_CURRENT = "0b000000";
      (* \desc = "0b000000 = 0mA, 0b000001 = 4mA, 0b000011 = 8mA, 0b000111 = 12mA, 0b001111 = 16mA, 0b011111 = 20mA, 0b111111 = 24mA. Divide by 2 for half current mode", \otherValues = "{0b000001, 0b000011, 0b000111, 0b001111, 0b011111, 0b111111}" *)
  parameter RGB2_CURRENT = "0b000000";

  RGB_CORE RGB_CORE_inst(.CURREN(CURREN), .RGBLEDEN(RGBLEDEN), .RGB0PWM(RGB0PWM), .RGB1PWM(RGB1PWM), .RGB2PWM(RGB2PWM), .TRIM9 (gnd), .TRIM8 (gnd), .TRIM7 (vcc), .TRIM6 (gnd), .TRIM5 (vcc), .TRIM4 (gnd), .TRIM3 (gnd), .TRIM2 (gnd), .TRIM1 (gnd), .TRIM0 (gnd), .RGB2(rgb2Out), .RGB1(rgb1Out), .RGB0(rgb0Out));
  defparam RGB_CORE_inst.CURRENT_MODE = CURRENT_MODE;
  defparam RGB_CORE_inst.RGB0_CURRENT = RGB0_CURRENT;
  defparam RGB_CORE_inst.RGB1_CURRENT = RGB1_CURRENT;
  defparam RGB_CORE_inst.RGB2_CURRENT = RGB2_CURRENT;
  defparam RGB_CORE_inst.FABRIC_TRIME = "ENABLE";

    OB_RGB rgb0Pad (.T_N(vcc), .I(rgb0Out), .O(), .B(RGB0));
    OB_RGB rgb1Pad (.T_N(vcc), .I(rgb1Out), .O(), .B(RGB1));
    OB_RGB rgb2Pad (.T_N(vcc), .I(rgb2Out), .O(), .B(RGB2));


endmodule
