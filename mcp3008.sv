/********
mcp3008.sv

Written by Jimmy Bates (A01035957)
ELEX 7660-Digital System Design -Final Proj
Date created: Mar 19,2022

Implements an spi module to talk to MCP3008 chip that performs ADC on 2 potentiometers

code for modelsim:
vsim work.mcp3008_tb; add wave -r sim:/mcp3008_tb/*; run -all
*********/

`define SCLK_N 7 //Bit count of SCLK_next to create clock
`define N 10 // Bit count of ADC
//`define CHANNELS 2 // How many channels to keep track of and poll
//`define CHAN_N $clog2(`CHANNELS) // How many bits are needed to keep track of channels (log_2(CHANNELS))
`define INDEX_MAX 24 // How many bits are in the spi total

module mcp3008 #(parameter CHANNELS = 2) ( 
    input logic CLK50, reset_n, // Connects from top level
    input logic SPI_IN, // Spi input from MCP3008
    output logic SPI_OUT, // Spi output to MCP3008
    output logic SCLK, // SPI clock
    output logic CS_n, // Conversion start / Shutdown
    output logic [$clog2(CHANNELS):0][`N-1:0] adc_out, // Connects to top level
    output logic valid // Signals conversion is ready and stable
);

logic [`SCLK_N-1:0] SCLK_count; // Clock divider for SCLK
logic [2:0][7:0] inWord, outWord; // Stores buffered words
logic [$clog2(CHANNELS):0] chan, chan_next; //Keeps track of ADC channel
logic [5:0] spi_index, spi_index_next; //index that keeps track of overall sequence of SPI
logic [3:0] bit_index; // Which bit is getting updated
logic [1:0] word_index; // Which word is getting updated
logic [`CHAN_N:0][`N-1:0] adc_out_next; // Stores ADC value in
logic CS_n_next; // Turns low when SPI index is at max

//Get state machine
typedef enum { 
    OFF,
    START, 
    ACTIVE, 
    READY 
} state_t;
state_t CURR = OFF;
state_t NEXT;


//Cycle through state machine
always_comb begin : STATEMACHINE
    NEXT = CURR;
    case (CURR)
        OFF: NEXT = START; // Start SPI after reset
        START: NEXT = ACTIVE; // Advance when CS_N gets turned off
        ACTIVE: NEXT = (spi_index == 0) ? READY : ACTIVE; // Advance
        READY: NEXT = START; 
    endcase
end : STATEMACHINE


always_comb begin
    //Assign outBuff bits
    outWord[2] = 'h01; // Always 1
    outWord[1] = 'h80 + chan * 'h10; // MSB is Single mode, then the next 3 bits are channel
    outWord[0] = 0; // Don't care

    word_index = spi_index/8; // Which word gets updated
    bit_index = spi_index%8; // Bit that gets updated

    //Set throughput values if no change is needed:
    CS_n_next = CS_n; 
    adc_out_next = adc_out;
    chan_next = chan;
    spi_index_next = spi_index;

    /* WHEN STATE MACHINE IS OFF (basically booted) WE NEED TO:
        - Set CS_n_next to 0
    */
    if(CURR==OFF) begin
        CS_n_next = 0;
    end

    /* WHEN STATE MACHINE IS START WE NEED TO:
        - reset spi_index
    */
    if(CURR==START) begin
        spi_index_next = `INDEX_MAX-1;
    end

    /* WHEN STATE MACHINE IS ACTIVE WE NEED TO:
        - increment spi_index by 1
        - output SPI_out according to word_index and bit_index
    */
    if(CURR==ACTIVE) begin
        spi_index_next = spi_index - 1;
        SPI_OUT = outWord[word_index][bit_index];
        if(spi_index == 0) CS_n_next = 1; // Turn off SC_n
    end

    /* WHEN STATE MACHINE IS READY, WE NEED TO:
        - change CS_n to high
        - move the channel up or reset it to 0
        - log the ADC value for the output
    */
    if(CURR==READY) begin
        CS_n_next = 0; // stop conversion
        chan_next = (chan == CHANNELS-1) ? 0 : chan+1; // increment channel
        adc_out_next[chan] = { inWord[1][1:0], inWord[0][7:0] }; // store word in adc_out
    end
end

always_ff @(posedge SCLK, negedge reset_n) begin
    if(~reset_n) begin
        CURR <= OFF;
        spi_index <= 0;
        adc_out <= 0; 
        chan <= 0;
        CS_n <= 1;
    end else begin
        CURR <= NEXT; // Change state
        spi_index <= spi_index_next; // Increment spi bit selected
        adc_out <= adc_out_next; // Load ADC values into output of module
        chan <= chan_next; // Increment channel when cycled through\
        CS_n <= CS_n_next; // Start conversion
    end
end

always_ff @(negedge SCLK) inWord[word_index][bit_index] <= SPI_IN; // Take bit from MCP3008 on falling edge of clk

always_ff @(posedge CLK50, negedge reset_n) begin
    //Counts up to 2^N-1 then rolls over
    if(~reset_n) begin
        SCLK_count <= 0;
        SCLK <= 0; 
    end else begin
        SCLK_count <= SCLK_count + 1; // Count up for 2^N-1
        if(&SCLK_count) SCLK <= ~SCLK; //Toggle SPI clock
    end
end

// assign valid conversion bit
assign valid = (CURR == START)? 1'b1:1'b0;

endmodule
