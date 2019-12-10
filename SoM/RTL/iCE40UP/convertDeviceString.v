 localparam MAX_STRING_LENGTH = 85;
 function [255:0] convertDeviceString; 
        input [(MAX_STRING_LENGTH)*8-1:0] attributeValue;

        integer i, j;
	integer decVal;
	real decPlace;
	integer temp, count;
	reg decimalFlag;
	reg [255:0] reverseVal;
	integer concatDec[255:0];
        reg [1:8] character;

        reg [7:0] checkType;
        begin 

	    decimalFlag = 1'b0;
	    decVal = 0;
	    decPlace = 1;
	    temp = 0;
	    count = 0;
	    for(i=0; i<=255; i=i+1) begin
	    	concatDec[i] = -1;
	    end
            convertDeviceString = 0;
            checkType = "N";
            for (i=MAX_STRING_LENGTH-1; i>=1 ; i=i-1) begin 
                for (j=1; j<=8; j=j+1) begin 

                    character[j] = attributeValue[i*8-j];
                end 

                //Check to see if binary or hex
                if (checkType === "N") begin 
                    if (character === "b" || character === "x") begin 
                        checkType = character;
			decimalFlag = 1'b1;
                    end else begin
			//Convert to string decimal to array of integers for each digit of the number
                        case(character) 
                            "0": concatDec[i-1] = 0;
                            "1": concatDec[i-1] = 1;
                            "2": concatDec[i-1] = 2;
                            "3": concatDec[i-1] = 3;
                            "4": concatDec[i-1] = 4;
                            "5": concatDec[i-1] = 5;
                            "6": concatDec[i-1] = 6;
                            "7": concatDec[i-1] = 7;
                            "8": concatDec[i-1] = 8;
                            "9": concatDec[i-1] = 9;
                            default: concatDec[i-1] = -1;
                        endcase 
		    end

                end else begin 

                    //$display("Index %d: %s", i, character);

                    //handle binary
                    if (checkType === "b") begin 
                        case(character) 
                            "0": convertDeviceString[i-1] = 1'b0;
                            "1": convertDeviceString[i-1] = 1'b1;
                            default: convertDeviceString[i-1] = 1'bx;
                        endcase 

                    //handle hex
                    end else if (checkType === "x") begin 
                        case(character)
                          "0" : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'h0;
                          "1" : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'h1;
                          "2" : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'h2;
                          "3" : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'h3;
                          "4" : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'h4;
                          "5" : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'h5;
                          "6" : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'h6;
                          "7" : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'h7;
                          "8" : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'h8;
                          "9" : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'h9;
                          "a", "A" : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'hA;
                          "b", "B" : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'hB;
                          "c", "C" : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'hC;
                          "d", "D" : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'hD;
                          "e", "E" : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'hE;
                          "f", "F" : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'hF;
                          default: {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'hX;     
                        endcase
                    end



                end 

            end 


	    //Calculate decmial value from integer array.
	    if(decimalFlag === 1'b0) begin
                for (i=0; i<=255 ; i=i+1) begin
                        case(concatDec[i]) 
                            0: temp = 0;
                            1: temp = 1;
                            2: temp = 2;
                            3: temp = 3;
                            4: temp = 4;
                            5: temp = 5;
                            6: temp = 6;
                            7: temp = 7;
                            8: temp = 8;
                            9: temp = 9;
                            default: temp = -1;
                        endcase 
			
			if(temp != -1) begin
				decVal = decVal + (temp * decPlace);
				count = count + 1;
				decPlace = 10 ** count;
			end
		end

		convertDeviceString = decVal;
	    end
        end
    endfunction 
