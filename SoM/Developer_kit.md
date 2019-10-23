# Vision FPGA SoM Developer Kit

The SoM is supported by a developer kit. The kit is designed to enable:
* Programming/debugging the SoM
  * Ability to program one-time programmable FPGA CRAM, FPGA SRAM and Flash with bitfiles/SW images.
  * Micro USB (FT232H) based interface
  * SPI, I2C and UART supported for SoM communication/debug
* 4 LED's on GPIO
* Programmable IO voltage capability
* Expansion to various sensors using QWIIC, PMOD and 0/1" headers
* Power measurement capability
* Easy access to all SoM interface pins on a 0.1" header
* Additional I2S microphone for stereo applications
* Ability to fully isolate the SoM for low power prototyping

## Configuration switches/jumpers
Please refer to the [SoM devkit schematics](./Schematics/Dev_kit) for details.

### Miscellaneous functions: SW1
| Switch | Name | Description |
| :---: | ---: | --- |
|1,2,3 | I2C Enable | When these switches are closed, the FTDI chip can be used in I2C mode to communicate with the on-board power monitor as well other devices on the I2C bus both on the SoM as well as on the QWIIC connector. This feature allows for power measurement as well as development of drivers for various I2C devices. |
|4 | LDO_EN_N | When closed, the LDO's on the SoM are disabled allowing the user to source these rails from an external power source to test a high efficiency power system. |
|5 | FT_SEL_N | When opened, the FTDI chip is isolated from the SoM. This can be used when the SoM is hooked up through the PMOD connector for example to an external device.|
|6 | PIX_RESET_N | Normally open, can be closed to hold the on-board Pixart imager in reset. |
|7 | VDD_IR_LED | Power supply for the on-board IR LED. The switch may be opened in case an external IR LED is used to illuminate the scene and the on-board LED is not used. |
|8 | PROG_FLASH | When closed, selects the Flash as the destination for the host accesses. When open, the host will be able to access the FPGA CRAM/SRAM if the SPI_SEL switch is also closed. |

### IO voltage selection: J1
This 3 position jumper selects the IO voltage (1.8 or 3.3V) of the host interface on the SoM (GPIO and HOST_* signals). The FTDI chip operates on 3.3V hence 3.3V IO should be normally selected.

### External Power: P2
This normally closed jumper can be opened to supply power externally to the board in case there is no USB connection available.

### PMOD: P7
A dual PMOD (6x2) is provided for convenient access to the host signals in a single location. This connector may be used to communicate with the Digilent PMOD devices or used for other purposes.

### QWIIC: J3
The SoM I2C lines are translated and available on this connector to allow connectivity to the QWICC family of peripherals. Note that the INA219 power monitor as well as the SoM IMU and the FPGA are connected to this interface.
When the FPGA drives the Pixart sensor, it uses the I2C lines as SPI clock and MOSI. I2C devices should ignore these signals as they do not follow the I2C START/STOP signals required to frame an I2C transaction.

### SoM pins
All SoM pins are brought out to two dual row 0.1" headers. Pin numbers are staggered to meet the 0.05: pitch on the SoM.

## Programming details
The SoM has a 4Mb WinBond W25x40CL USON8 package. Please select this if required on the programmer.

| Functionality | SW1-5   | SW1-8   | PROGRAM | Description |
| :---:         | ---:    |  ---:   | ---:    |--- |
| Isolate       | Open    | x       | x       | FTDI isolated from SoM |
| Host mode     | Close   | x       | Open    | FTDI connected to SoM host port |
| Flash         | Close   | Close   | Close   | FTDI connected to FPGA flash |
| CRAM/SRAM     | Close   | Open    | Close   | FTDI connected to FPGA CRAM/SRAM for programming|

## LED's
| LED Reference | Functionality |
| :---: | --- |
| DS1 | Lights up when the FPGA is programmed or the SoM is not installed. |
| DS2 | HOST_INTR, set high to light up the LED|
| DS3 | GPIO 0, set high to light up the LED|
| DS4 | GPIO 1, set high to light up the LED|
| DS5 | GPIO 2, set high to light up the LED|

## IO voltage capability
The logic levels on the FPGA host interface (Bank 2) can be selected for compatibility with the host using this jumper. The two most commonly used logic levels (1.8V, 3.3V) can be selected.

Note that the FTDI operates at 3.3V hence, the voltage must be set to 3.3V if the FTDI is used for FPGA programming.

## Power measurement
Power is measured on the board using an INA219 chip. This I2C device can measure the 3.3V applied to the SoM and also teh current flowing intot he SoM. The data can be accessed over the I2C bus on the board eithe rusing the QWIIC connector or the FTDI as long as the SW1 settings are proerly selected.

## Expansion connectors
The devkit provides remote microphone capability on the P5 header where power, ground and the I2S microphone signals are brought out. Note that the SoM has a microphone on this bus already and is set to be device 0. If the external microphone is used, please tie the select line low so taht the microphones work together as a stereo pair.

## Microphone
An I2S/TDM microphone is provided on the developer kit. This allows the user to create a stereo microphone system when using I2S. By switching to the TDM mode of the microphone (TBD), up to 8 microphones can be used with the SoM.

## Miscellaneous functionality
* FPGA reset: a pushbutton is used to manually reset the FPGA and cause it to re-download.
* Prototyping area
