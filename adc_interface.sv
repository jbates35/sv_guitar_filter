/********
adcinterface.sv

Written by Jimmy Bates (A01035957)

ELEX 7660-Digital System Design
Lab 3

Date created: January 20,2022

Implements the state of the ADC machine

code for modelsim:
vsim work.adcinterface_tb; add wave sim:*; run -all

*********/

`define SCK_COUNT_MAX 'd11
`define N 12

module adcinterface(
    input logic clk, reset_n, //Clock and reset
    input logic [2:0] chan, // ADC channel to sample
    output logic [11:0] result, //ADC result

    // ltc2308 signals
    output logic ADC_CONVST, ADC_SCK, ADC_SDI,
    input logic ADC_SDO
);

    logic [`N:0] SPI_word_in, SPI_word_in_next; //If channel gets switched, need to make new word
    logic [(`N-1):0] SPI_word_out; //This might be unnecessary - will store the result that gets stuffed into "result"
    logic [3:0] count, count_next; // Which bit in the result that is currently being updated
    logic ADC_CONVST_next, ADC_SDI_next; // Take care of inversion and next config big
    logic word_finished; // Take rising edge and stuff word into result
    logic reset_count;  // Bit that resets count

    //State machine for the ADC
    typedef enum logic[5:0] { s_adc_start, s_adc_off, s_adc_sampnhold, s_adc_active, s_adc_finished } state_t;
        state_t ADC_curr = s_adc_start;
        state_t ADC_next; //Change this later to be a bit shifter

    always_comb begin
        //Multiplex state machine
        ADC_next = ADC_curr;

        case(ADC_curr)
            s_adc_start: ADC_next = s_adc_off;
            s_adc_off: ADC_next = (ADC_CONVST=='b1) ? s_adc_sampnhold : s_adc_off; //Lets CONVST go high for one cycle
            s_adc_sampnhold: ADC_next = s_adc_active; //Wait one cycle before taking ADC bits
            s_adc_active: ADC_next = (count==0) ? s_adc_finished : s_adc_active; //Continue taking bits until count is 0
            s_adc_finished: ADC_next = s_adc_off; //Wait one cycle before allowed to reset cycle
        endcase

        //Assign next counts
        count_next = (count == 0) ? 0 : count-1;

        //Config word
        SPI_word_in_next = (ADC_curr == s_adc_off) ? { 1'b1, chan[0], chan[2:1], 9'b1_0000_0000 } : SPI_word_in;

        //Assign clock to SCK if correct state
        ADC_SCK = (ADC_curr == s_adc_active) ? clk : 1'b0;

        //Set to high when ADC is finished, else 0
        word_finished = (ADC_curr == s_adc_finished) ? 'b1 : 'b0;

        //SPI_word_in and count get set when this is high
        reset_count = (ADC_curr == s_adc_sampnhold) ? 'b1 : 'b0; 

        //Config word bit
        case(ADC_curr)
            s_adc_sampnhold: ADC_SDI_next = SPI_word_in[`N];
            s_adc_active: ADC_SDI_next = SPI_word_in[count];
            default: ADC_SDI_next = 0;
        endcase
        

        //CONVST script
        if(ADC_curr == s_adc_off) ADC_CONVST_next = ~ADC_CONVST;
        else ADC_CONVST_next = 'b0;

    end

    //Take care of sck clock counting down 
    always_ff @(posedge ADC_SCK) begin  
        SPI_word_out[count] <= ADC_SDO; //Capture word coming in from SDI Out of ADC
    end
    always_ff @(negedge ADC_SCK, posedge reset_count) begin
			if(reset_count)        
				//Reset count to max value (11)
				count <= `SCK_COUNT_MAX;
			else
				//Else take next value of count which is either count-1 or 0
				count <= count_next;    
    end

    //update result once ADC is finished
    always_ff @(posedge word_finished) result <= SPI_word_out;

    //State machine clock
    always_ff @(negedge clk, negedge reset_n) begin   
        //Reset ADC
        if(~reset_n) begin
            ADC_curr <= s_adc_start;
            ADC_SDI <= 'b0;
            ADC_CONVST <= 'b0;
        end
        //Else, take next state of state machine
        else begin
            ADC_CONVST <= ADC_CONVST_next;
            ADC_curr <= ADC_next;
            SPI_word_in <= SPI_word_in_next;
            ADC_SDI <= ADC_SDI_next; //Config message
        end
    end
    
endmodule
