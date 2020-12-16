`timescale 1ns/1ps
`default_nettype none

`include "wb_spi_slave.sv"

module tb;
    parameter logic debug = 0; 
  
    logic                 clk = 1'b0;                  // To dut of wb_spi_slave.v
    logic               rst, rst_dut;                  // To dut of wb_spi_slave.v
    
    logic               i_wb_ack;               // To dut of wb_spi_slave.v
    logic [31:0]         i_wb_dat;               // To dut of wb_spi_slave.v
    logic [23:0]        o_wb_adr;               // From dut of wb_spi_slave.v
    logic               o_wb_cyc;               // From dut of wb_spi_slave.v
    logic [31:0]         o_wb_dat;               // From dut of wb_spi_slave.v
    logic               o_wb_stb;               // From dut of wb_spi_slave.v
    logic               o_wb_we;                // From dut of wb_spi_slave.v
    
    logic               spi_mosi;                   // To dut of wb_spi_slave.v
    logic               spi_miso;               // From dut of wb_spi_slave.v
    logic               spi_clk;                    // To dut of wb_spi_slave.v
    logic               spi_ss;                    // To dut of wb_spi_slave.v

    logic tx_overrun;
    logic spi_busy;
    logic [7:0] spi_id, spi_status;
    logic spi_start;
    logic reset_out;

    logic [31:0]        recvWord;
    int                 i;

    `include "tb_spi_helpers.sv"
    
    assign #100 rst_dut = reset_out | rst;
    
    wb_spi_slave
        dut
        (
            .rst( rst_dut ),
            .sck                               (spi_clk),
            .ssn                               (spi_ss),
            .mosi                              (spi_mosi),
            .miso                              (spi_miso),
            .*
        );
    // Implement a memory for testing
    logic [31:0]         mem[10000:0];
    logic i_ack;
    assign i_wb_ack = i_ack & o_wb_stb;
    
    always @(posedge clk) begin
        i_ack <= o_wb_stb & o_wb_cyc;

        if (o_wb_cyc & o_wb_stb) begin
            if (o_wb_we) begin
                mem[o_wb_adr] <= o_wb_dat;
                if (i_wb_ack)
                    $display("%t:: WB Write: addr: 0x%x, data: 0x%x", $time, o_wb_adr, o_wb_dat);
            end else begin
                i_wb_dat <= mem[o_wb_adr];
                if (i_wb_ack)
                    $display("%t:: WB Read: addr: 0x%x, data: 0x%x", $time, o_wb_adr, mem[o_wb_adr]);
            end
        end
        
    end

    always @(posedge reset_out)
        $display("%t::: Got a reset!", $time);
        
    // Stimulus
    always #10 clk = ~clk;
    logic [23:0] exp_addr;
    logic [31:0] temp, temp1, temp2;

    initial begin
        $display("Starting simulation");
        $dumpfile("tb_wb_spi_slave.vcd");
        $dumpvars;
        // Log the memories
        //for (int i=0; i<2; i++) $dumpvars(0, dut.tx_buffer[i]);
        
        spi_ss = '1;
        spi_mosi = '0;
        spi_clk = '0;
        spi_id = 'hde;
        spi_status = 'had;
        
        #100 rst = '1;
        #100 rst = '0;
        #100;
        
        spiWriteReg('hdeadbabe, 'hfeedf00d);
        # 1000;
            // Burst write
        spiWriteStart('hff);
        for (int i=0; i<10; i++)
            spiWriteWord('hdeadbeef+i);
        spiWriteEnd();

        #1000;
    
            // Write then read
        spiWriteReg('h7fe, 'hfeedf00d);
        spiReadReg('h7fe, temp);
        $display("Read back: 0x%x", temp);

                
        // Many write then many read
        for (int i=0; i<4; i++)
            spiWriteReg('h100+i, 'h12345678+4*i);
        #5000;
        for (int i=0; i<4; i++) begin
            spiReadReg('h100+i, temp);
            $display("Read back: 0x%x", temp);
        end
        
        // Streaming write then Read
        spiWriteStart('hfe);
        for (int i=0; i<10; i++)
            spiWriteWord('h12345678+i);
        spiWriteEnd();
        
        #1000;
        spiReadStart('hfe); // Address
        for (int i=0; i<4; i++) begin
            spiReadWord(temp);
            $display("Read back: 0x%x", temp);
        end
        spiReadEnd();

        // Get SPI ID
        for (int i=0; i<10; i++) begin
            spiGetStatus(temp);
            $display("Status: 0x%x", temp);
            spi_id = spi_id + 'd1;
            spi_status = spi_status - 'd1;
        end
        
        // Reset the chip
        $display("Expect a reset now");
        spiSendReset();
        
        /*
        spiGetID(temp1, temp2);
        `expect_h("SPI ID: ", spi_id, temp1);
        `expect_h("SPI Status: ", spi_status, temp2);

        exp_addr = $random();
        $display("Starting streaming write from address: 0x%x", exp_addr);
        spiWriteStart(exp_addr);
        for (int i=0; i<16; i++) begin
          temp = $random();
        	spiWriteWord(temp);
        	`expect_h("SPI_write_addr: ", exp_addr, address);
        	`expect_h("SPI_write_data: ", temp, rx_data);
        	exp_addr++;
        end
        spiWriteEnd();

        exp_addr = $random();
        $display("Starting streaming write from address: 0x%x", exp_addr);
        spiWriteStart(exp_addr);
        for (int i=0; i<16; i++) begin
          temp = $random();
        	spiWriteNext(temp);
        	`expect_h("SPI_write_addr: ", exp_addr, address);
        	`expect_h("SPI_write_data: ", temp, rx_data);
        	exp_addr++;
        end
        spiWriteEnd();
        
        #100;
        
        spiReadStart(15'h10);
        for (int i=0; i<16; i++) begin
            spiReadNext(recvWord);
            `expect_h("SPI read: ", i, recvWord);
        end
        spiReadEnd();
         */
        
        #10000;
        $display("Finishing simulation");
        $finish;
        
    end
    
    
endmodule // tb_spi_slave
// Local Variables:
// verilog-library-flags:("-y ../src")
// End:
