`timescale 1ns / 1ps


import posit_defines::*;

module testadd;

    reg [POSIT_SERIALIZED_WIDTH_PRODUCT_ES2-1:0] in1, in2;
    reg start;
    wire [POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_ES2-1:0] out;
    wire done, truncated;

    reg clk;
    integer outfile;


    // Instantiate the Unit Under Test (UUT)
    positadd_prod_4_raw uut (
        .clk(clk),
        .in1(in1),
        .in2(in2),
        .start(start),
        .result(out),
        .done(done),
        .truncated(truncated)
    );

    initial begin
        clk = '0;
    end

    always #5
    begin
        clk = ~clk;
    end

    always @(posedge clk)
    begin
        in1 = '0;
        in2 = {{POSIT_SERIALIZED_WIDTH_PRODUCT_ES2{1'b0}}, 1'b1};
    end

endmodule
