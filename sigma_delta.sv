module sigma_delta  #(parameter N = 10) (
    input logic clk, reset_n,
    input logic [N-1:0] ADC_in,
    output logic pwm_out
);

logic [N:0] PWM_accumulator;
logic [N-1:0] accumulator_next;

always_ff @(posedge clk, negedge reset_n) begin
    PWM_accumulator <= accumulator_next + ADC_in;

end 

always_comb begin
    accumulator_next = PWM_accumulator[N-1:0];
end

assign pwm_out = PWM_accumulator[8];

endmodule