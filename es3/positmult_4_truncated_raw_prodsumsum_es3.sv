// Laurens van Dam
// Delft University of Technology
// May 2018

`timescale 1ns / 1ps
`default_nettype wire

import posit_defines_es3::*;

module positmult_4_truncated_raw_prodsumsum_es3 (clk, in1, in1_truncated, in2, in2_truncated, start, result, done, truncated);

    input wire clk, start;
    input wire [POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_SUM_ES3-1:0] in1, in2;
    input wire in1_truncated, in2_truncated;
    output wire [POSIT_SERIALIZED_WIDTH_PRODUCT_SUM_PRODUCT_SUM_ES3-1:0] result;
    output wire done, truncated;

    //   ___
    //  / _ \
    // | | | |
    // | | | |
    // | |_| |
    //  \___/
    logic r0_start;

    value_prod_sum_sum r0_a, r0_b;
    logic r0_in1_truncated, r0_in2_truncated;

    always @(posedge clk)
    begin
        if (in1[0] == 1'b1)
        begin
            r0_a.sgn <= '0;
            r0_a.scale <= '0;
            r0_a.fraction <= '0;
            r0_a.inf <= '0;
            r0_a.zero <= '1;

            r0_in1_truncated <= '0;
        end
        else
        begin
            r0_a.sgn <= in1[74];
            r0_a.scale <= in1[73:64];
            r0_a.fraction <= in1[63:2];
            r0_a.inf <= in1[1];
            r0_a.zero <= in1[0];

            r0_in1_truncated <= in1_truncated;
        end

        if (in2[0] == 1'b1)
        begin
            r0_b.sgn <= '0;
            r0_b.scale <= '0;
            r0_b.fraction <= '0;
            r0_b.inf <= '0;
            r0_b.zero <= '1;

            r0_in2_truncated <= '0;
        end
        else
        begin
            r0_b.sgn <= in2[74];
            r0_b.scale <= in2[73:64];
            r0_b.fraction <= in2[63:2];
            r0_b.inf <= in2[1];
            r0_b.zero <= in2[0];

            r0_in2_truncated <= in2_truncated;
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

    value_prod_sum_sum r1_a, r1_b;
    value_product_prod_sum_sum r1_product;
    logic r1_truncated;

    always @(posedge clk)
    begin
        r1_start <= r0_start;

        r1_a <= r0_a;
        r1_b <= r0_b;

        r1_truncated <= r0_in1_truncated | r0_in2_truncated;
    end

    logic [AAMMBITS-1:0] r1_fraction_mult, r1_result_fraction;

    logic [AAMHBITS-1:0] r1_r1, r1_r2;
    assign r1_r1 = {1'b1, r1_a.fraction[AAMBITS-1:0]}; // Add back hidden bit (fraction is without hidden bit)
    assign r1_r2 = {1'b1, r1_b.fraction[AAMBITS-1:0]}; // Add back hidden bit (fraction is without hidden bit)
    assign r1_fraction_mult = r1_r1 * r1_r2; // Unsigned multiplication of fractions

    // Check if the radix point needs to shift
    assign r1_product.scale   = r1_fraction_mult[AAMMBITS-1] ? (r1_a.scale + r1_b.scale + 1) : (r1_a.scale + r1_b.scale);
    assign r1_result_fraction = r1_fraction_mult[AAMMBITS-1] ? (r1_fraction_mult << 1) : (r1_fraction_mult << 2); // Shift hidden bit out

    assign r1_product.fraction = r1_result_fraction[AAMMBITS-1:0];
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
    value_product_prod_sum_sum r2_product;
    logic r2_truncated;

    always @(posedge clk)
    begin
        r2_start <= r1_start;
        r2_product <= r1_product;
        r2_truncated <= r1_truncated;
    end

    //  ____
    // |___ \
    //   __) |
    //  |__ <
    //  ___) |
    // |____/
    logic r3_start;
    value_product_prod_sum_sum r3_product;
    logic r3_truncated;

    always @(posedge clk)
    begin
        r3_start <= r2_start;
        r3_product <= r2_product;
        r3_truncated <= r2_truncated;
    end

    // Final output
    assign done = r3_start;

    value_product_prod_sum_sum result_product;

    assign result_product.sgn = r3_product.sgn;
    assign result_product.inf = r3_product.inf;
    assign result_product.zero = ~r3_product.inf & r3_product.zero;
    assign result_product.fraction = r3_product.fraction;
    assign result_product.scale = r3_product.scale;

    assign result = {result_product.sgn, result_product.scale, result_product.fraction, result_product.inf, result_product.zero};
    assign truncated = r3_truncated;

endmodule
