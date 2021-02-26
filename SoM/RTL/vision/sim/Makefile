

WORKDIR = work

LIBS = ../..
RTL = ../src
TB = ../tb

SIM_SRCS = $(TB)/tb_$(TOP).sv

ASYNC_FIFO = $(LIBS)/async_fifo/src
CDC_UTILS = $(LIBS)/cdc_utils/rtl/verilog
FIFO = $(LIBS)/fifo/rtl/verilog
I2C = $(LIBS)/i2c/bench/verilog
STREAM_UTILS = $(LIBS)/stream_utils/rtl/verilog
STREAM_UTILS_TB = $(LIBS)/stream_utils/bench
WB_BFM = $(LIBS)/wb_bfm/
WB_INTERCON = $(LIBS)/wb_intercon/rtl
WB_STREAMER = $(LIBS)/wb_streamer/rtl/verilog
VLOG_TB_UTILS = $(LIBS)/vlog_tb_utils
WB_COMMON = $(LIBS)/wb_common
COMMON = $(LIBS)/common
UART = $(LIBS)/uart
MISC = $(LIBS)/misc
DPRAM = ../synth/dpram512x8/rtl

SRCH_PATH = -y $(TB) -y $(RTL) -y $(COMMON) -y $(CDC_UTILS) -y $(WB_COMMON) -y $(ASYNC_FIFO) -y $(FIFO) -y $(I2C) -y $(STREAM_UTILS) -y $(STREAM_UTILS_TB) -y $(WB_STREAMER) -y $(WB_BFM) -y $(WB_INTERCON) -y $(VLOG_TB_UTILS) -y $(UART) -y $(MISC) -y $(DPRAM)

VLOG_OPTS = -lint -pedanticerrors -fsmverbose w +libext+.v +libext+.sv $(SRCH_PATH) +incdir+$(WB_COMMON) +incdir+$(COMMON) +incdir+$(TB) +incdir+$(RTL)
VSIM_OPTS = -warning vsim-3009 -t ps

.PHONY: compile sim lib clean

compile: $(WORKDIR) $(SIM_SRCS)
	vlog $(VLOG_OPTS) $(SIM_SRCS)

sim:
	vsim -c $(VSIM_OPTS) -do "run -all; quit" work.tb_$(TOP) -L iCE40UP

sim_gui:
	vsim -gui $(VSIM_OPTS) work.tb_$(TOP) -L iCE40UP

$(WORKDIR):
	vlib work

clean:
	rm -r transcript $(WORKDIR)