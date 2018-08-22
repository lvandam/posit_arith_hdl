`timescale 1ns / 1ps

import posit_defines::*;

module test_mult;

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

    // Enter latency here
    integer latency = 12;
    integer latency_demt = 4;
    integer latency_epit = 4;

    parameter N = 32;
    parameter Bs = log2(N);
    parameter es = 2;

    reg [N-1:0] tmis_delta, mids_mt, tmis_epsilon, mids_it;
    reg start;
    wire [POSIT_SERIALIZED_WIDTH_PRODUCT_ES2-1:0] demt_raw, epit_raw;
    wire [POSIT_SERIALIZED_WIDTH_ES2-1:0] tmis_delta_raw, mids_mt_raw, tmis_epsilon_raw, mids_it_raw;
    wire [POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_ES2-1:0] deept_raw;
    wire [N-1:0] demt_out, epit_out, deept_out;
    wire done;
    wire deept_truncated;

    wire truncated;

    reg clk;
    integer outfile, outfile_demt, outfile_epit;

    function bit [POSIT_SERIALIZED_WIDTH_ES2-1:0] prod2val (input bit [POSIT_SERIALIZED_WIDTH_PRODUCT_ES2-1:0] a);
      prod2val = {a[67], a[65:58], a[57:31], a[1], a[0]};
    endfunction

    function bit [POSIT_SERIALIZED_WIDTH_ES2-1:0] sum2val (input bit [POSIT_SERIALIZED_WIDTH_SUM_ES2-1:0] a);
      sum2val = {a[41], a[40:33], a[32:6], a[1], a[0]};
    endfunction

    // Instantiate the Unit Under Test (UUT)
    posit_extract_raw extr1 (
        .in1(tmis_delta),
        .absolute(),
        .result(tmis_delta_raw)
    );

    posit_extract_raw extr2 (
        .in1(mids_mt),
        .absolute(),
        .result(mids_mt_raw)
    );

    positmult_4_raw mul_demt (
        .clk(clk),
        .in1(tmis_delta_raw),
        .in2(mids_mt_raw),
        .start(start),
        .result(demt_raw),
        .done()
    );

    posit_normalize_prod norm1 (
        .in1(demt_raw),
        .result(demt_out),
        .truncated('0),
        .inf(),
        .zero()
    );

    // mul epit
    posit_extract_raw extr3 (
        .in1(tmis_epsilon),
        .absolute(),
        .result(tmis_epsilon_raw)
    );

    posit_extract_raw extr4 (
        .in1(mids_it),
        .absolute(),
        .result(mids_it_raw)
    );

    positmult_4_raw mul_epit (
        .clk(clk),
        .in1(tmis_epsilon_raw),
        .in2(mids_it_raw),
        .start(start),
        .result(epit_raw),
        .done()
    );

    posit_normalize_prod norm_epit (
        .in1(epit_raw),
        .result(epit_out),
        .truncated('0),
        .inf(),
        .zero()
    );

    // add_delta_epsilon
    positadd_prod_8_raw add_deept (
        .clk(clk),
        .in1(demt_raw),
        .in2(epit_raw),
        .start(start),
        .result(deept_raw),
        .truncated(deept_truncated),
        .done()
    );

    posit_normalize_prod_sum norm_deept (
        .in1(deept_raw),
        .result(deept_out),
        .truncated(deept_truncated),
        .inf(),
        .zero()
    );

    reg [N-1:0] data1 [1:65534];
    reg [N-1:0] data2 [1:65534];
    reg [N-1:0] data3 [1:65534];
    reg [N-1:0] data4 [1:65534];
    initial $readmemb("Pin1_add_prod_32-2.txt", data1);
    initial $readmemb("Pin2_add_prod_32-2.txt", data2);
    initial $readmemb("Pin3_add_prod_32-2.txt", data3);
    initial $readmemb("Pin4_add_prod_32-2.txt", data4);

    reg [31:0] i;

	initial
    begin
		// Initialize Inputs
		tmis_delta = 0;
		mids_mt = 0;
        tmis_epsilon = 0;
        mids_it = 0;
		clk = 0;
		start = 0;

		// Wait 100 ns for global reset to finish
		#100 i = 0;
		#20 start = 1;
        #652790 start = 0;
		#100;

		$fclose(outfile);
		$fclose(outfile_demt);
		$fclose(outfile_epit);
		$finish;
	end

    always #5
    begin
        clk = ~clk;
    end

    always @(posedge clk)
    begin
        tmis_delta = data1[i];
        mids_mt = data2[i];
        tmis_epsilon = data3[i];
        mids_it = data4[i];

        if(i == 32'hffffffff)
        begin
            $finish;
        end
    	else
        begin
            i = i + 1;
        end
    end

    initial
    begin
        outfile = $fopen("deept_error_32bit.txt", "wb");
        outfile_demt = $fopen("demt_error_32bit.txt", "wb");
        outfile_epit = $fopen("epit_error_32bit.txt", "wb");
    end

    reg [N-1:0] result [1:65534];
    reg [N-1:0] result_demt [1:65534];
    reg [N-1:0] result_epit [1:65534];

    initial
    begin
        $readmemb("Pout_add_prod_32-2.txt", result);
        $readmemb("Pout_demt_add_prod_32-2.txt", result_demt);
        $readmemb("Pout_epit_add_prod_32-2.txt", result_epit);
    end

    reg [N-1:0] diff;
    always @(negedge clk)
    begin
    	if(start)
        begin
         	diff = (result[i-latency-1] > deept_out) ? (result[i-latency-1] - deept_out) : (deept_out - result[i-latency-1]);
         	$fwrite(outfile, "in1=%b, in2=%b, in3=%b, in4=%b, result=%b, real=%b, diff=%d\n", data1[i-latency-1], data2[i-latency-1], data3[i-latency-1], data4[i-latency-1], deept_out, result[i-latency-1], diff);
     	end
    end

    reg [N-1:0] diff_demt;
    always @(negedge clk)
    begin
    	if(start)
        begin
         	diff_demt = (result_demt[i-latency_demt-1] > demt_out) ? (result_demt[i-latency_demt-1] - demt_out) : (demt_out - result_demt[i-latency_demt-1]);
         	$fwrite(outfile_demt, "in1=%b, in2=%b, result=%b, real=%b, diff=%d\n", data1[i-latency_demt-1], data2[i-latency_demt-1], demt_out, result_demt[i-latency_demt-1], diff_demt);
     	end
    end

    reg [N-1:0] diff_epit;
    always @(negedge clk)
    begin
    	if(start)
        begin
         	diff_epit = (result_epit[i-latency_epit-1] > epit_out) ? (result_epit[i-latency_epit-1] - epit_out) : (epit_out - result_epit[i-latency_epit-1]);
         	$fwrite(outfile_epit, "in1=%b, in2=%b, result=%b, real=%b, diff=%d\n", data1[i-latency_epit-1], data2[i-latency_epit-1], epit_out, result_epit[i-latency_epit-1], diff_epit);
     	end
    end
endmodule
