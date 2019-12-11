`ifndef IRTCVCB_DEFINES_V
`define IRTCVCB_DEFINES_V

`define IRTCVCBDW   8                    // IR Transceiver Control Bus Data Width
`define IRTCVCBCW   3                    // Bit Counter Width for given SBDW
`define IRTCVCBAW   4                    // IR Transceiver Control Bus Address width

`endif //!IRTCVCB_DEFINES_V

`ifndef IRTCV_DEFINES_V
`define IRTCV_DEFINES_V

`define IRSYSFRW    28                   // IRSYSFR Width
`define IRTCVFRW    24                   // IRTCVFR Width
`define IRTCVDRW    16                   // IRTCVDR Width
`define IRTCVCRW    16                   // IRTCV Frequency Counter Width

// IRTCV SCI Registers Address
`define ADDR_IRTCVCR  4'b0001            // CR      
`define ADDR_IRSYSFR3 4'b0010            // SYSFR3
`define ADDR_IRSYSFR2 4'b0011            // SYSFR2
`define ADDR_IRSYSFR1 4'b0100            // SYSFR1
`define ADDR_IRSYSFR0 4'b0101            // SYSFR0
`define ADDR_IRTCVFR2 4'b0110            // TCVFR2
`define ADDR_IRTCVFR1 4'b0111            // TCVFR1
`define ADDR_IRTCVFR0 4'b1000            // TCVFR0
`define ADDR_IRTCVDR1 4'b1001            // DR1 
`define ADDR_IRTCVDR0 4'b1010            // DR0
`define ADDR_IRTCVSR  4'b1011            // SR 

// IRTCV SCI Registers Default Value
`define DEFAULT_IRTCVCR   8'b00000000

`define BIT_IRTCVCR_EN       7
`define BIT_IRTCVCR_DT33     6
`define BIT_IRTCVCR_OPOL     5
`define BIT_IRTCVCR_DISOE    4
`define BIT_IRTCVCR_USRMAX   3
`define BIT_IRTCVCR_REMEASEN 2
`define BIT_IRTCVCR_IFSEL    1

`define BIT_IRTCVDR_IRFLAG 15

`else
`endif //!IRTCV_DEFINES_V

