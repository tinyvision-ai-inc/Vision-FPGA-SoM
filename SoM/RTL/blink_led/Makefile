filename = blink_led
SRCS = 
SRCS += my_pll.v
SRCS += ../common/ice40_resetn.v
SRCS += ../common/spi_slave_core.sv
SRCS += ../common/wb_spi_slave.sv
#SRCS += ../common/uart.v
SRCS += $(filename).sv


pcf_file = ../common/som.pcf

synth: $(filename).bin

$(filename).bin: Makefile $(SRCS)
	yosys -p "synth_ice40 -json $(filename).json -blif $(filename).blif" $(SRCS)
	nextpnr-ice40 --up5k --package sg48 --json $(filename).json --pcf $(pcf_file) --asc $(filename).asc --pcf-allow-unconstrained
	icepack $(filename).asc $(filename).bin

prog: #for sram
	iceprog.exe -S $(filename).bin

prog_flash:
	iceprog.exe $(filename).bin

#my_pll.v: Makefile
#	icepll -i 48 -o 24 -m -f my_pll.v

clean:
	rm -rf $(filename).blif $(filename).asc $(filename).bin
