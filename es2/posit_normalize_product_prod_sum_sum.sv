// Laurens van Dam
// Delft University of Technology
// August 2018

`timescale 1ns / 1ps
`default_nettype wire

import posit_defines::*;

module posit_normalize_product_prod_sum_sum (in1, truncated, result, inf, zero);

    input wire [POSIT_SERIALIZED_WIDTH_PRODUCT_SUM_PRODUCT_SUM_ES2-1:0] in1;
    input wire truncated;
    output wire [31:0] result;
    output wire inf, zero;

    value_product_prod_sum_sum in;
    assign in.sgn = in1[142];
    assign in.scale = in1[141:132];
    assign in.fraction = in1[131:2];
    assign in.inf = in1[1];
    assign in.zero = in1[0];

    logic [8:0] regime_shift_amount;
    assign regime_shift_amount = (in.scale[9] == 0) ? 1 + (in.scale >> ES) : -(in.scale >> ES);

    logic [ES-1:0] result_exponent;
    assign result_exponent = in.scale % (2 << ES);

    logic [255:0] fraction_leftover;
    logic [8:0] leftover_shift;
    assign leftover_shift = NBITS - 4 - regime_shift_amount;
    // Determine all fraction bits that are truncated in the final result
    shift_left #(
        .N(256),
        .S(9)
    ) fraction_leftover_shift (
        .a({in.fraction, {256-AAMMBITS{1'b0}}}),
        .b(leftover_shift), // Shift to right by regime value (clip at maximum number of bits)
        .c(fraction_leftover)
    );

    logic sticky_bit;
    assign sticky_bit = truncated | |fraction_leftover[254:0]; // Logical OR of all truncated fraction multiplication bits //ABITS TODO Laurens


    logic [28:0] fraction_truncated;
    assign fraction_truncated = {in.fraction[AAMMBITS-1:AAMMBITS-28], in.fraction[AAMMBITS-29] | sticky_bit};

    logic [2*NBITS-1:0] regime_exp_fraction;
    assign regime_exp_fraction = { {NBITS-1{~in.scale[9]}}, // Regime leading bits
                            in.scale[9], // Regime terminating bit
                            result_exponent, // Exponent
                            fraction_truncated[28:0] }; // Fraction

    logic [2*NBITS-1:0] exp_fraction_shifted_for_regime;
    shift_right #(
        .N(2*NBITS),
        .S(8)
    ) shift_in_regime (
        .a(regime_exp_fraction), // exponent + fraction bits
        .b(regime_shift_amount), // Shift to right by regime value (clip at maximum number of bits)
        .c(exp_fraction_shifted_for_regime)
    );

    // Determine result (without sign), the unsigned regime+exp+fraction
    logic [NBITS-2:0] result_no_sign;
    assign result_no_sign = exp_fraction_shifted_for_regime[NBITS-1:1];

    logic bafter;
    assign bafter = fraction_leftover[255];

    // Perform rounding (based on sticky bit)
    logic blast, tie_to_even, round_nearest;
    logic [NBITS-2:0] result_no_sign_rounded;

    assign blast = result_no_sign[0];
    assign tie_to_even = blast & bafter; // Value 1.5 -> round to 2 (even)
    assign round_nearest = bafter & sticky_bit; // Value > 0.5: round to nearest

    assign result_no_sign_rounded = (tie_to_even | round_nearest) ? (result_no_sign + 1) : result_no_sign;

    // In case the product is negative, take 2's complement of everything but the sign
    logic [NBITS-2:0] signed_result_no_sign;
    assign signed_result_no_sign = in.sgn ? -result_no_sign_rounded[NBITS-2:0] : result_no_sign_rounded[NBITS-2:0];

    // Final output
    assign result = (in.zero | in.inf) ? {in.inf, {NBITS-1{1'b0}}} : {in.sgn, signed_result_no_sign[NBITS-2:0]};

    assign inf = in.inf;
    assign zero = ~in.inf & in.zero;

endmodule
