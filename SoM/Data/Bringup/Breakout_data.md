# Vision SoM Feather Breakout bringup

## Voltages
| Node 	| Expected| Measured |
| :---: | ---: 			| --- |
| VUSB 	| 5V+/-10% 		| 5.078V|
| VBATT (No battery)| 3.7V-4.2V 		| 4.289V|
| VBATT (Only battery) | 3.7V-4.2V 		| 4.097V|
| VBATT (USB+Battery)| 3.7V-4.2V 		| 4.134V|
| 3.3V 	| 3.3V+/- 10% 	| 3.297V|
| 1.8V 	| 1.8V+/- 10% 	| 1.800V|
| 1.2V 	| 1.2V+/- 10% 	| 1.203V|

## Miscellaneous functions
- Charge LED comes on when batery is plugged in along with USB. Battery voltage seen to rise slowly. Charge LED doesnt come on when there is no battery.
- Pushing the reset switch resets the FPGA
- DONE LED comes on when the FPGA is successfully programmed

## Feather
Connect to an ESP32 Feather. Check for whether power and charge functionality work with USB and battery. Also check if the reset button resets the Feather.
Result: USB on either Feather or the SoM breakout powers the stack. Battery charges when USB is in either ESP32 or SoM feather. Reset button on the SoM feather resets the ESP32.

## Untested
- QWIIC connection, I2C