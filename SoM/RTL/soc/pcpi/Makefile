tb:
	iverilog -opcpi_fastmul_dsp_testbench.vvp pcpi_fastmul_dsp_testbench.v pcpi_fastmul_dsp.v ../picorv32/picorv32.v mul_18x18_sim.v
	vvp pcpi_fastmul_dsp_testbench.vvp

clean:
	-rm -rf *.vvp *.vcd

.PHONE: 
	clean