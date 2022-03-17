/********
diffEq.sv

Written by Jimmy Bates (A01035957)
ELEX 7660-Digital System Design -Final Proj
Date created: Mar 16,2022

Implements difference equation

code for modelsim:
vsim work.diffEq_tb; add wave sim:*; run -all
*********/

`define PI       3.14159265 // fs / (FACT * pi) 

`define LPF     0
`define HPF     1 

module diffEq #(parameter N = 10) ( // N = bits
    input logic [0:1][N-1:0] x, // two inputs, x[n] and x[n-1]
    input logic [N-1:0] y, // feedback y[n-1]
    output logic [N-1:0] out, // output
    input logic [15:0] f, // frequency from pots
    input logic [16:0] fs, // sample frequency
    input logic filt_type // 0 for LPF, 1 for HPF 
);

logic [16:0] K;
logic [(N*2)+1:0] sum;
logic [1:0][N:0] h;

always_comb begin : difference

    K = fs/`PI; // h factor

    sum = 2**(2*N-1); // DC offset shifted by 2^N

    h[1] = 2**N * (K-f)/(K+f); // gets multiplied by y[n-1]

    if(filt_type==`HPF) begin
        h[0] = 2**N * K/(f+K); // gets multiplied by x[n] and x[n-1] for HPF
        sum += h[0] * (x[0] - x[1]) + h[1] * (y - 2**(N-1)); // SUM, y has to have offset subtracted
    end else begin
        h[0] = 2**N * f/(f+K);  // gets multiplied by x[n] and x[n-1] for LPF
        sum += h[0] * (x[0] + x[1] - 2**N) + h[1] * (y - 2**(N-1)); // SUM, now need dc offset on both
    end

    out = sum / 2**(N); //Shift to remove 2^N

end : difference

endmodule


 
