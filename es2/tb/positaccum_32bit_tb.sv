`timescale 1ns / 1ps

import posit_defines::*;

module positaccum_32bit_tb;

    function [31:0] log2;
        input reg [31:0] value;
    	begin
        	value = value - 1;
        	for (log2 = 0; value > 0; log2 = log2 + 1)
            begin
            	value = value >> 1;
            end
      	end
    endfunction

    parameter N = 32;
    parameter Bs = log2(N);
    parameter es = 2;

    reg [N-1:0] in1 = '0, in2 = '0;
    reg start = 0;
    reg rst;
    wire [POSIT_SERIALIZED_WIDTH_ACCUM_ES2-1:0] out_raw;
    wire [POSIT_SERIALIZED_WIDTH_PRODUCT_ES2-1:0] out_prod_raw;
    wire [POSIT_SERIALIZED_WIDTH_ES2-1:0] in1_raw, in2_raw;
    wire [N-1:0] out;
    wire done;
    wire done_mul;
    wire truncated;

    reg clk;
    integer outfile;

    function bit [POSIT_SERIALIZED_WIDTH_ES2-1:0] prod2val (input bit [POSIT_SERIALIZED_WIDTH_PRODUCT_ES2-1:0] a);
      prod2val = {a[67], a[65:58], a[57:31], a[1], a[0]};
    endfunction

        function bit [POSIT_SERIALIZED_WIDTH_ES2-1:0] accum2val (input bit [POSIT_SERIALIZED_WIDTH_ACCUM_ES2-1:0] a);
          accum2val = {a[157], a[156:149], a[148:122], a[1], a[0]};
        endfunction

    // Instantiate the Unit Under Test (UUT)
    posit_extract_raw extr1 (
        .in1(in1),
        .absolute(),
        .result(in1_raw)
    );

    posit_extract_raw extr2 (
        .in1(in2),
        .absolute(),
        .result(in2_raw)
    );

    positmult_4_raw mul (
        .clk(clk),
        .in1(in1_raw),
        .in2(in2_raw),
        .start(start),
        .result(out_prod_raw),
        .done(done_mul)
    );

    positaccum_16_raw accum (
        .clk(clk),
        .rst(rst),
        .in1(prod2val(out_prod_raw)),
        .start(done_mul),
        .result(out_raw),
        .done(done),
        .truncated(truncated)
    );

    posit_normalize_accum norm (
        .in1(out_raw),
        .truncated(truncated),
        .result(out),
        .inf(),
        .zero()
    );

    reg [N-1:0] data1 [1:65534];
    reg [N-1:0] data2 [1:65534];
    initial $readmemb("Pin1_inc_32-2_mult.txt", data1);
    initial $readmemb("Pin2_inc_32-2_mult.txt", data2);

    reg [31:0] i = 1;
    reg [31:0] j = 0;

	initial
    begin
		// Initialize Inputs
		in1 = 0;
        in2 = 0;
        rst = 0;
		in2 = 0;
		clk = 0;
		start = 0;
        i = 1;
        j = 0;

		// Wait 100 ns for global reset to finish
        #0 rst = 1; i = 1; j = 0;
        #15 rst = 0;
		// #100 i = 0; j = 0;
		// #20 start = 1;
        #652790 start = 0;
		#100;

		$fclose(outfile);
		$finish;
	end

    always #5
    begin
        clk = ~clk;
    end

    always @(posedge clk)
    begin
        if(j == 32'h00000001)
        begin
            in1 = data1[i];
            in2 = data2[i];
            start = 1;

            if(i == 32'hffffffff)
            begin
                $finish;
            end
            else
            begin
                if(rst == '0)
                    i = i + 1;
            end
        end
        else
        begin
            in1 = '0;
            in2 = '0;
            start = 0;
        end

        if(j == 32'h0000000f)
        begin
            j = 0;
        end
        else
        begin
            if(rst == '0)
                j = j + 1;
        end
    end

    initial
    begin
        outfile = $fopen("error_32bit.txt", "wb");
    end

    reg [N-1:0] result [1:65534];

    initial
    begin
        $readmemb("Pout_accum_32-2_mult.txt", result);
    end

    reg [N-1:0] diff;
    always @(negedge clk)
    begin
    	if(done)
        begin
         	diff = (result[i-2] > out) ? (result[i-2] - out) : (out - result[i-2]);
         	$fwrite(outfile, "in1=%b, in2=%b, result=%b, real=%b, diff=%d\n", data1[i-2], data2[i-2], out, result[i-2], diff);
     	end
    end
endmodule
