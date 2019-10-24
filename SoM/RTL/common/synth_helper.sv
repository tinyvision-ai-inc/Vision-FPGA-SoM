/****************************************************************************
 * synth_helper.sv
 ****************************************************************************/

/**
 * Package: synth_helper
 * 
 * TODO: Add package documentation
 */

`ifdef __YOSYS__
	`define UP_HSOSC SB_HFOSC
	`define UP_RGB SB_RGBA_DRV
`else
	`define UP_HSOSC HSOSC
	`define UP_RGB RGB
`endif

