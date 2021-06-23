# High level description
The Vision directory has a basic test application that allows the user to get images from the board.

An image is captured by sending a character on the UART when the devkit is connected. The captured image is then sent back over the UART at the default baud rate of 460,800 baud. Note that this can be changed by changing the UART_PERIOD parameter in the code.

Further details can be found in the sw directory.

## Simulations
The following simulations can be run using Modelsim installed along with the Radiant toolchain. Change to the sim directory and run the following commands:
- `make TOP=<block>`: Compiles the code
- `make TOP=<block> sim`: Runs the simulation in the shell
- `make TOP=<block> sim_gui`: Runs the simulation in a GUI

Simulations are visual and not self checking, an enhancement for another day!
