`default_nettype none

`include "spi_shifter.sv"

module spi_slave (
        input logic         clk,
        input logic         rst,
                  
        // SPI lines
        input logic         sck,
        input logic         ssn,
        input logic         mosi,
        output logic        miso,
                  

        // Data bus
        output logic o_vld,
        output logic o_we,
        output logic [23:0] o_adr,
        output logic [31:0] o_dat,
        
        input logic i_vld,
        output logic i_rdy,
        input logic [31:0] i_dat,
        
        // Control/status to/from SPI slave
        output logic reset_out,
        input logic [7:0] spi_id,
        input logic [7:0] spi_status,
        output logic spi_busy,
        output logic spi_start,
        output logic tx_overrun
        );
   
    // SPI protocol
    parameter
    //SPI_READ_ID             = 8'h90,
        SPI_READ_STATUS         = 8'h05,
        //SPI_WRITE_STATUS        = 8'h01,
        SPI_READ                = 8'h0B,
        SPI_WRITE               = 8'h02,
        //SPI_POWERDOWN           = 8'hB9,
        //SPI_EXIT_POWERDOWN      = 8'hAB,
        SPI_ARM_RESET           = 8'h66,
        SPI_FIRE_RESET          = 8'h99
    ;
    
    // SPI serializer & deserializer and clock domain crossing
    logic rx_vld, rx_vld_1d, tx_vld, tx_rdy;
    logic [7:0] rx_byte, tx_byte;
    
    spi_shifter
        u_spi_shifter
        (
            .sck                             (sck),
            .ssn                             (ssn),
            .mosi                            (mosi),
            .miso                            (miso),

            .clk (clk),
            .rst (rst),

            .rx_dat(rx_byte),
            .rx_vld(rx_vld),

            .tx_dat(tx_byte),
            .tx_vld(tx_vld),
            .tx_rdy(tx_rdy),

            .tx_overrun(tx_overrun),
            .busy(spi_busy),
            .start(spi_start)
        );

    // Rx processing state machine
    // State machine to handle the SPI protocol
    enum {
        S_IDLE='d0, 
        S_CMD='d1, 
        S_ADR_0='d2, 
        S_ADR_1='d3, 
        S_ADR_2='d4, 
        S_GET_RDDATA='d5, 
        S_DAT_0='d6, 
        S_DAT_1='d7, 
        S_DAT_2='d8, 
        S_DAT_3='d9, 
        S_INCR_ADR = 'd10,
        S_STATUS='d14, 
        S_XXX='d15
    } sm;
        
    logic [7:0] command;
    logic [2:0] rx_cnt;
    logic reset_armed;
    
    assign tx_ack = '1;
    
    // Next state for SM
    always @(posedge clk) begin
        if (rst) begin
            sm <= S_IDLE;
            o_we <= '0;
            o_adr <= '0;
            reset_armed <= '0;
            reset_out <= '0;
        end else begin
            
            // Default values:
            o_vld <= '0;
            tx_vld <= '0;

            case (sm)
                S_IDLE: if (spi_start) begin
                        sm <= S_CMD;
                        tx_vld <= '1;
                        tx_byte <= spi_id;
                    end
                
                S_CMD: begin
                    if (rx_vld) begin
                        // Command xaction
                        command <= rx_byte;
            
                        case (rx_byte)
                            SPI_READ, SPI_WRITE: begin 
                                sm <= S_ADR_0;
                                reset_armed <= '0;
                            end
                            
                            SPI_READ_STATUS: begin
                                sm <= S_STATUS;
                                tx_vld <= tx_rdy;
                                tx_byte <= spi_status;
                                reset_armed <= '0;
                            end
                            
                            SPI_ARM_RESET: begin
                                reset_armed <= '1;
                            end
                            
                            SPI_FIRE_RESET: begin
                                reset_out <= reset_armed;
                            end
                            
                            default: sm <= S_IDLE;
                        endcase
                    end
                end

                S_ADR_0: if (rx_vld) begin
                        sm <= S_ADR_1;
                        o_adr[23:16] <= rx_byte;
                    end
                S_ADR_1: if (rx_vld) begin
                        sm <= S_ADR_2;
                        o_adr[15:8] <= rx_byte;
                    end
                S_ADR_2: if (rx_vld) begin
                        case (command)
                            SPI_READ: begin
                                sm <= S_GET_RDDATA;
                                o_vld <= '1;
                                o_we <= '0;
                            end
                            SPI_WRITE: begin
                                sm <= S_DAT_0;
                                o_we <= '1;
                            end
                        endcase
                        o_adr[7:0] <= rx_byte;
                    end
                
                S_GET_RDDATA: if (i_vld) begin
                        sm <= S_DAT_0;
                        tx_vld <= '1;
                        tx_byte <= i_dat[31:24];
                    end
                
                S_DAT_0: if (rx_vld) begin
                        sm <= S_DAT_1;
                        if (command == SPI_WRITE)
                            o_dat[31:24] <= rx_byte;
                        else begin
                            tx_byte <= i_dat[23:16];
                            tx_vld <= '1;
                        end
                    end
                S_DAT_1: if (rx_vld) begin
                        sm <= S_DAT_2;
                        if (command == SPI_WRITE)
                            o_dat[23:16] <= rx_byte;
                        else begin
                            tx_byte <= i_dat[15:8];
                            tx_vld <= '1;
                        end
                    end
                S_DAT_2: if (rx_vld) begin
                        sm <= S_DAT_3;
                        if (command == SPI_WRITE) 
                            o_dat[15:8] <= rx_byte;
                        else begin 
                            tx_byte <= i_dat[7:0];
                            tx_vld <= '1;
                        end
                    end
                S_DAT_3: if (rx_vld) begin
                        sm <= S_INCR_ADR;
                        if (command == SPI_WRITE) begin
                            o_dat[7:0] <= rx_byte;
                            o_vld <= '1;
                        end
                    end
                S_INCR_ADR: begin
                    o_adr <= o_adr + 'd1;
                    if (command == SPI_WRITE)
                        sm <= S_DAT_0;
                    else begin
                        o_vld <= '1;
                        sm <= S_GET_RDDATA;
                    end
                end
                
                S_STATUS: begin
                    if (rx_vld) 
                        tx_vld <= '1;
                    tx_byte <= spi_status;
                end
                
            endcase
        end

        // Higher priority for ssn:
        if (ssn) begin
            sm <= S_IDLE;
            o_we <= '0;
            o_adr <= '0;
            o_vld <= '0;
            tx_vld <= '0;
        end

    end

    
    logic [2:0] tx_cnt;
    logic tx_ack;

    // Capture incoming data: assumes that the incoming data is held steady till ack'ed
    always @(posedge clk)
        if (rst) i_rdy <= '1;
        else if (i_vld & i_rdy) // Flow control input
            i_rdy <= '0;
        else if (tx_ack) // Good to go!
            i_rdy <= '1;

endmodule