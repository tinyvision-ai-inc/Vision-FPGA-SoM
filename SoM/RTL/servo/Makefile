filename = top
SRCS = 
SRCS += ../common/ice40_resetn.v
SRCS += servo.sv
SRCS += $(filename).sv

COMMON = ../common/

pcf_file = ../common/som.pcf

synth: $(filename).bin
sim: sim_tb_top

$(filename).bin: Makefile $(SRCS)
	yosys -p "synth_ice40 -json $(filename).json -blif $(filename).blif" $(SRCS)
	nextpnr-ice40 --up5k --package sg48 --json $(filename).json --pcf $(pcf_file) --asc $(filename).asc --pcf-allow-unconstrained
	icepack $(filename).asc $(filename).bin

prog: #for sram
	iceprog.exe -S $(filename).bin

prog_flash:
	iceprog.exe $(filename).bin

my_pll.v: Makefile
	icepll -i 48 -o 24 -m -f my_pll.v

#### Simulations
sim_tb_top: tb_top
	vvp -N tb | tee tb.log

tb_top: $(SRCS)
	iverilog -g2005-sv -DSIM -s tb_top -o tb $(SRCS) tb_top.sv $(shell yosys-config --datdir/ice40/cells_sim.v) -I $(COMMON)

#### Clean
clean:
	rm -rf abc.history $(filename).blif $(filename).asc $(filename).bin $(filename).json *.vcd *.log tb my_pll.v
