`timescale 1ps/100fs
module X109T001 (
  VDDA,
  VSSA,
  VDD,
  VSS,
  PD,
  TST,
  CN,
  CM,
  CO,
  CLKREF,
  OUTP,
  OUTN,
  LOCK
  );
////////////////////////////////////////////////////////////////////////////
parameter T_LOCK = 30000000;

input VDDA;
input VSSA;
input VDD;
input VSS;
input PD;	       // Power Down, active high
input [3:0] TST;		
input [4:0]CN;		// Control N divider
input [7:0]CM;		// Control M divider
input [1:0]CO;		// Control O divider
input CLKREF;		// Reference clock input
output OUTP;		// Output clock
output OUTN;		// Output clock
output LOCK;		// Lock detection. When high, the PLL has achieved
			        //   frequency lock.
////////////////////////////////////////////////////////////////////////////

//wire [4:0] L_RCN;
//wire [7:0] L_RCM;
//wire [1:0] L_RCO;
//wire [4:0] RCN;
//wire [7:0] RCM;
//wire [1:0] RCO;
reg LOCK;
reg OUTA;
reg OUT;

reg freq_change;
reg refclk_change;
reg freq_LOCK;
reg [7:0] ref_cnt;
reg lock_ready;
reg phase_LOCK;
reg [7:0] oa_cnt, ob_cnt;
wire freq_pre_LOCK;

real delay_out;
integer i, j, k;
real stime;
real prev_stime;
real delta;
real prev_delta;
real b[63:0];
integer N, M, O;
//integer OA, OB;
real sum;
real L_sum, L2_sum, L3_sum;

// latches the control input at the rising edge of the signal LD.
initial begin
//  RCN = 6'b111111;
//  RCM = 6'b111111;
//  RCOA = 5'b11111;
//  RCOB = 5'b11111;
//  L_RCN = 5'b11111;
//  L_RCM = 8'b11111111;
//  L_RCO = 2'b11;
  freq_change = 1'b0;
  end
 assign COAST =1'b0;
//always @(posedge LD) begin
//  assign RCN = {CN4, CN3, CN2, CN1, CN0};
//  assign RCM = {CM7, CM6, CM5, CM4, CM3, CM2, CM1, CM0};
//  assign RCO = {CO1, CO0};
//  end

//always @(posedge CLKREF) begin
// assign L_RCN = {CN4, CN3, CN2, CN1, CN0};
// assign L_RCM = {CM7, CM6, CM5, CM4, CM3, CM2, CM1, CM0};
// assign L_RCO  = {CO1, CO0};
 // end

always @(posedge CLKREF) begin
 // if ((L_RCN != RCN) || (L_RCM != RCM) || 
  //    (L_RCO != RCO) || refclk_change) freq_change = 1'b1;
  if (refclk_change) freq_change = 1'b1;
  else freq_change = 1'b0;
  end

// decoder for N, M, and O.
always @(CN) begin
  case (CN)
    5'b11111:	N = 	1;
    5'b00000: N = 	2;
    5'b00001:	N = 	3;
    5'b00011:	N = 	4;
    5'b00111:	N = 	5;
    5'b01110:	N = 	6;
    5'b11100:	N = 	7;
    5'b11001:	N = 	8;
    5'b10010:	N = 	9;
    5'b00100:	N = 	10;
    5'b01000:	N = 	11;
    5'b10001:	N = 	12;
    5'b00010:	N = 	13;
    5'b00101:	N = 	14;
    5'b01010:	N = 	15;
    5'b10101:	N = 	16;
    5'b01011:	N = 	17;
    5'b10111:	N = 	18;
    5'b01111:	N = 	19;
    5'b11110:	N = 	20;
    5'b11101:	N = 	21;
    5'b11011:	N = 	22;
    5'b10110:	N = 	23;
    5'b01101:	N = 	24;
    5'b11010:	N = 	25;
    5'b10100:	N = 	26;
    5'b01001:	N = 	27;
    5'b10011:	N = 	28;
    5'b00110:	N = 	29;
    5'b01100:	N = 	30;
    5'b11000:	N = 	31;
    5'b10000:	N = 	32;

  endcase
  end

always @(CM) begin
  case (CM)
    8'b11110000: M	 =	16;
    8'b11110001: M	 =	17;
    8'b11110010: M	 =	18;
    8'b11110011: M	 =	19;
    8'b11110100: M	 =	20;
    8'b11110101: M	 =	21;
    8'b11110110: M	 =	22;
    8'b11110111: M	 =	23;
    8'b11111000: M	 =	24;
    8'b11111001: M	 =	25;
    8'b11111010: M	 =	26;
    8'b11111011: M	 =	27;
    8'b11111100: M	 =	28;
    8'b11111101: M	 =	29;
    8'b11111110: M	 =	30;
    8'b11111111: M	 =	31;
    8'b11100000: M	 =	16;
    8'b11100001: M	 =	17;
    8'b11100010: M	 =	18;
    8'b11100011: M	 =	19;
    8'b11100100: M	 =	20;
    8'b11100101: M	 =	21;
    8'b11100110: M	 =	22;
    8'b11100111: M	 =	23;
    8'b11101000: M	 =	24;
    8'b11101001: M	 =	25;
    8'b11101010: M	 =	26;
    8'b11101011: M	 =	27;
    8'b11101100: M	 =	28;
    8'b11101101: M	 =	29;
    8'b11101110: M	 =	30;
    8'b11101111: M	 =	31;
    8'b11000000: M	 =	32;
    8'b11000001: M	 =	33;
    8'b11000010: M	 =	34;
    8'b11000011: M	 =	35;
    8'b11000100: M	 =	36;
    8'b11000101: M	 =	37;
    8'b11000110: M	 =	38;
    8'b11000111: M	 =	39;
    8'b11001000: M	 =	40;
    8'b11001001: M	 =	41;
    8'b11001010: M	 =	42;

    8'b11001011: M	 =	43;
    8'b11001100: M	 =	44;
    8'b11001101: M	 =	45;
    8'b11001110: M	 =	46;
    8'b11001111: M	 =	47;
    8'b11010000: M	 =	48;
    8'b11010001: M	 =	49;
    8'b11010010: M	 =	50;
    8'b11010011: M	 =	51;
    8'b11010100: M	 =	52;
    8'b11010101: M	 =	53;
    8'b11010110: M	 =	54;
    8'b11010111: M	 =	55;
    8'b11011000: M	 =	56;
    8'b11011001: M	 =	57;
    8'b11011010: M	 =	58;
    8'b11011011: M	 =	59;
    8'b11011100: M	 =	60;
    8'b11011101: M	 =	61;
    8'b11011110: M	 =	62;
    8'b11011111: M	 =	63;
    8'b10000000: M	 =	64;
    8'b10000001: M	 =	65;
    8'b10000010: M	 =	66;
    8'b10000011: M	 =	67;
    8'b10000100: M	 =	68;
    8'b10000101: M	 =	69;
    8'b10000110: M	 =	70;
    8'b10000111: M	 =	71;
    8'b10001000: M	 =	72;
    8'b10001001: M	 =	73;
    8'b10001010: M	 =	74;
    8'b10001011: M	 =	75;
    8'b10001100: M	 =	76;
    8'b10001101: M	 =	77;
    8'b10001110: M	 =	78;
    8'b10001111: M	 =	79;
    8'b10010000: M	 =	80;
    8'b10010001: M	 =	81;
    8'b10010010: M	 =	82;
    8'b10010011: M	 =	83;
    8'b10010100: M	 =	84;
    8'b10010101: M	 =	85;

    8'b10010110: M	 =	86;
    8'b10010111: M	 =	87;
    8'b10011000: M	 =	88;
    8'b10011001: M	 =	89;
    8'b10011010: M	 =	90;
    8'b10011011: M	 =	91;
    8'b10011100: M	 =	92;
    8'b10011101: M	 =	93;
    8'b10011110: M	 =	94;
    8'b10011111: M	 =	95;
    8'b10100000: M	 =	96;
    8'b10100001: M	 =	97;
    8'b10100010: M	 =	98;
    8'b10100011: M	 =	99;
    8'b10100100: M	 =	100;
    8'b10100101: M	 =	101;
    8'b10100110: M	 =	102;
    8'b10100111: M	 =	103;
    8'b10101000: M	 =	104;
    8'b10101001: M	 =	105;
    8'b10101010: M	 =	106;
    8'b10101011: M	 =	107;
    8'b10101100: M	 =	108;
    8'b10101101: M	 =	109;
    8'b10101110: M	 =	110;
    8'b10101111: M	 =	111;
    8'b10110000: M	 =	112;
    8'b10110001: M	 =	113;
    8'b10110010: M	 =	114;
    8'b10110011: M	 =	115;
    8'b10110100: M	 =	116;
    8'b10110101: M	 =	117;
    8'b10110110: M	 =	118;
    8'b10110111: M	 =	119;
    8'b10111000: M	 =	120;
    8'b10111001: M	 =	121;
    8'b10111010: M	 =	122;
    8'b10111011: M	 =	123;
    8'b10111100: M	 =	124;
    8'b10111101: M	 =	125;
    8'b10111110: M	 =	126;
    8'b10111111: M	 =	127;
    8'b00000000: M	 =	128;
    8'b00000001: M	 =	129;
    8'b00000010: M	 =	130;
    8'b00000011: M	 =	131;
    8'b00000100: M	 =	132;
    8'b00000101: M	 =	133;
    8'b00000110: M	 =	134;
    8'b00000111: M	 =	135;
    8'b00001000: M	 =	136;
    8'b00001001: M	 =	137;
    8'b00001010: M	 =	138;
    8'b00001011: M	 =	139;
    8'b00001100: M	 =	140;
    8'b00001101: M	 =	141;
    8'b00001110: M	 =	142;
    8'b00001111: M	 =	143;
    8'b00010000: M	 =	144;
    8'b00010001: M	 =	145;
    8'b00010010: M	 =	146;
    8'b00010011: M	 =	147;
    8'b00010100: M	 =	148;
    8'b00010101: M	 =	149;
    8'b00010110: M	 =	150;
    8'b00010111: M	 =	151;
    8'b00011000: M	 =	152;
    8'b00011001: M	 =	153;
    8'b00011010: M	 =	154;
    8'b00011011: M	 =	155;
    8'b00011100: M	 =	156;
    8'b00011101: M	 =	157;
    8'b00011110: M	 =	158;
    8'b00011111: M	 =	159;
    8'b00100000: M	 =	160;
    8'b00100001: M	 =	161;
    8'b00100010: M	 =	162;
    8'b00100011: M	 =	163;
    8'b00100100: M	 =	164;
    8'b00100101: M	 =	165;
    8'b00100110: M	 =	166;
    8'b00100111: M	 =	167;
    8'b00101000: M	 =	168;
    8'b00101001: M	 =	169;
    8'b00101010: M	 =	170;
    8'b00101011: M	 =	171;

    8'b00101100: M	 =	172;
    8'b00101101: M	 =	173;
    8'b00101110: M	 =	174;
    8'b00101111: M	 =	175;
    8'b00110000: M	 =	176;
    8'b00110001: M	 =	177;
    8'b00110010: M	 =	178;
    8'b00110011: M	 =	179;
    8'b00110100: M	 =	180;
    8'b00110101: M	 =	181;
    8'b00110110: M	 =	182;
    8'b00110111: M	 =	183;
    8'b00111000: M	 =	184;
    8'b00111001: M	 =	185;
    8'b00111010: M	 =	186;
    8'b00111011: M	 =	187;
    8'b00111100: M	 =	188;
    8'b00111101: M	 =	189;
    8'b00111110: M	 =	190;
    8'b00111111: M	 =	191;
    8'b01000000: M	 =	192;
    8'b01000001: M	 =	193;
    8'b01000010: M	 =	194;
    8'b01000011: M	 =	195;
    8'b01000100: M	 =	196;
    8'b01000101: M	 =	197;
    8'b01000110: M	 =	198;
    8'b01000111: M	 =	199;
    8'b01001000: M	 =	200;
    8'b01001001: M	 =	201;
    8'b01001010: M	 =	202;
    8'b01001011: M	 =	203;
    8'b01001100: M	 =	204;
    8'b01001101: M	 =	205;
    8'b01001110: M	 =	206;
    8'b01001111: M	 =	207;
    8'b01010000: M	 =	208;
    8'b01010001: M	 =	209;
    8'b01010010: M	 =	210;
    8'b01010011: M	 =	211;
    8'b01010100: M	 =	212;
    8'b01010101: M	 =	213;
    8'b01010110: M	 =	214;

    8'b01010111: M	 =	215;
    8'b01011000: M	 =	216;
    8'b01011001: M	 =	217;
    8'b01011010: M	 =	218;
    8'b01011011: M	 =	219;
    8'b01011100: M	 =	220;
    8'b01011101: M	 =	221;
    8'b01011110: M	 =	222;
    8'b01011111: M	 =	223;
    8'b01100000: M	 =	224;
    8'b01100001: M	 =	225;
    8'b01100010: M	 =	226;
    8'b01100011: M	 =	227;
    8'b01100100: M	 =	228;
    8'b01100101: M	 =	229;
    8'b01100110: M	 =	230;
    8'b01100111: M	 =	231;
    8'b01101000: M	 =	232;
    8'b01101001: M	 =	233;
    8'b01101010: M	 =	234;
    8'b01101011: M	 =	235;
    8'b01101100: M	 =	236;
    8'b01101101: M	 =	237;
    8'b01101110: M	 =	238;
    8'b01101111: M	 =	239;
    8'b01110000: M	 =	240;
    8'b01110001: M	 =	241;
    8'b01110010: M	 =	242;
    8'b01110011: M	 =	243;
    8'b01110100: M	 =	244;
    8'b01110101: M	 =	245;
    8'b01110110: M	 =	246;
    8'b01110111: M	 =	247;
    8'b01111000: M	 =	248;
    8'b01111001: M	 =	249;
    8'b01111010: M	 =	250;
    8'b01111011: M	 =	251;
    8'b01111100: M	 =	252;
    8'b01111101: M	 =	253;
    8'b01111110: M	 =	254;
    8'b01111111: M	 =	255;

  endcase
  end

always @(CO) begin
  case (CO)
    2'b00: O = 1;
    2'b01: O = 2;
    2'b10: O = 4;
    2'b11: O = 8;
  endcase
  end


// frequency calculation
initial begin
  for (i=0; i<64; i=i+1) b[i] = 100000;
  prev_stime = 0;
  k = 0;
  end

always @(posedge CLKREF) begin
  stime = $time;
  delta = (stime - prev_stime);
  if (PD | freq_change) begin
    for (i=0; i<64; i=i+1) b[i] = 100000;
    end
  else b[k] = delta;
  prev_stime = stime;
  if ((COAST | LOCK) & (delta != prev_delta)) refclk_change = 1;
  else refclk_change = 0;
  prev_delta = delta;
  if (k < 63) k = k + 1;
  else k = 0;
  end


always @(posedge CLKREF) begin
  if (~freq_LOCK & freq_pre_LOCK) ref_cnt <= 0;
  else if (ref_cnt < N-1) ref_cnt <= ref_cnt + 1'b1;
  else ref_cnt <= 0;
  end


always @(posedge CLKREF) begin
  if (PD | freq_change) begin
    delay_out  = 100000;
    end
  else if (~COAST) begin
    sum = 0;
    for(j=0; j<64; j=j+1) sum = sum + b[j];
    delay_out  = (sum * N )/(M * 128); //VCO clock period divide by 2
    end
  end

// Lock detection

initial begin
  sum = 0;
  L_sum = 0;
  L2_sum = 0;
  L3_sum = 0;
  end

always @(posedge CLKREF) begin
  L_sum <= sum;
  L2_sum <= L_sum;
  L3_sum <= L2_sum;
  end

assign freq_pre_LOCK = ~COAST & (PD == 1'b0) &
              (sum != 6400000) & (sum != 0) &
              (sum == L_sum) & (sum == L2_sum) & (sum == L3_sum);

always @(posedge OUT) begin
  freq_LOCK <= freq_pre_LOCK;
  end

// PLL output
initial begin
  OUT = 1'b0;
  LOCK = 1'b0;
  phase_LOCK = 1'b0;
  freq_LOCK = 1'b0;
  end

always @(posedge CLKREF) begin
  LOCK = phase_LOCK & lock_ready;
  if (PD) begin
    OUT = 1'b0;
    phase_LOCK = 1'b0;
    end
  else if (freq_LOCK) begin
    OUT = ~OUT & ~PD;
      #(delay_out);
    for(i = 0; i < 2*(M-1); i=i+1) begin
      OUT = ~OUT & ~PD;
      #(delay_out);
      end
    OUT = ~OUT & ~PD;
    phase_LOCK = ~COAST;
    end
  else begin
    phase_LOCK = 1'b0;
    while (~freq_LOCK) begin
      OUT = ~OUT & ~PD;
      #(delay_out);
      end
    OUT = 1'b0;
    while (ref_cnt != 0) #(delay_out);
    end
  end

// divider output phase counters
initial begin
  oa_cnt = 8'h00;
  end

always @(posedge OUT) begin
  if (~freq_LOCK & freq_pre_LOCK) oa_cnt <= 8'h00;
  else if (oa_cnt >= (O - 1)) oa_cnt <= 8'h00;
  else oa_cnt <= oa_cnt + 1'b1;

  end

// divider output OUTA
initial begin
  OUTA = 1'b0;
  forever begin
    if (PD) begin
      @(posedge CLKREF);
      OUTA = 1'b0;
      end
    else if (O == 1) begin
      @(posedge OUT or posedge PD);
      OUTA = ~PD;
      #(delay_out);
      OUTA = 1'b0;
      end
    else begin
      @(posedge OUT or posedge PD);
      if (oa_cnt == 8'h00) OUTA = ~PD;	// one pulse every OA cycles
      else OUTA = 1'b0;
      end
    end
  end

assign OUTP = OUTA;
assign OUTN = ~OUTA;

// PLL lock ready
initial begin
  lock_ready = 0;
  end
 
always @(COAST or freq_change) begin
  if (~COAST & ~freq_change) begin
    #(T_LOCK);
    lock_ready = 1'b1;
    end
  else begin
    lock_ready = 1'b0;
    end
  end
  
  
endmodule // X102T001
