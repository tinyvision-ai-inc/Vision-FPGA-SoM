`timescale 1ns/1ps
module LED_control (
        // inputs
        input   wire        clk27M,        // 27M clock
        input   wire        rst,           // async reset
        input   wire        params_ok,     // sample parameters on rising edge
        input   wire  [3:0] RGB_color,     // 
        input   wire  [3:0] Brightness,    // 
        input   wire  [3:0] BreatheRamp,   // 
        input   wire  [3:0] BlinkRate,     // 
        
        output  reg         red_pwm,       // Red
        output  reg         grn_pwm,       // Blue
        output  reg         blu_pwm        // Green
        );


//----------------------------------------------------------------------------
//                                                                          --
//                       ARCHITECTURE DEFINITION                            --
//                                                                          --
//----------------------------------------------------------------------------
//------------------------------
// INTERNAL SIGNAL DECLARATIONS: 
//------------------------------
// parameters (constants)
parameter     on_hi = 2'b10;
parameter     on_lo = 2'b01;
parameter     off   = 2'b00; 

parameter     LED_OFF   = 2'b00;
parameter     RAMP_UP   = 2'b01;
parameter     LED_ON    = 2'b10;
parameter     RAMP_DOWN = 2'b11;

parameter     on_max_cnt  = 22'h008000;  // 1 sec steady


// wires (assigns)   
wire   [4:0] red_intensity;
wire   [4:0] grn_intensity;
wire   [4:0] blu_intensity;


// regs (always)
reg     [9:0] clk_div_cnt;      // 
reg           clk32K;

reg           params_ok_d1;
reg           params_ok_d2;
reg           update;
reg     [3:0] RGB_color_s;    // sample values from SPI i/f      
reg     [3:0] Brightness_s;        
reg     [3:0] BreatheRamp_s;       
reg     [3:0] BlinkRate_s;         

reg     [1:0] red_set;		  // hi/lo/off
reg     [1:0] grn_set;		  
reg     [1:0] blu_set;		  

reg    [21:0] red_peak;		  // LED 'on' peak intensity (high precision)
reg    [21:0] grn_peak;
reg    [21:0] blu_peak;

reg    [21:0] off_max_cnt;  // LED off duration
reg     [3:0] step_shift;      // scaling calculation aid

reg    [19:0] ramp_max_cnt;			// LED ramp up/down duration
reg    [23:0] red_intensity_step;	// LED intensity step when ramping
reg    [23:0] grn_intensity_step;
reg    [23:0] blu_intensity_step;

reg     [1:0] blink_state;          // state variable
reg    [19:0] ramp_count;			// counter for LED on/off duration
reg    [17:0] steady_count;		    // counter for LED ramp up/down duration

reg    [21:0] red_accum;			// intensity accumulator during ramp
reg    [21:0] grn_accum;
reg    [21:0] blu_accum;

reg     [8:0] curr_red;				// current LED intensity ( /256 = PWM duty cycle)
reg     [8:0] curr_grn;
reg     [8:0] curr_blu;

reg     [8:0] pwm_count;            // PWM counter

//-------------------------------------//
//---- always (process) operations ----//
//-------------------------------------//


//   Clock divider 
//   divides 27MHz to 32.768kHz
//   (basic PWM cycle)
always @ (posedge clk27M or posedge rst)
    if (rst) begin
      clk_div_cnt  <= 0;
      clk32K  <= 0;
    end else begin    
//        if (clk_div_cnt >= (10'd0)) begin // for sim only
        if (clk_div_cnt >= (10'd411)) begin
            clk_div_cnt <= 0;
            clk32K <= ~clk32K;
        end else begin                       
            clk_div_cnt <= clk_div_cnt + 1;
        end
    end

//  Capture low CS pulse (faster than 32K clock)
always @ (posedge clk32K or negedge params_ok)
    if (!params_ok) begin
        params_ok_d1        <= 0;
    end else begin    
        params_ok_d1 <= params_ok;
    end

//   Capture stable parameters in local clock domain
always @ (posedge clk32K or posedge rst)
    if (rst) begin
      params_ok_d2        <= 0;
      update        <= 0;
      RGB_color_s   <= 4'b0000; 
      Brightness_s  <= 4'b0111;
      BreatheRamp_s <= 4'b0000;
      BlinkRate_s   <= 4'b0101;
    end else begin    
        params_ok_d2 <= params_ok_d1;
        update <= params_ok_d1 && !params_ok_d2;
        if (update) begin  // rising edge
          RGB_color_s   <= RGB_color   ;
          Brightness_s  <= Brightness  ;
          BreatheRamp_s <= BreatheRamp ;
          BlinkRate_s   <= BlinkRate   ;
        end
    end

// interpret 'brightness' setting
assign red_intensity = Brightness_s + 1'b1;
assign grn_intensity = Brightness_s + 1'b1;
assign blu_intensity = Brightness_s + 1'b1;

// interpret 'color' setting
always @ (RGB_color_s)	 
  case (RGB_color_s)
    4'b0000:   begin red_set   <= on_hi; grn_set   <= off;   blu_set   <= off;   end //Red
    4'b0001:   begin red_set   <= on_hi; grn_set   <= on_lo; blu_set   <= off;   end //Orange
    4'b0010:   begin red_set   <= on_hi; grn_set   <= on_hi; blu_set   <= off;   end //Yellow
    4'b0011:   begin red_set   <= on_lo; grn_set   <= on_hi; blu_set   <= off;   end //Chartreuse
    4'b0100:   begin red_set   <= off;   grn_set   <= on_hi; blu_set   <= off;   end //Green
    4'b0101:   begin red_set   <= off;   grn_set   <= on_hi; blu_set   <= on_lo; end //SpringGreen
    4'b0110:   begin red_set   <= off;   grn_set   <= on_hi; blu_set   <= on_hi; end //Cyan
    4'b0111:   begin red_set   <= off;   grn_set   <= on_lo; blu_set   <= on_hi; end //Azure
    4'b1000:   begin red_set   <= off;   grn_set   <= off;   blu_set   <= on_hi; end //Blue
    4'b1001:   begin red_set   <= on_lo; grn_set   <= off;   blu_set   <= on_hi; end //Violet
    4'b1010:   begin red_set   <= on_hi; grn_set   <= off;   blu_set   <= on_hi; end //Magenta
    4'b1011:   begin red_set   <= on_hi; grn_set   <= off;   blu_set   <= on_lo; end //Rose
    4'b1111:   begin red_set   <= on_hi; grn_set   <= on_hi; blu_set   <= on_hi; end //White
    default: begin red_set   <= off;   grn_set   <= off;   blu_set   <= off;   end //off
  endcase

// set peak values per 'brightness' and 'color'
//   when color setting is 'on_lo', then peak intensity is divided by 2
always @ (posedge clk32K or posedge rst)
    if (rst) begin
      red_peak <= 22'b0;
    end else begin
      case (red_set)
        on_hi:  red_peak <= {red_intensity, 17'h000};       // 100%
        on_lo:  red_peak <= {1'b0, red_intensity, 16'h000}; // 50%
        default: red_peak <= 22'h00000;
      endcase
    end
    
always @ (posedge clk32K or posedge rst)
    if (rst) begin
      grn_peak <= 22'b0;
    end else begin
      case (grn_set)
        on_hi:  grn_peak <= {grn_intensity, 17'h000};       // 100%
        on_lo:  grn_peak <= {1'b0, grn_intensity, 16'h000}; // 50%
        default: grn_peak <= 22'h00000;
      endcase
    end
  
always @ (posedge clk32K or posedge rst)
    if (rst) begin
      blu_peak <= 22'b0;
    end else begin
      case (blu_set)
        on_hi:  blu_peak <= {blu_intensity, 17'h000};       // 100%
        on_lo:  blu_peak <= {1'b0, blu_intensity, 16'h000}; // 50%
        default: blu_peak <= 22'h00000;
      endcase
    end
  
// interpret 'Blink rate' setting
//   'off_max_cnt' is time spent in 'LED_OFF' states
//   'step_shift' is used to scale the intensity step size.
//   Stated period is blink rate with no ramp.  Ramping adds to the period.
always @ (posedge clk32K or posedge rst)
    if (rst) begin
      off_max_cnt <= 22'h0 - 1;
      step_shift     <=  4'b0;
    end else begin
      case (BlinkRate_s)
        4'b0001:   begin off_max_cnt   <= 22'h000800; end // 1/16sec
        4'b0010:   begin off_max_cnt   <= 22'h001000; end // 1/8 sec
        4'b0011:   begin off_max_cnt   <= 22'h002000; end // 1/4 sec
        4'b0100:   begin off_max_cnt   <= 22'h004000; end // 1/2 sec
        4'b0101:   begin off_max_cnt   <= 22'h008000; end // 1 sec
        4'b0110:   begin off_max_cnt   <= 22'h010000; end // 2 sec
        4'b0111:   begin off_max_cnt   <= 22'h020000; end // 4 sec

        default: begin off_max_cnt   <= 22'h0; end //
      endcase
    end


// interpret 'Breathe Ramp' setting
//     'ramp_max_cnt' is time spent in 'RAMP_UP', RAMP_DOWN' states
//     '***_intensity_step' is calculated to add to color accumulators each ramp step
always @ (posedge clk32K or posedge rst)
    if (rst) begin
      ramp_max_cnt        <= 20'b0;
      red_intensity_step  <= 24'b0;
      grn_intensity_step  <= 24'b0;
      blu_intensity_step  <= 24'b0;
    end else begin
      case (BreatheRamp_s)
        4'b0001: begin
                ramp_max_cnt   <= 20'h00400;  // 1/16sec
                red_intensity_step  <= red_peak >> (10) ;
                grn_intensity_step  <= grn_peak >> (10) ;
                blu_intensity_step  <= blu_peak >> (10) ;
              end                 
        4'b0010: begin
                ramp_max_cnt   <= 20'h00800;  // 1/8 sec
                red_intensity_step  <= red_peak >> (11) ;
                grn_intensity_step  <= grn_peak >> (11) ;
                blu_intensity_step  <= blu_peak >> (11) ;                 
              end                 
        4'b0011: begin
                ramp_max_cnt   <= 20'h01000;  // 1/4 sec
                red_intensity_step  <= red_peak >> (12) ;
                grn_intensity_step  <= grn_peak >> (12) ;
                blu_intensity_step  <= blu_peak >> (12) ;                 
              end                 
        4'b0100: begin
                ramp_max_cnt   <= 20'h02000;  // 1/2 sec
                red_intensity_step  <= red_peak >> (13) ;
                grn_intensity_step  <= grn_peak >> (13) ;
                blu_intensity_step  <= blu_peak >> (13) ;                 
              end                 
        4'b0101: begin
                ramp_max_cnt   <= 20'h04000;     // 1 sec
                red_intensity_step  <= red_peak >> (14) ;			// 15
                grn_intensity_step  <= grn_peak >> (14) ;
                blu_intensity_step  <= blu_peak >> (14) ;                 
              end                 
        4'b0110: begin
                ramp_max_cnt   <= 20'h08000;  // 2 sec
                red_intensity_step  <= red_peak >> (15) ;
                grn_intensity_step  <= grn_peak >> (15) ;
                blu_intensity_step  <= blu_peak >> (15) ;                 
              end                 
        4'b0111: begin
                ramp_max_cnt   <= 20'h10000;  // 4 sec
                red_intensity_step  <= red_peak >> (16) ;
                grn_intensity_step  <= grn_peak >> (16) ;
                blu_intensity_step  <= blu_peak >> (16) ;                 
              end                 
        default: begin
                ramp_max_cnt        <= 20'd0; //
                red_intensity_step  <= 24'b0;
                grn_intensity_step  <= 24'b0;
                blu_intensity_step  <= 24'b0;
              end                 
      endcase
    end

//  state machine to create LED ON/OFF/RAMP periods
//   state machine is held (no cycles) if LED is steady state on/off
//   state machine is reset to LED_ON state whenever parameters are updated.
always @ (posedge clk32K or posedge rst)
    if (rst) begin
      blink_state <= LED_OFF;
      ramp_count   <= 20'b0;
      steady_count <= 18'b0;
    end else begin
      if(BlinkRate_s == 4'b0000) begin
        blink_state <= LED_ON;
        ramp_count   <= 0;
        steady_count <= 0;
      end else if (BlinkRate_s == 4'b1000) begin
        blink_state <= LED_OFF;
        ramp_count   <= 0;
        steady_count <= 0;
      end else if (update) begin
        blink_state <= LED_ON;
        ramp_count   <= 0;
        steady_count <= 0;
      end else begin
        case (blink_state)
          LED_OFF:  begin
                      if(steady_count >= off_max_cnt) begin
                        ramp_count   <= 0;
                        steady_count <= 0;
                        blink_state <= RAMP_UP;
                      end else begin
                        steady_count <= steady_count + 1;
                      end
                    end
          RAMP_UP:  begin
                      if(ramp_count >= ramp_max_cnt) begin
                        ramp_count   <= 0;
                        steady_count <= 0;
                        blink_state <= LED_ON;
                      end else begin
                        ramp_count <= ramp_count + 1;
                      end
                    end
          LED_ON:  begin
                      if(steady_count >= on_max_cnt) begin
                        ramp_count   <= 0;
                        steady_count <= 0;
                        blink_state <= RAMP_DOWN;
                      end else begin
                        steady_count <= steady_count + 1;
                      end
                    end
          RAMP_DOWN:  begin
                      if(ramp_count >= ramp_max_cnt) begin
                        ramp_count   <= 0;
                        steady_count <= 0;
                        blink_state <= LED_OFF;
                      end else begin
                        ramp_count <= ramp_count + 1;
                      end
                    end
          default:  begin
                      blink_state <= LED_OFF;
                      ramp_count   <= 20'b0;
                      steady_count <= 18'b0;
                    end
        endcase
      end
    end


// RampUP/DN accumulators
always @ (posedge clk32K or posedge rst)
    if (rst) begin
      red_accum <= 22'b0;
      grn_accum <= 22'b0;
      blu_accum <= 22'b0;
    end else begin
      case (blink_state)
        LED_OFF:  begin
                    red_accum <= 0;
                    grn_accum <= 0;
                    blu_accum <= 0;
                  end
        LED_ON:   begin
//                    red_accum <= red_accum;
//                    grn_accum <= grn_accum;
//                    blu_accum <= blu_accum;
                    red_accum <= red_peak;
                    grn_accum <= grn_peak;
                    blu_accum <= blu_peak;
                  end
        RAMP_UP:  begin
                    red_accum <= red_accum + red_intensity_step;
                    grn_accum <= grn_accum + grn_intensity_step;
                    blu_accum <= blu_accum + blu_intensity_step;
                  end
        RAMP_DOWN: begin
                    red_accum <= red_accum - red_intensity_step;
                    grn_accum <= grn_accum - grn_intensity_step;
                    blu_accum <= blu_accum - blu_intensity_step;
                  end
        default: begin
                    red_accum <= 0;
                    grn_accum <= 0;
                    blu_accum <= 0;
                  end
      endcase
    end


// set PWM duty cycle. 8-bit resolution 0x100 is 100% on
always @ (posedge clk32K or posedge rst)
    if (rst) begin
      curr_red <= 9'b0;
      curr_grn <= 9'b0;
      curr_blu <= 9'b0;
    end else begin
      case (blink_state)
        LED_ON: begin
                    curr_red <= red_peak[21:13]; // there should be no discrepancy between _peak and _accum in this state
                    curr_grn <= grn_peak[21:13];
                    curr_blu <= blu_peak[21:13];
                  end
        RAMP_UP: begin
                    curr_red <= red_accum[21:13];
                    curr_grn <= grn_accum[21:13];
                    curr_blu <= blu_accum[21:13];
                  end
        RAMP_DOWN: begin
                    curr_red <= red_accum[21:13];
                    curr_grn <= grn_accum[21:13];
                    curr_blu <= blu_accum[21:13];
                  end
        LED_OFF: begin
                    curr_red <= 0;
                    curr_grn <= 0;
                    curr_blu <= 0;
                  end
        default: begin
                    curr_red <= 0;
                    curr_grn <= 0;
                    curr_blu <= 0;
                  end
      endcase
    end

// generate PWM outputs
always @ (posedge clk32K or posedge rst)
    if (rst) begin
      pwm_count <= 9'b0;
      red_pwm   <= 0;
      grn_pwm   <= 0;
      blu_pwm   <= 0;
    end else begin
      if(pwm_count < 255)
        pwm_count <= pwm_count + 1;
      else
        pwm_count <= 0;
      
      if(pwm_count < curr_red)
        red_pwm <= 1;
      else
        red_pwm <= 0;

      if(pwm_count < curr_grn)
        grn_pwm <= 1;
      else
        grn_pwm <= 0;

      if(pwm_count < curr_blu)
        blu_pwm <= 1;
      else
        blu_pwm <= 0;  
		
    end





endmodule
