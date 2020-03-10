# Vision FPGA SoM Quick Reference Guide

This guide is intended to be used to:
* Figure out whether the Developer kit/SoM is functional
* Get back to the original factory shipped configuration

All devices are shipped fully tested and with a demo program. We will run the factory test program that will ensure that you verify that the devices you received work properly. If they do not pass this test, please contact: sales at tinyvision dot ai.

## Unboxing
- Carefully unpackage the SoM and developer kit. Note that the devices are ESD sensitive and appropriate care must be taken to prevent ESD damage to the devices.
- Mount the SoM on the developer kit taking care to align the connectors. There is a silkscreen guide that will help you to align the SoM. Inserting the SoM in reverse will cause damage to the device and is not covered under warranty! Please be careful!
- Connect a Micro USB cable to the dev kit and connect it to a computer.
- You should see the DS1 green LED light up indicating that the SoM is programmed. You should also see the DS2 green LED and the small tri-color LED on the SoM blink at about 2Hz. This indicates that the image sensor is capturing images.
- We will now check whether the device can detect objects. The SoM flash is programmed to detect human being upper torso. With the developer kit powered up,  rotate the kit so that the tinyVision logos are inverted and point the image sensor at a human being. You should see the tri-color LED occasionally turn bright red indicating that it has detected a human being.

> ***Note:***
>* 

## Restoring the developer kit
- Download the icestorm or Radiant toolchain
- Turn off all switches in the switch bank except for SW5 and SW8.
- Insert a jumper to enable programming
- Download the factor FPGA image from [here]()
- Program the image using icestorm/Radiant:
 ` icestorm <factory FPGA file>`
- Remove the programming jumper and push the reset button

You should now be back to the factory shipped configuration.
