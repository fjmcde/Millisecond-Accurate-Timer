// ============================================================================
//   Ver  :| Author					:| Mod. Date :| Changes Made:
//   V1.0 :| Frank McDermott		:| 04/25/2022:| Created modules 
// ============================================================================


//=======================================================
//  This code is generated by Terasic System Builder
//=======================================================

`define ENABLE_ADC_CLOCK
`define ENABLE_CLOCK1
`define ENABLE_CLOCK2
`define ENABLE_SDRAM
`define ENABLE_HEX0
`define ENABLE_HEX1
`define ENABLE_HEX2
`define ENABLE_HEX3
`define ENABLE_HEX4
`define ENABLE_HEX5
`define ENABLE_KEY
`define ENABLE_LED
`define ENABLE_SW
`define ENABLE_VGA
`define ENABLE_ACCELEROMETER
`define ENABLE_ARDUINO
`define ENABLE_GPIO

module DE10_LITE_Golden_Top(

	//////////// ADC CLOCK: 3.3-V LVTTL //////////
`ifdef ENABLE_ADC_CLOCK
	input 		          		ADC_CLK_10,
`endif
	//////////// CLOCK 1: 3.3-V LVTTL //////////
`ifdef ENABLE_CLOCK1
	input 		          		MAX10_CLK1_50,
`endif
	//////////// CLOCK 2: 3.3-V LVTTL //////////
`ifdef ENABLE_CLOCK2
	input 		          		MAX10_CLK2_50,
`endif

	//////////// SDRAM: 3.3-V LVTTL //////////
`ifdef ENABLE_SDRAM
	output		    [12:0]		DRAM_ADDR,
	output		     [1:0]		DRAM_BA,
	output		          		DRAM_CAS_N,
	output		          		DRAM_CKE,
	output		          		DRAM_CLK,
	output		          		DRAM_CS_N,
	inout 		    [15:0]		DRAM_DQ,
	output		          		DRAM_LDQM,
	output		          		DRAM_RAS_N,
	output		          		DRAM_UDQM,
	output		          		DRAM_WE_N,
`endif

	//////////// SEG7: 3.3-V LVTTL //////////
`ifdef ENABLE_HEX0
	output		     [7:0]		HEX0,
`endif
`ifdef ENABLE_HEX1
	output		     [7:0]		HEX1,
`endif
`ifdef ENABLE_HEX2
	output		     [7:0]		HEX2,
`endif
`ifdef ENABLE_HEX3
	output		     [7:0]		HEX3,
`endif
`ifdef ENABLE_HEX4
	output		     [7:0]		HEX4,
`endif
`ifdef ENABLE_HEX5
	output		     [7:0]		HEX5,
`endif

	//////////// KEY: 3.3 V SCHMITT TRIGGER //////////
`ifdef ENABLE_KEY
	input 		     [1:0]		KEY,
`endif

	//////////// LED: 3.3-V LVTTL //////////
`ifdef ENABLE_LED
	output		     [9:0]		LEDR,
`endif

	//////////// SW: 3.3-V LVTTL //////////
`ifdef ENABLE_SW
	input 		     [9:0]		SW,
`endif

	//////////// VGA: 3.3-V LVTTL //////////
`ifdef ENABLE_VGA
	output		     [3:0]		VGA_B,
	output		     [3:0]		VGA_G,
	output		          		VGA_HS,
	output		     [3:0]		VGA_R,
	output		          		VGA_VS,
`endif

	//////////// Accelerometer: 3.3-V LVTTL //////////
`ifdef ENABLE_ACCELEROMETER
	output		          		GSENSOR_CS_N,
	input 		     [2:1]		GSENSOR_INT,
	output		          		GSENSOR_SCLK,
	inout 		          		GSENSOR_SDI,
	inout 		          		GSENSOR_SDO,
`endif

	//////////// Arduino: 3.3-V LVTTL //////////
`ifdef ENABLE_ARDUINO
	inout 		    [15:0]		ARDUINO_IO,
	inout 		          		ARDUINO_RESET_N,
`endif

	//////////// GPIO, GPIO connect to GPIO Default: 3.3-V LVTTL //////////
`ifdef ENABLE_GPIO
	inout 		    [35:0]		GPIO
`endif
);



//=======================================================
// CUSTOM CODE: HARDWARE INSTANTIATION
//=======================================================

	wire clkOut;
	wire [29:0] timeOut;
	reg [15:0] reset1 = 50000; // clockDiv reset
	reg [19:0] reset2 = 1000000; // timer_ms reset

	clockDiv clk1KHz(MAX10_CLK1_50, reset1, clkOut); // divides 50MHz down to 1Khz
	timer tms(clkOut, reset2, timeOut); // generates a millisecond accurate timer
	hexDriver h5(timeOut[29:25], HEX5); /* splices the individually encoded 5-bit nibs  */
	hexDriver h4(timeOut[24:20], HEX4); /* and wires them into each of the 6 hexDrivers */
	hexDriver h3(timeOut[19:15], HEX3); /* which are wired to the 6 hex displays of the */
	hexDriver h2(timeOut[14:10], HEX2); /* DE10-Lite												*/
	hexDriver h1(timeOut[9:5], HEX1);
	hexDriver h0(timeOut[4:0], HEX0);

endmodule


//=======================================================
//  CUSTOM CODE: MODULE DECLARATION
//=======================================================

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
