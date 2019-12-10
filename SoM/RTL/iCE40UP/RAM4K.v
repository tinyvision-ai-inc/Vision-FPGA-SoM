`timescale 1ps/1ps
module RAM4K (RDATA, RCLK, RCLKE, RE, RADDR, WCLK, WCLKE, WE, WADDR, MASK, WDATA);
output [15:0] RDATA;
input RCLK;
input RCLKE;
input RE;
input [7:0] RADDR;
input WCLK;
input WCLKE;
input WE;
input [7:0] WADDR;
input [15:0] MASK;
input [15:0] WDATA;

assign (weak0, weak1) MASK = 16'b0;

parameter INIT_0 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter INIT_1 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter INIT_2 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter INIT_3 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter INIT_4 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter INIT_5 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter INIT_6 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter INIT_7 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter INIT_8 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter INIT_9 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter INIT_A = 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter INIT_B = 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter INIT_C = 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter INIT_D = 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter INIT_E = 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter INIT_F = 256'h0000000000000000000000000000000000000000000000000000000000000000;

//Dummy parameters to keep device model 1:1. Effectively not used. 
parameter DATA_WIDTH_W = 16;
parameter DATA_WIDTH_R = 16;

// local Parameters
localparam          CLOCK_PERIOD = 200; //
localparam          DELAY   = (CLOCK_PERIOD/10);        // Clock-to-output delay. Zero
                            // time delays can be confusing
                            // and sometimes cause problems.
//localparam            DATA_WIDTH_R = 16;     // Width of RAM (number of bits)

localparam          ADDRESS_BUS_SIZE = 8;   // Number of bits required to
                            // represent the RAM address

localparam   ADDRESSABLE_SPACE  = 2**ADDRESS_BUS_SIZE;  // Decimal address range [2^Size:0]

// SIGNAL DECLARATIONS
wire                WCLK_g, RCLK_g;
reg                 WCLKE_sync, RCLKE_sync; 
assign (weak0, weak1) RCLKE =1'b1 ;
assign (weak0, weak1) RE =1'b0 ;
assign (weak0, weak1) WCLKE =1'b1 ;
assign (weak0, weak1) WE =1'b0 ;
//reg  [DATA_WIDTH_R-1:0] Memory [ADDRESSABLE_SPACE-1:0];  // The RAM
reg Memory  [DATA_WIDTH_R*ADDRESSABLE_SPACE-1:0];
// 
event Read_e, Write_e;

//////////////////// Collision detect begins here ///////////////////////////////
localparam  TRUE = 1'b1;
localparam  FALSE = 1'b0;
reg         Time_Collision_Detected = 1'b0;
wire        Address_Collision_Detected;

event Collision_e;

time COLLISION_TIME_WINDOW = (CLOCK_PERIOD/8); // This is an arbitray value, but is better than using an absolute 
                            // value, because the actual time window depends on the actual silicon 
                            // implementation. Thus the test is indicative of an Error and not
                            // guaranteed to be an error. Even so this is usefull.
time time_WCLK_RCLK, time_WCLK, time_RCLK;


//function reg Check_Timed_Window_Violation;
function    Check_Timed_Window_Violation;   //  by Jeffrey
input T1, T2, Minimum_Time_Window;
time T1, T2;
time Minimum_Time_Window;
time Difference;    
    begin
        Difference = (T1 - T2);
        if (Difference < 0) Difference = -Difference;
        Check_Timed_Window_Violation = (Difference < Minimum_Time_Window);
    end
endfunction


initial begin
       time_WCLK = CLOCK_PERIOD;    // Arbitrary initialisation value, ensure no window collison error on first clock edge.
       time_RCLK = (CLOCK_PERIOD*8);    // Arbitrary initialisation difference value, ensure no collision error on first clock edge.                    
end

integer i,j;

genvar k;
wire [7:0] RADDR_g;
wire [7:0] WADDR_g;
wire [15:0] WDATA_g;
for (k = 0; k < 8; k = k + 1) begin
    assign RADDR_g[k] = (RADDR[k] === 1'bz)? 1'b0 : RADDR[k];
    assign WADDR_g[k] = (WADDR[k] === 1'bz)? 1'b0 : WADDR[k];
    assign WDATA_g[k] = (WDATA[k] === 1'bz)? 1'b0 : WDATA[k];
    assign WDATA_g[k+8] = (WDATA[k+8] === 1'bz)? 1'b0 : WDATA[k+8];
end

initial //  initialize ram_4k by parameter, section by section
begin
    for (i=0; i<=256/DATA_WIDTH_R -1; i=i+1)
    begin
        for (j=0; j<=DATA_WIDTH_R-1; j=j+1)
            Memory[DATA_WIDTH_R*i+j]   =   INIT_0[DATA_WIDTH_R*i+j];
    end

    for (i=0; i<=256/DATA_WIDTH_R -1; i=i+1)
    begin
        for (j=0; j<=DATA_WIDTH_R-1; j=j+1)
            Memory[256*1+DATA_WIDTH_R*i+j] =   INIT_1[DATA_WIDTH_R*i+j];
    end

    for (i=0; i<=256/DATA_WIDTH_R -1; i=i+1)
    begin
        for (j=0; j<=DATA_WIDTH_R-1; j=j+1)
            Memory[256*2+DATA_WIDTH_R*i+j] =   INIT_2[DATA_WIDTH_R*i+j];
    end

    for (i=0; i<=256/DATA_WIDTH_R -1; i=i+1)
    begin
        for (j=0; j<=DATA_WIDTH_R-1; j=j+1)
            Memory[256*3+DATA_WIDTH_R*i+j] =   INIT_3[DATA_WIDTH_R*i+j];
    end

    for (i=0; i<=256/DATA_WIDTH_R -1; i=i+1)
    begin
        for (j=0; j<=DATA_WIDTH_R-1; j=j+1)
            Memory[256*4+DATA_WIDTH_R*i+j] =   INIT_4[DATA_WIDTH_R*i+j];
    end

    for (i=0; i<=256/DATA_WIDTH_R -1; i=i+1)
    begin
        for (j=0; j<=DATA_WIDTH_R-1; j=j+1)
            Memory[256*5+DATA_WIDTH_R*i+j] =   INIT_5[DATA_WIDTH_R*i+j];
    end

    for (i=0; i<=256/DATA_WIDTH_R -1; i=i+1)
    begin
        for (j=0; j<=DATA_WIDTH_R-1; j=j+1)
            Memory[256*6+DATA_WIDTH_R*i+j] =   INIT_6[DATA_WIDTH_R*i+j];
    end

    for (i=0; i<=256/DATA_WIDTH_R -1; i=i+1)
    begin
        for (j=0; j<=DATA_WIDTH_R-1; j=j+1)
            Memory[256*7+DATA_WIDTH_R*i+j] =   INIT_7[DATA_WIDTH_R*i+j];
    end

    for (i=0; i<=256/DATA_WIDTH_R -1; i=i+1)
    begin
        for (j=0; j<=DATA_WIDTH_R-1; j=j+1)
            Memory[256*8+DATA_WIDTH_R*i+j] =   INIT_8[DATA_WIDTH_R*i+j];
    end

    for (i=0; i<=256/DATA_WIDTH_R -1; i=i+1)
    begin
        for (j=0; j<=DATA_WIDTH_R-1; j=j+1)
            Memory[256*9+DATA_WIDTH_R*i+j] =   INIT_9[DATA_WIDTH_R*i+j];
    end

    for (i=0; i<=256/DATA_WIDTH_R -1; i=i+1)
    begin
        for (j=0; j<=DATA_WIDTH_R-1; j=j+1)
            Memory[256*10+DATA_WIDTH_R*i+j]    =   INIT_A[DATA_WIDTH_R*i+j];
    end

    for (i=0; i<=256/DATA_WIDTH_R -1; i=i+1)
    begin
        for (j=0; j<=DATA_WIDTH_R-1; j=j+1)
            Memory[256*11+DATA_WIDTH_R*i+j]    =   INIT_B[DATA_WIDTH_R*i+j];
    end

    for (i=0; i<=256/DATA_WIDTH_R -1; i=i+1)
    begin
        for (j=0; j<=DATA_WIDTH_R-1; j=j+1)
            Memory[256*12+DATA_WIDTH_R*i+j]    =   INIT_C[DATA_WIDTH_R*i+j];
    end

    for (i=0; i<=256/DATA_WIDTH_R -1; i=i+1)
    begin
        for (j=0; j<=DATA_WIDTH_R-1; j=j+1)
            Memory[256*13+DATA_WIDTH_R*i+j]    =   INIT_D[DATA_WIDTH_R*i+j];
    end

    for (i=0; i<=256/DATA_WIDTH_R -1; i=i+1)
    begin
        for (j=0; j<=DATA_WIDTH_R-1; j=j+1)
            Memory[256*14+DATA_WIDTH_R*i+j]    =   INIT_E[DATA_WIDTH_R*i+j];
    end

    for (i=0; i<=256/DATA_WIDTH_R -1; i=i+1)
    begin
        for (j=0; j<=DATA_WIDTH_R-1; j=j+1)
            Memory[256*15+DATA_WIDTH_R*i+j]    =   INIT_F[DATA_WIDTH_R*i+j];
    end

end

assign Address_Collision_Detected = ((RE & WE & WCLKE & RCLKE)&(WADDR == RADDR)); 

always @(WCLK or WCLKE) 
begin 
    if(~WCLK)
    WCLKE_sync = WCLKE;     
end 

always @(RCLK or RCLKE) 
begin 
    if (~RCLK)
    RCLKE_sync = RCLKE;     
end 

assign WCLK_g = WCLK & WCLKE_sync;
assign RCLK_g = RCLK & RCLKE_sync;

always @(posedge WCLK_g) begin
    time_WCLK = $time;
end

always @(posedge RCLK_g) begin
        time_RCLK = $time;
end
integer RAM4K_RDATA_log_file;                                    //.....................
initial RAM4K_RDATA_log_file=("RAM4K_RDATA_log_file.txt");    //.....................
always @(posedge WCLK_g) begin

    Time_Collision_Detected = Check_Timed_Window_Violation(time_WCLK,time_RCLK,COLLISION_TIME_WINDOW);
        if (Time_Collision_Detected & Address_Collision_Detected)begin
            $display("Warning: Write-Read collision detected, Data read value is XXXX\n");
        $display("WCLK Time: %.3f   RCLK Time:%.3f  ",time_WCLK, time_RCLK,"WADDR: %d   RADDR:%d\n",WADDR, RADDR); 
        $fdisplay(RAM4K_RDATA_log_file,"Warning: Write-Read collision detected, Data read value is XXXX\n");
        $fdisplay(RAM4K_RDATA_log_file,"WCLK Time: %.3f   RCLK Time:%.3f  ",time_WCLK, time_RCLK, "WADDR: %d   RADDR:%d\n",WADDR, RADDR);    
        -> Collision_e;
    end
end




//  code modify for universal verilog compiler

always @ (posedge WCLK_g)
begin
    if  (WE)
    begin
        -> Write_e;
        for (i=0;i<=DATA_WIDTH_R-1; i=i+1)
        begin
            if  (MASK[i] !=1)
                Memory[WADDR_g*DATA_WIDTH_R+i] <=  WDATA_g[i];
            else
                Memory[WADDR_g*DATA_WIDTH_R+i] <=  Memory[WADDR_g*DATA_WIDTH_R+i];
        end
    end
end

//reg   [15:0]  RDATA = 0;
reg [15:0]  RDATA;

initial
begin
   RDATA = $random;
end

// Look at the rising edge of the clock

always @ (posedge RCLK_g)
begin
    if  (RE)
    begin
        -> Read_e;
        if  (Time_Collision_Detected & Address_Collision_Detected) 
            RDATA <= 16'hXXXX;
        else
            for (i=0;i<=DATA_WIDTH_R-1;i=i+1)
                RDATA[i]    <= Memory[RADDR_g*DATA_WIDTH_R+i];
    end
end


endmodule    // RAM4K
