/********
audio_top.sv

Written by Tom Kuzma (A01075531)
ELEX 7660-Digital System Design
Date created: April 6,2022

Top level for guitar filter Final Project for ELEX 7660
*********/

`define CHANNELS    2   // # of input channels for MCP3008_2
`define N           10  // # of bits for ADC/DAC
`define LPF         0   // LPF designator
`define HPF         1   // HPF designator

module audio_top (

    // board pins
    input logic reset_n,    // Right button on board
    input CLOCK_50,         // 50 MHz internal clock
    output [7:0] LED,       // On-Board LED's

    // Testing Pins
    output [15:0]GPIO,      // General testing output pins  [0:5]: GPIO_1 pysical pins 23-28
                            //                              pin 29: 5V, pin 30: GND 
                            //                              [6:15]: GPIO_1 pysical pins 31-40 
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

    output PWM_OUT,          // PWM DAC output               GPIO_1 physical pin 9

    // Switch input pin for HPF or LPF 
    input FILT_TYPE         // Switch input for HPF/LPF     GPIO_1 physical pin 10

    // MX7533 DAC
        // TBD if needed
);

    //***********************************************************************//
    //  Internal Signals                                                     //
    //***********************************************************************//

    // ADC from MCP3008's
    logic [`N-1:0] audio_adc;                   // Audio ADC conversion
    logic [1:0][`N-1:0] x;                      // Current and previous Digital Audio from MCP3008_1
    logic audio_valid;                          // Signals conversion is ready and stable
    logic [`CHANNELS - 1:0][`N-1:0] pot_adc;    // pot input MCP3008_2 Internal
    logic pot_valid;                            // Signals conversion is ready and stable

    // IIR filter 
    logic[`N-1:0] lpf_out;                      // lpf output
    logic[`N-1:0] hpf_out;                      // hpf output
    logic filt_type;                            // 0 for LPF, 1 for HPF 

    // Frequency
    logic [1:0][15:0] freq_out;                 // converted frequency from freq module sent to diffEq
    logic [16:0] fs;                            // sample frequency: 60.096 kHz

    // PWM DAC 
    logic [1:0][`N-1:0] z;                      // PWM duty after LPF processing 
    logic [1:0][`N-1:0] y;                      // PWM duty after HPF processing  
    logic [`N-1:0] pwm_send;                    // to be sent to PWM_out
    logic pwm_ready;                            // PWM ready for next duty cycle

    // clocks
    logic PLL_CLK1;                             // 50 MHz Clock
    logic PLL_CLK2;                             // 300 MHz Clock
    logic clk_2MHz;                             // 2 MHz Clock

    // internal
    logic [1:0][`N-1:0] freq_input;              // MCP3008_2 ADC out from either channel 0 or 1



    //***********************************************************************//
    //  Module Instantiations                                                //
    //***********************************************************************//

    mcp3008_audio #(.SCLK_N(4)) ADC_audio (// SCLK_N = # of bits for clock divider counter
        .CLK50(PLL_CLK1),           // Divided Rate = 50 MHz/2^5 = 1.5625 MHz. fs =  1.5625 MHz/26 = 60.096 kHz
        .reset_n,                   // active low reset
        .SPI_IN(SPI_IN_AUD),        // Spi input from MCP3008_1
        .SPI_OUT(SPI_OUT_AUD),      // Spi output to MCP3008_1
        .SCLK(SCLK_AUD),            // SPI clock
        .CS_n(CS_n_AUD),            // Conversion start / Shutdown
        .adc_out(audio_adc),        // Converted output
        .valid(audio_valid)         // Signals conversion is ready and stable
    );  

    mcp3008 #(.CHANNELS(2), .SCLK_N(7)) POT_input ( // CHANNELS = # of Channels to cycle through, SCLK_N = clock divisor count
        .CLK50(PLL_CLK1),           // Divided Rate = 50 MHz/2^8 = 195.313 kHz. fs =  1.5625 MHz/26/2 = 30.048 kHz
        .reset_n,                   // active low reset
        .SPI_IN(SPI_IN_POT),        // Spi input from MCP3008_2
        .SPI_OUT(SPI_OUT_POT),      // Spi output to MCP3008_2
        .SCLK(SCLK_POT),            // SPI clock
        .CS_n(CS_n_POT),            // Conversion start / Shutdown
        .adc_out(pot_adc[1:0]),     // pot_adc[0] = LPF, pot_adc[1] = HPF
        .valid(pot_valid)           // Signals conversion is ready and stable
    );

    diffEq #(.N(10)) lpf (          // N = bits
        .x(x[0:1]),                 // two inputs, x[n] and x[n-1]
        .y(y[1]),                   // feedback y[n-1]
        .out(lpf_out),              // output
        .f(freq_out[`LPF]),         // frequency from converter module
        .fs(fs),                    // sample frequency fs =  1.5625 MHz/26 = 60.096 kHz
        .filt_type(1'b0)            // 0 for LPF, 1 for HPF ** SET TO 1 OR 0 FOR TESTING ***
    );   

    diffEq #(.N(10)) hpf (          // N = bits
        .x(y[0:1]),                 // two inputs, y[n] and y[n-1]
        .y(z[1]),                   // feedback y[n-1]
        .out(hpf_out),              // output
        .f(freq_out[`HPF]),         // frequency from converter module
        .fs(fs),                    // sample frequency fs =  1.5625 MHz/26 = 60.096 kHz
        .filt_type(1'b1)            // 0 for LPF, 1 for HPF ** SET TO 1 OR 0 FOR TESTING ***
    );                        

    freqconvert #(.M(10), .N(15), .FMAX(10000), .FMIN(100)) lpf_freq
    (
        .clk(clk_2MHz),             // Clock 2 MHz
        .reset_n,                   // active low reset
        .adc_in(freq_input[`LPF]),  // Raw ADC word to be converted to frequency. Depends on pin input.
        .freq_out(freq_out[`LPF])   // Converted frequency output
    );
    freqconvert #(.M(10), .N(15), .FMAX(16000), .FMIN(1000)) hpf_freq
    (
        .clk(clk_2MHz),             // Clock 2 MHz
        .reset_n,                   // active low reset
        .adc_in(freq_input[`HPF]),  // Raw ADC word to be converted to frequency. Depends on pin input.
        .freq_out(freq_out[`HPF])   // Converted frequency output
    );

    pwm_audio #(.N(10)) pwm (
        .clk(PLL_CLK2),             // 300 MHz Clock. DAC sample rate = 300 MHz/2^10 = 293 kHz
        .reset_n,                   // active low reset
        .duty_val(pwm_send),        // duty value input after processing (audio out)
        .pwm_out(PWM_OUT),          // PWM output
        .pwm_ready                  // PWM ready for next duty cycle
    );

    pll_1 pll_50MHz (
		.refclk   (CLOCK_50),       //  refclk.clk
        .rst(~reset_n),
		.outclk_0 (PLL_CLK1)        // 50 MHz clock
	);
	
	pllfast2 pll_300MHz (
		.refclk   (CLOCK_50),       //  refclk.clk
        .rst(~reset_n),
		.outclk_0 (PLL_CLK2)        // 300 MHz clock		
	);

    clockDiv #(.DIVISOR(500)) twoMeg (
        .clk(PLL_CLK1),             // 50 MHz reference clock
        .divClk(clk_2MHz)           // 200 kHz clock
    );

    //***********************************************************************//
    //  CLOCK AND SAMPLING CALCULATIONS                                      //
    //***********************************************************************//
    /*
    Audio ADC In Frequency: 
    fs_in = INPUT_CLOCK / (DIVIDER * 26)
    fs_in = 50 MHz /(32 * 26) = 60.096 kHz

    PWM DAC Out Frequency: 
    fs_out = INPUT_CLOCK / 1024
    fs_out = 300 MHz / 1024 = 292.968 kHz

    Pot Input Frequency (not that important. Can go slower if we need)
    fs_pot = INPUT_CLOCK / (DIVIDER * 26 / 2)
    fs_pot = 50 MHz / (2^8 * 26 / 2) = 3.756 kHz 

    */

    //***********************************************************************//
    //  LOGIC                                                                //
    //***********************************************************************//

    // Send valid pot conversion to freq converter module
    always_ff @(posedge pot_valid) begin
        freq_input[`LPF] <= pot_adc[`LPF]; // change FILT_TYPE to HPF or LPF if testing withou input switch
        freq_input[`HPF] <= pot_adc[`HPF];
    end

    // duty values get valid signal from PWM module halfway through cycle
    always_ff @(posedge pwm_ready) begin
       pwm_send <= z[0];
    end

    // Load new conversion on posedge of valid signal and shift previous
    always_ff @(posedge audio_valid) begin
        x[0] <= audio_adc;
        x[1] <= x[0];
        y[0] <= lpf_out;        
        y[1] <= y[0];
        z[0] <= hpf_out;
        z[1] <= z[0];
    end 

    // Combinational
    always_comb begin
        // set sampling frequency for IRR logic
        fs = 17'd60096; // 60.096 kHz
    end

    // Test Outputs to GPIO_1 Physical pins pins 23-28, 31-40 (skip pin 29 and 30)
    // assign GPIO[9:0] = audio_adc; // duty_val on pins 23-28, 31-34
    // assign GPIO[12] = PLL_CLK1; // 50 MHz clock on pin 37
    // assign GPIO[13] = PLL_CLK2; // 300 MHz clock on pin 38
    // assign GPIO[14] = pwm_ready;    // for pwm output frequency measurement on pin 39
    // assign GPIO[15] = audio_valid; // for audio sampling frequency measurement pin 40
    // assign GPIO[11] = SCLK_AUD; // tie unused pins to GND
    // assign GPIO[10] = 1'b0;

    assign GPIO[15:0] = 1'b0;

    // Monitor cutoff frequency with onboard LEDs
    assign LED[7:4] = pot_adc[1][9:6];
	assign LED[3:0] = pot_adc[0][9:6];


endmodule


