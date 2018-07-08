// Laurens van Dam
// Delft University of Technology
// July 2018

`timescale 1ns / 1ps
`default_nettype wire

import posit_defines_es3::*;

module posit_sum_to_value_es3 (in1, result);

    input value_product in1;
    output value result;

    assign result.sgn = in1.sgn;
    assign result.scale = in1.scale[8:0];
    assign result.fraction = in1.fraction[ABITS-1:ABITS-FBITS];
    assign result.inf = in1.inf;
    assign result.zero = in1.zero;
endmodule
