/********
mcp3008_tb.sv

Written by Jimmy Bates (A01035957)
ELEX 7660-Digital System Design -Final Proj
Date created: Mar 20,2022

Implements testbench for spi module

code for modelsim:
vsim work.mcp3008_tb; add wave -r sim:/mcp3008_tb/*; run -all
*********/

`define SCLK_N 7 //Bit count of SCLK_next to create clock
`define N 10 // Bit count of ADC
`define CHANNELS 2 // How many channels to keep track of and poll
`define CHAN_N 1 // How many bits are needed to keep track of channels (log_2(CHANNELS))
`define INDEX_MAX 24 // How many bits are in the spi total

`define TEST_WORD_1 'h8001D3 // 'b 01 1101 0011
`define TEST_WORD_2 'h8003F2 // 'b 11 1111 0010

module mcp3008_tb;

logic CLK50, reset_n; // Connects from top level
logic SPI_IN; // Spi input from MCP3008
logic SPI_OUT; // Spi output to MCP3008
logic SCLK; // SPI clock
logic CS_n; // Conversion start / Shutdown
logic [`CHAN_N:0][`N-1:0] adc_out; // Connects to top level

mcp3008 dut_0 (.*); //device under test

logic [23:0] spi_test_word;

initial begin

    //set SPI test word
    spi_test_word = `TEST_WORD_1;
    
    // reset
    CLK50 = '1;
    reset_n = '0;
    @(posedge CLK50);
    reset_n = '1;

    SPI_IN = 0;

    // have clock go for a while
    repeat(2) @(posedge SCLK);

    for(int i = `INDEX_MAX-1; i>=0; i--) begin
        SPI_IN = spi_test_word[i];
        @(posedge SCLK);
    end 

    //set SPI test word
    spi_test_word = `TEST_WORD_2; 

    repeat(2) @(posedge SCLK);

    for(int i = `INDEX_MAX-1; i>=0; i--) begin
        SPI_IN = spi_test_word[i];
        @(posedge SCLK);
    end    

    repeat(4) @(posedge SCLK);

    $stop ;

end

// 50MHz clock
always
    #20ns CLK50 = ~CLK50 ;

endmodule;