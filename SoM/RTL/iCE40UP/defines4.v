`ifndef LEDCB_DEFINES_V
 `define LEDCB_DEFINES_V

`define LEDCBDW   8                    // LED Control Bus Data Width
`define LEDCBCW   3                    // Bit Counter Width for given SBDW
`define LEDCBAW   4                    // LED Control Bus Address width

`endif //!LEDCB_DEFINES_V

`ifndef LEDD_DEFINES_V
`define LEDD_DEFINES_V

`define LEDDBRW 10                     // LEDDBR Width
`define LEDDPWW 8                      // LEDD PWM Counter Width

// LED Driver SCI Registers Address
`define ADDR_LEDDCR0  4'b1000
`define ADDR_LEDDBR   4'b1001
`define ADDR_LEDDONR  4'b1010
`define ADDR_LEDDOFR  4'B1011
`define ADDR_LEDDBCRR 4'b0101
`define ADDR_LEDDBCFR 4'b0110
`define ADDR_LEDDPWRR 4'b0001
`define ADDR_LEDDPWGR 4'b0010
`define ADDR_LEDDPWBR 4'b0011

// I2C SCI Registers Default Value
`define DEFAULT_LEDDCR0  8'b00000000
`define DEFAULT_LEDDBR   8'b00000000

`define BIT_LEDDCR0_EN    7
`define BIT_LEDDCR0_FR    6
`define BIT_LEDDCR0_POL   5
`define BIT_LEDDCR0_SKEW  4
`define BIT_LEDDCR0_QSTOP 3
`define BIT_LEDDCR0_LFSR  2
`define BIT_LEDDCR0_BREXT 1
`define BIT_LEDDBCRR_EN   7
`define BIT_LEDDBCFR_EN   7
`define BIT_LEDDBCRR_MD   5
`define BIT_LEDDBCFR_MD   5
`define BIT_LEDDBCRR_ALL  6
// `define BIT_LEDDBCRR_RT   3
// `define BIT_LEDDBCFG_RT   3
`define BIT_LEDDBCFR_EXT  6

`define LFSR_POLY 8'h95

`else
`endif //!LEDD_DEFINES_V
