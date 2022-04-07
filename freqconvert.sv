/********
freqconvert.sv

Written by Jimmy Bates (A01035957)
ELEX 7660-Digital System Design -Final Proj
Date created: Apr 2,2022

Converts adc to

code for modelsim:
vsim work.freqconvert_tb; add wave -r sim:/freqconvert_tb/*; run -all
*********/

`define ADC_MAX 1024

module freqconvert #(parameter M=10, parameter N=15, parameter FMAX = 20000, parameter FMIN = 20)
(
    input logic [M-1:0] adc_in,
    input logic clk, reset_n,
    output logic [N-1:0] freq_out
);

    logic [63:0] freq_temp; // Extra digits so calculation doesn't truncate

    always_comb begin   
        freq_temp = (FMAX - FMIN) * (adc_in**3) / (`ADC_MAX**3) + FMIN; // Convert adc from 0-1024 to likely 20Hz-20kHz
    end

    always_ff @(posedge clk, negedge reset_n)
        if(~reset_n) freq_out <= 0; // reset to 0
        else freq_out <= freq_temp[N-1:0]; // take calculated value

endmodule