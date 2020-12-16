
# Invoke simulations with make TOP=<block name> sim 
TB_SRCS = tb_$(TOP).sv
SRCS = $(TOP).sv

COMMON = ../common/

#pcf_file = ../common/som.pcf
pcf_file = ./upduino.pcf

INCLUDE = -DSIM -g2012 -I$(COMMON) -I./


synth: $(TOP).bin
sim: sim_tb_top

$(TOP).bin: Makefile $(SRCS)
	yosys -p "synth_ice40 -json $(TOP).json -blif $(TOP).blif" $(SRCS)
	nextpnr-ice40 --up5k --package sg48 --json $(TOP).json --pcf $(pcf_file) --asc $(TOP).asc --pcf-allow-unconstrained
	icepack $(TOP).asc $(TOP).bin

prog: #for sram
	iceprog.exe -S $(TOP).bin

flash:
	iceprog.exe $(TOP).bin

my_pll.v: Makefile
	icepll -i 48 -o 24 -m -f my_pll.v

#### Simulations
sim_tb_top: tb_top
	vvp -N tb | tee tb.log

tb_top: $(SRCS)
	iverilog $(INCLUDE) -s tb -o tb $(TB_SRCS) $(shell yosys-config --datdir/ice40/cells_sim.v)

#### Clean
clean:
	rm -rf abc.history *.blif *.asc *.bin *.json *.vcd *.log tb my_pll.v
