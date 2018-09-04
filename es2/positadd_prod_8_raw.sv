// Laurens van Dam
// Delft University of Technology
// May 2018

`timescale 1ns / 1ps
`default_nettype wire

import posit_defines::*;

module positadd_prod_8_raw (clk, in1, in2, start, result, done, truncated);

    input wire clk, start;
    input wire [POSIT_SERIALIZED_WIDTH_PRODUCT_ES2-1:0] in1, in2;
    output wire [POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_ES2-1:0] result;
    output wire done, truncated;


    //   ___
    //  / _ \
    // | | | |
    // | | | |
    // | |_| |
    //  \___/
    logic r0_start;

    value_product r0_a, r0_b;
    logic r0_operation;

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
            r0_a.sgn <= in1[67];
            r0_a.scale <= in1[66:58];
            r0_a.fraction <= in1[57:2];
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
            r0_b.sgn <= in2[67];
            r0_b.scale <= in2[66:58];
            r0_b.fraction <= in2[57:2];
            r0_b.inf <= in2[1];
            r0_b.zero <= in2[0];
        end

        r0_start <= (start === 'x) ? '0 : start;
    end

    value_product r0_low, r0_hi;

    logic r0_a_lt_b; // A larger than B
    assign r0_a_lt_b = r0_b.zero ? '1 : (r0_a.zero ? '0 : ((r0_a.scale > r0_b.scale) ? '1 : (r0_a.scale < r0_b.scale ? '0 : (r0_a.fraction >= r0_b.fraction ? '1 : '0))));

    assign r0_operation = r0_a.sgn ~^ r0_b.sgn; // 1 = equal signs = add, 0 = unequal signs = subtract
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

    logic r1_operation;

    always @(posedge clk)
    begin
        r1_start <= r0_start;

        r1_low <= r0_low;
        r1_hi <= r0_hi;
        r1_operation <= r0_operation;
    end

    // Difference in scales (regime and exponent)
    // Amount the smaller input has to be shifted (everything of the scale difference that the regime cannot cover)
    logic unsigned [8:0] r1_scale_diff;
    assign r1_scale_diff = r1_hi.scale - r1_low.scale; // TODO this is dirty

    // Shift smaller magnitude based on scale difference
    logic [2*AMBITS-1:0] r1_low_fraction_shifted; // TODO We lose some bits here
    shift_right #(
        .N(2*AMBITS),
        .S(9)
    ) scale_matching_shift (
        .a({~r1_low.zero, r1_low.fraction, {AMBITS+3{1'b0}}}),
        .b(r1_scale_diff), // Shift to right by scale difference
        .c(r1_low_fraction_shifted)
    );

    logic r1_truncated_after_equalizing;
    assign r1_truncated_after_equalizing = |r1_low_fraction_shifted[AMBITS-1:0];

    // Add the fractions
    logic unsigned [AMBITS:0] r1_fraction_sum_raw, r1_fraction_sum_raw_add, r1_fraction_sum_raw_sub;

    assign r1_fraction_sum_raw_add = {~r1_hi.zero, r1_hi.fraction, {3{1'b0}}} + r1_low_fraction_shifted[2*AMBITS-1:AMBITS];
    assign r1_fraction_sum_raw_sub = {~r1_hi.zero, r1_hi.fraction, {3{1'b0}}} - r1_low_fraction_shifted[2*AMBITS-1:AMBITS];
    assign r1_fraction_sum_raw = r1_operation ? r1_fraction_sum_raw_add : r1_fraction_sum_raw_sub;


    //  __   ____
    // /_ | |  _ \
    //  | | | |_) |
    //  | | |  _ <
    //  | | | |_) |
    //  |_| |____/
    logic r1b_start;

    value_product r1b_low, r1b_hi;
    value_prod_sum r1b_sum;
    logic unsigned [AMBITS:0] r1b_fraction_sum_raw;
    logic r1b_truncated_after_equalizing;
    logic r1b_operation;

    always @(posedge clk)
    begin
        r1b_start <= r1_start;

        r1b_low <= r1_low;
        r1b_hi <= r1_hi;
        r1b_fraction_sum_raw <= r1_fraction_sum_raw;

        r1b_truncated_after_equalizing <= r1_truncated_after_equalizing;
        r1b_operation <= r1_operation;
    end

    // Result normalization: shift until normalized (and fix the sign)
    // Find the hidden bit (leading zero counter)
    logic [6:0] r1b_hidden_pos;
    LOD_N #(
        .N(128)
    ) hidden_bit_counter(
        .in({r1b_fraction_sum_raw[AMBITS:0], {128-AMBITS-1{1'b0}}}),
        .out(r1b_hidden_pos)
    );

    logic signed [8:0] r1b_scale_sum;
    assign r1b_scale_sum = r1b_fraction_sum_raw[AMBITS] ? (r1b_hi.scale + 1) : (~r1b_fraction_sum_raw[AMBITS-1] ? (r1b_hi.scale - r1b_hidden_pos + 1) : r1b_hi.scale);

    assign r1b_sum.sgn = r1b_hi.sgn;
    assign r1b_sum.scale = r1b_scale_sum;
    assign r1b_sum.zero = (r1b_operation == 1'b0 && r1b_hi.scale == r1b_low.scale && r1b_hi.fraction == r1b_low.fraction) ? '1 : (r1b_hi.zero & r1b_low.zero);
    assign r1b_sum.inf = r1b_hi.inf | r1b_low.inf;

    logic [6:0] r1b_shift_amount_hiddenbit_out;
    assign r1b_shift_amount_hiddenbit_out = r1b_hidden_pos + 1;


    //  ___
    // |__ \
    //    ) |
    //   / /
    //  / /_
    // |____|
    logic r2_start;

    value_prod_sum r2_sum;
    logic unsigned [AMBITS:0] r2_fraction_sum_raw;
    logic [6:0] r2_shift_amount_hiddenbit_out;
    logic r2_truncated_after_equalizing;

    always @(posedge clk)
    begin
        r2_start <= r1b_start;

        r2_sum <= r1b_sum;
        r2_fraction_sum_raw <= r1b_fraction_sum_raw;
        r2_shift_amount_hiddenbit_out <= r1b_shift_amount_hiddenbit_out;

        r2_truncated_after_equalizing <= r1b_truncated_after_equalizing;
    end

    // Normalize the sum output (shift left)
    logic [AMBITS:0] r2_fraction_sum_normalized;
    shift_left #(
        .N(AMBITS+1),
        .S(7)
    ) ls (
        .a(r2_fraction_sum_raw[AMBITS:0]),
        .b(r2_shift_amount_hiddenbit_out),
        .c(r2_fraction_sum_normalized)
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

    always @(posedge clk)
    begin
        r2b_start <= r2_start;

        r2b_sum <= r2_sum;
        r2b_sum.fraction <= r2_fraction_sum_normalized[AMBITS:1];

        r2b_truncated_after_equalizing <= r2_truncated_after_equalizing;
    end

    //  ____
    // |___ \
    //   __) |
    //  |__ <
    //  ___) |
    // |____/
    logic r3_start;
    value_prod_sum r3_sum;
    logic r3_truncated_after_equalizing;

    always @(posedge clk)
    begin
        r3_start <= r2b_start;
        r3_sum <= r2b_sum;
        r3_truncated_after_equalizing <= r2b_truncated_after_equalizing;
    end



    //  ____    ____
    // |___ \  |  _ \
    //   __) | | |_) |
    //  |__ <  |  _ <
    //  ___) | | |_) |
    // |____/  |____/
    logic r3b_start;
    value_prod_sum r3b_sum;
    logic r3b_truncated_after_equalizing;

    always @(posedge clk)
    begin
        r3b_start <= r3_start;
        r3b_sum <= r3_sum;

        r3b_truncated_after_equalizing <= r3_truncated_after_equalizing;
    end


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
