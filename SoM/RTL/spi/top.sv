`default_nettype none

`include "wb_spi_slave.sv"
`include "../common/ice40_resetn.v"

module top (
                  
        // SPI lines
        input logic         spi_sck,
        input logic         gpio_23,
        output logic         spi_mosi,
        input logic        spi_miso,
        
        output logic led_red,
        output logic led_blue,
        output logic led_green
        );
    
    
    logic clk, rst_n, rst;
    logic spi_reset_out;
    logic [22:0] counter;

    // Internal oscillator
    SB_HFOSC #(.CLKHF_DIV("0b01")) SB_HFOSC_inst(.CLKHFEN(1'b1), .CLKHFPU(1'b1), .CLKHF(clk) );

    // Reset
    ice40_resetn u_reset_n (.clk(clk), .resetn(rst_n));
    assign rst = ~rst_n; // | spi_reset_out;

    // Wishbone signals
    logic wb_cyc, wb_stb, wb_we, wb_ack;
    logic [23:0] wb_adr;
    logic [31:0] wb_dat_m2s, wb_dat_s2m;
    
    // SPI Slave
    wb_spi_slave u_wb_spi_slave (
        .sck(spi_sck),
        .ssn(gpio_23),
        .mosi(spi_miso),
        .miso(spi_mosi),

            .o_wb_cyc(wb_cyc),
            .o_wb_stb(wb_stb),
            .o_wb_adr(wb_adr),
            .o_wb_dat(wb_dat_m2s),
            .o_wb_we(wb_we),
            .i_wb_ack(wb_ack),
            .i_wb_dat(wb_dat_s2m),
        
            .reset_out(spi_reset_out),
            .spi_id(counter[22:15]),
            .spi_status(counter[15:8]),
            .spi_start(),
            .spi_busy(),
            .tx_overrun(),
    .*);        
    
    // Wishbone peripheral
    logic [31:0] mem[255:0];
    logic [31:0] my_reg;
    logic i_ack;
    assign wb_ack = i_ack & wb_stb;
    
    always @(posedge clk) begin
        i_ack <= wb_stb & wb_cyc;

        if (wb_cyc & wb_stb) begin
            if (wb_we) begin
                if (wb_adr == 'h0)
                    my_reg <= wb_dat_m2s;
                else
                    mem[wb_adr[7:0]] <= wb_dat_m2s;
            end else begin
                if (wb_adr == 'h0)
                    wb_dat_s2m <= my_reg;
                else
                    wb_dat_s2m <= mem[wb_adr[7:0]];
            end
        end
        
    end

    // Drive some LED's for fun!
    logic toggle;
    
    always @(posedge clk) begin
        counter <= counter + 'd1;
    end
    assign toggle = counter[22];
   
    logic       duty_cycle;
    assign duty_cycle = ~& counter[3:0];
   
    SB_RGBA_DRV u_led_driver(
            .CURREN(1'b1), 
            .RGBLEDEN(1'b1),
            .RGB0PWM(my_reg[0] & toggle), 
            .RGB1PWM(my_reg[1] & toggle), 
            .RGB2PWM(my_reg[2] & toggle), 
            .RGB0(led_red),
            .RGB1(led_green), 
            .RGB2(led_blue)
        );
    defparam u_led_driver.CURRENT_MODE = "0b0" ;
    defparam u_led_driver.RGB0_CURRENT = "0b000001";
    defparam u_led_driver.RGB1_CURRENT = "0b000001";
    defparam u_led_driver.RGB2_CURRENT = "0b000001";

endmodule