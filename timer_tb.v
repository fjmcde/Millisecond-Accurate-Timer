`include "timer.v"

// testbench for a millisecond-accurate timer
module timer_tb;
    reg clkIn; // 50Mhz
    wire clkOut; // 1KHz
    wire [29:0] timeOut;
    wire [7:0] hex5, hex4, hex3, hex2, hex1, hex0;
    localparam [15:0] reset1 = 50000; // clockDiv reset
    localparam [19:0] reset2 = 1000000; // timer_ms reset
    

    // instantiate hardware for a millisecond accurate timer
    clockDiv clk1KHz(clkIn, reset1, clkOut);
    timer tms(clkOut, reset2, timeOut);
    hexDriver h5(timeOut[29:25], hex5);
    hexDriver h4(timeOut[24:20], hex4);
    hexDriver h3(timeOut[19:15], hex3);
    hexDriver h2(timeOut[14:10], hex2);
    hexDriver h1(timeOut[9:5], hex1);
    hexDriver h0(timeOut[4:0], hex0);


    initial begin
        // generate a dumpfile (to generate waveform)
        $dumpfile("timer_tb.vcd");
        $dumpvars(0, timer_tb);

        // initalize clock
        #0 clkIn = 'b0;

        // forever oscillate the clock
        forever #1 clkIn = ~clkIn;
    end

    // this always block is used to stop the simulation
    // which will never stop due to the forever block above.
    // I last used it to ensure the behavior of the ones place
    // digit was as expected. Refer to hexDriver module for
    // encoded outputs. NOTE: DUMPFILE WILL BE VERY LARGE
    // WITH THIS FINISH CONDITION.
    always @(hex3) begin
        if(hex3 == 8'b01111001) begin
            $finish;
        end
    end
endmodule