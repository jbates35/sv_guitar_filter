module pwm_audio_tb ();

parameter N = 4;
logic clk = 0, reset_n = 1;			 // clock and reset
logic [3:0] duty_val;
logic pwm_out;

pwm_audio#(.N(4)) dut_0 (.*);

initial begin
    duty_val = 8;

    reset_n = 0; // hold reset for 4 clocks
    repeat(4) @(negedge clk);
    reset_n = 1;



    repeat(32) @(posedge clk);

    duty_val = 2;

    repeat(32) @(posedge clk);

    duty_val = 14;

    repeat(32) @(posedge clk);


    $stop; 

end

// generate clock
always
	#1us clk = ~clk;

endmodule 