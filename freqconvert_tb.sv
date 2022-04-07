/********
freqconvert.sv

Written by Jimmy Bates (A01035957)
ELEX 7660-Digital System Design -Final Proj
Date created: Apr 2,2022

test bench for freqconvert

code for modelsim:
vsim work.freqconvert_tb; add wave -r sim:/freqconvert_tb/*; run -all
*********/


module freqconvert_tb;

    logic [9:0] adc_in;
    logic [14:0] freq_out;
    logic clk, reset_n;
    
    int freq_correct;

    freqconvert dut_0 ( .* );
    
    int adc[] = { 0, 341, 683, 1023 };
    int freq[] = { 20, 197, 1998, 20000 };

    initial begin

        clk = 'b0;
        reset_n = 'b0;
        @(posedge clk);
        reset_n = 'b1;

        for(int i=0; i<=adc.size; i++) begin
            adc_in = adc[i];
            freq_correct = freq[i];
            @(posedge clk);
        end

        $stop;
        
    end

    // 50MHz clock
    always
        #1us clk = ~clk;
endmodule