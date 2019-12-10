# Power measurements on the SoM v3 with devkit
Power measured by the INA219 sensor on the devkit.

## Data
| Condition | Power | Description |
| :---: | ---: | --- |
| No SoM | 0mW | No SoM inserted|
| Blank Flash | 14mW | FPGA not programmed |
| FPGA reset | 10mW | FPGA held in reset using push button |
| Zero design | 9.5mW | Minimal design with no blinking LED's |
| Red LED on | 59.22mW |  Zero design with red LED on |
| Green LED on | 39.2mW |  Zero design with Green LED on |
| Blue LED on | 37.1 mW |  Zero design with Blue LED on |
| All LED's on | 108mW | All LED's on full blast |
| IR LED on | 106.4mW | IR LED on full blast, note that the Pixart imager must be kept in reset for this case since the drive is supposed to come from it! Without pre-configuring the Pixart imager first, we end up backdriving the device leading to higher power consumption. |
| GPIO LED | 57.8mW | Single GPIO LED turned on|
| 48MHz osc  | 11-14mW | Added 48MHz osc |
| PLL@20MHz  |  | Added PLL with a 20MHz oscillator output |