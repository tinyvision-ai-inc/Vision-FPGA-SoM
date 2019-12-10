# Allow local changes if any
-include ./local-settings.mk

#Seed for nextpnr. Change this to another random value if you happen to run 
#into a situation that mis-synths or takes extremely long to synth the SoC.
SEED = 1020

# Sources

# Audio
SRC += $(addprefix audio/, \
)

# Common
SRC += $(addprefix common/, \
)

# IMU
SRC += $(addprefix audio/, \
)

# Misc
SRC += $(addprefix misc/, \
	delay.v \
	fifo_sync_ram.v \
	fifo_sync_shift.v \
	glitch_filter.v \
	ram_sdp.v \
)

# Processor
SRC += \
	picorv32/picorv32.v \
	pcpi/pcpi_fastmul_dsp.v \
	$(NULL)

# qSPI Memory
SRC += $(addprefix qspi_mem/, \
)

# UART
SRC += $(addprefix uart/, \
	uart_irda_rx.v \
	uart_irda_tx.v \
	uart_rx.v \
	uart_tx.v \
	uart_wb.v \
)

# Vision
SRC += $(addprefix vision/, \
)



EXTRA_DEPEND=
BRAMFILE=rom.hex
CONSTR=$(word $(SOM_VERSION), som_v1.lpf som_v2.lpf som_v3.lpf)

ifeq ($(OS),Windows_NT)
EXE:=.exe
endif
ifneq ("$(WSL_DISTRO_NAME)","")
	# if using Windows Subsystem for Linux, and yosys not found, try adding .exe
	ifeq (, $(shell which yosys))
		EXE:=.exe
 	endif
endif

#Image read mode: qspi, dual-spi, fast-read
#FLASH_MODE=qspi
#Image read freq, in MHz: 2.4, 4.8, 9.7, 19.4, 38.8, 62.0
#FLASH_FREQ=38.8 #MHz


all: $(PROJ).svf

$(PROJ).json $(PROJ).blif: $(SRC) $(SRC_SYNTH) $(EXTRA_DEPEND)
	yosys$(EXE) -e ".*(assigned|implicitly).*" -l yosys.log \
		-p "read -sv $(SRC) $(SRC_SYNTH); \
	synth -abc9 -top fpga_top -json $(PROJ).json -blif $(PROJ).blif"

%_out_synth.config: %.json clock-constraints.py
	nextpnr$(EXE) --json $< --lpf $(CONSTR) --textcfg $@ --5k --speed 8 \
			--pre-pack clock-constrainsts.py -l nextpnr.log --freq 48 --seed $(SEED)
#	nextpnr$(EXE) --json $< --lpf $(CONSTR) --textcfg $@ --45k --package CABGA381 --speed 8 \
#			--pre-pack clock-constrainsts.py -l nextpnr.log --freq 48 --seed $(SEED)

# Initialize BRAM if thats possible with code
#%_out.config: %_out_synth.config rom.hex
#	ecpbram -i $< -o $@ -f booga.hex -t rom.hex

# Create the final binary file
#%.bit: %_out.config
#	ecppack$(EXE) --spimode $(FLASH_MODE) --freq $(FLASH_FREQ) --input $< --bit $@

clean:
	rm -f $(PROJ).json $(PROJ).svf $(PROJ).bit $(PROJ)_out.config
	rm -rf verilator-build
	$(MAKE) -C boot clean
	rm -f rom.hex




.PHONY: prog clean
.PRECIOUS: $(PROJ).json $(PROJ)_out_synth.config $(PROJ)_out.config

