// Laurens van Dam
// Delft University of Technology
// May 2018

`timescale 1ns / 1ps
`default_nettype wire

import posit_defines_es3::*;

module positadd_4_raw_es3 (clk, in1, in2, start, result, done);

    input wire clk, start;
    input wire [POSIT_SERIALIZED_WIDTH_ES3-1:0] in1, in2;
    output wire [POSIT_SERIALIZED_WIDTH_SUM_ES3-1:0] result;
    output wire done;

    //   ___
    //  / _ \
    // | | | |
    // | | | |
    // | |_| |
    //  \___/
    logic r0_start;

    value r0_a, r0_b;
    logic r0_operation;

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

    value r0_low, r0_hi;

    logic r0_a_lt_b; // A larger than B
    assign r0_a_lt_b = {r0_a.scale, r0_a.fraction} >= {r0_b.scale, r0_b.fraction} ? '1 : '0;

    assign r0_operation = r0_a.sgn ~^ r0_b.sgn; // 1 = equal signs = add, 0 = unequal signs = subtract
    assign r0_low = r0_a_lt_b ? r0_b : r0_a;
    assign r0_hi = r0_a_lt_b ? r0_a : r0_b;

    logic unsigned [8:0] r0_scale_diff;
    assign r0_scale_diff = r0_hi.scale - r0_low.scale; // TODO this is dirty


    //  __
    // /_ |
    //  | |
    //  | |
    //  | |
    //  |_|
    logic r1_start;

    value r1_low, r1_hi;
    logic r1_operation;
    logic unsigned [8:0] r1_scale_diff;

    always @(posedge clk)
    begin
        r1_start <= r0_start;

        r1_low <= r0_low;
        r1_hi <= r0_hi;
        r1_operation <= r0_operation;
        r1_scale_diff <= r0_scale_diff;
    end

    // Difference in scales (regime and exponent)
    // Amount the smaller input has to be shifted (everything of the scale difference that the regime cannot cover)

    // Shift smaller magnitude based on scale difference
    logic [2*ABITS-4:0] r1_low_fraction_shifted; // TODO We lose some bits here
    shift_right #(
        .N(2*ABITS-3),
        .S(9)
    ) scale_matching_shift (
        .a({~r1_low.zero, r1_low.fraction, {ABITS{1'b0}}}),
        .b(r1_scale_diff), // Shift to right by scale difference
        .c(r1_low_fraction_shifted)
    );

    logic r1_truncated_after_equalizing;
    assign r1_truncated_after_equalizing = |r1_low_fraction_shifted[ABITS-4:0];

    // Add the fractions
    logic unsigned [ABITS:0] r1_fraction_sum_raw, r1_fraction_sum_raw_add, r1_fraction_sum_raw_sub;

    assign r1_fraction_sum_raw_add = {~r1_hi.zero, r1_hi.fraction, {2{1'b0}}} + r1_low_fraction_shifted[2*ABITS-4:ABITS-2];
    assign r1_fraction_sum_raw_sub = {~r1_hi.zero, r1_hi.fraction, {2{1'b0}}} - r1_low_fraction_shifted[2*ABITS-4:ABITS-2];
    assign r1_fraction_sum_raw = r1_operation ? r1_fraction_sum_raw_add : r1_fraction_sum_raw_sub;

    // Result normalization: shift until normalized (and fix the sign)
    // Find the hidden bit (leading zero counter)
    logic [4:0] r1_hidden_pos;
    logic signed [8:0] r1_scale_sum;
    LOD_N #(
        .N(32)
    ) hidden_bit_counter(
        .in({r1_fraction_sum_raw[ABITS-1:0], 2'b0}),
        .out(r1_hidden_pos)
    );

    assign r1_scale_sum = r1_fraction_sum_raw[ABITS-1] ? (r1_hi.scale + 1) : (~r1_fraction_sum_raw[ABITS-2] ? (r1_hi.scale - r1_hidden_pos + 1) : r1_hi.scale);


    //  ___
    // |__ \
    //    ) |
    //   / /
    //  / /_
    // |____|
    logic r2_start;
    value r2_hi, r2_low;

    value_sum r2_sum;
    logic unsigned [ABITS-1:0] r2_fraction_sum_raw;
    logic r2_truncated_after_equalizing, r2_out_rounded_zero;
    logic [4:0] r2_shift_amount_hiddenbit_out, r2_hidden_pos;
    logic signed [8:0] r2_scale_sum;

    always @(posedge clk)
    begin
        r2_start <= r1_start;
        r2_hi <= r1_hi;
        r2_low <= r1_low;
        r2_fraction_sum_raw <= r1_fraction_sum_raw;
        r2_truncated_after_equalizing <= r1_truncated_after_equalizing;
        r2_hidden_pos <= r1_hidden_pos;
        r2_scale_sum <= r1_scale_sum;
    end

    logic [6:0] r2_regime_shift_amount;
    assign r2_regime_shift_amount = (r2_scale_sum[8] == 0) ? 1 + (r2_scale_sum >> ES) : -(r2_scale_sum >> ES);

    assign r2_sum.sgn = r2_hi.sgn;
    assign r2_sum.scale = r2_scale_sum;
    assign r2_sum.zero = r2_hi.zero & r2_low.zero;
    assign r2_sum.inf = r2_hi.inf | r2_low.inf;

    assign r2_shift_amount_hiddenbit_out = r2_hidden_pos + 1;

    assign r2_out_rounded_zero = (r2_hidden_pos >= ABITS); // The hidden bit is shifted out of range, our sum becomes 0 (when truncated)

    // Normalize the sum output (shift left)
    logic [ABITS:0] r2_fraction_sum_normalized;
    shift_left #(
        .N(ABITS-0),
        .S(5)
    ) ls (
        .a(r2_fraction_sum_raw[ABITS-1:0]),
        .b(r2_shift_amount_hiddenbit_out),
        .c(r2_fraction_sum_normalized)
    );

    assign r2_sum.fraction = r2_fraction_sum_normalized;

    //  ____
    // |___ \
    //   __) |
    //  |__ <
    //  ___) |
    // |____/
    logic r3_start;
    value_sum r3_sum;

    always @(posedge clk)
    begin
        r3_start <= r2_start;
        r3_sum <= r2_sum;
    end

    assign done = r3_start;

    value_sum result_sum;
    assign result_sum.sgn = r3_sum.sgn;
    assign result_sum.inf = r3_sum.inf;
    assign result_sum.zero = ~r3_sum.inf & r3_sum.zero;
    assign result_sum.fraction = r3_sum.fraction;
    assign result_sum.scale = r3_sum.scale;

    assign result = {result_sum.sgn, result_sum.scale, result_sum.fraction, result_sum.inf, result_sum.zero};

endmodule
