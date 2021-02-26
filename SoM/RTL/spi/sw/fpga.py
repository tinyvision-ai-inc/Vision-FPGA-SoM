import sys
import time
from os import environ
from binascii import hexlify
from typing import Iterable, Optional, Tuple, Union
import numpy as np
from pyftdi.misc import pretty_size
from pyftdi.spi import SpiController, SpiPort

#  ftdi://ftdi:232h:2:11/1   (UPduino v3.0)
ftdi_url = environ.get('FTDI_DEVICE', 'ftdi://::/1')
print('Using FTDI device %s' % ftdi_url)
ctrl = SpiController(cs_count=2)
ctrl.configure(ftdi_url)
spi_freq = 1e6
spi1 = ctrl.get_port(cs=1, freq=spi_freq, mode=0)
spi0 = ctrl.get_port(cs=0, freq=spi_freq, mode=0)
#gpio = ctrl.get_gpio()
#gpio.set_direction(0x80, 0x80)

# Reset the FPGA and get the Flash ID
#gpio.write(0x00)
#time.sleep(0.1)
#spi1.exchange([0xAB], 1) # Wake up the flash
#jedec_id = spi1.exchange([0x9f,], 3)
#print(jedec_id)
#spi1.exchange([0xB9], 1) # Put the flash to sleep

# Release from reset
#gpio.write(0x80)
#gpio.set_direction(0x0, 0x0)

#time.sleep(0.1) # Let the FPGA reconfigure
#while(True):



class FPGA:
    SPI_READ_ID = 0x90
    SPI_READ_STATUS = np.uint8(0x05)
    SPI_WRITE_STATUS = 0x01
    SPI_READ 				= np.uint8(0x0B)
    SPI_WRITE 			    = np.uint8(0x02)
    SPI_POWERDOWN 			= 0xB9
    SPI_EXIT_POWERDOWN 	    = 0xAB
    SPI_ARM_RESET			= np.uint8(0x66)
    SPI_FIRE_RESET			= np.uint8(0x99)

    def __init__ (self, spi):
        self.spi = spi
        # Setup a word format
        self.dt = np.dtype(np.uint32)
        self.dt = self.dt.newbyteorder('>')

    def getID (self):
        buf = bytearray()
        length = 2
        buf.extend(self.SPI_READ_STATUS)
        id = self.spi.exchange(buf, 2, duplex=True)
        return id[1]
    
    def read (self, addr, num_words):
        buf=bytearray()
        buf.extend(self.SPI_READ)
        buf.extend(addr.to_bytes(3, 'big'))
        buf.extend(np.uint8(0x0))
        length = 4*num_words
        dat = self.spi.exchange(buf, length, duplex=False)
        #dat = np.frombuffer(dat, dtype=self.dt)
        return dat
        
    def write (self, addr, data):
        buf=bytearray()
        buf.extend(self.SPI_WRITE)
        buf.extend(addr.to_bytes(3, 'big'))
        buf.extend(data.to_bytes(4, 'big'))
        length = 4 #*len(data)
        ret = self.spi.exchange(buf, length, duplex=False)
    
    def reset(self):
        buf=bytearray()
        buf.extend(self.SPI_ARM_RESET)
        ret = self.spi.exchange(buf, 1, duplex=False)
        buf=bytearray()
        buf.extend(self.SPI_FIRE_RESET)
        ret = self.spi.exchange(buf, 1, duplex=False)


if __name__ == "__main__":
    f = FPGA(spi0)
    print(f.getID())
    #f.reset()

    #f.write(0x100, 0xdeadbabe)
    print("Writing...")
    for i in range(8):
        f.write(0x0, i)
        time.sleep(0.1)
    print("Reading...")
    dat = f.read(0, 2)
    print("0x%x"%dat[0])
