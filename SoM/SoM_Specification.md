# SoM Specification

The Sensor module uses a Lattice iCE40UP5K QFN device as its core programmable device. This part is connected to and supported by various other components on the board as shown in the figure below.

The board has an I2S microphone, Invensense IMU and an installed low power low-cost monochrome camera (PAJ6100U6) from Pixart Inc. In addition, provision is made for a Himax HM01B0 low power camera and also an OV7670 Omnivision flex connector. These options allow for various applications. An IR LED is connected to the Pixart sensor to allow for illumination of the scene with the LED synchronized to the shutter.
The FPGA is connected to 4Mb of qSPI capable NOR flash for booting as well as storage of other code. The qSPI bus is shared with a 64Mb qSPI SRAM. The SRAMcan be used for buffering sensor or intermediate data such as video frames and/or audio streams. Selection between the flash and SRAM is done using dedicated active-low slave select lines.

## Electrical interface
### Pinout & Signal description
All signal levels on the interface are 3.3V CMOS unless otherwise noted. A 0.5mm pitch connector is used to connect to the host board. The mate to the connector has the MPN: DF23C-30DP-0.5V(92).
The board edge castellations share the same pinout and can be used to reduce overall system cost by directly soldering the module to the host board. Note that in this configuration, the module will not have the microphone installed as it is bottom ported. The following table shows the pinout of the connector.

#### Host connector and Castellation pinout

| Pin number | Signal name | Description |
| :---: | ---: | --- |
|1, 2, 29, 30 | GND | Ground |
|3 | VDD33 | 3.3V supply |
|4 | VDD12 | 1.2V power |
|5 | LDO_EN | Enable internal LDO’s, pulled up to VDD33 with 10K resistor |
|6 | PIX_RESET_N | Assert low to reset the Pixart imager |
|7 | SCL | I2C master SCL |
|8 | NC | No connect |
|9 | SDA |I2C master SCL |
|10 |NC | No connect |
|11 |MIC_CLK |Microphone clock (Output)|
|12 |HOST_MOSI |Host master out, slave in|
|13 |MIC_DOUT |Microphone data (Input)|
|14 |HOST_SSN |Host slave select (Input)|
|15 |MIC_WS |Mic word select (Output)|
|16 |GPIO_2 |GPIO|
|17 |SENSOR_LED |External LED sync (Output)|
|18 |HOST_SCK |Host SPI clock (Input)|
|19 |SPI_SEL |Flash vs. CRAM selection, set high to program flash. (Input)|
|20 |GPIO_1 |GPIO |
|21 |PROG_FLASH |Pull low to select flash programming (Input, pulled high to 1.8V rail with 1K)|
|22 |GPIO_0 |GPIO|
|23 |DONE |FPGA done signal|
|24 |HOST_MISO |Host SPI Master In, Slave Out (Output) |
|25 |RESET_N |FPGA reset, active low, pulled to 1.8V via 1K resistor|
|26 |HOST_INTR |Interrupt pin to host, can be used as GPIO|
|27 |VDD18 | Internal 1.8V rail (Power) |
|28 |VDDIO_2 |Voltage reference for the FPGA Bank 2|

### Image subsystem
The module has an installed Pixart imager (PAJ6100) which is capable of qVGA (320x240), monochrome global shutter with excellent low light performance due to the large pixels (3um). The imager uses SPI for control and an 8-bit parallel data bus with framing signals for the data. This device requires a 6MHz (nominal) clock for its internal operations.
The Himax HMB010 imager is supported by providing a high-density connector with the right pinout. Note that the Himax imager requires multiple voltages for optimal operation which has not been provided in this version of the board.
An Omnivision compatible flex is provided in addition that allows a cheap but higher power camera to be plugged in with a variety of lens options for specific applications.
The Pixart imager can be held in reset to prevent it from interfering in any way with the Himax/Omnivision sensor by tying the PIX_RESET_N line low on the castellation/connector.
The Omnivision and Himax sensors use I2C as the control bus while the Pixart sensor uses SPI. The design overloads the SENSOR_SCK and SENSOR_MOSI for I2C communications. This should allow communication with the IMU to be transparent since the IMU_SSN line can be held inactive in this case.

### Memory subsystem
The module supports a 4Mb qSPI NOR flash (Winbond W25Q040) and a 64Mb qSPI SRAM (AP Memory APS1604M) connected as shown below. The flash is used to boot the FPGA as well as store any other non volatile code. The SRAM can be used to store volatile data such as images, audio buffer etc.

### IMU subsystem
The module supports a 6-axis Invensense IMU connected as shown below. The SENSOR_LED signal is used to synchronize the IMU to the image sensor for specific applications that require this functionality.

### Microphone subsystem
The module has a bottom ported I2S microphone. This microphone allows for expansion to a stereo configuration using an external I2S microphone with the SELECT line tied high. The mic is also capable of TDM operation with up to 8 mics sharing the TDM lines.

### Power
The FPGA requires 1.2V, 2.5V and 3.3V. The 2.5V is derived as a diode drop from the 3.3V supply per the Lattice reference design.
The imager requires 3.3V and 1.8V. The Himax sensor requires other voltages but appears to be capable of operating from other voltages as well.
The LDO’s can be disabled using an external pin (LDO_EN) to allow applications which already have these voltages for higher efficiency.

### FPGA programming
The FPGA can be programmed either from the onboard flash or else, through the external port allowing for applications where the external processor may want to implement this feature. 4 wires are dedicated as a SPI slave interface that the host processor can interface with. This interface is normally intended to be used to communicate with the FPGA.
On asserting the TBD signal, the 4 wire SPI FPGA programming port is MUX’ed on the same pins. Flash vs. CRAM programming is selected by the TBD signal.
The FPGA CRAM or the flash can be programmed. This requires the MISO and MOSI lines to be interchanged which is done by a mux that does double duty as a level translator.


## Mechanical Interface

## Interface API
