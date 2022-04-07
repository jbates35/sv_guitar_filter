/********
audio_top.sv

Written by Tom Kuzma (A01075531)
ELEX 7660-Digital System Design
Date created: April 6,2022

Top level for guitar filter Final Project for ELEX 7660
*********/

`define CHANNELS    2   // # of input channels for MCP3008_2
`define N           10  // # of bits for ADC/DAC
`define LPF         0
`define HPF         1 

module audio_top (

    // board pins
    input logic reset_n, CLOCK_50, 

    // Audio MCP3008_1 Pins
    input SPI_IN_AUD,       // SPI input from MCP3008_1     GPIO_1 physical pin 1         
    output SPI_OUT_AUD,     // SPI output from MCP3008_1    GPIO_1 physical pin 2       
    output SCLK_AUD,        // SPI clock                    GPIO_1 physical pin 3 
    output CS_n_AUD,        // Conversion start/Shutdown    GPIO_1 physical pin 4 

    // Pot MCP3008_2 Pins
    input SPI_IN_POT,       // SPI input from MCP3008_2     GPIO_1 physical pin 5         
    output SPI_OUT_POT,     // SPI output from MCP3008_2    GPIO_1 physical pin 6       
    output SCLK_POT,        // SPI clock                    GPIO_1 physical pin 7 
    output CS_n_POT,        // Conversion start/Shutdown    GPIO_1 physical pin 8 

    output PWM_OUT          // PWM DAC output               GPIO_1 physical pin 9

    // Switch input pin for HPF or LPF 
    input FILT_TYPE         // Switch input for HPF/LPF     GPIO_1 physical pin 10

    // MX7533 DAC
        // TBD if needed
);

    //***********************************************************************//
    //  Internal Signals                                                     //
    //***********************************************************************//

    // ADC from MCP3008's
    logic [0:1][`N:0] audio_in                  // Current and previous Digital Audio from MCP3008_1
    logic [$clog2(`CHANNELS):0][9:0] pot_in;    // pot input MCP3008_2 Internal

    // IIR filter 
    logic [`N-1:0] iir_out,                     // output
    logic filt_type                             // 0 for LPF, 1 for HPF 

    // Frequency
    logic [15:0] f,                             // frequency from pots
    logic [16:0] fs,                            // sample frequency ******** NEEDS TO BE FIGURED OUT

    // PWM DAC 
    logic [1:0] duty_val;                       // PWM duty using audio_in

    // clocks
    logic PLL_CLK1;                             // 50 MHz Clock??????
    logic PLL_CLK2;                             // 300 MHz Clock

    // internal
    logic raw_freq_input;                       // MCP3008_2 ADC out from either channel 0 or 1
    logic irr_out;                              // Processed output from IRR Filter


    //***********************************************************************//
    //  Module Instantiations                                                //
    //***********************************************************************//

    mcp3008_audio #(.SCLK_N(4)) ADC_audio (// SCLK_N = # of bits for clock divider counter
        .CLK50(PLL_CLK2),           // Divided Rate = 50 MHz/2^4 = 3.125 MHz. fs = 3.125 MHz/25 = 125 kHz
        .reset_n,                   // active low reset
        .SPI_IN(SPI_IN_AUD),        // Spi input from MCP3008_1
        .SPI_OUT(SPI_OUT_AUD),      // Spi output to MCP3008_1
        .SCLK(SCLK_AUD),            // SPI clock
        .CS_n(CS_n_AUD),            // Conversion start / Shutdown
        .adc_out(audio_in[0])       // Connects to top level
    );  

    mcp3008_audio #(.SCLK_N(4)) POT_input ( // SCLK_N = # of bits for clock divider counter
        .CLK50(PLL_CLK1),           // 50 MHz Clock. Divided Rate = 50 MHz/2^4 = 3.125 MHz
        .reset_n,                   // active low reset
        .SPI_IN(SPI_IN_POT),        // Spi input from MCP3008_2
        .SPI_OUT(SPI_OUT_POT),      // Spi output to MCP3008_2
        .SCLK(SCLK_POT),            // SPI clock
        .CS_n(CS_n_POT),            // Conversion start / Shutdown
        .adc_out(pot_in)            // pot_in[0] = LPF, pot_in[1] = HPF
    );

    diffEq #(.N(`N)) iir (          // N = bits
        .x(audio_in[0:1]),          // two inputs, x[n] and x[n-1]
        .y(duty_val[1]),            // feedback y[n-1]
        .out(irr_out),              // output
        .f,                         // frequency from pots
        .fs,                        // sample frequency (NEEDS TO BE FIGURED OUT) **************
        .filt_type(FILT_TYPE)       // 0 for LPF, 1 for HPF 
    );              

    freqconvert #(.M(10), .N(15), .FMAX(20000), .FMIN(20)) freq
    (
        .clk(CLOCK_50),             // Clock (MAY NEED TO BE ADJUSTED)**************
        .reset_n,                   // active low reset
        .adc_in(raw_freq_input),    // Raw ADC word to be converted to frequency. Depends on pin input.
        .freq_out(f)                // Converted frequency output
    );

    pwm_audio #(.N(`N)) pwm (
        /********* MAYBE CHANGE CLOCK TO 256 MHz to get 2x ADC fs (125 kHz * 1024 * 2 = 256 MHz)*/
        .clk(PLL_CLK2),             // 300 MHz Clock. DAC sample rate = 300 MHz/2^10 = 293 kHz
        .reset_n,                   // active low reset
        .duty_val(irr_out),         // Output value after processing
        .pwm_out(PWM_OUT)           // PWM output
    );

    pll_1 pll_1_0 (
		.refclk   (CLOCK_50),   //  refclk.clk
		.outclk_0 (PLL_CLK1) // outclk0.clk
	);
	
	pllfast2 pllfast2_0 (
		.refclk   (FPGA_CLK1_50),   //  refclk.clk
		.outclk_0 (PLL_CLK2) // outclk0.clk		
	);

    //***********************************************************************//
    //  CLOCK AND SAMPLING CALCULATIONS                                      //
    //***********************************************************************//
    /*
    Audio ADC In Frequency: 
    fs_in = INPUT_CLOCK / (DIVIDER * 25)
    fs_in = 50 MHz /(16 * 25) = 125 kHz

    PWM DAC Out Frequency: 
    Might want to match to audio in and update halfway through input sample for stability
    fs_out = INPUT_CLOCK / 1024
    fs_out = 300 MHz / 1024 = 292.968 kHz

    Pot Input Frequency (not that important. Can go slower if we need)
    fs_pot = INPUT_CLOCK / (DIVIDER * 25 / 2)
    fs_pot = 50 MHz / (16 * 25 / 2) = 62.5 kHz 

    */

    //***********************************************************************//
    //  LOGIC                                                                //
    //***********************************************************************//

    // Select pot input
    assign raw_freq_input = FILT_TYPE? pot_in[`HPF]:pot_in[`LPF];

    // ff for storing previous values
    always_ff @(posedge clk, negedge reset_n) begin // ******* CHANGE CLOCK WHEN U KNOW WHAT ONE TO USE
        if (~reset_n) begin
            // figure out what to reset later
        end
        else begin
            audio_in[1] <= audio_in[0];  // might need next_vals to hold until its time to shift
            duty_val[1] <= duty_val[0];  // might need next_vals to hold until its time to shift   
        end

    end



    // Combinational
    always_comb begin
        // set sampling frequency for IRR logic
        fs = 'd48000; // PLACEHOLDER
    end


    endmodule


    // TO DO
    // - merge other top level stuff
    // - figure out clock syncs between modules to avoid unstable sampling
    // - figure out sampling frequency