// Laurens van Dam
// Delft University of Technology
// May 2018

`timescale 1ns / 1ps
`default_nettype wire

import posit_defines::*;

module positadd (clk, in1, in2, start, result, inf, zero, done);

    input wire clk, start;
    input wire [31:0] in1, in2;
    output wire [31:0] result;
    output wire inf, zero, done;

    value a, b;
    value_sum sum;

    // Extract posit characteristics, among others the regime & exponent scales
    posit_extract a_extract (
        .in(in1),
        .out(a)
    );

    posit_extract b_extract (
        .in(in2),
        .out(b)
    );

    value low, hi;

    assign sum.zero = a.zero & b.zero;
    assign sum.inf = a.inf | b.inf;

    logic a_lt_b; // A larger than B
    logic [NBITS-1:0] in1_abs, in2_abs; // absolute inputs (TODO integrate this somewhere, unnecessary logic)
    assign in1_abs = a.sgn ? -in1 : in1;
    assign in2_abs = b.sgn ? -in2 : in2;
    assign a_lt_b = in1_abs[NBITS-2:0] >= in2_abs[NBITS-2:0] ? '1 : '0;

    assign operation = a.sgn ~^ b.sgn; // 1 = equal signs = add, 0 = unequal signs = subtract
    assign low = a_lt_b ? b : a;
    assign hi = a_lt_b ? a : b;

    // Difference in scales (regime and exponent)
    logic unsigned [7:0] scale_diff;
    assign scale_diff = hi.scale - low.scale; // TODO this is dirty

    // Amount the smaller input has to be shifted (everything of the scale difference that the regime cannot cover)
    logic unsigned [7:0] equalize_shift_amount;
    assign equalize_shift_amount = scale_diff;

    // Shift smaller magnitude based on scale difference
    logic [2*ABITS-1:0] low_fraction_shifted; // TODO We lose some bits here
    shift_right #(
        .N(2*ABITS),
        .S(8)
    ) scale_matching_shift (
        .a({~low.zero, low.fraction, {ABITS+3{1'b0}}}),
        .b(equalize_shift_amount), // Shift to right by scale difference
        .c(low_fraction_shifted)
    );

    logic truncated_after_equalizing;
    assign truncated_after_equalizing = |low_fraction_shifted[ABITS-1:0];

    // Add the fractions
    logic unsigned [ABITS:0] fraction_sum_raw, fraction_sum_raw_add, fraction_sum_raw_sub;

    assign fraction_sum_raw_add = {~hi.zero, hi.fraction, {3{1'b0}}} + low_fraction_shifted[2*ABITS-1:ABITS];
    assign fraction_sum_raw_sub = {~hi.zero, hi.fraction, {3{1'b0}}} - low_fraction_shifted[2*ABITS-1:ABITS];
    assign fraction_sum_raw = operation ? fraction_sum_raw_add : fraction_sum_raw_sub;

    // Result normalization: shift until normalized (and fix the sign)
    // Find the hidden bit (leading zero counter)
    logic [4:0] hidden_pos;
    LOD_N #(
        .N(ABITS+1)
    ) hidden_bit_counter(
        .in(fraction_sum_raw[ABITS:0]),
        .out(hidden_pos)
    );

    logic signed [7:0] scale_sum;
    assign scale_sum = fraction_sum_raw[ABITS] ? (hi.scale + 1) : (~fraction_sum_raw[ABITS-1] ? (hi.scale - hidden_pos + 1) : hi.scale);

    // Normalize the sum output (shift left)
    logic [4:0] shift_amount_hiddenbit_out;
    assign shift_amount_hiddenbit_out = hidden_pos + 1;

    logic [ABITS:0] fraction_sum_normalized;
    shift_left #(
        .N(ABITS+1),
        .S(5)
    ) ls (
        .a(fraction_sum_raw[ABITS:0]),
        .b(shift_amount_hiddenbit_out),
        .c(fraction_sum_normalized)
    );

    logic out_rounded_zero;
    assign out_rounded_zero = (hidden_pos >= ABITS); // The hidden bit is shifted out of range, our sum becomes 0 (when truncated)

    assign sum.sgn = hi.sgn;
    assign sum.scale = scale_sum;

    // PACK INTO POSIT
    logic [ES-1:0] result_exponent;
    assign result_exponent = sum.scale % (2 << ES);

    logic [6:0] regime_shift_amount;
    assign regime_shift_amount = (sum.scale[7] == 0) ? 1 + (sum.scale >> ES) : -(sum.scale >> ES);

    // STICKY BIT CALCULATION (all the bits from [msb, lsb], that is, msb is included)
    logic [ABITS:0] fraction_leftover;
    logic [6:0] leftover_shift;
    assign leftover_shift = NBITS - 4 - regime_shift_amount;
    // Determine all fraction bits that are truncated in the final result
    shift_left #(
        .N(ABITS+1),
        .S(7)
    ) fraction_leftover_shift (
        .a(fraction_sum_normalized), // exponent + fraction bits
        .b(leftover_shift), // Shift to right by regime value (clip at maximum number of bits)
        .c(fraction_leftover)
    );
    logic sticky_bit;
    assign sticky_bit = truncated_after_equalizing | |fraction_leftover[ABITS-1:0]; // Logical OR of all truncated fraction multiplication bits

    logic bafter;
    assign bafter = fraction_leftover[ABITS];
    // END STICKY BIT CALCULATION

    logic [28:0] fraction_truncated;
    assign fraction_truncated = {fraction_sum_normalized[ABITS:4], (fraction_sum_normalized[3] | sticky_bit)};

    logic [2*NBITS-1:0] regime_exp_fraction;
    assign regime_exp_fraction = { {NBITS-1{~sum.scale[7]}}, // Regime leading bits
                            sum.scale[7], // Regime terminating bit
                            result_exponent, // Exponent
                            fraction_truncated[28:0] }; // Fraction

    logic [2*NBITS-1:0] exp_fraction_shifted_for_regime;
    shift_right #(
        .N(2*NBITS),
        .S(7)
    ) shift_in_regime (
        .a(regime_exp_fraction), // exponent + fraction bits
        .b(regime_shift_amount), // Shift to right by regime value (clip at maximum number of bits)
        .c(exp_fraction_shifted_for_regime)
    );

    // TODO Inward projection?
    // Determine result (without sign), the unsigned regime+exp+fraction
    logic [NBITS-2:0] result_no_sign;
    assign result_no_sign = exp_fraction_shifted_for_regime[NBITS-1:1];

    // Perform rounding (based on sticky bit)
    logic blast, tie_to_even, round_nearest;
    logic [NBITS-2:0] result_no_sign_rounded;

    assign blast = result_no_sign[0];
    assign tie_to_even = blast & bafter; // Value 1.5 -> round to 2 (even)
    assign round_nearest = bafter & sticky_bit; // Value > 0.5: round to nearest

    assign result_no_sign_rounded = (tie_to_even | round_nearest) ? (result_no_sign + 1) : result_no_sign;

    // In case the product is negative, take 2's complement of everything but the sign
    logic [NBITS-2:0] signed_result_no_sign;
    assign signed_result_no_sign = sum.sgn ? -result_no_sign_rounded[NBITS-2:0] : result_no_sign_rounded[NBITS-2:0];

    // Final output
    assign result = (out_rounded_zero | sum.zero | sum.inf) ? {sum.inf, {NBITS-1{1'b0}}} : {sum.sgn, signed_result_no_sign[NBITS-2:0]};
    assign inf = sum.inf;
    assign zero = ~sum.inf & sum.zero;
    assign done = start;

endmodule
