// Laurens van Dam
// Delft University of Technology
// May 2018

package posit_defines;

parameter NBITS = 32;
parameter ES = 2;
parameter FBITS = NBITS - 3 - ES; // Size of fraction bits // 27
parameter FHBITS = FBITS + 1; // Size of fraction + hidden bit // 28
parameter MBITS = 2 *  FHBITS; // Size of multiplier output // 56
parameter ABITS = FBITS + 4; // Size of addend // 31
parameter AMBITS = MBITS + 4; // Size of product addend // 60

parameter AAMBITS = AMBITS + 4; // Size of product addend addend // 64
parameter AAMHBITS = AAMBITS + 1; // Size of product addend addend + hidden bit // 65
parameter AAMMBITS = 2 * AAMHBITS; // Size of product of product addend addend // 130

parameter MAX_FRACTION_SHIFT = (1 << ES) * (NBITS - 2);
parameter FBITS_ACCUM = MAX_FRACTION_SHIFT + FBITS; // 147
parameter ABITS_ACCUM = FBITS_ACCUM + 4;

parameter POSIT_SERIALIZED_WIDTH_ES2 = 1+8+FBITS+1+1;
parameter POSIT_SERIALIZED_WIDTH_SUM_ES2 = 1+8+ABITS+1+1;
parameter POSIT_SERIALIZED_WIDTH_PRODUCT_ES2 = 1+9+MBITS+1+1;
parameter POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_ES2 = 1+9+AMBITS+1+1;
parameter POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_SUM_ES2 = 1+9+AAMBITS+1+1;
parameter POSIT_SERIALIZED_WIDTH_PRODUCT_SUM_PRODUCT_SUM_ES2 = 1+10+AAMMBITS+1+1;
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
    logic sgn;                   // 1
    logic signed [8:0] scale;    // 9
    logic [AMBITS-1:0] fraction;  // 60
    logic inf;                   // 1
    logic zero;                  // 1
} value_prod_sum; // 72

typedef struct {
    logic sgn;                   // 1
    logic signed [8:0] scale;    // 9
    logic [AAMBITS-1:0] fraction;  // 64
    logic inf;                   // 1
    logic zero;                  // 1
} value_prod_sum_sum; // 76

typedef struct {
    logic sgn;                         // 1
    logic signed [9:0] scale;          // 10
    logic [AAMMBITS-1:0] fraction;  // 130
    logic inf;                         // 1
    logic zero;                        // 1
} value_product_prod_sum_sum; // 143

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
    logic [FBITS_ACCUM-1:0] fraction;  // 147
    logic inf;                         // 1
    logic zero;                        // 1
} value_accum_prod;

endpackage : posit_defines
