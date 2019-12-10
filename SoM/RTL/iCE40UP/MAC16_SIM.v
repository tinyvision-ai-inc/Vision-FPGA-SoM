`timescale 1ps/1ps
module MAC16_SIM (
		A,
		B,
		C,
		D,
		O,
		CLK,
		CE,
		IRSTTOP,
	    IRSTBOT,
		ORSTTOP,
		ORSTBOT,
		AHOLD,
		BHOLD,
		CHOLD,
		DHOLD,
		OHOLDTOP,
		OHOLDBOT,
		OLOADTOP,
		OLOADBOT,
		ADDSUBTOP,
		ADDSUBBOT,
		CO,
		CI,  		//from bottom tile
		ACCUMCI, 	// Carry input from MAC CO below
		ACCUMCO, 	// Carry output to above MAC block.    
		SIGNEXTIN,
		SIGNEXTOUT
);
output 	[31:0] O;	 // Output [31:0]
input	[15:0] A;        // data  to upper mult block / upper accum block.
input	[15:0] B;        // data  to lower mult block / lower accum block.   
input	[15:0] C;        // direct data  to upper accum block. 
input	[15:0] D;        // direct data  to lower accum block.
input	CLK;	         // Clock for MAC16 elements 
input	CE;              // Clock enable . global control 
input	IRSTTOP;         // Active High  reset for  A,C registers,upper half multplier pipeline regs(16). 
input	IRSTBOT;         // Active High reset for  B,D registers, lower half multiplier pipeline regs(16), 32 bit result pipelines regs   
input	ORSTTOP;	 // Active High reset for top accum registers O[31:16]
input	ORSTBOT;         // Active High reset for bottom accum registers O[15:0]   
input   AHOLD;           // Active High hold data signal for A register
input   BHOLD;           // Active High hold data signal for B register   
input   CHOLD;           // Active High hold data signal for C register
input   DHOLD;           // Active High hold data signal for D register 
input   OHOLDTOP;        // Active High hold data signal for top accum registers O[31:16]
input   OHOLDBOT;        // Active High hold data signal for bottom  accum registers O[15:0]     
input 	OLOADTOP;        // Load top accum regiser with  direct input C or Registered data C.  
input 	OLOADBOT;        // Load bottom accum regisers with direct input D or Registered data D
input 	ADDSUBTOP;       // Control for Add/Sub operation for top accum . 0-addition , 1-subtraction.  
input 	ADDSUBBOT;       // Control for Add/Sub operation for bottom accum . 0-addition , 1-subtraction.
output  CO;              // top accumulator carry out to next LUT
input 	CI;              // bottom accumaltor carry in signal from lower LUT block. 
input   ACCUMCI;         // Carry in from  MAC16 below
output  ACCUMCO;         // Carry out to MAC16 above
input   SIGNEXTIN;	 // Single bit Sign extenstion from MAC16 below         
output  SIGNEXTOUT;      // Single bit Sign extenstion to MAC16 above


parameter NEG_TRIGGER = 1'b0;    
parameter C_REG = 1'b0;     			// C0
parameter A_REG = 1'b0;     			// C1
parameter B_REG = 1'b0;     			// C2
parameter D_REG = 1'b0;     			// C3

parameter TOP_8x8_MULT_REG = 1'b0; 		//C4
parameter BOT_8x8_MULT_REG = 1'b0; 		//C5
parameter PIPELINE_16x16_MULT_REG1 = 1'b0; 	//C6
parameter PIPELINE_16x16_MULT_REG2 = 1'b0; 	//C7

parameter TOPOUTPUT_SELECT =  2'b00; 		//COMB, ACCUM_REG, MULT_8x8, MULT_16x16  // {C9,C8} = 00, 01, 10, 11
parameter TOPADDSUB_LOWERINPUT = 2'b00; 	//DATA, MULT_8x8, MULT_16x16, SIGNEXT    // {C11,C10} = 00, 01, 10, 11
parameter TOPADDSUB_UPPERINPUT = 1'b0; 		//ACCUM_REG, DATAC  			 //  C12 = 0, 1
parameter TOPADDSUB_CARRYSELECT = 2'b00; 	//LOGIC0, LOGIC1, LCOCAS, GENERATED_CARRY (LCO) // {C14, C13} = 00, 01, 10, 11

parameter BOTOUTPUT_SELECT =  2'b00; 		//COMB, ACCUM_REG, MULT_8x8, MULT_16x16   // {C16,C15} = 00, 01, 10, 11
parameter BOTADDSUB_LOWERINPUT = 2'b00; 	//DATA, MULT_8x8, MULT_16x16, SIGNEXTIN   // {C18,C17} = 00, 01, 10, 11
parameter BOTADDSUB_UPPERINPUT = 1'b0;  	//ACCUM_REG, DATAD   			  // C19 = 0, 1
parameter BOTADDSUB_CARRYSELECT = 2'b00; 	//LOGIC0, LOGIC1, ACCUMCI, CI  		  // {C21, C20} = 00, 01, 10, 11
parameter MODE_8x8 = 1'b0; 			// C22 

parameter A_SIGNED = 1'b0;  			// C23
parameter B_SIGNED = 1'b0;  			// C24	 

//--------- local params ----------------------------------------------------// 
localparam cbits_inreg   	= {D_REG,B_REG,A_REG,C_REG}; 
localparam cbits_mpyreg   	= {PIPELINE_16x16_MULT_REG2,PIPELINE_16x16_MULT_REG1,BOT_8x8_MULT_REG,TOP_8x8_MULT_REG};
localparam cbits_topmac	 	= {TOPADDSUB_CARRYSELECT,TOPADDSUB_UPPERINPUT,TOPADDSUB_LOWERINPUT,TOPOUTPUT_SELECT};
localparam cbits_botmac	 	= {BOTADDSUB_CARRYSELECT,BOTADDSUB_UPPERINPUT,BOTADDSUB_LOWERINPUT,BOTOUTPUT_SELECT};
localparam cbits_sign	 	= {B_SIGNED,A_SIGNED,MODE_8x8}; 
localparam cbits 	  	= {cbits_sign,cbits_botmac,cbits_topmac,cbits_mpyreg,cbits_inreg}; 

wire CLK_g , intCLK; 
reg NOTIFIER;


//------------------- initial block --------------------------------------// 
	
	initial 
begin 
	
	
	
	if( (TOPOUTPUT_SELECT != 2'b00 )&& (TOPOUTPUT_SELECT != 2'b01 ) && (TOPOUTPUT_SELECT != 2'b10 ) && (TOPOUTPUT_SELECT !=2'b11 ) ) begin 
	$display("Error: TOPOUTPUT_SELECT parameter is set to incorrect value. Exiting Simulation ...."); 
	$finish;	
	end 
	if( (TOPADDSUB_LOWERINPUT != 2'b00) && (TOPADDSUB_LOWERINPUT != 2'b01) && (TOPADDSUB_LOWERINPUT != 2'b10) && (TOPADDSUB_LOWERINPUT != 2'b11) ) begin 
	$display("Error: TOPADDSUB_LOWERINPUT parameter is set to incorrect value. Exiting Simulation ...."); 
	$finish; 
	end 
	if( (TOPADDSUB_UPPERINPUT != 1'b0 ) && (TOPADDSUB_UPPERINPUT != 1'b1) ) begin
	$display("Error: TOPADDSUB_UPPERINPUT parameter is set to incorrect value. Exiting Simulation ....");
        $finish;
        end
	if( (TOPADDSUB_CARRYSELECT != 2'b00 )&&(TOPADDSUB_CARRYSELECT != 2'b01) && (TOPADDSUB_CARRYSELECT != 2'b10) &&(TOPADDSUB_CARRYSELECT != 2'b11)) begin 
	$display("Error: TOPADDSUB_CARRYSELECT parameter is set to incorrect value. Exiting Simulation ....");
        $finish;
        end

	
	if( (BOTOUTPUT_SELECT != 2'b00 )&& (BOTOUTPUT_SELECT != 2'b01 ) && (BOTOUTPUT_SELECT != 2'b10 ) && (BOTOUTPUT_SELECT !=2'b11 ) ) begin 
	$display("Error: BOTOUTPUT_SELECT parameter is set to incorrect value. Exiting Simulation ...."); 
	$finish;	
	end 
	if( (BOTADDSUB_LOWERINPUT != 2'b00) && (BOTADDSUB_LOWERINPUT != 2'b01) && (BOTADDSUB_LOWERINPUT != 2'b10) && (BOTADDSUB_LOWERINPUT != 2'b11) ) begin 
	$display("Error: BOTADDSUB_LOWERINPUT parameter is set to incorrect value. Exiting Simulation ...."); 
	$finish; 
	end 
	if( (BOTADDSUB_UPPERINPUT != 1'b0 ) && (BOTADDSUB_UPPERINPUT != 1'b1) ) begin
	$display("Error:BOTADDSUB_UPPERINPUT parameter is set to incorrect value. Exiting Simulation ....");
        $finish;
        end
	if( (BOTADDSUB_CARRYSELECT != 2'b00 ) && (BOTADDSUB_CARRYSELECT != 2'b01) && (BOTADDSUB_CARRYSELECT != 2'b10) && (BOTADDSUB_CARRYSELECT != 2'b11)) begin 
	$display("Error: BOTADDSUB_CARRYSELECT parameter is set to incorrect value. Exiting Simulation ....");
        $finish;
        end
	
	//Validation for mode8x8.
		if (PIPELINE_16x16_MULT_REG1 == 1'b1 || PIPELINE_16x16_MULT_REG2 ==1'b1 ) begin   		
		$display ("**************  INFO  ***********************************"); 
		$display ("Info : To Reset 16x16 multiplier INTERNAL PIPELINE REGISTER assert both IRSTTOP and IRSTBOT signals") ;  
	        $display ("Info : To Reset 16x16 multiplier OUTPUT  REGISTER   assert IRSTBOT signal");  	
		$display ("**********************************************************"); 	
		end else if ( (PIPELINE_16x16_MULT_REG1 == 1'b1 || PIPELINE_16x16_MULT_REG2 ==1'b1) &&  MODE_8x8 == 1'b1) begin
		  
		$display ("***********  ERROR  ****************************************"); 
		$display ("Error : MODE_8x8 parameter is set to 1. To use 16x16 mulitplier internal and output registers it should be set to 0.Exiting Simulation ...."); 
		
		$display ("***************************************************************"); 	
		$finish; 
		end else if( (PIPELINE_16x16_MULT_REG1 == 1'b0 &&  PIPELINE_16x16_MULT_REG2 ==1'b0)  &&  MODE_8x8 == 1'b0 ) begin
                $display ("************ WARNING  **********************************************");
                $display ("Warning : When 16x16 multiplier PIPELINE REGISTERS are not used, set MODE_8x8 to 1(power save mode) ");
                $display ("*******************************************************************");
		end 


end	// initial  

//-------------------------- Default input signals -------------------------------------// 
assign (weak0,weak1) CE 	= 1'b1; 
assign (weak0,weak1) A  	= 16'b0; 
assign (weak0,weak1) B  	= 16'b0; 
assign (weak0,weak1) C  	= 16'b0; 
assign (weak0,weak1) D  	= 16'b0; 
assign (weak0,weak1) AHOLD 	= 1'b0; 
assign (weak0,weak1) BHOLD 	= 1'b0; 
assign (weak0,weak1) CHOLD 	= 1'b0; 
assign (weak0,weak1) DHOLD    	= 1'b0; 
assign (weak0,weak1) IRSTTOP  	= 1'b0; 
assign (weak0,weak1) IRSTBOT  	= 1'b0; 
assign (weak0,weak1) ORSTTOP  	= 1'b0; 
assign (weak0,weak1) ORSTBOT  	= 1'b0; 
assign (weak0,weak1) OLOADTOP 	= 1'b0; 
assign (weak0,weak1) OLOADBOT 	= 1'b0; 
assign (weak0,weak1) ADDSUBTOP	= 1'b0; 
assign (weak0,weak1) ADDSUBBOT  = 1'b0; 
assign (weak0,weak1) OHOLDTOP   = 1'b0; 
assign (weak0,weak1) OHOLDBOT	= 1'b0;   
assign (weak0,weak1) CI		= 1'b0;   
assign (weak0,weak1) ACCUMCI	= 1'b0;   


//---------------------------Logic section --------------------------------------------// 

assign CLK_g = (CLK & CE);  				// CE=0 disables entire clock  
assign intCLK = (CLK_g ^ NEG_TRIGGER);			// Clock Polarity control 

 mac16_physical  mac16physical_i (
	 .CLK(intCLK) ,
	 .A(A) ,
	 .B(B) ,
	 .C(C) ,
	 .D(D) ,
	 .IHRST(IRSTTOP),
	 .ILRST(IRSTBOT),
	 .OHRST(ORSTTOP),
	 .OLRST(ORSTBOT),
	 .AHLD(AHOLD),
	 .BHLD(BHOLD),
	 .CHLD(CHOLD),
	 .DHLD(DHOLD),
		
	 .OHHLD(OHOLDTOP),
	 .OLHLD(OHOLDBOT),
	 .OHADS(ADDSUBTOP),
	 .OLADS(ADDSUBBOT),
	 .OHLDA(OLOADTOP),
	 .OLLDA(OLOADBOT),
	 .CICAS(ACCUMCI),
	 .CI(CI),
	 .SIGNEXTIN(SIGNEXTIN),
	 .SIGNEXTOUT(SIGNEXTOUT),
	 .COCAS(ACCUMCO),
	 .CO(CO),
	 .O(O), 
	 .CBIT(cbits)
    );
		

endmodule
