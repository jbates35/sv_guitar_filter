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
     // TBD ////////////////////////

    // internal
    logic raw_freq_input;                       // MCP3008_2 ADC out from either channel 0 or 1
    logic irr_out;                              // Processed output from IRR Filter


    //***********************************************************************//
    //  Module Instantiations                                                //
    //***********************************************************************//

    mcp3008_audio #(.SCLK_N(4)) ADC_audio (// SCLK_N = # of bits for clock divider counter
        .CLK50(CLOCK_50),           // Clock (MAY NEED TO BE ADJUSTED)************
        .reset_n,                   // active low reset
        .SPI_IN(SPI_IN_AUD),        // Spi input from MCP3008_1
        .SPI_OUT(SPI_OUT_AUD),      // Spi output to MCP3008_1
        .SCLK(SCLK_AUD),            // SPI clock
        .CS_n(CS_n_AUD),            // Conversion start / Shutdown
        .adc_out(audio_in[0])       // Connects to top level
    );  

    mcp3008_audio #(.SCLK_N(4)) POT_input ( // SCLK_N = # of bits for clock divider counter
        .CLK50(CLOCK_50),           // clock (MAY NEED TO BE ADJUSTED)**************
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
        .clk(CLOCK_50),             // Clock  (NEEDS TO BE ADJUSTED)**************
        .reset_n,                   // active low reset
        .duty_val(irr_out),         // Output value after processing
        .pwm_out(PWM_OUT)           // PWM output
    );

    // Select pot input
    assign raw_freq_input = FILT_TYPE? `HPF:`LPF;

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