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
    input logic [1:0][N-1:0] x, // two inputs, x[n] and x[n-1]
    input logic [N-1:0] y, // feedback y[n-1]
    output logic [N-1:0] out, // output
    input logic [15:0] f, // frequency from pots
    input logic [16:0] fs, // sample frequency
    input logic filt_type // 0 for LPF, 1 for HPF 
);

logic [16:0] K;
logic signed [16:0] KHPF;
logic [(N*4)+1:0] sumLPF, sum2LPF;
logic [1:0][N:0] h;
logic signed [(N*6)+1:0] sumHPF, sum2HPF;
logic signed [1:0][N+1:0] hHPF;
logic signed [1:0][N:0] xTEMP;



always_comb begin : difference

    K = 'd19120; // h factor
    KHPF = signed'(K);///`PI;
    
    //sum = '0;//2**(2*N-1); // DC offset shifted by 2^N

    h[1] = (K-f)*2**N/(K+f); // gets multiplied by y[n-1]
    hHPF[1] = (KHPF-f)*2**N/(KHPF+f);

    xTEMP[0] = signed'(x[0]);
    xTEMP[1] = signed'(x[1]);

    if(filt_type==`HPF) begin

        sum2HPF = ( 'd19578880 / ( f + 'd19120 ) * (xTEMP[0] - xTEMP[1]) + 'd1024 * ( 'd19120 - f ) / ( f + 'd19120 ) * (y - 'd512) ) / 'd1024 + 'd512;

        out = sum2HPF[9:0] ; //Add offset back in 2^N

        sumLPF = '0; // clear LPF sum
        sum2LPF = '0; // Clear LPF sum

    end else begin
        h[0] = f*2**N/(f+K);  // gets multiplied by x[n] and x[n-1] for LPF
        sumLPF = (h[0] * (x[0] + x[1])) + (h[1] * y); // SUM, now need dc offset on both
        sum2LPF = sumLPF/2**N;
        out = sum2LPF[9:0]; //Shift to remove 2^N

        sumHPF = '0; // clear HPF sum
        sum2HPF = '0; // clear HPF sum

    end



end : difference

endmodule


 
