/********
audio_test.sv

Written by Tom Kuzma (A01075531)
ELEX 7660-Digital System Design
Date created: April 6,2022

audio test for guitar filter Final Project for ELEX 7660
*********/

`define CHANNELS    2   // # of input channels for MCP3008_2
`define N           10  // # of bits for ADC/DAC
`define LPF         0   // LPF designator
`define HPF         1   // HPF designator

module audio_test (

    input logic reset_n,    // Right button on board
    input CLOCK_50,         // 50 MHz internal clock

    // Testing Pins
    output [15:0]GPIO,      // General testing output pins  [15:10]: GPIO_1 pysical pins 23-28
                            //                              pin 29: 5V, pin 30: GND 
                            //                              [9:0]: GPIO_1 pysical pins 31-40 

    // Audio MCP3008_1 Pins
    input SPI_IN_AUD,       // SPI input from MCP3008_1     GPIO_1 physical pin 1         
    output SPI_OUT_AUD,     // SPI output from MCP3008_1    GPIO_1 physical pin 2       
    output SCLK_AUD,        // SPI clock                    GPIO_1 physical pin 3 
    output CS_n_AUD,        // Conversion start/Shutdown    GPIO_1 physical pin 4 

    output PWM_OUT          // PWM DAC output               GPIO_1 physical pin 9
);

    // ADC from MCP3008's
    logic [`N-1:0] audio_adc;                   // Audio ADC conversion
    logic audio_valid;                          // Signals conversion is ready and stable

    // PWM DAC 
    logic [1:0][`N-1:0] duty_val;               // PWM duty after processing (audio_out)
    logic pwm_ready;                            // PWM ready for next duty cycle

    // clocks
    logic PLL_CLK1;                             // 50 MHz Clock
    logic PLL_CLK2;                             // 300 MHz Clock

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

    pwm_audio #(.N(10)) pwm (
        .clk(PLL_CLK2),             // 300 MHz Clock. DAC sample rate = 300 MHz/2^10 = 293 kHz
        .reset_n,                   // active low reset
        .duty_val(duty_val[0]),     // duty value input after processing (audio out)
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

    // duty values get valid signal from PWM module halfway through cycle
    always_ff @(posedge pwm_ready) begin
        duty_val[1] <= duty_val[0];
        duty_val[0] <= audio_adc;
    end

    // Test Outputs to GPIO_1 Physical pins pins 23-28, 31-40 (skip pin 29 and 30)
    assign GPIO[9:0] = audio_adc; // duty_val on pins 23-28, 31-34
    assign GPIO[12] = PLL_CLK1; // 50 MHz clock on pin 37
    assign GPIO[13] = PLL_CLK2; // 300 MHz clock on pin 38
    assign GPIO[14] = pwm_ready;    // for pwm output frequency measurement on pin 39
    assign GPIO[15] = audio_valid; // for audio sampling frequency measurement pin 40
    assign GPIO[11] = SCLK_AUD; // tie unused pins to GND
    assign GPIO[10] = 1'b0;


endmodule