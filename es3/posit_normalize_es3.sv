// Laurens van Dam
// Delft University of Technology
// July 2018

`timescale 1ns / 1ps
`default_nettype wire

import posit_defines_es3::*;

module posit_normalize_es3 (in1, result, inf, zero);

    input wire [POSIT_SERIALIZED_WIDTH_ES3-1:0] in1;
    output wire [31:0] result;
    output wire inf, zero;

    value in;
    assign in.sgn = in1[37];
    assign in.scale = in1[36:28];
    assign in.fraction = in1[27:2];
    assign in.inf = in1[1];
    assign in.zero = in1[0];

    logic [6:0] regime_shift_amount;
    assign regime_shift_amount = (in.scale[8] == 0) ? 1 + (in.scale >> ES) : -(in.scale >> ES);

    logic [ES-1:0] result_exponent;
    assign result_exponent = in.scale % (2 << ES);

    logic [27:0] fraction_truncated;
    assign fraction_truncated = {in.fraction[FBITS-1:0], {28-FBITS{1'b0}}};

    logic [2*NBITS-1:0] regime_exp_fraction;
    assign regime_exp_fraction = { {NBITS-1{~in.scale[8]}}, // Regime leading bits
                            in.scale[8], // Regime terminating bit
                            result_exponent, // Exponent
                            fraction_truncated[27:0] }; // Fraction

    logic [2*NBITS-1:0] exp_fraction_shifted_for_regime;
    shift_right #(
        .N(2*NBITS),
        .S(7)
    ) shift_in_regime (
        .a(regime_exp_fraction), // exponent + fraction bits
        .b(regime_shift_amount), // Shift to right by regime value (clip at maximum number of bits)
        .c(exp_fraction_shifted_for_regime)
    );

    // Determine result (without sign), the unsigned regime+exp+fraction
    logic [NBITS-2:0] result_no_sign;
    assign result_no_sign = exp_fraction_shifted_for_regime[NBITS-1:1];

    // In case the product is negative, take 2's complement of everything but the sign
    logic [NBITS-2:0] signed_result_no_sign;
    assign signed_result_no_sign = in.sgn ? -result_no_sign[NBITS-2:0] : result_no_sign[NBITS-2:0];

    // Final output
    assign result = (in.zero | in.inf) ? {in.inf, {NBITS-1{1'b0}}} : {in.sgn, signed_result_no_sign[NBITS-2:0]};

    assign inf = in.inf;
    assign zero = ~in.inf & in.zero;

endmodule
