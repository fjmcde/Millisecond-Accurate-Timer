// Module to divide the clock of the DE10-Lite from it's base 50MHz
// down to 1Khz. 1Khz is necessary for a millisecond accurate timer
module clockDiv(input clk, input[15:0] divider, output clkOut);

	integer counter = 0;
	reg state = 0;

   always@(posedge clk) begin
		counter <= counter + 1;

		if(counter == (divider/ 2)) begin
			counter <= 0;
			state <= ~state;
        end
    end
	 
    assign clkOut = state;
endmodule


// The timer module takes a 19-bit reset input in order to reset the clock
// after a given number of clock cycles (in this case 1,000,000). There are six
// outputs encoded into a single 30-bit binary number (binEncode). 10 most
// significant bits are hardcoded to be in the OFF state initially, but illuminate
// as the timer counts from 0 - 999 seconds, with three additional decimal places to 
// make this a millisecond accurate timer. When the timer resets back to zero, the 
// hundreds and tens place turn off and the ones place resets to 0.
module timer(input clk, input [19:0] reset, output [29:0] timeOut);
	// initialize encodeBin to it's defaul state (__0.000)
	reg [29:0] encodeBin = {5'b10100, 5'b10100, 5'b01010, 5'b0, 5'b0, 5'b0};
	integer clockCycles = 1;

	always @(posedge clk) begin
		// always increment the thousandths place
		encodeBin[4:0] = encodeBin[4:0] + 5'b1;
	
		// if clockCycles is a multiple of 10:
		// reset the thousandths place digit to zero (__x.xx0)
		// and increment the hundredths place digit
		if(clockCycles % 10 == 0) begin
			encodeBin[9:5] = encodeBin[9:5] + 5'b1; // increment place
			encodeBin[4:0] = 5'b0; // reset digit
		
			// if clockCycles is a multiple of 100:
			// reset the hundredths place digit to zero (__x.x0x)
			// and increment the tenths place digit
			if(clockCycles % 100 == 0) begin
				encodeBin[9:5] = 5'b0; // reset digit
				encodeBin[14:10] = encodeBin[14:10] + 5'b1; // increment place

				// if clockCycles is a multiple of 1000:
				// reset the tenths place digit to zero (__x.0xx)
				// and increment the ones place digit
				if(clockCycles % 1000 == 0) begin
					encodeBin[14:10] = 5'b0; // reset digt
					encodeBin[19:15] = encodeBin[19:15] + 5'b1; // increment place

					// if clockCycles is a multiple of 10000:
					// reset the ones place digit to zero (__0.xxx)
					// and increment the tens place digit
					if(clockCycles % 10000 == 0) begin
						encodeBin[19:15] = 5'b01010; // reset digt
						if(encodeBin[24:20] == 5'b10100) begin encodeBin[24:20] = 5'b0; end
						encodeBin[24:20] = encodeBin[24:20] + 5'b1; // increment place

						// if clockCycles is a multiple of 100000:
						// reset the tens place digit to zero (_0x.xxx)
						// and increment the hundreds place digit
						if(clockCycles % 100000 == 0) begin
							encodeBin[24:20] = 5'b0; // reset digt
							if(encodeBin[29:25] == 5'b10100) begin encodeBin[29:25] = 5'b0; end
							encodeBin[29:25] = encodeBin[29:25] + 5'b1; // increment place
					
							// reset clockCycles counter after 1000000 cycles.
							// reset the hundreds, tens and ones place (__0.xxx)
							if(clockCycles == reset) begin
								clockCycles = 0;
								encodeBin[29:15] = {5'b10100, 5'b10100, 5'b01010};
							end
						end
					end
			    end
		    end
        end
		
		// always increment clockCycles
		clockCycles = clockCycles + 1;
	end
	
	assign timeOut = encodeBin;
endmodule


// hexDriver accepts a 5-bit binary input and encodes it to a valid
// value to output to a hex display.
module hexDriver(input [4:0] bin, output reg [7:0] hexOut);
	always @(bin) begin
		case(bin)
			5'b00000: hexOut = 8'b11000000; // 0
			5'b00001: hexOut = 8'b11111001; // 1
			5'b00010: hexOut = 8'b10100100; // 2
			5'b00011: hexOut = 8'b10110000; // 3
			5'b00100: hexOut = 8'b10011001; // 4
			5'b00101: hexOut = 8'b10010010; // 5
			5'b00110: hexOut = 8'b10000010; // 6
			5'b00111: hexOut = 8'b11111000; // 7
			5'b01000: hexOut = 8'b10000000; // 8
			5'b01001: hexOut = 8'b10011000; // 9
			5'b01010: hexOut = 8'b01000000; // 0.
			5'b01011: hexOut = 8'b01111001; // 1.
			5'b01100: hexOut = 8'b00100100; // 2.
			5'b01101: hexOut = 8'b00110000; // 3.
			5'b01110: hexOut = 8'b00011001; // 4.
			5'b01111: hexOut = 8'b00010010; // 5.
			5'b10000: hexOut = 8'b00000010; // 6.
			5'b10001: hexOut = 8'b01111000; // 7.
			5'b10010: hexOut = 8'b00000000; // 8.
			5'b10011: hexOut = 8'b00011000; // 9.
            5'b10100: hexOut = 8'b11111111; // OFF
        endcase
	end
endmodule
