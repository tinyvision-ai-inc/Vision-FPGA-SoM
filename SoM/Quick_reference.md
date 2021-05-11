# Vision FPGA SoM Quick Reference Guide

This guide is intended to be used to:
* Figure out whether the Developer kit/SoM is functional
* Get back to the original factory shipped configuration

All devices are shipped fully tested and with a demo program. We will run the factory test program that will ensure that you verify that the devices you received work properly. If they do not pass this test, please contact: sales at tinyvision dot ai.

## Unboxing
- Carefully unpackage the SoM and developer kit. Note that the devices are ESD sensitive and appropriate care must be taken to prevent ESD damage to the devices.
- Mount the SoM on the developer kit taking care to align the connectors. There is a silkscreen guide that will help you to align the SoM. Inserting the SoM in reverse will cause damage to the device and is not covered under warranty! Please be careful!
- Connect a Micro USB cable to the dev kit and connect it to a computer.
- You should see the DS1 green LED light up indicating that the SoM is programmed. You should also see the green LED's and the small tri-color LED on the SoM cycle through 3 colors. This is the factory default setting which can be used to ensure that you have a functional device.
- Install python, OpenCV and NumPy on your machine
- Use the read_himax.py file in the repo at RTL/vision/sw to obtain an image from the image sensor. This is a 160x120 pixel grayscale image. Note that this is a limitation of the python script rather than that of the setup as the Himax sensor has a bayer color output.


> ***Note:***
>* If you do not have a developer kit, the same process can be used except that you need to provide a programmer that can program flash such as an [FTDI cable](http://www.latticesemi.com/~/media/BCA4EE8C9F8F49C4AC4A2D74737514B3.ashx) or a processor that has a SPI master port and a couple of GPIO's to spare.

## Restoring the developer kit
- Download the icestorm or Radiant toolchain
- Turn off all switches in the switch bank except for SW5 and SW8.
- Insert a jumper to enable programming
- Download the factor FPGA image from [here](SoM\RTL\vision\synth\blink_impl_1.bin)
- Program the image using icestorm/Radiant:
 ` icestorm <factory FPGA file>`
- Remove the programming jumper and push the reset button

You should now be back to the factory shipped configuration.
