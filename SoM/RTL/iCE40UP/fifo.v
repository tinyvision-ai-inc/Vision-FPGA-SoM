`timescale        1ns/1ps
module fifo (/*AUTOARG*/
   // Outputs
   dout, empty, full, aempty, afull, overf, underf,
   // Inputs
   rst_async, rst_sync, wclk, we, rclk, re, din,
   aempty_val, afull_val
   );
   parameter FIFO_DATW  = 8;
   parameter FIFO_DEPTH = 32;
   parameter FIFO_CNTW  = 5;
   
   input rst_async;
   input rst_sync;
   input wclk, we;
   input rclk, re;
   input [FIFO_DATW-1:0] din;
   input [FIFO_CNTW-1:0] aempty_val;
   input [FIFO_CNTW-1:0] afull_val;
   
   output [FIFO_DATW-1:0] dout;
   output empty, full;
   output aempty, afull;
   output underf, overf;
   
   // Regs
   reg [FIFO_DATW-1:0] mem[FIFO_DEPTH-1:0];
   reg [FIFO_CNTW:0] wptr_syncr, wptr, wbin, rptr_syncw, rptr, rbin, wbin_syncr, rbin_syncw;
   reg underf, overf;
   
   // wires
   wire empty, full;
   wire [FIFO_CNTW:0] wptr_inc, wbin_inc;
   wire [FIFO_CNTW:0] rptr_inc, rbin_inc;

   wire wena = we & ~full;
   wire rena = re & ~empty;
   // *********************************** Gray Write Pointer ************************************
   always @(posedge wclk or posedge rst_async)
     if (rst_async)     rptr_syncw <= {FIFO_CNTW+1{1'b0}};
     else if (rst_sync) rptr_syncw <= {FIFO_CNTW+1{1'b0}};
     else               rptr_syncw <= rptr;
   
   always @(posedge wclk or posedge rst_async)
     if (rst_async)     rbin_syncw <= {FIFO_CNTW+1{1'b0}};
     else if (rst_sync) rbin_syncw <= {FIFO_CNTW+1{1'b0}};
     else               rbin_syncw <= rbin;

   always @(posedge wclk or posedge rst_async)
     if (rst_async)     wptr <= {FIFO_CNTW+1{1'b0}};
     else if (rst_sync) wptr <= {FIFO_CNTW+1{1'b0}};
     else if (wena)     wptr <= wptr_inc;
     
   always @(posedge wclk or posedge rst_async)
     if (rst_async)     wbin <= {FIFO_CNTW+1{1'b0}};
     else if (rst_sync) wbin <= {FIFO_CNTW+1{1'b0}};
     else if (wena)     wbin <= wbin_inc;

   assign wbin_inc   = wbin + 1;
   assign wptr_inc   = (wbin_inc >> 1) ^ wbin_inc;
   
   // *********************************** Gray Read Pointer ***********************************
   always @(posedge rclk or posedge rst_async)
     if (rst_async)     wptr_syncr <= {FIFO_CNTW+1{1'b0}};
     else if (rst_sync) wptr_syncr <= {FIFO_CNTW+1{1'b0}};
     else               wptr_syncr <= wptr;
    
   always @(posedge rclk or posedge rst_async)
     if (rst_async)     wbin_syncr <= {FIFO_CNTW+1{1'b0}};
     else if (rst_sync) wbin_syncr <= {FIFO_CNTW+1{1'b0}};
     else               wbin_syncr <= wbin;

   always @(posedge rclk or posedge rst_async)
     if (rst_async)     rptr <= {FIFO_CNTW+1{1'b0}};
     else if (rst_sync) rptr <= {FIFO_CNTW+1{1'b0}};
     else if (rena)     rptr <= rptr_inc;
     
   always @(posedge rclk or posedge rst_async)
     if (rst_async)     rbin <= {FIFO_CNTW+1{1'b0}};
     else if (rst_sync) rbin <= {FIFO_CNTW+1{1'b0}};
     else if (rena)     rbin <= rbin_inc;

   assign rbin_inc   = rbin + 1;
   assign rptr_inc   = (rbin_inc >> 1) ^ rbin_inc;

   // ************************************** FULL/EMPTY Logic *********************************
   
   assign empty = ((wptr_syncr[FIFO_CNTW-1:0] == rptr[FIFO_CNTW-1:0]) && (wptr_syncr[FIFO_CNTW] ~^ rptr[FIFO_CNTW]));
   assign full  = ((rptr_syncw[FIFO_CNTW-2:0] == wptr[FIFO_CNTW-2:0]) && (rptr_syncw[FIFO_CNTW] ^ wptr[FIFO_CNTW]) && (rptr_syncw[FIFO_CNTW-1] ^ wptr[FIFO_CNTW-1]));

   assign aempty = (((wbin_syncr[FIFO_CNTW-1:0] - rbin[FIFO_CNTW-1:0]) <= aempty_val) && (wbin_syncr[FIFO_CNTW] ~^ rbin[FIFO_CNTW]))
		   | (((rbin[FIFO_CNTW-1:0] - wbin_syncr[FIFO_CNTW-1:0]) >= (FIFO_DEPTH-aempty_val)) && (wbin_syncr[FIFO_CNTW] ^ rbin[FIFO_CNTW]));

   assign afull  = (((rbin_syncw[FIFO_CNTW-1:0] - wbin[FIFO_CNTW-1:0]) <= afull_val) && (rbin_syncw[FIFO_CNTW] ^ wbin[FIFO_CNTW]))
   		   | (((wbin[FIFO_CNTW-1:0] - rbin_syncw[FIFO_CNTW-1:0]) >= (FIFO_DEPTH-afull_val)) && (rbin_syncw[FIFO_CNTW] ~^ wbin[FIFO_CNTW]));
 
   // ************************************** Overflow/Underflow Logic *********************************

   always @(posedge wclk or posedge rst_async)
   if (rst_async)         overf <= 1'b0;
   else if (rst_sync)     overf <= 1'b0;
	 else if (full && we)   overf <= 1'b1;
  
   always @(posedge rclk or posedge rst_async)
	 if (rst_async)         underf <= 1'b0;
	 else if (rst_sync)     underf <= 1'b0;
	 else if (empty && re) underf <= 1'b1;	 
	
   // *************************************** FIFO MEM ****************************************
   always @(posedge wclk)
    if (wena) mem[wbin[FIFO_CNTW-1:0]] <= din[FIFO_DATW-1:0];

   // fifo output
   assign dout = mem[rbin[FIFO_CNTW-1:0]];
   
endmodule // fifo
