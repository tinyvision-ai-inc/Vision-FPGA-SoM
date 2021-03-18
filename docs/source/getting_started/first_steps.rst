First Steps
====

1. When you receive your Vision SoM, make sure it works properly before you proceed further! A simple way to do this is to plug it into a standard micro USB cable attached to a standard USB power supply such as a computer or a phone charger. 
  - You should see the 3 color LED cycle through Red-Green-Blue.
  - If you have the developer kit, the SoM will cycle all LED's on the board in a binary incrementing pattern. 
  - Also, if you are on a computer, you should see a new USB device called the "Vision FPGA SoM" show up in your list of USB devices. 
  - The board shows up as a pair of serial ports (COMxx on windows and /dev/ttyUSB0, /dev/ttyUSB1 on Linux and Mac). If this doesnt happen, please copy the SoM/Setup/udev-rules/* to the /etc/udev/rules.d location as root.
2. Download the toolchain of choice: Lattice Radiant and/or icestorm/apio.
3. Download the git repository for the Vision SoM and go the RTL/blink_led directory.
4. Test your toolchain installation:
  - apio/icestorm toolchain:
    - Type in "make design=blink_led" and this should create a bin file to be uploaded to the SoM. 
    - For Windows, you will need to install Zadig and go through the process of switching the SoM devkit to the libusbk driver so that iceprog can see this. An alternative is to install the iceprog tool for windows and use that for programming instead of the icestorm version, some instructions are on [this forum](https://forum.1bitsquared.com/t/official-win10-instructions-missing/73).
    - Program the SoM and ensure the DONE LED lights up and the 3 color LED starts cycling through its sequence.
5. Fiddle with the code!
