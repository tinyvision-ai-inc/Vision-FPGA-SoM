`timescale 1ns/1ps

`include "spi_shifter.sv"

module tb;
    parameter logic debug = 1; 
  
    logic                 clk = 1'b0;                  // To dut of wb_spi_slave.v
    logic               rst;                  // To dut of wb_spi_slave.v
    
    logic               spi_mosi;                   // To dut of wb_spi_slave.v
    logic               spi_miso;               // From dut of wb_spi_slave.v
    logic               spi_clk;                    // To dut of wb_spi_slave.v
    logic               spi_ss;                    // To dut of wb_spi_slave.v

        // Rx data
        logic [7:0] rx_dat;
        logic rx_vld;

        // Tx data
        logic tx_vld, tx_rdy;
        logic [7:0] tx_dat;

        // Status
        logic tx_overrun; // Asserts when tx_vld comes along when the Tx buffer overruns
        logic busy;
        logic start;
        logic tx_byte_done;
    
    int                 i;

`include "tb_spi_helpers.sv"
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 24;
    
  spi_shifter
  	dut
    (
     .sck                               (spi_clk),
     .ssn                               (spi_ss),
     .mosi                              (spi_mosi),
     .miso                              (spi_miso),
     .*
     );

    // MOSI checker
    always @(posedge clk) begin
    	if (rx_vld && debug) begin
    		$display("%t:: MOSI data: 0x%x", $time, rx_dat);  
    	end
    end
    
    // Read stimulus
    always @(posedge clk or rst) begin
    	if (rst) begin
    		tx_dat <= '0;
    	end else begin
    		if (rx_vld)
    			tx_dat <= tx_dat + 'd1;
          tx_vld <= rx_vld;
    	end
    end

    // MISO checker
    logic [7:0]        recvWord;
    always @(posedge spi_clk) begin
        if (~spi_ss) begin
            recvWord <= {recvWord[6:0], spi_mosi};
        end else
            recvWord <= 'X;
    end
    
    always @(posedge rx_vld)
        $display("%t:: MISO data: 0x%x", $time, recvWord);
    
    // Stimulus
    always #10 clk = ~clk;
    logic [7:0] temp, temp1, temp2;

    initial begin
        $display("Starting simulation");
        $dumpfile("tb_spi_shifter.vcd");
        $dumpvars;
        // Log the memories
        //for (int i=0; i<2; i++) $dumpvars(0, dut.tx_buffer[i]);
        
        spi_ss = '1;
        spi_mosi = '0;
        spi_clk = '0;
        
        #100 rst = '1;
        #100 rst = '0;
        #100;
        
        if (debug) $display("%t Writing a bunch of incrementing bytes", $time);
        spiTxStart();
        for (int i='haa; i<'haf; i++)
            spiSendByte(i);
        spiTxStop();
        
        #10000;
        $display("Finishing simulation");
        $finish;
        
    end
    
    
endmodule // tb_spi_slave
// Local Variables:
// verilog-library-flags:("-y ../src")
// End:
