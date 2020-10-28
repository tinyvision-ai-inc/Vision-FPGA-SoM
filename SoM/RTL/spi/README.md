# SPI Slave to Wishbone Master bridge
This block forms the main core interface to the FPGA since all data enters/exits through the SPI. The design follows a simple byte oriented protocol that allows direct Wishbone read/write. Since the FPGA is a SPI slave, a side band interrupt request line is also provided and integrated into the protocol for fast interrupt service.

A SPI packet consists of the first byte containing a command followed by an optional address and either a dummy byte or write data. A dummy byte is required to do a read which takes some time in the FPGA.

The following commands are supported, roughly based on typical Flash commands:
- Read ID ( '0x90' ): A 1 byte FPGA ID will be read back immediately following this command with no dummy byte.
- Read Status ( '0x05' ): A 4 (TBD) byte Status will be read back immediately following this command with no dummy byte. A continued read of the status will show any changes in status in real time. Status words typically include an interrupt request bit.
- Write Command ( '0x01' ): This can be used to clear any sticky bits in the status register such as an interrupt request.
- Read ( '0x0B' ): A 32 bit address followed by a dummy byte then a stream of reads will cause Wishbone read's to happen every 32 bits. This scheme allows for indefinite length Read capability.
- Write ( '0x02' ): A 32 bit address and then a stream of 32 bit data wordxs follows this command. A Wishbone write goes out at every 32 bit boundary. This scheme allows for indefinite length write capability.
- Soft Reset FPGA: The FPGA can be soft reset using a pair of commands that must be sent one after the other with no other intervening commands. This prevent inadvertent FPGA resets.
  - Arm Reset ( '0x66' )
  - Fire Reset ( '0x99' )

## Interrupt Service
Interrupts are supported using a dedicated interrupt line. THis line goes active as soon as the interrupt is requested at the core interface. A STATUS read will show the source of the interrupt. Interrupts are captured on the rising edge of the core clock and can be cleared by writing the respective bit with a '1' in the command word.

## Future work
- Quad SPI support