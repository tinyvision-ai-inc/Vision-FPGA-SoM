`ifndef SYS_DEFINES_V1
 `define SYS_DEFINES_V1

`define SBDW            8                   // System Bus Data Width
`define SBCW            3                   // Bit Counter Width for given SBDW
`define SBAW            4                   // System Bus Address width
`define FIDW           10		    						// Fabric Interface Data Width    
`define TXFIFO_DEPTH   16                   // TXFIFO Depth
`define TXFIFO_PWIDTH   4                   // TXFIFO Pointer Width
`define RXFIFO_DEPTH   32                   // RXFIFO Depth
`define RXFIFO_PWIDTH   5                   // RXFFIO Pointer Width


`endif //!SYS_DEFINES_V

`ifndef I2C_DEFINES_V1
 `define I2C_DEFINES_V1

// I2C PORT Parameters
`define GENERAL_ADDR 7'b0000000             // Gerneral Call Address
`define HSMODE_ADDR  5'b00001               // HSMODE address
`define S10BIT_ADDR  5'b11110               // 10 bits addressing
`define GEN_UPDRST   8'b00000110
`define GEN_UPDADDR  8'b00000100
`define GEN_WKUPCMD  8'b11110011            // CMD to wakeup from standby/sleep (LSB=1)

`define I2CBRW 10                           // I2CBR Width

// I2C SCI Registers Address
`define FIFO_ADDR_I2CCR1           4'b0001       // CR (both mode)
`define FIFO_ADDR_I2CBRLSB         4'b0010       // prescale (both mode)
`define FIFO_ADDR_I2CBRMSB         4'b0011       // prescale (both mode)
`define FIFO_ADDR_I2CSADDR         4'b0100       // slave addr (both mode)
`define FIFO_ADDR_I2CINTCR         4'b0101       // interupt control (both mode)
`define ADDR_I2CFIFOTHRESHOLD 4'b0110       // FIFO threshold (fofo mode)
`define FIFO_ADDR_I2CCMDR          4'b0111       // command  (register mode)
`define FIFO_ADDR_I2CTXDR          4'b1000       // txdr or txfifo (both mode)
`define FIFO_ADDR_I2CRXDR          4'b1001       // rxdr or rxfifo (both mode)
`define FIFO_ADDR_I2CGCDR          4'b1010       // general call (both mode)
`define FIFO_ADDR_I2CSR            4'b1011       // status reg (both mode)
`define FIFO_ADDR_I2CINTSR         4'b1100       // interrupt status reg (both mode)
`define ADDR_I2CFIFOSMSR      4'b1101       // fifo state machine (fifo mode)
`define ADDR_I2CFIFOTXCNT     4'b1110       // fifo tx counter (fifo mode)
`define ADDR_I2CFIFORXCNT     4'b1111       // fifo rx counter (fifo mode)

// I2C SCI Registers Default Value
`define FIFO_DEFAULT_I2CCR1   8'b00000000
`define FIFO_DEFAULT_I2CINTCR 8'b00000000

`define FIFO_DEFAULT_I2CBR    10'b0000000111   // 7 (6.5) based on 12MHz System Clock Frequency
`define FIFO_DEFAULT_SADDRMSB  8'b11111000     // Default Slave Address MSB

`define DTRMW         4                   // SDA Unit Delay TRiM Width, to achieve 75ns unit delay.
`define F_SDA_DEL     12                  // MHz
`define T_SDA_DEL_075 75.0                // ns
`ifndef CONFORMAL_LEC
`define N_SDA_DEL_075 `T_SDA_DEL_075 * `F_SDA_DEL/1000 + 0.49
`else
// LEC doesn't evaluate the expression correctly,so we must do the math for it.
`define N_SDA_DEL_075 1                   // 0.9 Based on 12 MHz System Clock Frequency
`endif // conformal

// i2c int cr
`define INDEX_HGC     0
`define INDEX_TROE    1
`define INDEX_TRRDY   2
`define INDEX_ARBL    3
`define INDEX_INTFRC  6   
`define INDEX_INTCLR  7

// i2c fifo intcr
`define INDEX_RXOVERF   0
`define INDEX_TXUNDERF  1
`define INDEX_TXSERR    2    
`define INDEX_FIFO_ARBL 3   
`define INDEX_MRDCMPL   4
`define INDEX_RNACK     5    
`define INDEX_FIFO_HGC  6
`define INDEX_FIFO_INTFRC 8 
`define INDEX_FIFO_INTCLR 9 

`endif //!I2CIFO_DEFINES_V

