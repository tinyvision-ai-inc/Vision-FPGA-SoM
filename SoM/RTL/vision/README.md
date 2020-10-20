# High level description
The Camera interface block converts 8 bit data from the camera to a 32 bit wishbone master bus. Note that the block has an input called timestamp which can be tied to a free running counter that timestamps the incoming Start of Frame allowing for accurate reconstruction at a later time and also coordination with other sensors such as an IMU on the same platform.

## Simulations
The following simulations can be run:
- `make TOP=camera_if sim`: Runs the simple non-wishbone core simulation
- `make TOP=wb_camera_if sim`: Runs the wishbone simulation

Simulations are visual and not self checking, an enhancement for another day!

## Future work
- Core that can stream camera data over a streaming interface with a valid-ready protocol.
