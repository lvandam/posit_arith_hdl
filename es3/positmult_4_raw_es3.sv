// Laurens van Dam
// Delft University of Technology
// May 2018

`timescale 1ns / 1ps
`default_nettype wire

import posit_defines_es3::*;

module positmult_4_raw_es3 (clk, in1, in2, start, result, done);

    input wire clk, start;
    input wire [POSIT_SERIALIZED_WIDTH_ES3-1:0] in1, in2;
    output wire [POSIT_SERIALIZED_WIDTH_PRODUCT_ES3-1:0] result;
    output wire done;

    //   ___
    //  / _ \
    // | | | |
    // | | | |
    // | |_| |
    //  \___/

    logic r0_start;

    value r0_a, r0_b;

    always @(posedge clk)
    begin
        if (in1[0] == 1'b1)
        begin
            r0_a.sgn <= '0;
            r0_a.scale <= '0;
            r0_a.fraction <= '0;
            r0_a.inf <= '0;
            r0_a.zero <= in1[0];
        end
        else
        begin
            r0_a.sgn <= in1[37];
            r0_a.scale <= in1[36:28];
            r0_a.fraction <= in1[27:2];
            r0_a.inf <= in1[1];
            r0_a.zero <= in1[0];
        end

        if (in2[0] == 1'b1)
        begin
            r0_b.sgn <= '0;
            r0_b.scale <= '0;
            r0_b.fraction <= '0;
            r0_b.inf <= '0;
            r0_b.zero <= in2[0];
        end
        else
        begin
            r0_b.sgn <= in2[37];
            r0_b.scale <= in2[36:28];
            r0_b.fraction <= in2[27:2];
            r0_b.inf <= in2[1];
            r0_b.zero <= in2[0];
        end

        r0_start <= (start === 'x) ? '0 : start;
    end

    //  __
    // /_ |
    //  | |
    //  | |
    //  | |
    //  |_|
    logic r1_start;

    value r1_a, r1_b;
    value_product r1_product;

    always @(posedge clk)
    begin
        r1_start <= r0_start;

        r1_a <= r0_a;
        r1_b <= r0_b;
    end

    logic [MBITS-1:0] r1_fraction_mult, r1_result_fraction;

    logic [FHBITS-1:0] r1_r1, r1_r2;
    assign r1_r1 = {1'b1, r1_a.fraction}; // Add back hidden bit (fraction is without hidden bit)
    assign r1_r2 = {1'b1, r1_b.fraction}; // Add back hidden bit (fraction is without hidden bit)
    assign r1_fraction_mult = r1_r1 * r1_r2; // Unsigned multiplication of fractions

    // Check if the radix point needs to shift
    assign r1_product.scale   = r1_fraction_mult[MBITS-1] ? (r1_a.scale + r1_b.scale + 1) : (r1_a.scale + r1_b.scale);
    assign r1_result_fraction = r1_fraction_mult[MBITS-1] ? (r1_fraction_mult << 1) : (r1_fraction_mult << 2); // Shift hidden bit out

    assign r1_product.fraction = r1_result_fraction[MBITS-1:0];
    assign r1_product.sgn = r1_a.sgn ^ r1_b.sgn;
    assign r1_product.zero = r1_a.zero | r1_b.zero;
    assign r1_product.inf = r1_a.inf | r1_b.inf;


    //  ___
    // |__ \
    //    ) |
    //   / /
    //  / /_
    // |____|
    logic r2_start;
    value_product r2_product;

    always @(posedge clk)
    begin
        r2_start <= r1_start;
        r2_product <= r1_product;
    end


    //  ____
    // |___ \
    //   __) |
    //  |__ <
    //  ___) |
    // |____/
    logic r3_start;
    value_product r3_product;

    always @(posedge clk)
    begin
        r3_start <= r2_start;
        r3_product <= r2_product;
    end

    assign done = r3_start;

    value_product result_product;
    assign result_product.sgn = r3_product.sgn;
    assign result_product.inf = r3_product.inf;
    assign result_product.zero = ~r3_product.inf & r3_product.zero;
    assign result_product.fraction = r3_product.fraction;
    assign result_product.scale = r3_product.scale;

    assign result = {result_product.sgn, result_product.scale, result_product.fraction, result_product.inf, result_product.zero};

endmodule
