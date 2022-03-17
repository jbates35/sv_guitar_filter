/********
diffEq_tb.sv

Written by Jimmy Bates (A01035957)
ELEX 7660-Digital System Design -Final Proj
Date created: Mar 16,2022

Tests difference equation with a set of values

code for modelsim:
vsim work.diffEq_tb; add wave sim:*; run -all
*********/

`define LPF         0
`define HPF         1 

`define FS          88200   // Sample rate

`define F_HPF1      120     // for 60Hz sine
`define F_LPF1      10000   // for 15kHz sine

`define F_HPF2      2000    // For bandpass filt w 2kHz square
`define F_LPF2      15000   // For bandpass filt w 2kHz square


module diffEq_tb;

parameter N = 10; // Number of bits 

logic [0:1][N-1:0] x; // two inputs, x[n] and x[n-1]
logic [N-1:0] y; // feedback y[n-1]
logic [N-1:0] out; // output
logic [15:0] f; // frequency from pots
logic [16:0] fs; // sample frequency
logic filt_type; // 0 for LPF, 1 for HPF

diffEq dut_0 (.*); // device under test

// float h1_test_float;
int h1_test_int;
logic [N:0] h1_test_logic;

//Store values to test from CSV file
int x1 [0:2];
int x2 [0:2];
int y2 [0:2];
int out_correct_val [0:2];
int out_correct;

logic match;

initial begin

fs = `FS;

// 60 Hz sine first with HPF set at 120Hz

f = `F_HPF1;
filt_type = `HPF;

x1 = {
    525,
    732,
    798
};

x2 = {
    523,
    731,
    797
};

y2 = {
    523,
    636,
    643
};

out_correct_val = {
    525,
    636,
    643
};

for (int i = 0; i<=2; i++) begin
    y = y2[i];
    x[0] = x1[i];
    x[1] = x2[i];
    out_correct = out_correct_val[i];

    #5ns;

    match = ((out >= out_correct-5) && (out <= out_correct+5)); 

    #1us;
end

#1us;

// 15000 Hz sine second with LPF set at 10000Hz

//h1_test_float1 = (28075-f)/(28075+f);
//h1_test_float2 = 2^N * (28075-f)/(28075+f);
h1_test_int = 2**N * (28075-f)/(28075+f); // gets multiplied by y[n-1]
h1_test_logic = 2**N * (28075-f)/(28075+f); // gets multiplied by y[n-1]

f = `F_LPF1;
filt_type = `LPF;

x1 = {
    895,
    179,
    296
};

x2 = {
    715,
    520,
    130
};

y2 = {
    422,
    684,
    427
};

out_correct_val = {
    623,
    508,
    314
};

for (int i = 0; i<=2; i++) begin
    y = y2[i];
    x[0] = x1[i];
    x[1] = x2[i];
    out_correct = out_correct_val[i];

    #5ns;

    match = ((out >= out_correct-5) && (out <= out_correct+5)); 

    #1us;
end

$stop;

end

endmodule;