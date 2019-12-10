`timescale 1ns/1ns
module IOLOGIC (PADDO, PADDT, PADDI, DO1, DO0, CE, DI1, DI0, IOLTO, HOLD, INCLK, OUTCLK);

        //Port Type List [Expanded Bus/Bit]
        output PADDO;
        output PADDT;
        input PADDI;
        input DO1;
        input DO0;
        input CE;
        output DI1;
        output DI0;
        input IOLTO;
        input HOLD;
        input INCLK;
        input OUTCLK;

        //Attribute List
        parameter LATCHIN = "NONE";
        parameter DDROUT = "NO";
		
        reg paddt_r, paddo_r, di1_r, di0_r, do1_r, do0_r;

        wire outclk, inclk;

        assign outclk = OUTCLK & CE;
        assign inclk  = INCLK & CE;

        //PADDT Logic
        always @ (posedge outclk) begin
            paddt_r <= IOLTO;
        end

        assign PADDT = paddt_r;

        //PADDO Logic
        always @ (posedge outclk) begin
            paddo_r <= DO0;
        end

        always @ (negedge outclk) begin
            if (DDROUT == "YES") begin
                paddo_r <= DO1;
            end
        end

        assign PADDO = paddo_r; 
		
		initial begin
			di0_r <= 0;
			di1_r <= 1;
		end

        //PADDI Logic
        always @ (posedge inclk) begin
            di0_r <= PADDI;
        end

        always @ (negedge inclk) begin
            di1_r <= PADDI;
        end

        assign DI0 = (LATCHIN == "NONE_DDR" | LATCHIN == "NONE_REG")? di0_r : (HOLD === 1'b1 & (LATCHIN == "LATCH_REG" | LATCHIN == "LATCH_BYPASS"))? DI0 : (HOLD === 1'b0 & (LATCHIN == "LATCH_REG"))? di0_r : PADDI;
        assign DI1 = di1_r;



endmodule
