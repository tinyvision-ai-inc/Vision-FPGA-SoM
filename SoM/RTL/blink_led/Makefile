SRCS = 
SRCS += ../common/ice40_resetn.v
SRCS += ../common/spi_slave_core.sv
SRCS += ../common/wb_spi_slave.sv
SRCS += ../common/uart.v
SRCS += my_pll.v
SRCS += $(design).sv

COMMON = ../common/

pcf_file = ../common/som.pcf

synth: $(design).bin
sim: sim_tb_top

$(design).bin: Makefile $(SRCS)
	yosys -p "synth_ice40 -json $(design).json -blif $(design).blif" $(SRCS)
	nextpnr-ice40 --up5k --package sg48 --json $(design).json --pcf $(pcf_file) --asc $(design).asc
	icepack $(design).asc $(design).bin

#	nextpnr-ice40 --up5k --package sg48 --json $(design).json --pcf $(pcf_file) --asc $(design).asc --pcf-allow-unconstrained

prog_sram: #for sram
	iceprog.exe -S $(design).bin

prog_flash:
	iceprog.exe $(design).bin

my_pll.v: Makefile
	icepll -i 48 -o 24 -m -f my_pll.v

#### Simulations
sim_tb_top: tb_top
	vvp -N tb | tee tb.log

tb_top: $(SRCS)
	iverilog -g2005-sv -DSIM -s tb_top -o tb tb_top.sv $(SRCS) $(shell yosys-config --datdir/ice40/cells_sim.v) -I $(COMMON)

#### Clean
clean:
	rm -rf *.blif *.asc *.bin my_pll.v
