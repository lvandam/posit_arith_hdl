// Laurens van Dam
// Delft University of Technology
// May 2018

`timescale 1ns / 1ps
`default_nettype wire

import posit_defines::*;

module positmult (clk, in1, in2, start, result, inf, zero, done);

    input wire clk, start;
    input wire [31:0] in1, in2;
    output wire [31:0] result;
    output wire inf, zero, done;

    value a, b;
    value_product product;

    // Extract posit characteristics, among others the regime & exponent scales
    posit_extract a_extract (
        .in(in1),
        .out(a)
    );

    posit_extract b_extract (
        .in(in2),
        .out(b)
    );

    logic [MBITS-1:0] fraction_mult, result_fraction;

    logic [FHBITS-1:0] r1, r2;
    assign r1 = {1'b1, a.fraction}; // Add back hidden bit (fraction is without hidden bit)
    assign r2 = {1'b1, b.fraction}; // Add back hidden bit (fraction is without hidden bit)
    assign fraction_mult = r1 * r2; // Unsigned multiplication of fractions

    // Check if the radix point needs to shift
    assign product.scale   = fraction_mult[MBITS-1] ? (a.scale + b.scale + 1) : (a.scale + b.scale);
    assign result_fraction = fraction_mult[MBITS-1] ? (fraction_mult << 1) : (fraction_mult << 2); // Shift hidden bit out

    assign product.fraction = result_fraction[MBITS-1:0];
    assign product.sgn = a.sgn ^ b.sgn;
    assign product.zero = a.zero | b.zero;
    assign product.inf = a.inf | b.inf;

    logic [ES-1:0] result_exponent;
    assign result_exponent = product.scale % (2 << ES);

    logic [6:0] regime_shift_amount;
    // Positive scale -> Should shift with 1's with 1 extra (specification)
    // Negative scale -> Make value positive
    assign regime_shift_amount = (product.scale[8] == 0) ? 1 + (product.scale >> ES) : -(product.scale >> ES);

    // STICKY BIT CALCULATION (all the bits from [msb, lsb], that is, msb is included)
    logic [MBITS-1:0] fraction_leftover;
    logic [NBITS-1:0] leftover_shift;
    assign leftover_shift = NBITS - 4 - regime_shift_amount;
    // Determine all fraction bits that are truncated in the final result
    shift_left #(
        .N(MBITS),
        .S(NBITS)
    ) fraction_leftover_shift (
        .a(product.fraction), // exponent + fraction bits
        .b(leftover_shift), // Shift to right by regime value (clip at maximum number of bits)
        .c(fraction_leftover)
    );
    logic sticky_bit;
    assign sticky_bit = |fraction_leftover[MBITS-2:0]; // Logical OR of all truncated fraction multiplication bits

    logic bafter;
    assign bafter = fraction_leftover[MBITS-1];
    // END STICKY BIT CALCULATION

    logic [28:0] fraction_truncated;
    assign fraction_truncated = {product.fraction[MBITS-1:MBITS-NBITS+4], (product.fraction[MBITS-NBITS+3] | sticky_bit)};

    logic [2*NBITS-1:0] regime_exp_fraction;
    assign regime_exp_fraction = { {NBITS{~product.scale[8]}}, // Regime leading bits
                            product.scale[8], // Regime terminating bit
                            result_exponent, // Exponent
                            fraction_truncated[28:0] }; // Fraction

    logic [2*NBITS-1:0] exp_fraction_shifted_for_regime;
    shift_right #(
        .N(2*NBITS),
        .S(7)
    ) dsr2 (
        .a(regime_exp_fraction), // exponent + fraction bits
        .b(regime_shift_amount), // Shift to right by regime value (clip at maximum number of bits)
        .c(exp_fraction_shifted_for_regime)
    );

    logic [NBITS-2:0] result_no_sign;

    // Calculate the max k factor for this posit config
	logic signed [7:0] max_k;
	assign max_k = product.scale[8] ? -120 : 120;
    // Determine if we have inward projection (which means the regime dominated)
    logic inward_projection;
    assign inward_projection = product.scale[8] ? (product.scale < max_k) : (product.scale > max_k);

    // In case of inward projection, determine the regime
    logic [6:0] inward_projection_k1;
    logic inward_projection_k2;
    assign inward_projection_k1 = product.scale[8] ? -(-product.scale >> ES) : (product.scale >> ES);
    assign inward_projection_k2 = (~|inward_projection_k1 & product.scale[8]) ? 1 : inward_projection_k1[6];

    // Determine result (without sign), either a full regime part (inward projection) or the unsigned regime+exp+fraction
    assign result_no_sign = inward_projection ? (inward_projection_k2 ? {{NBITS-2{1'b0}}, 1'b1} : {NBITS-1{1'b1}}) : exp_fraction_shifted_for_regime[NBITS-1:1];

    // Perform rounding (based on sticky bit)
    logic blast, tie_to_even, round_nearest;
    logic [NBITS-2:0] result_no_sign_rounded;

    assign blast = result_no_sign[0];
    assign tie_to_even = blast & bafter; // Value 1.5 -> round to 2 (even)
    assign round_nearest = bafter & sticky_bit; // Value > 0.5: round to nearest

    assign result_no_sign_rounded = (tie_to_even | round_nearest) ? (result_no_sign + 1) : result_no_sign;

    // In case the product is negative, take 2's complement of everything but the sign
    logic [NBITS-2:0] signed_result_no_sign;
    assign signed_result_no_sign = product.sgn ? -result_no_sign_rounded[NBITS-2:0] : result_no_sign_rounded[NBITS-2:0];

    // Final output
    assign result = (product.zero | product.inf) ? {product.inf, {NBITS-1{1'b0}}} : {product.sgn, signed_result_no_sign[NBITS-2:0]};
    assign inf = product.inf;
    assign zero = ~product.inf & product.zero;
    assign done = start;

endmodule
