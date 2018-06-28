// Laurens van Dam
// Delft University of Technology
// May 2018

package posit_defines_es3;

parameter NBITS = 32;
parameter ES = 3;
parameter FBITS = NBITS - 3 - ES; // Size of fraction bits // 26
parameter FHBITS = FBITS + 1; // Size of fraction + hidden bit
parameter MBITS = 2 *  FHBITS; // Size of multiplier output
parameter ABITS = FBITS + 4; // Size of addend

parameter FBITS_ACCUM = 252; //MAX_FRACTION_SHIFT + FBITS;
parameter MAX_FRACTION_SHIFT = FBITS_ACCUM - FBITS;//(1 << ES) * (NBITS - 2); // 240
parameter ABITS_ACCUM = FBITS_ACCUM + 4; // 256

typedef struct {
    logic sign;
    logic signed [8:0] scale;
    logic [FBITS-1:0] fraction;
    logic inf;
    logic zero;
} value;

typedef struct {
    logic sign;
    logic signed [9:0] scale;
    logic [MBITS-1:0] fraction;
    logic inf;
    logic zero;
} value_product;

typedef struct {
    logic sign;
    logic signed [8:0] scale;
    logic [ABITS-1:0] fraction;
    logic inf;
    logic zero;
} value_sum;

typedef struct {
    logic sign;
    logic signed [8:0] scale;
    logic [FBITS_ACCUM-1:0] fraction; // 256
    logic inf;
    logic zero;
} value_accum;

endpackage : posit_defines_es3
