`timescale 1ns / 1ps

module positadd_8_32_3_tb;

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
    integer latency = 8;

    parameter N = 32;
    parameter Bs = log2(N);
    parameter es = 3;

    reg [N-1:0] in1, in2;
    reg start;
    wire [N-1:0] out;
    wire done;

    reg clk;
    integer outfile;


    // Instantiate the Unit Under Test (UUT)
    positadd_8_es3 uut (
        .clk(clk),
        .in1(in1),
        .in2(in2),
        .start(start),
        .result(out),
        .inf(inf),
        .zero(zero),
        .done(done)
    );

    reg [N-1:0] data1 [1:65534];
    reg [N-1:0] data2 [1:65534];
    initial $readmemb("Pin1_add_32-3_rand3.txt", data1);
    initial $readmemb("Pin2_add_32-3_rand3.txt", data2);

    reg [31:0] i;

	initial
    begin
		// Initialize Inputs
		in1 = 0;
		in2 = 0;
		clk = 0;
		start = 0;

		// Wait 100 ns for global reset to finish
		#100 i = 0;
		#20 start = 1;
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
        in1 = data1[i];
        in2 = data2[i];

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
        outfile = $fopen("error_32bit.txt", "wb");
    end

    reg [N-1:0] result [1:65534];

    initial
    begin
        $readmemb("Pout_add_32-3_rand3.txt", result);
    end

    reg [N-1:0] diff;
    always @(negedge clk)
    begin
    	if(start)
        begin
         	diff = (result[i-latency-1] > out) ? (result[i-latency-1] - out) : (out - result[i-latency-1]);
         	$fwrite(outfile, "in1=%b, in2=%b, result=%b, real=%b, diff=%d\n", data1[i-latency-1], data2[i-latency-1], out, result[i-latency-1], diff);
     	end
    end
endmodule
