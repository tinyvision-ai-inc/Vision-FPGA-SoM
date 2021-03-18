# Vision FPGA SoM Developer Kit

The SoM is supported by a developer kit. The kit is designed to enable:
* Programming/debugging the SoM
  * Ability to program one-time programmable FPGA CRAM, FPGA SRAM and Flash with bitfiles/SW images.
  * Micro USB (FT2232H) based interface
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
|1,2 | IO Voltage | The SoM can operate from either 1.8V or 3.3V IO. This switch allows selection of the IO voltage in case the devkit is being used to communicate with an external device that uses 1.8V IO. The on-board FTDI operates only at 3.3V so the switches should normally select 3.3V (SW1:1 On, SW1:2 Off) |
|3 | IR_LED Power Enable| When On, enables 3.3V to the IR LED on the SoM for night illumination. The IR LED is itself controlled by the FPGA.|
|4 | PIX_RESET_N | Normally open, can be closed to hold the on-board Pixart imager in reset. Suggest resetting the image sensor if you dont see any images coming through. The Image sensor can also be reset under SW over the SPI bus.|
|5 | LDO_EN_N | When On, the LDO's on the SoM are disabled allowing the user to source these rails from an external power source to test a high efficiency power system. The voltage pins are brought out to the prototyping area for easy access.|
|6 | Flash programming select| When On (default), selects the SoM Flash for programming|
|7 | Flash programming select| When On (default), selects the SoM Flash for programming|
|8 | CRAM Programming select | When On, selects the SoM CRAM for programming|

### IO voltage selection: SW1:[1,2]
This switch selects the IO voltage (1.8 or 3.3V) of the host interface on the SoM (GPIO and HOST_* signals). The FTDI chip operates on 3.3V hence 3.3V IO should be normally selected. This is the normally shipped configuration of the board.

### External Power: P2
External power to the board can be supplied over this port to measure power. Note that the FTDI is also powered from this port.

### PMOD: P7
A dual PMOD (6x2) is provided for convenient access to the host signals in a single location. This connector may be used to communicate with Digilent PMOD devices or used for other purposes.

### QWIIC: J1
The SoM I2C lines are translated and available on this connector to allow connectivity to the QWICC family of peripherals. Note that the INA219B power monitor as well as the SoM IMU and the FPGA are connected to this interface.


### SoM pins
All SoM pins are brought out to two dual row 0.1" headers. Pin numbers are staggered to meet the 0.05" pitch on the SoM.

## Programming details
FPGA programming can be done using either the open source [icestorm](http://www.clifford.at/icestorm/) toolchain or the Radiant programmer. The SoM allows programming of either the flash or the FPGA non-volatile RAM. Please see the table below for the switch settings to put the develop kit in various modes.

The SoM has a 4Mb WinBond W25x40CL USON8 package. Please select this in the Radiant programmer. Note that the icestorm programmer (iceprog) doesnt care what flash device is installed.


| Functionality | SW1-6	| SW1-7	| SW1-8	| Description |
| :---:         | ---:  |  ---: | ---:  |--- |
| Flash         | On 	| On   	| Off   | FTDI connected to FPGA flash |
| CRAM/SRAM     | Off  	| Off   | On   	| FTDI connected to FPGA CRAM/SRAM for programming|

> ***NOTE:***
> The devkit is still in development and programming the FPGA requires that the PROGRAM jumper
> must be installed before programming. Once programmed, the PROGRAM jumper must be removed
> and the FPGA reconfigured by pressing the RESET button.

## LED's
| LED Reference | Functionality |
| :---: | --- |
| DONE | Lights up when the FPGA is programmed or the SoM is not installed. |
| INT | HOST_INTR, set high to light up the LED|
| GP_0 | GPIO 0, set high to light up the LED|
| GP_1 | GPIO 1, set high to light up the LED|
| GP_2 | GPIO 2, set high to light up the LED|

## IO voltage capability
The logic levels on the FPGA host interface (Bank 2) can be selected for compatibility with the host using this jumper. The two most commonly used logic levels (1.8V, 3.3V) can be selected.

Note that the FTDI operates at 3.3V hence, the voltage must be set to 3.3V if the FTDI is used for FPGA programming.

## Power measurement
Power is measured on the board using an INA219B chip. This I2C device can measure the 3.3V applied to the SoM and also teh current flowing intot he SoM. The data can be accessed over the I2C bus on the board either using the QWIIC connector or the FTDI as long as the SW1 settings are proerly selected.

Sample code to measure power using an Arduino is provided [here](./Boards/Artemis/Arduino/power/som_power/som_power.ino)

## Microphone
An I2S microphone is provided on the developer kit. This microphone is set to be the stereo pair for the mic on the SoM. The SoM or other I2S master can provide the I2S clock and word select. The microphones in the developer kit and SoM will work together to provide stereo data.

## Expansion connectors
The devkit provides remote microphone capability on the P5 header where power, ground and the I2S microphone signals are brought out. Note that the SoM has a microphone on this bus already and is set to be device 0. If the external microphone is used, please tie the select line low so that the microphones work together as a stereo pair.

## Miscellaneous functionality
* FPGA reset: a pushbutton is used to manually reset the FPGA and cause it to re-download.
* Prototyping area: Note that the Ground, 3.3V, 1.8V, 1.2V and IO voltages are brought out to specific pins on the proto array for users to develop their applications with. These pins are identified on the silkscreen.
