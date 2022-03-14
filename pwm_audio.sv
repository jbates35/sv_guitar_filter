// PWM Module
// Takes an input from 0-(2^N - 1) and outputs a PWM at 97.7 kHz @ N = 10
// Author: Tom Kuzma
// March 14, 2022

module pwm_audio #(parameter N = 10) (
    input logic clk, reset_n
    input logic [N:0] duty_val,
    output logic pwm_out 
    );

    // internal signals
    logic [N-1:0] count, count_next;
    logic buff, buff_next;
    
    // counter and output error buffer ff
    always_ff @(posedge clik or negedge reset_n) begin
        if (~reset_n) begin
            count <= '0;
            buff <= 1'b0;
        end 
        else begin
            count <= count_next;
            buff <= buff_next;
        end
    end 

    // next state comb logic
    always_comb begin
        count_next = count + 1;
        buff_next = (count < duty_val);
    end


    // PWM output 
    assign pwm_out = buff;

endmodule