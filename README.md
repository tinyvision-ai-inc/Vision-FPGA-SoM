![tinyVision.ai Inc.](./resources/images/TVAI-FINAL-01-tight.png)
# Vision FPGA SoM
## Low Power Vision, Audio &amp; motion sensing/processing FPGA System on Module

The FPGA SoM enables IoT devices to see, hear and sense motion. This is a tightly integrated platform consisting of a low power image sensor, IMU and microphone coupled to a local computing device (Lattice ultra low power ICE40 5K FPGA). The SoM is designed to be dropped into end products as-is with no hardware modifications, significantly shortening the time to market of the end product.

![Diagram](./resources/images/SoM_block_diagram.png)
The module integrates the following capabilities:

- Local processing using the Lattice ICE40 Ultra-low-power FPGA, 5K LUT, 1Mb RAM, 8 MAC units
- Image sensor options
  - Integrated qVGA monochrome global shutter imager (Pixart PAJ6100U6)
  - Connector for color/monochrome rolling shutter imager (Himax HMB010)
  - Connector for OV7670 flex
- One MEMS I2S/TDM microphone, expandable to up to 8 microphones
- LED's
  - Tri-colour LED
  - IR LED for low light illumination with exposure synchronization
- 6 axis Gyro/accelerometer (Invensense IMU 60289)
- Memory
  - 8Mb qSPI Flash for bitstream/code storage
  - 64Mb qSPI SRAM for data
- Four GPIO, programmable IO voltage
- 4 wire SPI host interface with programmable IO voltage
- 2 power options:
  - Single 3.3V operation, can supply 1.8V and 1.2V @100mA (max) to external devices using onboard LDO
  - External 3.3V, 1.8V, 1.2V for lower power operation
- SW support	using the Lattice [SensAI](https://www.latticesemi.com/sensAI) toolchain which supports Tensorflow/Caffe/Keras for model development, toolchain for quantization and mapping to Neural Network engines.

For more details, please see the [Datasheet](./Sensor_FPGA_SoM_data_sheet_2.0.pdf) and [SoM specification](SoM/README.md).

Modules and developer kits are available at the tinyVision.ai [store](https://tinyvision.ai/collections/frontpage).
