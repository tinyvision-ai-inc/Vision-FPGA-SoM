SHELL = bash
COMMON = .

tb_spi: tb_wb_spi_slave
	vvp -N tb | tee tb.log

tb_wb_spi_slave: tb_wb_spi_slave.sv
	iverilog -g2005-sv -DSIM -s tb_wb_spi_slave -o tb tb_wb_spi_slave.sv wb_spi_slave.sv spi_slave_core.sv -I$(COMMON) $(shell yosys-config --datdir/ice40/cells_sim.v)

clean:
	rm -f tb tb_spi_slave.vcd tb.log

.PHONY: spi spi_tb clean