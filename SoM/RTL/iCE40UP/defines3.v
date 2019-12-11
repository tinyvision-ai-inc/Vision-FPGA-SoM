`define SBDW   8                    // System Bus Data Width
`define SBCW   3                    // Bit Counter Width for given SBDW
`define SBAW   8                    // System Bus Address width

// SPI SCI Registers Address
`define ADDR_SPICR0   4'b1000
`define ADDR_SPICR1   4'b1001
`define ADDR_SPICR2   4'b1010
`define ADDR_SPIBR    4'B1011
`define ADDR_SPISR    4'b1100
`define ADDR_SPITXDR  4'b1101
`define ADDR_SPIRXDR  4'b1110
`define ADDR_SPICSR   4'b1111
`define ADDR_SPIINTCR 4'b0111
`define ADDR_SPIINTSR 4'b0110

// I2C SCI Registers Default Value
`define DEFAULT_SPICR0   8'b00000000
`define DEFAULT_SPICR1   8'b00000000
`define DEFAULT_SPICR2   8'b00000000
`define DEFAULT_SPIINTCR 8'b00000000

`define INDEX_MDF     0
`define INDEX_ROE     1
`define INDEX_TOE     2
`define INDEX_RRDY    3
`define INDEX_TRDY    4

`define INDEX_INTFRC  6  
`define INDEX_INTCLR  7

