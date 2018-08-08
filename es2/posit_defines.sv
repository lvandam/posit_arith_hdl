// Laurens van Dam
// Delft University of Technology
// May 2018

package posit_defines;

parameter NBITS = 32;
parameter ES = 2;
parameter FBITS = NBITS - 3 - ES; // Size of fraction bits
parameter FHBITS = FBITS + 1; // Size of fraction + hidden bit
parameter MBITS = 2 *  FHBITS; // Size of multiplier output
parameter ABITS = FBITS + 4; // Size of addend

parameter MAX_FRACTION_SHIFT = (1 << ES) * (NBITS - 2);
parameter FBITS_ACCUM = MAX_FRACTION_SHIFT + FBITS; // 147
parameter ABITS_ACCUM = FBITS_ACCUM + 4;

parameter POSIT_SERIALIZED_WIDTH_ES2 = 1+8+FBITS+1+1;
parameter POSIT_SERIALIZED_WIDTH_SUM_ES2 = 1+8+ABITS+1+1;
parameter POSIT_SERIALIZED_WIDTH_PRODUCT_ES2 = 1+9+MBITS+1+1;
parameter POSIT_SERIALIZED_WIDTH_ACCUM_ES2 = 1+8+147+1+1;
parameter POSIT_SERIALIZED_WIDTH_ACCUM_PROD_ES2 = 1+9+147+1+1;

typedef struct {
    logic sgn;                   // 1
    logic signed [7:0] scale;    // 8
    logic [FBITS-1:0] fraction;  // 27
    logic inf;                   // 1
    logic zero;                  // 1
} value; // 38

typedef struct {
    logic sgn;                   // 1
    logic signed [8:0] scale;    // 9
    logic [MBITS-1:0] fraction;  // 56
    logic inf;                   // 1
    logic zero;                  // 1
} value_product; // 68

typedef struct {
    logic sgn;                   // 1
    logic signed [7:0] scale;    // 8
    logic [ABITS-1:0] fraction;  // 31
    logic inf;                   // 1
    logic zero;                  // 1
} value_sum; // 42

typedef struct {
    logic sgn;                         // 1
    logic signed [7:0] scale;          // 8
    logic [FBITS_ACCUM-1:0] fraction;  // 147
    logic inf;                         // 1
    logic zero;                        // 1
} value_accum;

typedef struct {
    logic sgn;                         // 1
    logic signed [8:0] scale;          // 9
    logic [FBITS_ACCUM-1:0] fraction;  // 151
    logic inf;                         // 1
    logic zero;                        // 1
} value_accum_prod;

endpackage : posit_defines
