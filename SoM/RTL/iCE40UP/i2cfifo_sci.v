`include "defines6.v"
`timescale 1ns/1ps
module i2cfifo_sci (/*AUTOARG*/
   // Outputs
   i2ccr1, i2ccmdr, i2ctxdr, i2cbr, i2csaddr,i2csaddr_lsb,i2ccr1_wt, i2ccmdr_wt,
   i2cbr_wt, i2ctxdr_wt, i2csaddr_wt, i2crxdr_rd, i2cgcdr_rd,   
   trim_sda_del, sb_dat_o, sb_ack_o, i2c_irq,
   mrdcmpl, srdwr, txfifo_empty, txfifo_aempty, txfifo_full,
   rxfifo_empty, rxfifo_afull, rxfifo_full,
   // Inputs
   scl_i, sda_i,
   i2c_rst_async, sb_clk_i, sb_we_i, sb_stb_i, sb_cs_i, sb_adr_i, sb_fifo_rst,
   sb_dat_i, i2csr, i2crxdr, i2cgcdr, scan_test_mode
   );

   // INPUTS
   // From IP TOP Tie High/Tie Low
   //input [`SBAW-5:0] SB_ID;
   
   // From full chip POR ...
   input i2c_rst_async;
   
   // From i2c bus
   input scl_i;
   input sda_i;

   // From System Bus
   input sb_clk_i;
   input sb_we_i;
   input sb_stb_i;
   input sb_cs_i;

   input [`SBAW-1:0] sb_adr_i;
   input [`FIDW-1:0] sb_dat_i;
   
   input sb_fifo_rst; 										// for FIFO mode only, can be optional for users

   // From I2C_port logc
   input [`SBDW-1:0] i2csr, i2crxdr, i2cgcdr;

   // From SCAN TEST Control
   input             scan_test_mode;
   
   // OUTPUTS
   // To I2C Port Logic
   output [`SBDW-1:0]   i2ccr1, i2ccmdr, i2ctxdr;
   output [`I2CBRW-1:0] i2cbr;
   output [`SBDW-1:0]   i2csaddr;
   output [1:0]         i2csaddr_lsb;
   
   output               i2ccr1_wt, i2ccmdr_wt, i2cbr_wt, i2ctxdr_wt, i2csaddr_wt;
   output               i2crxdr_rd, i2cgcdr_rd;

   output [`DTRMW-1:0]  trim_sda_del;
   
   // To Sysem Bus
   output [`FIDW-1:0]   sb_dat_o;
   output               sb_ack_o;
   
   // To System Host
   output               i2c_irq;
   output 							mrdcmpl, srdwr;
   output 						  txfifo_empty, txfifo_aempty, txfifo_full;
   output               rxfifo_empty, rxfifo_afull, rxfifo_full;
   
   // REGS
   reg                  ack_reg;
   reg                  id_stb_dly, id_stb_pulse;
   reg                  sb_we_dly;
   
   reg [`SBDW-1:0]      i2ccr1, i2ccmdr, i2ctxdr;
   reg [`SBDW-1:0]      i2cbrlsb;
   reg [`SBDW-1:0]      i2cbrmsb;
   reg [`SBDW-1:0]      i2csaddr;
   reg [1:0]            i2csaddr_lsb;
   reg [`FIDW-1:0]      i2cintcr;
   
   //reg [`FIDW-1:0] 			i2cfifointcr;
   //reg [`FIDW-1:0] 			i2cfifointsr;    
   reg [`FIDW-1:0]      i2cfifothreshold; 
   //reg [`FIDW-1:0] 			i2cfifosmsr;  
   reg [`FIDW-1:0] 			i2cfifotxcnt;  
   reg [`FIDW-1:0] 			i2cfiforxcnt;  
   
   
   reg [`FIDW-1:0]      rdmux_dat;
   reg [`FIDW-1:0]      sb_dat_o;
   		
      
   // additinal reg and parameters for i2cfifo
   localparam FIFO_DATW  = `FIDW;
   localparam TXFIFO_DEP = `TXFIFO_DEPTH;
   localparam TXFIFO_PTRW = `TXFIFO_PWIDTH;
   localparam RXFIFO_DEP = `RXFIFO_DEPTH;
   localparam RXFIFO_PTRW = `RXFIFO_PWIDTH;
   
   
   reg [4:0]            state, next_state;  
   reg                  rxoverf, txunderf;
   reg                  mrdcmpl_int, txserr;
   reg                  rnack;
   
   reg                  txfifo_rd,  rxfifo_wr;
   reg                  srw_enable;
   reg [`FIDW-1:0]      cmd_buffer;			
   reg [RXFIFO_PTRW:0]  rxcnt_burst;		
   reg                  i2ctxfifo_rd;  
   reg                  i2crxfifo_wr;
   				
   localparam[4:0]       idle            = 10'd0,   
                         mstr_mod        = 10'd1, 
                         stop_cmd        = 10'd2, 
                         chk_bus_idle    = 10'd3,
                         get_saddr       = 10'd4, 
                         sta_cmd         = 10'd5,           
                         chk_sta_status  = 10'd6,
                         tx_sync_err     = 10'd7, 
                         tx_mod          = 10'd8, 
                         wr_txdata       = 10'd9, 
                         wr_txcmd        = 10'd10,       
                         chk_tx_status   = 10'd11,
                         wr_txcmd_stop   = 10'd12,
                         wait_tx_data    = 10'd13,
                         wait_tx_underf  = 10'd14,
                         wait_tx_idle    = 10'd15,
                         rx_mod          = 10'd16,       
                         wr_rxcmd	 = 10'd17,
                         chk_txfifo      = 10'd18,
                         wr_rxfifo       = 10'd19,
                         chk_rx_lastbyte = 10'd20,
                         wr_rxcmd_stop   = 10'd21,  
                         wait_rx_data    = 10'd22,
                         slv_mod         = 10'd23,
                         slv_wr          = 10'd24,
                         slv_wr_chk      = 10'd25,
                         slv_chk_rxfifo  = 10'd26,
                         slv_get_rxdata  = 10'd27,
                         slv_rd          = 10'd28,
                         slv_chk_txfifo  = 10'd29,
                         slv_get_txdata  = 10'd30,
                         slv_rd_chk      = 10'd31;


   // WIRES
   wire                 sb_id_match, sb_ip_match;
   wire                 id_wstb, id_wstb_ext;
   wire                 id_rstb_pulse, id_wstb_pulse;
   wire                 ip_rstb;
   
   //wire               i2ccr1_wt, i2ccmdr_wt, i2cbr_wt, i2ctxdr_wt;
   wire                 i2ccmdr_wt, i2ctxdr_wt;
   reg                  i2cbrlsb_wt, i2cbrmsb_wt;
   reg                  i2csaddr_wt, i2cgcdr_rd;
   wire                 i2crxdr_rd; 
   //wire               i2cintsr_wt, i2cintsr_rd;
   
   wire                 irq_arbl, irq_trrdy, irq_troe, irq_hgc;      
  
    // additional wire for i2cfifo
   wire                 irq_rxoverf, irq_txunderf, irq_txserr, irq_mrdcmpl, irq_rnack; 
   wire 								fifo_mode = i2ccr1[4];
   wire [`FIDW-1:0]     i2cfifosr;   			    
          
   wire [`FIDW-1:0] txfifo_din, txfifo_dout;                         
   wire [`FIDW-1:0] rxfifo_din, rxfifo_dout;                         
                                                                        
   wire txfifo_aempty, txfifo_empty, txfifo_full; 						
   wire rxfifo_empty, rxfifo_afull, rxfifo_full;                                                                                  
   // FIFO signals not used for this IP                                 
   wire txfifo_afull,  txfifo_underf, txfifo_overf;                     
   wire rxfifo_aempty, rxfifo_underf, rxfifo_overf;				
   
   wire i2csr_tip 		= i2csr[7];
   wire i2csr_busy		= i2csr[6];
   wire i2csr_rarc		= i2csr[5];
   wire i2csr_srw 		= i2csr[4];
   wire i2csr_arbl		= i2csr[3];
   wire i2csr_trrdy 	= i2csr[2];
   wire i2csr_troe    = i2csr[1];
   wire i2csr_hgc     = i2csr[0];
   wire i2ccr1_cksdis = i2ccr1[1];
   	
   
  
   // LOGIC

   // SCI Registers
   //assign sb_id_match = (sb_adr_i[`SBAW-1:4] == SB_ID);
   assign sb_id_match = sb_cs_i;
   /*assign sb_ip_match = sb_id_match & (sb_adr_i[3] | (sb_adr_i[3:0] == `ADDR_I2CINTCR) | 
                                                     (sb_adr_i[3:0] == `ADDR_I2CINTSR) |
                                                     (sb_adr_i[3:0] == `ADDR_I2CSADDR));
   */
   assign sb_ip_match = sb_id_match & (sb_adr_i[3:0] != 4'b000);                                                       

   assign id_stb      = sb_id_match & sb_stb_i;
   assign ip_stb      = sb_ip_match & sb_stb_i;
   
   assign ip_rstb     = ip_stb & ~sb_we_i;
   //assign ip_rstb_ext     = ip_stb & (~sb_we_i || sb_we_dly);

   assign id_wstb     = id_stb &  sb_we_i;
   //assign id_wstb_ext     = id_stb &  (sb_we_i || sb_we_dly);
   
   // SB STB Pulse
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async) id_stb_dly <= 1'b0;
     else               id_stb_dly <= id_stb;

   always @(posedge sb_clk_i or posedge i2c_rst_async)   // delay the we signal
     if (i2c_rst_async) sb_we_dly <= 1'b0;
     else               sb_we_dly <= sb_we_i;


   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async) id_stb_pulse <= 1'b0;
     else               id_stb_pulse <= id_stb & ~id_stb_dly;

   //assign id_rstb_pulse = id_stb_pulse & ~sb_we_i;
   //assign id_wstb_pulse = id_stb_pulse &  sb_we_i;

   // ACK OUTPUT
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async) ack_reg <= 1'b0;
     else               ack_reg <= ip_stb;
   
   assign sb_ack_o = sb_stb_i & ack_reg;
   
   // Synchronous reset for FIFOs, and FIFO related logic
   //wire fifo_int_clr = (i2c_rst_async || sb_fifo_rst) ; 
   wire fifo_sync_clr = i2ctxfifo_rd || sb_fifo_rst;
   
   // System Bus Addassable Registers
   // I2CCR1
   wire i2ccr1_match = (sb_adr_i[3:0] == `FIFO_ADDR_I2CCR1);
   wire wena_i2ccr1  = id_wstb & i2ccr1_match;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)    i2ccr1 <= `FIFO_DEFAULT_I2CCR1;
     else if (wena_i2ccr1) i2ccr1 <= sb_dat_i[`FIDW-3:0];
   
   //assign i2ccr1_wt = id_wstb_pulse & i2ccr1_match;
   reg i2ccr1_wt;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)    i2ccr1_wt <= 1'b0;
     else if (wena_i2ccr1) i2ccr1_wt <= 1'b1;
     else 		   i2ccr1_wt <= 1'b0;


   // I2CCMDR  -- usd in both modes
   wire i2ccmdr_match = (sb_adr_i[3:0] == `FIFO_ADDR_I2CCMDR);
   wire wena_i2ccmdr  = id_wstb & i2ccmdr_match;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)     i2ccmdr <= {`SBDW{1'b0}};
     else begin
          if (!fifo_mode)
            begin if (wena_i2ccmdr) i2ccmdr <= sb_dat_i; end
          else
            case (next_state)
              stop_cmd:       i2ccmdr <= {4'h4 ,1'b0, i2ccr1_cksdis, 2'b00};                                    // stop
              sta_cmd :       i2ccmdr <= {4'h9, 1'b0, i2ccr1_cksdis, 2'b00};                                    // start + wr
              wr_txcmd:       i2ccmdr <= {4'h1, 1'b0, i2ccr1_cksdis, 2'b00};                                    // wr
              wr_txcmd_stop:  i2ccmdr <= {4'h4, 1'b0, i2ccr1_cksdis, 2'b00};                                    // stop
              wr_rxcmd:       i2ccmdr <= {4'h2, 1'b0, i2ccr1_cksdis, 2'b00};                                    // rd
              wr_rxcmd_stop:  i2ccmdr <= {4'h6, 1'b1, i2ccr1_cksdis, 2'b00};                                    // rd + nack + stop
              default :       i2ccmdr <= {i2ccmdr[7:3], i2ccr1_cksdis, 2'b00};
            endcase
         end  

   reg i2ccmdr_reg_wt;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)     				i2ccmdr_reg_wt <= 1'b0;
     else if (wena_i2ccmdr  & !ack_reg & !fifo_mode) 	i2ccmdr_reg_wt <= 1'b1;
     else                                		i2ccmdr_reg_wt <= 1'b0;
   
   wire i2ccmdr_fifomode_match = (state == stop_cmd) || (state == sta_cmd) || (state == wr_txcmd)
                                 ||(state == wr_txcmd_stop) || (state == wr_rxcmd) || ((state == wr_rxcmd_stop) & !i2csr_rarc);
   //assign i2ccmdr_wt = ((id_wstb_pulse & i2ccmdr_match) & !fifo_mode) 
   //                   | (i2ccmdr_fifomode_match & fifo_mode);
   assign i2ccmdr_wt = i2ccmdr_reg_wt | (i2ccmdr_fifomode_match & fifo_mode);
   
   // I2CTXDR  -- used in both modes 
   wire i2ctxdr_match = (sb_adr_i[3:0] == `FIFO_ADDR_I2CTXDR);
   wire wena_i2ctxdr  = id_wstb & i2ctxdr_match;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)     i2ctxdr <= {`SBDW{1'b0}};
     else begin 
          if (!fifo_mode)
            begin if (wena_i2ctxdr) i2ctxdr <= sb_dat_i; end
          else 
            case (state)
             get_saddr:      i2ctxdr <= txfifo_dout;
             wr_txdata:      i2ctxdr <= txfifo_dout;
             slv_get_txdata: i2ctxdr <= txfifo_dout;
             default:        i2ctxdr <= i2ctxdr;
            endcase
         end
   
   reg i2ctxdr_reg_wt; 
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)                  		i2ctxdr_reg_wt <= 1'b0;
     else if (wena_i2ctxdr & !ack_reg & !fifo_mode) 	i2ctxdr_reg_wt <= 1'b1;
     else                                		i2ctxdr_reg_wt <= 1'b0;
   
   //assign i2ctxdr_wt = (id_wstb_pulse & i2ctxdr_match) & !fifo_mode
   //                    | (((state == sta_cmd) | ((state == wr_txcmd) & !txfifo_empty)) & fifo_mode)
   //                    | (((state == slv_get_txdata) & i2csr_trrdy) & fifo_mode);
   
   assign i2ctxdr_wt = i2ctxdr_reg_wt
                       | (((state == sta_cmd) | ((state == wr_txcmd) & !txfifo_empty)) & fifo_mode)
                       | (((state == slv_get_txdata) & i2csr_trrdy) & fifo_mode);
  
  // to detect if clock stretch is needed  during Master-Transmitting         
   reg clksrdy;
   always @(posedge sb_clk_i or posedge i2c_rst_async) 
    if (i2c_rst_async)                              clksrdy <= 1'b0;
    else 
      begin
      if (fifo_sync_clr)                             clksrdy <= 1'b0;
      else if (i2ctxdr_wt && !txfifo_dout[`FIDW-1])  clksrdy <= !txfifo_dout[`FIDW-2] && !i2ccr1_cksdis; 
      else if (state == idle)                        clksrdy <= 1'b0;   
      end   
   
   reg last_tx; 
   always @(posedge sb_clk_i or posedge i2c_rst_async)       
    if (i2c_rst_async)                              last_tx <= 1'b1;
    else 
      begin
      if (fifo_sync_clr)                             last_tx <= 1'b1;
      else if (i2ctxdr_wt && !txfifo_dout[`FIDW-1])  last_tx <= txfifo_dout[`FIDW-2]; 
      else if (state == idle)                        last_tx <= 1'b0;     
      end 
   

   // I2CBRLSB
   wire i2cbrlsb_match = (sb_adr_i[3:0] == `FIFO_ADDR_I2CBRLSB);
   wire wena_i2cbrlsb  = id_wstb & i2cbrlsb_match;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)      i2cbrlsb <= {`SBDW{1'b0}};
     else if (wena_i2cbrlsb) i2cbrlsb <= sb_dat_i[`FIDW-3:0];

   //assign i2cbrlsb_wt = id_wstb_pulse & i2cbrlsb_match;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)      i2cbrlsb_wt <= 1'b0;
     else if (wena_i2cbrlsb) i2cbrlsb_wt <= 1'b1;
     else                    i2cbrlsb_wt <= 1'b0;
   
   // I2CBRMSB
   wire i2cbrmsb_match = (sb_adr_i[3:0] == `FIFO_ADDR_I2CBRMSB);
   wire wena_i2cbrmsb  = id_wstb & i2cbrmsb_match;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)      i2cbrmsb <= {`SBDW{1'b0}};
     else if (wena_i2cbrmsb) i2cbrmsb <= sb_dat_i[`FIDW-3:0];

   //assign i2cbrmsb_wt = id_wstb_pulse & i2cbrmsb_match;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)      i2cbrmsb_wt <= 1'b0;
     else if (wena_i2cbrmsb) i2cbrmsb_wt <= 1'b1;
     else                    i2cbrmsb_wt <= 1'b0;
   
   // I2CBR
   assign i2cbr = {i2cbrmsb[`I2CBRW-`SBDW-1:0], i2cbrlsb};

   assign i2cbr_wt = i2cbrmsb_wt | i2cbrlsb_wt;
   // assign i2cbr_wt = i2cbrmsb_wt;

   assign trim_sda_del[3:0] = i2cbrmsb[`SBDW-1:`SBDW-4];
   
   // I2CSADDR or I2CFIFOSADDR, differentiated by fifo_mode
   wire i2csaddr_match = (sb_adr_i[3:0] == `FIFO_ADDR_I2CSADDR);
   wire wena_i2csaddr  = id_wstb & i2csaddr_match;
   wire wena_i2csaddr_reg = wena_i2csaddr && !fifo_mode;
   wire wena_i2csaddr_fifo = wena_i2csaddr && fifo_mode;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)           begin i2csaddr <= {`FIDW{1'b0}}; i2csaddr_lsb = 2'b00; end
     else if (wena_i2csaddr_reg)  begin i2csaddr <= sb_dat_i[`FIDW-3:0]; i2csaddr_lsb = 2'b00; end
     else if (wena_i2csaddr_fifo) begin i2csaddr <= sb_dat_i[`FIDW-1:2]; i2csaddr_lsb = sb_dat_i[1:0]; end

   //assign i2csaddr_wt = id_wstb_pulse & i2csaddr_match;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)      i2csaddr_wt <= 1'b0;
     else if (wena_i2csaddr) i2csaddr_wt <= 1'b1;
     else                    i2csaddr_wt <= 1'b0;
   
   // I2CINTCR or I2CFIFOINTCR, differentiated by fifo_mode
   wire i2cintcr_match = (sb_adr_i [3:0] == `FIFO_ADDR_I2CINTCR);
   wire wena_i2cintcr  = id_wstb & i2cintcr_match;
   wire wena_i2cintcr_reg = wena_i2cintcr && !fifo_mode;
   wire wena_i2cintcr_fifo = wena_i2cintcr && fifo_mode;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)           i2cintcr <= {`FIDW{1'b0}};
     else if (wena_i2cintcr_reg)  i2cintcr <= {2'b0, sb_dat_i[`FIDW-3:0]};
     else if (wena_i2cintcr_fifo) i2cintcr <= sb_dat_i;
     
   // I2CFIFOTHRESHOLD, only used in fifo_mode
   wire i2cfifothreshold_match = (sb_adr_i [3:0] == `ADDR_I2CFIFOTHRESHOLD) && fifo_mode;
   wire wena_i2cfifothreshold = id_wstb & i2cfifothreshold_match;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)              i2cfifothreshold <= {`FIDW{1'b0}};
     else if (wena_i2cfifothreshold) i2cfifothreshold <= sb_dat_i;

   // I2CRXDR RD PULSE, used in both modes
   reg i2crxdr_reg_rd;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
   if (i2c_rst_async)       				  	     i2crxdr_reg_rd <= 1'b0;
   else if (ip_rstb & !ack_reg & (sb_adr_i[3:0] == `FIFO_ADDR_I2CRXDR))   i2crxdr_reg_rd <= 1'b1;
   else                                                  	     i2crxdr_reg_rd <= 1'b0;
   //assign i2crxdr_rd = (id_rstb_pulse & (sb_adr_i[3:0] == `ADDR_I2CRXDR) & !fifo_mode)
   //                    | (((state == wr_rxfifo) & i2csr_trrdy)  & fifo_mode)
   //                    | (((state == slv_get_rxdata) & !i2csr_srw) & fifo_mode);
   assign i2crxdr_rd = (i2crxdr_reg_rd & !fifo_mode)
                       | (((state == wr_rxfifo) & i2csr_trrdy)  & fifo_mode)
                       | (((state == slv_get_rxdata) & !i2csr_srw) & fifo_mode);

   // I2CGCDR RD PULSE
   //assign i2cgcdr_rd = id_rstb_pulse & (sb_adr_i[3:0] == `ADDR_I2CGCDR);
   always @(posedge sb_clk_i or posedge i2c_rst_async)
   if (i2c_rst_async)       				  	     i2cgcdr_rd <= 1'b0;
   else if (ip_rstb & !ack_reg & (sb_adr_i[3:0] == `FIFO_ADDR_I2CGCDR))   i2cgcdr_rd <= 1'b1;
   else                                                   	     i2cgcdr_rd <= 1'b0;
   
   // I2CFIFOSR status bits
   always @(posedge sb_clk_i or posedge i2c_rst_async)
   if (i2c_rst_async)       rxoverf <= 1'b0;
   else                     rxoverf <= rxfifo_overf;

   always @(posedge sb_clk_i or posedge i2c_rst_async)
   if (i2c_rst_async)       txunderf <= 1'b0;
   else                     txunderf <= txfifo_underf;

   always @(posedge sb_clk_i or posedge i2c_rst_async)
   if (i2c_rst_async)       txserr <= 1'b0;
   else                     txserr <= (state == tx_sync_err);

   wire rd_last_byte =  ((state == wr_rxfifo) && i2csr_rarc );
   always @(posedge sb_clk_i or posedge i2c_rst_async)
   if (i2c_rst_async)                mrdcmpl_int <= 1'b0;
   else if (rxcnt_burst == 0)        mrdcmpl_int <= 1'b0;
   else if (rd_last_byte)            mrdcmpl_int <= 1'b1;  
   
   wire rnack_set = (state == chk_tx_status) || ((state == chk_sta_status) && (next_state == stop_cmd));
   wire rnack_reset = (state == mstr_mod);
   always @(posedge sb_clk_i or posedge i2c_rst_async)
   if (i2c_rst_async)       rnack <= 1'b0;
   else if (rnack_set)      rnack <= i2csr_rarc;
   else if (rnack_reset)    rnack <= 1'b0;
   
   // I2CFIFOSR
   assign i2cfifosr = {({3{1'b0}}), i2csr_hgc, rnack, mrdcmpl_int, i2csr_arbl, txserr, txunderf, rxoverf}; 
   
   // sb_dat_o MUX
   always @(/*AUTOSENSE*/`FIFO_ADDR_I2CBRLSB or `FIFO_ADDR_I2CBRMSB
            or `FIFO_ADDR_I2CCMDR or `FIFO_ADDR_I2CCR1 or `FIFO_ADDR_I2CGCDR
            or `FIFO_ADDR_I2CINTCR or `FIFO_ADDR_I2CINTSR or `FIFO_ADDR_I2CRXDR
            or `FIFO_ADDR_I2CSADDR or `FIFO_ADDR_I2CSR or `FIFO_ADDR_I2CTXDR or `SBDW or `FIDW
            or i2cbrlsb or i2cbrmsb or i2ccmdr or i2ccr1 or i2cgcdr
            or i2cintcr or i2crxdr or rxfifo_dout or i2csaddr or i2csr or i2cfifosr
            or i2ctxdr or txfifo_dout or i2cfifothreshold or i2cfifotxcnt or i2cfiforxcnt
            or irq_arbl or irq_hgc or irq_troe or irq_trrdy
            or irq_rxoverf or irq_txunderf or irq_txserr or irq_mrdcmpl or irq_rnack
            or fifo_mode or state or i2csaddr_lsb
            or sb_adr_i)
     begin
      case (sb_adr_i[3:0])
        `FIFO_ADDR_I2CCR1  			    : rdmux_dat = {2'b00, i2ccr1};
        `FIFO_ADDR_I2CCMDR 			    : rdmux_dat = {2'b00, i2ccmdr}; 
        `FIFO_ADDR_I2CBRLSB			    : rdmux_dat = {2'b00, i2cbrlsb};
        `FIFO_ADDR_I2CBRMSB			    : rdmux_dat = {2'b00, i2cbrmsb};
        `FIFO_ADDR_I2CSR   			    : if (!fifo_mode) rdmux_dat = {2'b00, i2csr};   else rdmux_dat = i2cfifosr;  		
        `FIFO_ADDR_I2CTXDR 			    : if (!fifo_mode) rdmux_dat = {2'b00, i2ctxdr}; else rdmux_dat = txfifo_dout; 		// This will cause a reset of txfifo pointers
        `FIFO_ADDR_I2CRXDR 			    : if (!fifo_mode) rdmux_dat = {2'b00, i2crxdr}; else rdmux_dat = rxfifo_dout; 		// need to be connected to rxfifo output
        `FIFO_ADDR_I2CGCDR 			    : rdmux_dat = {2'b00, i2cgcdr};
        `FIFO_ADDR_I2CINTCR			    : rdmux_dat = i2cintcr;
        `FIFO_ADDR_I2CINTSR			    : if (!fifo_mode) rdmux_dat = {{6{1'b0}}, irq_arbl, irq_trrdy, irq_troe, irq_hgc}; 
        				                  else rdmux_dat = {{3{1'b0}}, irq_hgc, irq_rnack, irq_mrdcmpl, irq_arbl, irq_txserr, irq_txunderf, irq_rxoverf};
        `FIFO_ADDR_I2CSADDR			    : if (!fifo_mode) rdmux_dat = {2'b00, i2csaddr}; else rdmux_dat = {i2csaddr,i2csaddr_lsb};      
        `ADDR_I2CFIFOTHRESHOLD  : if (!fifo_mode) rdmux_dat = {`FIDW{1'b0}}; else rdmux_dat = i2cfifothreshold; 
        `ADDR_I2CFIFOSMSR       : if (!fifo_mode) rdmux_dat = {`FIDW{1'b0}}; else rdmux_dat = {{5{1'b0}}, state};
        `ADDR_I2CFIFOTXCNT      : if (!fifo_mode) rdmux_dat = {`FIDW{1'b0}}; else rdmux_dat = i2cfifotxcnt; 		// It is readable only in FIFO mode only  
        `ADDR_I2CFIFORXCNT      : if (!fifo_mode) rdmux_dat = {`FIDW{1'b0}}; else rdmux_dat = i2cfiforxcnt; 		// It is readable only in FIFO mode only  
        default                 : rdmux_dat = {`FIDW{1'b0}};
      endcase // case (adr_i[3:0])
   end // always @ (...

   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async) sb_dat_o <= 0;
     else if (ip_rstb)  sb_dat_o <= rdmux_dat;
     else               sb_dat_o <= sb_dat_o;
     

   // ****************************************************************************************
   // Interrupt Logic
   // ****************************************************************************************
   wire match_intsr = (sb_adr_i[3:0] == `FIFO_ADDR_I2CINTSR);
   wire wena_i2cintsr = id_wstb & match_intsr;
   wire rena_i2cintsr = ip_rstb & match_intsr;
   //assign i2cintsr_wt = id_wstb_pulse & match_intsr;
   reg i2cintsr_wt;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)         i2cintsr_wt <= 1'b0;
     else if (wena_i2cintsr) 	i2cintsr_wt <= 1'b1;
     else                       i2cintsr_wt <= 1'b0;
   
   //assign i2cintsr_rd = id_rstb_pulse & match_intsr;
   reg i2cintsr_rd;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
     if (i2c_rst_async)          i2cintsr_rd <= 1'b0;
     else if (rena_i2cintsr)     i2cintsr_rd <= 1'b1;
     else                        i2cintsr_rd <= 1'b0;

   wire int_clr_all = fifo_mode ? (i2cintcr[`INDEX_FIFO_INTCLR] & i2cintsr_rd) : (i2cintcr[`INDEX_INTCLR] & i2cintsr_rd);
   
   wire int_force = fifo_mode ? i2cintcr[`INDEX_FIFO_INTFRC] : i2cintcr[`INDEX_INTFRC];
   
   // IRQ ARBL
   wire int_arbl;
   wire int_set_arbl = i2csr[`INDEX_ARBL];
   wire int_clr_arbl = (i2cintsr_wt & sb_dat_i[`INDEX_ARBL]) | int_clr_all;
   sci_int_reg intr_arbl(
                         // Outputs
                         .status                (int_arbl),
                         // Inputs
                         .rst_async             (i2c_rst_async),
                         .sb_clk_i              (sb_clk_i),
                         .int_force             (int_force),
                         .int_set               (int_set_arbl),
                         .int_clr               (int_clr_arbl),
                         .scan_test_mode        (scan_test_mode));

   assign irq_arbl = fifo_mode ? (i2cintcr[`INDEX_FIFO_ARBL] & int_arbl) : (i2cintcr[`INDEX_ARBL] & int_arbl);

   // IRQ TRRDY
   wire int_trrdy;
   wire int_set_trrdy = i2csr[`INDEX_TRRDY];
   wire int_clr_trrdy = (i2cintsr_wt & sb_dat_i[`INDEX_TRRDY]) | int_clr_all;
   sci_int_reg intr_trrdy(
                          // Outputs
                          .status                (int_trrdy),
                          // Inputs
                          .rst_async             (i2c_rst_async),
                          .sb_clk_i              (sb_clk_i),
                          .int_force             (int_force),
                          .int_set               (int_set_trrdy),
                          .int_clr               (int_clr_trrdy),
                          .scan_test_mode        (scan_test_mode));

   assign irq_trrdy = i2cintcr[`INDEX_TRRDY] & int_trrdy;

   // IRQ TROD
   wire int_troe;
   wire int_set_troe = i2csr[`INDEX_TROE];
   wire int_clr_troe = (i2cintsr_wt & sb_dat_i[`INDEX_TROE]) | int_clr_all;
   sci_int_reg intr_troe(
                         // Outputs
                         .status                (int_troe),
                         // Inputs
                         .rst_async             (i2c_rst_async),
                         .sb_clk_i              (sb_clk_i),
                         .int_force             (int_force),
                         .int_set               (int_set_troe),
                         .int_clr               (int_clr_troe),
                         .scan_test_mode        (scan_test_mode));
   
   assign irq_troe = i2cintcr[`INDEX_TROE] & int_troe;

   // IRQ HGC
   wire int_hgc;
   wire int_set_hgc = i2csr[`INDEX_HGC];
   wire int_hgc_mux = fifo_mode ? sb_dat_i[`INDEX_FIFO_HGC] : sb_dat_i[`INDEX_HGC] ;
   wire int_clr_hgc = (i2cintsr_wt & int_hgc_mux) | int_clr_all;
   sci_int_reg intr_hgc(
                        // Outputs
                        .status                (int_hgc),
                        // Inputs
                        .rst_async             (i2c_rst_async),
                        .sb_clk_i              (sb_clk_i),
                        .int_force             (int_force),
                        .int_set               (int_set_hgc),
                        .int_clr               (int_clr_hgc),
                        .scan_test_mode        (scan_test_mode));
   
   assign irq_hgc = fifo_mode ? (i2cintcr[`INDEX_FIFO_HGC] & int_hgc) : (i2cintcr[`INDEX_HGC] & int_hgc);

   // IRQ rxoverf
   wire int_rxoverf;
   wire int_set_rxoverf = i2cfifosr[`INDEX_RXOVERF];
   wire int_clr_rxoverf = (i2cintsr_wt & sb_dat_i[`INDEX_RXOVERF]) | int_clr_all;
   sci_int_reg intr_rxoverf(
                        // Outputs
                        .status                (int_rxoverf),
                        // Inputs
                        .rst_async             (i2c_rst_async),
                        .sb_clk_i              (sb_clk_i),
                        .int_force             (int_force),
                        .int_set               (int_set_rxoverf),
                        .int_clr               (int_clr_rxoverf),
                        .scan_test_mode        (scan_test_mode));      
  
   assign irq_rxoverf = i2cintcr[`INDEX_RXOVERF] & int_rxoverf;      
   
   // IRQ txunderf
   wire int_txunderf;
   wire int_set_txunderf = i2cfifosr[`INDEX_TXUNDERF];
   wire int_clr_txunderf = (i2cintsr_wt & sb_dat_i[`INDEX_TXUNDERF]) | int_clr_all;
   sci_int_reg intr_txunderf(
                        // Outputs
                        .status                (int_txunderf),
                        // Inputs
                        .rst_async             (i2c_rst_async),
                        .sb_clk_i              (sb_clk_i),
                        .int_force             (int_force),
                        .int_set               (int_set_txunderf),
                        .int_clr               (int_clr_txunderf),
                        .scan_test_mode        (scan_test_mode));           
                        
   assign irq_txunderf = i2cintcr[`INDEX_TXUNDERF] & int_txunderf;                           

   // IRQ txserr
   wire int_txserr;
   wire int_set_txserr = i2cfifosr[`INDEX_TXSERR];
   wire int_clr_txserr = (i2cintsr_wt & sb_dat_i[`INDEX_TXSERR]) | int_clr_all;
   sci_int_reg intr_txserr(
                        // Outputs
                        .status                (int_txserr),
                        // Inputs
                        .rst_async             (i2c_rst_async),
                        .sb_clk_i              (sb_clk_i),
                        .int_force             (int_force),
                        .int_set               (int_set_txserr),
                        .int_clr               (int_clr_txserr),
                        .scan_test_mode        (scan_test_mode));       

   assign irq_txserr = i2cintcr[`INDEX_TXSERR] & int_txserr;                             
    
   // IRQ mrdcmpl
   wire int_mrdcmpl;
   wire int_set_mrdcmpl = i2cfifosr[`INDEX_MRDCMPL];
   wire int_clr_mrdcmpl = (i2cintsr_wt & sb_dat_i[`INDEX_MRDCMPL]) | int_clr_all;
   sci_int_reg intr_mrdcmpl(
                        // Outputs
                        .status                (int_mrdcmpl),
                        // Inputs
                        .rst_async             (i2c_rst_async),
                        .sb_clk_i              (sb_clk_i),
                        .int_force             (int_force),
                        .int_set               (int_set_mrdcmpl),
                        .int_clr               (int_clr_mrdcmpl),
                        .scan_test_mode        (scan_test_mode));

   assign irq_mrdcmpl = i2cintcr[`INDEX_MRDCMPL] & int_mrdcmpl;          
   assign mrdcmpl = irq_mrdcmpl;
   
   // IRQ rnack
   wire int_rnack;
   wire int_set_rnack = i2cfifosr[`INDEX_RNACK];
   wire int_clr_rnack = (i2cintsr_wt & sb_dat_i[`INDEX_RNACK]) | int_clr_all;
   sci_int_reg intr_rnack(
                        // Outputs
                        .status                (int_rnack),
                        // Inputs
                        .rst_async             (i2c_rst_async),
                        .sb_clk_i              (sb_clk_i),
                        .int_force             (int_force),
                        .int_set               (int_set_rnack),
                        .int_clr               (int_clr_rnack),
                        .scan_test_mode        (scan_test_mode));

   assign irq_rnack = i2cintcr[`INDEX_RNACK] & int_rnack;     

   // Generate interrupt signal, in fifo mode and in registser mode
   assign i2c_irq = fifo_mode ? (irq_hgc | irq_rnack | irq_arbl | irq_txserr | irq_txunderf | irq_rxoverf) : (irq_arbl | irq_trrdy | irq_troe | irq_hgc);
   
   
   // ****************************************************************************************
   // FIFO Instantiation
   // ****************************************************************************************
   
   // get threshold value for the FIFO from the register
   wire [TXFIFO_PTRW-1:0] txfifo_aeval = i2cfifothreshold[TXFIFO_PTRW-1:0];
   wire [RXFIFO_PTRW-1:0] rxfifo_afval = i2cfifothreshold[RXFIFO_PTRW+4:5];
    
   // TXFIFO control signals 
   wire i2ctxfifo_match = (sb_adr_i[3:0] == `FIFO_ADDR_I2CTXDR);    
   wire wena_i2ctxfifo  = id_wstb & i2ctxfifo_match & fifo_mode;     									       
      
   always @(posedge sb_clk_i or posedge i2c_rst_async)    
   if (i2c_rst_async)  i2ctxfifo_rd <= 1'b0;
   else                i2ctxfifo_rd <= ip_rstb & i2ctxfifo_match & fifo_mode;              
      
   assign txfifo_din = wena_i2ctxfifo ?  sb_dat_i : {`FIDW{1'b0}};
   
   fifo #(FIFO_DATW, TXFIFO_DEP, TXFIFO_PTRW) 
        i2ctxfifo (
                  // Outputs
                  .dout            (txfifo_dout),
                  .empty           (txfifo_empty),
                  .full            (txfifo_full),
                  .aempty          (txfifo_aempty),
                  .afull           (txfifo_afull),															
                  .underf          (txfifo_underf),
                  .overf           (txfifo_overf),															
                  // Inputs
                  .rst_async       (i2c_rst_async),
                  .rst_sync        (fifo_sync_clr),
                  .wclk            (sb_clk_i),
                  .rclk            (sb_clk_i),
                  .we              (wena_i2ctxfifo),
                  .re              (txfifo_rd),
                  .din             (txfifo_din),
                  .aempty_val      (txfifo_aeval),
                  .afull_val       ({TXFIFO_PTRW{1'b0}})
                  );

   // RXFIFO control signals        
   wire i2crxfifo_match = (sb_adr_i[3:0] == `FIFO_ADDR_I2CRXDR);                                  	   								      
   wire rena_i2crxfifo  = ip_rstb & i2crxfifo_match & fifo_mode;
   
   always @(posedge sb_clk_i or posedge i2c_rst_async)                           
   if (i2c_rst_async)  i2crxfifo_wr <= 1'b0;                                     
   else                i2crxfifo_wr <= id_wstb & i2crxfifo_match & fifo_mode;      

  // internal synchronous reset 
  wire rxfifo_sync_clr = i2crxfifo_wr || sb_fifo_rst;
   
  // detect start and stop   
   reg [1:0] sda_buffer;
   reg [1:0] scl_buffer;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
   if (i2c_rst_async) begin sda_buffer <= 2'b00; scl_buffer <= 2'b00; end
   else
    begin
      sda_buffer[0] <= sda_i;
	    sda_buffer[1] <= sda_buffer[0];
	    scl_buffer[0] <= scl_i;
	    scl_buffer[1] <= scl_buffer[0];     
	  end  
	  
	 // detect Stop to reset the STA_DET register	
	 reg stop_det;
	 always @(posedge sb_clk_i or posedge i2c_rst_async)    
	 if (i2c_rst_async)  stop_det <= 1'b0; 
   else if (!fifo_mode)                                     stop_det <= 1'b0;
	 else if ((sda_buffer == 2'b01) && (scl_buffer == 2'b11)) stop_det <= 1'b1;
	 else                                                     stop_det <= 1'b0;         
   
   // detect Start or Restart
   reg rxfifo_wr_dly;
   always @(posedge sb_clk_i or posedge i2c_rst_async)
   if (i2c_rst_async)  rxfifo_wr_dly <= 1'b0;
   else                rxfifo_wr_dly <= rxfifo_wr;
     
   reg sta_det;           
   always @(posedge sb_clk_i or posedge i2c_rst_async)  
   if (i2c_rst_async)           sta_det <= 1'b0;    
   else if (!fifo_mode)                                       sta_det <= 1'b0;          
   else if ((sda_buffer == 2'b10) && (scl_buffer == 2'b11))   sta_det <= 1'b1; //sta_det || scl_i;  
   else if (stop_det || rxfifo_wr_dly || srdwr)               sta_det <= 1'b0;

   assign rxfifo_din[`FIDW-3:0] = i2crxdr;     
   assign rxfifo_din[`FIDW-1:`FIDW-2] = sta_det ? 2'b01 : 2'b00; 
  

   fifo #(FIFO_DATW, RXFIFO_DEP, RXFIFO_PTRW) 
        i2crxfifo (
                  // Outputs
                  .dout            (rxfifo_dout),
                  .empty           (rxfifo_empty),
                  .full            (rxfifo_full),
                  .aempty          (rxfifo_aempty),
                  .afull           (rxfifo_afull),
                  .underf          (rxfifo_underf),
                  .overf           (rxfifo_overf),
                  // Inputs
                  .rst_async       (i2c_rst_async),
                  .rst_sync        (rxfifo_sync_clr),
                  .wclk            (sb_clk_i),
                  .rclk            (sb_clk_i),
                  .we              (rxfifo_wr),
                  .re              (rena_i2crxfifo),
                  .din             (rxfifo_din),
                  .aempty_val      ({RXFIFO_PTRW{1'b0}}),
                  .afull_val       (rxfifo_afval)
                  );							   
				
    // ****************************************************************************************
    // FIFO State Machine control                                                                     
    // ****************************************************************************************							
		
    // internal registers are cleared when the FIFOs are cleared
    // FIFO sm will issue an early STOP if it is in either MAster read or Master write mode		      								
	  
	  // buffer the command byte so that it can see the expected RX byte number, and check TX sync error
    wire cmd_buffer_load = (state == mstr_mod); 
	  always @(posedge sb_clk_i or posedge i2c_rst_async)
	    if (i2c_rst_async)            cmd_buffer <= {`FIDW{1'b0}};
	    else 
	      begin 
	      if (fifo_sync_clr)         cmd_buffer <= {`FIDW{1'b0}};
	      else if (cmd_buffer_load)  cmd_buffer <= txfifo_dout; 
	      end
	  
	  // Counter to keep track of the received bytes for current RD command
    wire rxcnt_burst_inc = (state == wr_rxfifo) && i2csr_trrdy;
    wire rxcnt_burst_clr = (state == idle);
	  always @(posedge sb_clk_i or posedge i2c_rst_async)    
	    if (i2c_rst_async)            rxcnt_burst <= {RXFIFO_PTRW{1'b0}};     
	    else 
	      begin
	      if (fifo_sync_clr)         rxcnt_burst <= {RXFIFO_PTRW{1'b0}}; 
	      else if (rxcnt_burst_inc)  rxcnt_burst <= rxcnt_burst + 1; 
	      else if (rxcnt_burst_clr)  rxcnt_burst <= {RXFIFO_PTRW{1'b0}};
	      end
	  
	  // mask the SRW status for Slave mode only
	  always @(posedge sb_clk_i or posedge i2c_rst_async)
	  if (i2c_rst_async)         srw_enable <= 1'b0;
	  else if (state == slv_rd)  srw_enable <= 1'b1;
	  else if (state == idle)    srw_enable <= 1'b0;
	  
	  assign srdwr = (i2csr_srw && srw_enable);
	    
	  // Detect risign edge of i2csr_tip signal for 1 byte Master Read
	  reg tip_dly;
	  reg tip_posedge;
	  always @(posedge sb_clk_i or posedge i2c_rst_async)             
      if (i2c_rst_async)     tip_dly  <= 1'b1;   
      else                   tip_dly <= i2csr_tip;
    
    always @(posedge sb_clk_i or posedge i2c_rst_async)
      if (i2c_rst_async)     tip_posedge <= 1'b0;         
	    else                   tip_posedge <= i2csr_tip && !tip_dly;    
  	                                                     
	  // ****************************************************************************************
    // FIFO State Machine                                                                    
    // ****************************************************************************************						
	  
	  always @(posedge sb_clk_i or posedge i2c_rst_async )
	    if (i2c_rst_async)		state <= idle;
      else if (!fifo_mode)  state <= idle;
      else  							  state <= next_state;
	  
    always @(/*AUTOSENSE*/ *)
      begin
        txfifo_rd = 1'b0;
        rxfifo_wr = 1'b0;
        case (state)
        	idle :	         begin
                           if (!fifo_mode)                                       next_state = idle;
                           else
                           begin
        	                  if (!txfifo_empty && txfifo_dout[9] && !sta_det)     next_state = mstr_mod;    
        	                  else 
        	                   begin  
        	                     if (i2csr_busy ) 
        	                     begin                                                            
        	                      if (i2csr_rarc || i2csr_arbl)        next_state = idle;
        	                      else                                 next_state = slv_mod;  
        	                     end  
        	                     else                                  next_state = idle;          
        	                   end
                           end
        	                 end  	  																							
        	//---------------------------------------------------------------------------------
          // In Master Mode
          //----------------------------------------------------------------------------------
          mstr_mod:        if (!txfifo_dout[8] && i2csr_busy) 
        	                  begin next_state = stop_cmd; txfifo_rd = 1'b0; end		  
        	                 else   
        	                  begin next_state = get_saddr; txfifo_rd = 1'b1; end											
        	stop_cmd:        if (!irq_rnack && !i2csr_tip)  next_state = chk_bus_idle; 
        	                 else                           next_state = idle;      
        	chk_bus_idle:    if (!i2csr_busy) 
        	                    begin next_state = get_saddr; txfifo_rd = 1'b1; end
        	                 else             
        	                    begin next_state = chk_bus_idle; txfifo_rd = 1'b0; end         																	
        	get_saddr:       if (!txfifo_dout[9])  next_state = sta_cmd;		
        	                 else                  next_state = tx_sync_err;		
        	sta_cmd:         next_state = chk_sta_status;          
          chk_sta_status:  if (i2csr_arbl && i2csr_busy )    				
														 next_state = idle;    
													 else if (~i2csr_tip && i2csr_busy && i2csr_rarc) 
													   next_state = stop_cmd;
													 else if (!txfifo_dout[0] && ~i2csr_tip && i2csr_busy && i2csr_trrdy) 
                             next_state = tx_mod;
                           else if (txfifo_dout[0] && ~i2csr_tip && i2csr_busy && i2csr_srw)
                             next_state = rx_mod;
                           else
                             next_state = chk_sta_status;															 
          tx_sync_err:      next_state = mstr_mod;       

          // Master Write    
          tx_mod:           begin next_state = wr_txdata; txfifo_rd = 1'b1; end
        	wr_txdata:		    if (txfifo_dout[9] && !txfifo_empty) next_state = mstr_mod;
                            else                                 next_state = wr_txcmd;  
        	wr_txcmd:         next_state = chk_tx_status;
        	chk_tx_status:    if (i2csr_arbl && i2csr_busy )    				
														 next_state = idle;    
													  else if (~i2csr_tip && i2csr_busy && i2csr_rarc) 
													   next_state = wr_txcmd_stop;
													  else if (i2csr_busy && txfifo_empty)
													   begin
													    if (last_tx)
													     next_state = wr_txcmd_stop;
													    else
													     next_state = wait_tx_data;
													   end   
													  else if ((~i2csr_tip && i2csr_busy && i2csr_trrdy) && (!txfifo_empty))
													   next_state = tx_mod;
                            else
                             next_state = chk_tx_status;		
          wr_txcmd_stop:    next_state = wait_tx_idle;
          wait_tx_data:     if (!txfifo_empty) next_state = wr_txdata;        // do not move the pointer
                            else 
                            begin
                              if (!clksrdy)        next_state = wait_tx_underf; 
                              else                 next_state = wait_tx_data;
                            end
          wait_tx_underf:   if (txfifo_empty) 
                              begin 
                                next_state = wait_tx_underf; 
                                if (i2csr_trrdy) txfifo_rd = 1'b1; 
                                else             txfifo_rd = 1'b0; 
                              end
                            else              next_state = wr_txdata;
          wait_tx_idle:     if (!i2csr_busy) next_state = idle;
                            else             next_state = wait_tx_idle;
          
          // Master Read
          rx_mod:           if (i2csr_srw)      next_state = wr_rxcmd;
                            else                next_state = rx_mod;
          wr_rxcmd:			    next_state = chk_txfifo;
          chk_txfifo:       begin    
                             next_state = wr_rxfifo;   
                             if (!txfifo_empty) txfifo_rd = 1'b1;
                             else               txfifo_rd = 1'b0;
                            end
          wr_rxfifo:        if (tip_posedge && (cmd_buffer[`RXFIFO_PWIDTH-1:0] == {`RXFIFO_PWIDTH{1'b0}}))       
                                                   begin next_state = wr_rxcmd_stop;    rxfifo_wr = 1'b0; end
                            else if (i2csr_trrdy)  begin next_state = chk_rx_lastbyte;  rxfifo_wr = 1'b1; end
                            else if (!i2csr_srw)   begin next_state = idle;             rxfifo_wr = 1'b0; end
                            else                   begin next_state = wr_rxfifo;        rxfifo_wr = 1'b0; end
          chk_rx_lastbyte:  if (rxcnt_burst == cmd_buffer[RXFIFO_PTRW-1:0])             
                              begin
                                if (txfifo_empty)          next_state = wr_rxcmd_stop;
                                else if (!txfifo_dout[9])  next_state = wr_rxcmd_stop;
                                else                       next_state = idle; 
                              end 
                            else 
                              begin
                                if (cmd_buffer == {`FIDW{1'b0}}) next_state = wr_rxcmd_stop;              
                                else  
                                  begin
                                    if (rxfifo_full )  next_state = wait_rx_data;                                   
                                    else               next_state = wr_rxfifo;    
                                  end                                                                         
                              end
          wr_rxcmd_stop:    next_state = wr_rxfifo;    
          wait_rx_data:     if (!rxfifo_full)       next_state = chk_rx_lastbyte;  
                            else 
                              begin
                              if (i2ccr1_cksdis)    begin next_state = wr_rxfifo; rxfifo_wr = 1'b1; end
                              else                  begin next_state = wait_rx_data; rxfifo_wr = 1'b0; end
                              end
          
        	//---------------------------------------------------------------------------------
          // In Slave Mode
          //----------------------------------------------------------------------------------
          slv_mod: 			    begin    
                              txfifo_rd = 1'b0;
                              rxfifo_wr = 1'b0;
                              if (!i2csr_busy)            next_state = idle;
                              else 
                                begin
                                  if (i2csr_srw) 						next_state = slv_rd;
  			  							          else 					            next_state = slv_wr;		
			  							          end  
			  							      end   
          // Slave Write
          slv_wr:           begin 
                              next_state = slv_wr_chk;
                              rxfifo_wr = 1'b0; 
                            end
          slv_wr_chk:       if (!i2csr_busy)            next_state = idle;    
                            else 
                            begin
                              if (i2csr_trrdy)      next_state = slv_chk_rxfifo; 
                              else                  next_state = slv_wr_chk;
                            end
                             
          slv_chk_rxfifo:   if (!i2csr_busy)            next_state = idle;
                            else 
                            begin
                              if (!rxfifo_full)         next_state = slv_get_rxdata;
                              else         
                                begin             
                                  if (!i2ccr1_cksdis)   next_state = slv_chk_rxfifo;
                                  else                  next_state = slv_get_rxdata;   
                                end 
                            end             
          slv_get_rxdata:   begin
                              next_state = slv_mod;
                              if (i2csr_srw)  rxfifo_wr = 1'b0;
                              else            rxfifo_wr = 1'b1;
                            end
          // Slave Read 
          slv_rd:          if (i2csr_srw)              next_state = slv_chk_txfifo;
                           else                        next_state = idle;                          
          slv_chk_txfifo:   if (!i2csr_busy)                        next_state = idle;  
                            else 
                            begin
                              if (!txfifo_empty)                    next_state = slv_get_txdata; 
                              else
                                begin
                                if (!i2ccr1_cksdis && i2csr_busy)   next_state = slv_chk_txfifo; 
                                else  
                                  begin 
                                   next_state = slv_rd; 
                                   if (i2csr_trrdy)                 txfifo_rd = 1'b1; 
                                   else                             txfifo_rd = 1'b0;
                                 end                                   
                                end      
                            end
          slv_get_txdata:   next_state = slv_rd_chk;
          slv_rd_chk:       if (!i2csr_busy)                        next_state = idle;  
                            else
                            begin
                              if (i2csr_trrdy)  
                                begin     next_state = slv_rd; txfifo_rd = 1'b1; end
                              else        
                                begin     next_state = slv_rd_chk; txfifo_rd = 1'b0; end   
                            end  
    
			                      
			    default:          begin next_state = idle; txfifo_rd = 1'b0; rxfifo_wr = 1'b0;  end
			  endcase
			 end

    // ****************************************************************************************
    // Number of transmitted bytes, not including saddr                                                                   
    // ****************************************************************************************							
     
   wire i2cfifotxcnt_match = (sb_adr_i[3:0] == `ADDR_I2CFIFOTXCNT);                                  	   								    
   
   reg i2cfifotxcnt_wr;
   always @(posedge sb_clk_i or posedge i2c_rst_async)                           
   if (i2c_rst_async)  i2cfifotxcnt_wr <= 1'b0;                                     
   else                i2cfifotxcnt_wr <= id_wstb & i2cfifotxcnt_match & fifo_mode;      
     
   always @(posedge sb_clk_i or posedge i2c_rst_async)
   if (i2c_rst_async)                        i2cfifotxcnt <= {`FIDW{1'b0}};
   else if (i2cfifotxcnt_wr || sb_fifo_rst)  i2cfifotxcnt <= {`FIDW{1'b0}};
   else if (i2ctxdr_wt)                      i2cfifotxcnt <= i2cfifotxcnt + 1;

    // ****************************************************************************************
    // Number of received bytes, not including saddr                                                                   
    // ****************************************************************************************							
     
   wire i2cfiforxcnt_match = (sb_adr_i[3:0] == `ADDR_I2CFIFORXCNT);                                  	   								    
   
   reg i2cfiforxcnt_wr;
   always @(posedge sb_clk_i or posedge i2c_rst_async)                           
   if (i2c_rst_async)  i2cfiforxcnt_wr <= 1'b0;                                     
   else                i2cfiforxcnt_wr <= id_wstb & i2cfiforxcnt_match & fifo_mode;      
                
   always @(posedge sb_clk_i or posedge i2c_rst_async)
   if (i2c_rst_async)                       i2cfiforxcnt <= {`FIDW{1'b0}};
   else if (i2cfiforxcnt_wr || sb_fifo_rst) i2cfiforxcnt <= {`FIDW{1'b0}};
   else if (i2crxdr_rd)                     i2cfiforxcnt <= i2cfiforxcnt + 1;
     
endmodule // i2cfifo_sci
