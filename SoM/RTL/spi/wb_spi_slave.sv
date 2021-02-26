`default_nettype none

`include "spi_slave.sv"

module wb_spi_slave (
        input logic         clk,
        input logic         rst,
                  
        // SPI lines
        input logic         sck,
        input logic         ssn,
        input logic         mosi,
        output logic        miso,
                  
        // Bus interface
        output logic        o_wb_cyc,
        //output logic      o_wb_sel,
        output logic        o_wb_stb,

        output logic [23:0] o_wb_adr,
        output logic [31:0]  o_wb_dat,
        output logic        o_wb_we,
                  
        input logic         i_wb_ack,
        input logic [31:0]   i_wb_dat,
        
        // Control/status to/from SPI slave
        output logic reset_out,
        input logic [7:0] spi_id,
        input logic [7:0] spi_status,
        output logic spi_start,
        output logic spi_busy,
        output logic tx_overrun
        );
   
    logic rx_vld, rx_vld_1d;
    logic [31:0] wb_rd_data;
    logic [23:0] rx_adr;
    logic wb_rd_data_vld, wb_rd_data_rdy;
    
    // Clock domain and ser/deser shift registers
    spi_slave u_spi_slave(
            .o_vld(rx_vld), .o_we(o_wb_we), .o_adr(rx_adr), .o_dat(o_wb_dat),
            .i_vld(wb_rd_data_vld), .i_rdy(wb_rd_data_rdy), .i_dat(wb_rd_data),
            .*);

    // State machine to handle the Wishbone master
    enum {WB_IDLE='d0, WB_REQ='d1, WB_WAIT='d2, WB_XXX='d3} wb_curr, wb_next;
  
    // Wishbone master state machine
    always @* begin
        wb_next = WB_XXX;
        o_wb_cyc = '0;
        o_wb_stb = '0;

        case (wb_curr)
          
            WB_IDLE: begin
                if ( rx_vld_1d) begin // (rx_vld_1d & o_wb_we) | (rx_vld & wb_rd_data_rdy & ~o_wb_we) ) begin
                    // @TODO: Add a WB_PENDING state if wb_rd_data_rdy isnt ready. This should never happen!
                    wb_next = WB_REQ;
                    o_wb_cyc = '1;
                    o_wb_stb = '1;
                  
                end else 
                    wb_next = WB_IDLE;
            end
          
            WB_REQ: begin
                o_wb_cyc = '1;
                o_wb_stb = '1;
                if (i_wb_ack) begin
                    wb_next = WB_IDLE;
                end
                else begin
                    wb_next = WB_WAIT;
                end
            end

            WB_WAIT: begin
                if (i_wb_ack) begin
                    wb_next = WB_IDLE;
                end
                else begin
                    o_wb_cyc = '1;
                    wb_next = WB_WAIT;
                end
            end
          
        endcase
    
        // Override reset of the SM
        if (rst) begin
            wb_next = WB_IDLE;
        end
    end

    // Wishbone SM 
    always @(posedge clk) begin
        if (rst) wb_curr <= WB_IDLE;
        else  	 wb_curr <= wb_next;
    end

    // Capture the WB read xaction
    always @(posedge clk) begin
        if (rst) begin
            o_wb_adr <= '0;
            wb_rd_data <= '0;
            wb_rd_data_vld <= '0;
            rx_vld_1d <= '0;
        end else begin
            rx_vld_1d <= rx_vld;
            
            if (rx_vld)
                o_wb_adr <= rx_adr;
            
            if (i_wb_ack & ~o_wb_we & o_wb_cyc) begin
                wb_rd_data <= i_wb_dat; 
            end 
            wb_rd_data_vld <= i_wb_ack & ~o_wb_we & o_wb_cyc;
        end
    end


endmodule
