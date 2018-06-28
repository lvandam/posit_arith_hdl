// Laurens van Dam
// Delft University of Technology
// May 2018

`timescale 1ns / 1ps
`default_nettype wire

import posit_defines_es3::*;

module positadd_prod_8_raw_es3 (clk, in1, in2, start, result, done, truncated);

    input wire clk, start;
    input wire [POSIT_SERIALIZED_WIDTH_PRODUCT_ES3-1:0] in1, in2;
    output wire [POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_ES3-1:0] result;
    output wire done, truncated;

    //   ___
    //  / _ \
    // | | | |
    // | | | |
    // | |_| |
    //  \___/
    logic r0_start;

    value_product r0_a, r0_b;

    always @(posedge clk)
    begin
        if (in1[0] == 1'b1)
        begin
            r0_a.sgn <= '0;
            r0_a.scale <= '0;
            r0_a.fraction <= '0;
            r0_a.inf <= '0;
            r0_a.zero <= '1;
        end
        else
        begin
            r0_a.sgn <= in1[66];
            r0_a.scale <= in1[65:56];
            r0_a.fraction <= in1[55:2];
            r0_a.inf <= in1[1];
            r0_a.zero <= in1[0];
        end

        if (in2[0] == 1'b1)
        begin
            r0_b.sgn <= '0;
            r0_b.scale <= '0;
            r0_b.fraction <= '0;
            r0_b.inf <= '0;
            r0_b.zero <= '1;
        end
        else
        begin
            r0_b.sgn <= in2[66];
            r0_b.scale <= in2[65:56];
            r0_b.fraction <= in2[55:2];
            r0_b.inf <= in2[1];
            r0_b.zero <= in2[0];
        end

        r0_start <= (start === 'x) ? '0 : start;
    end

    value_product r0_low, r0_hi;

    logic r0_a_lt_b; // A larger than B
    assign r0_a_lt_b = r0_b.zero ? '1 : (r0_a.zero ? '0 : ((r0_a.scale > r0_b.scale) ? '1 : (r0_a.scale < r0_b.scale ? '0 : (r0_a.fraction >= r0_b.fraction ? '1 : '0))));

    assign r0_low = r0_a_lt_b ? r0_b : r0_a;
    assign r0_hi = r0_a_lt_b ? r0_a : r0_b;


    //  __
    // /_ |
    //  | |
    //  | |
    //  | |
    //  |_|
    logic r1_start;

    value_product r1_low, r1_hi;

    always @(posedge clk)
    begin
        r1_start <= r0_start;

        r1_low <= r0_low;
        r1_hi <= r0_hi;
    end

    // Difference in scales (regime and exponent)
    // Amount the smaller input has to be shifted (everything of the scale difference that the regime cannot cover)
    logic unsigned [9:0] r1_scale_diff;
    assign r1_scale_diff = r1_hi.scale - r1_low.scale; // TODO this is dirty

    // Shift smaller magnitude based on scale difference
    logic [2*AMBITS-1:0] r1_low_fraction_shifted; // TODO We lose some bits here
    shift_right #(
        .N(2*AMBITS),
        .S(10)
    ) scale_matching_shift (
        .a({~r1_low.zero, r1_low.fraction, {AMBITS+3{1'b0}}}),
        .b(r1_scale_diff), // Shift to right by scale difference
        .c(r1_low_fraction_shifted)
    );

    //  __   ____
    // /_ | |  _ \
    //  | | | |_) |
    //  | | |  _ <
    //  | | | |_) |
    //  |_| |____/
    logic r1b_start;

    logic r1b_operation;
    value_product r1b_low, r1b_hi;
    logic r1b_zero, r1b_inf, r1b_sgn;
    logic signed [8:0] r1b_scale;
    logic [2*AMBITS-1:0] r1b_low_fraction_shifted;

    always @(posedge clk)
    begin
        r1b_start <= r1_start;

        r1b_low <= r1_low;
        r1b_hi <= r1_hi;
        r1b_low_fraction_shifted <= r1_low_fraction_shifted;
    end

    // Add the fractions
    logic unsigned [AMBITS:0] r1b_fraction_sum_raw, r1b_fraction_sum_raw_add, r1b_fraction_sum_raw_sub;

    assign r1b_operation = r1b_hi.sgn ~^ r1b_low.sgn; // 1 = equal signs = add, 0 = unequal signs = subtract
    // assign r1b_fraction_sum_raw_add = {~r1b_hi.zero, r1b_hi.fraction, {2{1'b0}}} + r1b_low_fraction_shifted[2*AMBITS-4:AMBITS-2];
    // assign r1b_fraction_sum_raw_sub = {~r1b_hi.zero, r1b_hi.fraction, {2{1'b0}}} - r1b_low_fraction_shifted[2*AMBITS-4:AMBITS-2];
    assign r1b_fraction_sum_raw_add = {~r1b_hi.zero, r1b_hi.fraction, {3{1'b0}}} + r1b_low_fraction_shifted[2*AMBITS-1:AMBITS];
    assign r1b_fraction_sum_raw_sub = {~r1b_hi.zero, r1b_hi.fraction, {3{1'b0}}} - r1b_low_fraction_shifted[2*AMBITS-1:AMBITS];
    assign r1b_fraction_sum_raw = r1b_operation ? r1b_fraction_sum_raw_add : r1b_fraction_sum_raw_sub;

    logic r1b_truncated_after_equalizing;
    assign r1b_truncated_after_equalizing = |r1b_low_fraction_shifted[AMBITS-1:0];

    assign r1b_zero = (r1b_operation == 1'b0 && r1b_hi.scale == r1b_low.scale && r1b_hi.fraction == r1b_low.fraction) ? '1 : (r1b_hi.zero & r1b_low.zero);
    assign r1b_inf = r1b_hi.inf | r1b_low.inf;
    assign r1b_sgn = r1b_hi.sgn;
    assign r1b_scale = r1b_hi.scale;



    //  ___
    // |__ \
    //    ) |
    //   / /
    //  / /_
    // |____|
    logic r2_start;

    logic r2_zero, r2_inf, r2_sgn;
    logic signed [9:0] r2_scale;
    logic unsigned [AMBITS:0] r2_fraction_sum_raw;
    logic r2_truncated_after_equalizing;

    always @(posedge clk)
    begin
        r2_start <= r1b_start;

        r2_zero <= r1b_zero;
        r2_inf <= r1b_inf;
        r2_sgn <= r1b_sgn;
        r2_scale <= r1b_scale;
        r2_fraction_sum_raw <= r1b_fraction_sum_raw;
        r2_truncated_after_equalizing <= r1b_truncated_after_equalizing;
    end

    // Result normalization: shift until normalized (and fix the sign)
    // Find the hidden bit (leading zero counter)
    logic [5:0] r2_hidden_pos;
    LOD_N #(
        .N(64)
    ) hidden_bit_counter(
        .in({r2_fraction_sum_raw[AMBITS:0], {64-AMBITS-1{1'b0}}}),
        .out(r2_hidden_pos)
    );



    //  ___    ____
    // |__ \  |  _ \
    //    ) | | |_) |
    //   / /  |  _ <
    //  / /_  | |_) |
    // |____| |____/
    logic r2b_start;

    value_prod_sum r2b_sum;
    logic r2b_truncated_after_equalizing;
    logic unsigned [AMBITS:0] r2b_fraction_sum_raw;
    logic r2b_zero, r2b_inf, r2b_sgn;
    logic signed [9:0] r2b_scale;
    logic [5:0] r2b_hidden_pos;

    always @(posedge clk)
    begin
        r2b_start <= r2_start;

        r2b_zero <= r2_zero;
        r2b_inf <= r2_inf;
        r2b_sgn <= r2_sgn;
        r2b_scale <= r2_scale;
        r2b_fraction_sum_raw <= r2_fraction_sum_raw;
        r2b_hidden_pos <= r2_hidden_pos;
        r2b_truncated_after_equalizing <= r2_truncated_after_equalizing;
    end

    logic signed [9:0] r2b_scale_sum;
    assign r2b_scale_sum = r2b_fraction_sum_raw[AMBITS] ? (r2b_scale + 1) : (~r2b_fraction_sum_raw[AMBITS-1] ? (r2b_scale - r2b_hidden_pos + 1) : r2b_scale);

    assign r2b_sum.sgn = r2b_sgn;
    assign r2b_sum.scale = r2b_scale_sum;
    assign r2b_sum.zero = r2b_zero;
    assign r2b_sum.inf = r2b_inf;

    //  ____
    // |___ \
    //   __) |
    //  |__ <
    //  ___) |
    // |____/
    logic r3_start;
    value_prod_sum r3_sum;
    logic unsigned [AMBITS:0] r3_fraction_sum_raw;
    logic [5:0] r3_hidden_pos;
    logic r3_truncated_after_equalizing;

    always @(posedge clk)
    begin
        r3_start <= r2b_start;

        r3_sum <= r2b_sum;
        r3_fraction_sum_raw <= r2b_fraction_sum_raw;
        r3_hidden_pos <= r2b_hidden_pos;
        r3_truncated_after_equalizing <= r2b_truncated_after_equalizing;
    end

    logic [6:0] r3_shift_amount_hiddenbit_out;
    assign r3_shift_amount_hiddenbit_out = r3_hidden_pos + 1;

    //  ____    ____
    // |___ \  |  _ \
    //   __) | | |_) |
    //  |__ <  |  _ <
    //  ___) | | |_) |
    // |____/  |____/
    logic r3b_start;
    value_prod_sum r3b_sum;
    logic unsigned [AMBITS:0] r3b_fraction_sum_raw;
    logic [6:0] r3b_shift_amount_hiddenbit_out;
    logic r3b_truncated_after_equalizing;

    always @(posedge clk)
    begin
        r3b_start <= r3_start;
        r3b_sum <= r3_sum;
        r3b_fraction_sum_raw <= r3_fraction_sum_raw;
        r3b_shift_amount_hiddenbit_out <= r3_shift_amount_hiddenbit_out;
        r3b_truncated_after_equalizing <= r3_truncated_after_equalizing;
    end

    // Normalize the sum output (shift left)
    logic [AMBITS:0] r3b_fraction_sum_normalized;
    shift_left #(
        .N(AMBITS+1),
        .S(7)
    ) ls (
        .a(r3b_fraction_sum_raw[AMBITS:0]),
        .b(r3b_shift_amount_hiddenbit_out),
        .c(r3b_fraction_sum_normalized)
    );


    //   ___     ___
    //  / _ \   / _ \
    // | (_) | | (_) |
    //  \__, |  \__, |
    //    / /     / /
    //   /_/     /_/
    logic r99_start;
    value_prod_sum r99_sum;
    logic r99_truncated_after_equalizing;

    always @(posedge clk)
    begin
        r99_start <= r3b_start;
        r99_sum <= r3b_sum;
        r99_sum.fraction <= r3b_fraction_sum_normalized[AMBITS:1];
        r99_truncated_after_equalizing <= r3b_truncated_after_equalizing;
    end

    // Final output
    assign done = r99_start;

    value_prod_sum result_sum;
    assign result_sum.sgn = r99_sum.sgn;
    assign result_sum.inf = r99_sum.inf;
    assign result_sum.zero = ~r99_sum.inf & r99_sum.zero;
    assign result_sum.fraction = r99_sum.fraction;
    assign result_sum.scale = r99_sum.scale;

    assign result = {result_sum.sgn, result_sum.scale, result_sum.fraction, result_sum.inf, result_sum.zero};
    assign truncated = r99_truncated_after_equalizing;

endmodule
