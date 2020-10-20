// This module implements a simple servo compatible PWM output with 256 positions

/* Input: 8 bit position
   Output: 50Hz PWM, 1ms maps to 0, 2ms maps to 255
*/

module servo
#(
    // Declare the clock frequency to get the 50Hz update rate
    parameter CLK_FREQUENCY = 12000000
)
(
    input logic clk,
    input logic rst,
    input logic [7:0] pos,
    output logic pwm
);

    localparam CLK_COUNT = CLK_FREQUENCY/(256*1000);

    // Design consists of a 256*50Hz generator followed by a simple comparator
    logic [7:0] clk_ctr;
    logic tick;

    // Generate pulses every 1/(256) of a ms for sufficient resolution
    always @(posedge clk) tick <= (clk_ctr == CLK_COUNT-2);

    always @(posedge clk) 
    if (rst | tick)
        clk_ctr <= '0;
    else
        clk_ctr <= clk_ctr + 'd1;

    // PWM counter
    logic [11:0] pwm_ctr;
    always @(posedge clk)
    if (rst)
        pwm_ctr <= '0;
    else if (tick)
        pwm_ctr <= pwm_ctr + 'd1;

    // Generate PWM output
    always @(posedge clk)
        pwm <= (pwm_ctr < {4'b0001, pos});    

endmodule