
/**
 * Module: spi_shifter
 * 
 * TODO: Add module documentation
 */
`default_nettype none

module spi_shifter (
        // SPI signals (SCK domain!)
        input logic ssn,
        input logic sck,
        input logic mosi,
        output logic miso,

        // Internal address/data bus (clk domain!)
        input logic clk,
        input logic rst,
    
        // Rx data
        output logic [7:0] rx_dat,
        output logic rx_vld,

        // Tx data
        input logic tx_vld,
        output logic tx_rdy,
        input logic [7:0] tx_dat,

        // Status
        output logic start,
        output logic tx_byte_done,
        output logic tx_overrun, // Asserts when tx_vld comes along when the Tx buffer overruns
        output logic busy
        );

    // SPI clock domain
    logic [2:0] tx_bit_cnt;
    logic [7:0] tx_buf[1:0];
    logic tx_buf_sel;
    logic [1:0] tx_demet;
    logic tx_ack;
    
    always @(negedge sck or posedge ssn) begin
        if (ssn) begin
            tx_buf_sel <= '0;
            tx_bit_cnt <= '0;
            tx_buf[0] <= '0; tx_buf[1] <= '0;
            tx_demet <= '0;
            tx_ack <= '0;
        end else begin

            // Load Tx buffer and ack incoming data
            if (tx_pend) begin
                tx_buf[~tx_buf_sel] <= tx_pend_dat;
                tx_ack <= '1;
            end else if (tx_bit_cnt =='d7)
                tx_ack <= '0;
            
            // Transmit bit counter
            tx_bit_cnt <= tx_bit_cnt + 'd1;
           
            // Swap buffers on byte boundaries
            if (tx_bit_cnt == 'd7)
                tx_buf_sel <= ~tx_buf_sel;
            
            // Left shift the data buffer
            tx_buf[tx_buf_sel] <= {tx_buf[tx_buf_sel][6:0], 1'b0};
        end
    end
    
    assign tx_rdy = ~tx_pend;
    
    assign miso = tx_buf[tx_buf_sel][7];

    // Debug:
    logic [7:0] tx_buf0, tx_buf1;
    assign tx_buf0 = tx_buf[0];
    assign tx_buf1 = tx_buf[1];
    
    logic [2:0] rx_bit_cnt;
    logic [7:0] rx_buf[1:0];
    logic rx_buf_sel;
    always @(negedge sck or posedge ssn) begin
        if (ssn) begin
            rx_buf[0] <= '0; rx_buf[1] <= '0;
            rx_buf_sel <= '0;
            rx_bit_cnt <= '0;
        end else begin
            // Receive bit counter
            rx_bit_cnt <= rx_bit_cnt + 'd1;
            
            // Swap Rx buffers on byte boundaries
            if (rx_bit_cnt == 'd7)
                rx_buf_sel <= ~rx_buf_sel;
            
            // Shift in the data
            rx_buf[rx_buf_sel] <= {rx_buf[rx_buf_sel][6:0], mosi};
        end
    end
    
    // CLK domain
    logic [1:0] rx_demet;
    logic [1:0] ssn_demet;
    logic tx_pend;
    logic [7:0] tx_pend_dat;
    always @(posedge clk) begin
        if (rst) begin
            rx_demet <= '0;
            ssn_demet <= '0;
            tx_pend <= '0;
            tx_pend_dat <= '0;
            tx_overrun <= '0;
        end else begin
            // Demet flops
            rx_demet <= {rx_demet[0], rx_buf_sel};
            ssn_demet <= {ssn_demet[0], ssn};
            
            if (ssn) begin
                tx_pend <= '0;
                tx_pend_dat <= '0;
            end if (tx_vld) begin
                tx_pend <= '1;
                tx_pend_dat <= tx_dat;
            end else if (tx_ack)
                tx_pend <= '0;

            // Capture overflow error
            if (tx_vld & tx_pend)
                tx_overrun <= '1;


            // Start of xaction when SSN goes low
            start <= ssn_demet[1] & ~ssn_demet[0];

            busy <= ~ssn;
        end
    end
    
    // Rx data is valid on either edge of the Rx demet.
    assign rx_vld = ~ssn & ( (rx_demet[1] & ~rx_demet[0]) | (~rx_demet[1] & rx_demet[0]) );
        
    // Rx data can be brought over without any issues since its stable by now
    assign rx_dat = rx_buf[~rx_buf_sel];
    
    assign tx_byte_done = tx_pend & tx_ack;

endmodule


