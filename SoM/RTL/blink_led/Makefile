filename = blink_led
SRCS = $(filename).sv
SRCS += ../common/ice40_resetn.v

pcf_file = ../common/som.pcf

build:
	yosys -p "synth_ice40 -json $(filename).json -blif $(filename).blif" $(SRCS)
	arachne-pnr -d up5k -P sg48 -p $(pcf_file) $(filename).blif -o $(filename).asc
	#nextpnr-ice40 --up5k --json $(filename).json --pcf $(pcf_file) --asc $(filename).asc
	icepack $(filename).asc $(filename).bin

prog: #for sram
	iceprog -S $(filename).bin

prog_flash:
	iceprog $(filename).bin

clean:
	rm -rf $(filename).blif $(filename).asc $(filename).bin