# Vision SoM data

Setup: SoM mounted on a developer kit board. Yosys environment.

## Voltages
| Node 	| Expected| Measured |
| :---: | ---: 			| --- |
| 3.3V 	| 3.3V+/- 10% 	| 3.301V|
| 1.8V 	| 1.8V+/- 10% 	| 1.801V|
| 1.2V 	| 1.2V+/- 10% 	| 1.203V|

## FPGA Programming
1. CRAM Programming: SW1, SW8: ON, all others off. Command line: "iceprog -S <design.bin>"
2. Flash Programming: SW1, SW6, SW7: ON, all others off. Command line: "iceprog <design.bin>"

Passed both flash and SRAM programming. Flash ID reads back as 0xEF6013.

## LED's
Procedure: Turn on each of the LED's individually.

| LED 	| Status|
| :---: | ---:|
| RED 	| Pass|
| GREEN 	| Pass|
| BLUE 	| Pass|
| IR_LED | Fail, IR LED's are on backwards! Passes on older SoM's |

## Microphones
Setup: Apply 3MHz clock and 3MHz/64 framing (Word Select) to the microphones.
Result: See data coming in on both high and low periods. Test with the breakout board as well where the mic only outputs during the high period of the word select as expected.

## I2C
Scan the I2C bus and report back any devices.
Result: Scan finds 2 devices on the breakout board: 0x69 (IMU) and 0x24 (HM01B0). On scanning the developer kit, we get an additional device at 0x40 (INA219B).

## Power Measurement
Load the INA219 code into the ESP32 and get shunt voltage measurements. Voltage across the 1 Ohm current sense resistor looks reasonable and comparable to whats measured with a DMM (13mV).