// Laurens van Dam
// Delft University of Technology
// May 2018

`timescale 1ns / 1ps
`default_nettype wire

// `include "posit_defines.sv"
import posit_defines::*;

module posit_extract (input wire [NBITS-1:0] in, output wire [NBITS-2:0] abs, output value out);
    logic [7:0] regime_scale;
    logic [4:0] regime_u, k0, k1;
    logic [NBITS-1:0] exp_fraction_u;
    logic [4:0] regime_width;
    logic [31:0] in_u;

    // Check if part without sign is non-zero (to determine inf and zero cases)
    logic posit_nonzero_without_sign;
    assign posit_nonzero_without_sign = |in[NBITS-2:0];

    // Special case handling (inf, zero) for both inputs
    assign out.zero = ~(in[NBITS-1] | posit_nonzero_without_sign);
    assign out.inf = in[NBITS-1] & (~posit_nonzero_without_sign);

    assign out.sgn = in[NBITS-1];

    // Unsigned input (*_u = unsigned)
    assign in_u = out.sgn ? -in : in;

    // Leading-One detection for regime
    LOD_N #(
        .N(NBITS)
    ) reg_pos_lod(
        .in({in_u[NBITS-2:0], 1'b0}),
        .out(k0)
    );

    // Leading-Zero detection for regime
    LZD_N #(
        .N(NBITS)
    ) reg_neg_lzd(
        .in({in_u[NBITS-3:0], 2'b0}),
        .out(k1)
    );

    // Determine absolute regime value depending on leading 0 or 1 regime bit
    assign regime_u = in_u[NBITS-2] ? k1 : k0;
    // Negative regime? Make the regime scale negative
    assign regime_scale = in_u[NBITS-2] ? (regime_u << ES) : -(regime_u << ES);
    // Number of bits occupied by regime
    assign regime_width = in_u[NBITS-2] ? (k1 + 1) : k0;

    // Shift away the regime resulting in only the exponent and fraction
    shift_left #(
        .N(32),
        .S(5)
    ) ls (
        .a({in_u[NBITS-3:0], 2'b0}),
        .b(regime_width),
        .c(exp_fraction_u)
    );

    assign out.fraction = exp_fraction_u[NBITS-ES-1:3];

    // Scale = k*(2^es) + 2^exp
    assign out.scale = regime_scale + exp_fraction_u[NBITS-1:NBITS-ES];

    assign abs = in_u[NBITS-2:0];

endmodule
