// clockDiv.sv
// Divides input clock by DIVISOR parameter. Includes odd Divisors. 
// Author: Tom Kuzma
// Date: March 21. 2022

module clockDiv #(parameter DIVISOR = 2) (
    input logic clk,
    output logic divClk
    );

    // counter variables
    logic [$clog2(DIVISOR)-1:0] count;

    // counting
    always_ff @(posedge clk) begin
        count <= (count >= DIVISOR - 1)? '0:count + 1'b1;
    end

    // assign divClock out
    assign divClk = (count < DIVISOR/2);

    endmodule
