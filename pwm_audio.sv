// PWM Module
// Takes an input from 0-(2^N - 1) and outputs a PWM with duty cycle input
// Author: Tom Kuzma
// March 14, 2022

module pwm_audio #(parameter N = 10) (
    input logic clk, reset_n,
    input logic [N-1:0] duty_val,
    output logic pwm_out 
    );

    // internal signals
    logic [N-1:0] count, count_next, duty, duty_next;
    logic buff, buff_next;
    
    // counter and output error buffer ff
    always_ff @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            count <= '0;
            buff <= 1'b0;
            duty <= '0;
        end 
        else begin
            count <= count_next;
            buff <= buff_next;
            duty <= duty_next;
        end
    end 

    // next state comb logic
    always_comb begin
        count_next = count + 1;
        buff_next = (count < duty);

        // 
        if (count == '0)
            duty_next = duty_val;
        else duty_next = duty;
    end

    // PWM output 
    assign pwm_out = buff;
    

endmodule