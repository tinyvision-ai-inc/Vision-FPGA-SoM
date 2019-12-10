`timescale 1 ns / 1 ps
module spi_div (/*AUTOARG*/
   // Outputs
   clk_out, hlf_cyc,
   // Inputs
   clk_in, clk_en, clk_run, clk_tog, clk_pol, div_exp, div
   );

   /**************************************************************/
   // PARAMETERS
   /**************************************************************/
   
   parameter DIV_SIZE = 6;  // up to 64 division options on clk_in
   parameter DIV_DEFAULT = {{DIV_SIZE-1{1'b0}}, 1'b1};
   /**************************************************************/
   // INPUTS
   /**************************************************************/
   input     clk_in;         // 2X oscillator clock, 50% duty cycle
   input     clk_en;         // Clock divider enable
   input     clk_run;        // Clock run enable 0 -> pulse
   input     clk_tog;        // Clock Toggle Enable 0 -> Stop Toggle, But div counter keep on running
   input     clk_pol;        // Clock Polority at idle, async glitchy switching
   input     div_exp;        // Expand to divide by 2 if MSB of div is 1
   input [DIV_SIZE-1:0] div; // division option for clk_out, should be generated with rising edge of clk_out
                             // 11111x -> /1		0/1
                             // 111101 -> /1.5		2
                             // 111100 -> /2		3
                             // 111011 -> /2.5		4
                             // 111010 -> /3		5
                             // ......
                             // 100001 -> /15.5	30
                             // 100000 -> /16		31
                             // 011111 -> /17		32
                             // 011101 -> /18		34
                             // 011011 -> /19		36
                             // ......
                             // 000011 -> /31		60
                             // 000001 -> /32		62
                             // 011110 -> /34		33
                             // 011100 -> /36		35
                             // 011010 -> /38		37
                             // ......
                             // 000010 -> /62		61
                             // 000000 -> /64		63

   /**************************************************************/
   // OUTPUTS
   /**************************************************************/
   
   output clk_out;           // the master clock for configuration, SED and/or CIB output
   output hlf_cyc;           // Half Clock Cycle Count.
   
   /**************************************************************/
   // SIGNAL DECLARATIONS
   /**************************************************************/
   wire 		clk_out;                     // 50% duty cycle, glitch free when changing division option
   wire 		cfg_ckb;                     // bufferred CFG_CK as internal clock
   wire [DIV_SIZE:0] 	div_ext_half; // half of DIV_EXT
   wire 		cnt_zero, cnt_half;
   wire 		hlf_cyc;
   
   reg 			cfg_ckp;      // posedge sync'd CFG_CK
   reg 			cfg_ckn;      // negedge sync'd CFG_CK
   reg 			div_even;     // DIV_EXT[0] sync'd with falling edge of cfg_ckp
   reg [DIV_SIZE:0] 	div_cnt;      // count up to 128 cycles of clk_in
   reg [DIV_SIZE:0] 	div_ext;      // convert div to DIV_SIZE bit for div_cnt
   
   /**************************************************************/
   // ASSIGN STATEMENTS
   /**************************************************************/

   // `MUX2 ck_mux (.D0(cfg_ckp | cfg_ckn), .D1(cfg_ckp), .SD(div_even), .Z(clk_out));  // don't touch in synthesis
   // `CKX3 ck_buf (.A(cfg_ckp), .Z(cfg_ckb));                                          // don't touch in synthesis
   
   // assign 		clk_out = (div_even) ? cfg_ckp : (cfg_ckp | cfg_ckn);  // borrow half cycle for divide by odd.
   // assign 		cfg_ckb = cfg_ckp;
   
   wire clk_out_mx;	// replaced rtl mux with tech cell (wmetcalf)
   CKHS_MUX4X2 mux_CTS_even (.z   (clk_out_mx),			// borrow half cycle for divide by odd.
                             .d3  (~cfg_ckp),
			     .d2  (~(cfg_ckp&cfg_ckn)),
			     .d1  (cfg_ckp),
			     .d0  ((cfg_ckp&cfg_ckn)),
                             .sd2 (clk_pol),
			     .sd1 (div_even));
   // (hard instance used so that CTS can be told exactly what pins should be used)
   CKHS_BUFX4 buf_CTS_clk_out
     (.z		(clk_out),
      .a		(clk_out_mx)
      );

   CKHS_BUFX4 buf_CTS_ckb
     (.z		(cfg_ckb),
      .a		(cfg_ckp)
      );
   
   assign 	       div_ext_half = div_ext[DIV_SIZE:1] + 1;  // divide 2 plus 1

   assign 	       cnt_zero = (div_cnt == 0);
   assign 	       cnt_half = (div_cnt == div_ext_half);

   assign hlf_cyc = (cnt_zero | cnt_half);
   
   /**************************************************************/
   // MAIN CODE
   /**************************************************************/
   wire div_by2_adj = div_exp & div[DIV_SIZE-1];
   always @(/*AUTOSENSE*/div or div_by2_adj or div_exp) begin
      if      (div == 0)    div_ext = div_exp ? {DIV_DEFAULT, 1'b1} : {1'b0, DIV_DEFAULT};
      else if (div_by2_adj) div_ext = (div[0]) ? {div[DIV_SIZE-1:0], 1'b1} : {1'b0, div[DIV_SIZE-1:1], 1'b1};
      else                  div_ext = {1'b0, div};
   end
   
   always @(negedge cfg_ckb or negedge clk_en)  // must be falling clock edge
     if (!clk_en) div_even <= 1'b1;             // divide by 64 by default
     else         div_even <= div_ext[0];       // odd binary number == divide by even

   always @(negedge clk_in or negedge clk_en)
     if (!clk_en) cfg_ckn <= 1'b0;
     else         cfg_ckn <= cfg_ckp;      // half cycle later

   always @(posedge clk_in or negedge clk_en)
     if (!clk_en)                 cfg_ckp <= 1'b0;
     else if (cnt_zero & clk_tog) cfg_ckp <= 1'b0;
     else if (cnt_half & clk_tog) cfg_ckp <= 1'b1;
   
   always @(posedge clk_in or negedge clk_en)
     if (!clk_en)       div_cnt <= {DIV_SIZE+1{1'b0}};
     else if (cnt_zero) div_cnt <= div_ext;     // count by 2 and up to 128 (default)
     else if (clk_run)  div_cnt <= div_cnt - 1;
   
endmodule // spi_div
