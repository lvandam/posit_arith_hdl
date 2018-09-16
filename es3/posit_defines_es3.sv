// Laurens van Dam
// Delft University of Technology
// May 2018

package posit_defines_es3;

parameter NBITS = 32;
parameter ES = 3;
parameter FBITS = NBITS - 3 - ES; // Size of fraction bits // 26
parameter FHBITS = FBITS + 1; // Size of fraction + hidden bit // 27
parameter MBITS = 2 *  FHBITS; // Size of multiplier output // 54
parameter ABITS = FBITS + 4; // Size of addend // 30
parameter AMBITS = MBITS + 4; // Size of product addend // 58

parameter AAMBITS = AMBITS + 4; // Size of product addend addend // 62
parameter AAMHBITS = AAMBITS + 1; // Size of product addend addend + hidden bit // 63
parameter AAMMBITS = 2 * AAMHBITS; // Size of product of product addend addend // 126

parameter FBITS_ACCUM = 252; //MAX_FRACTION_SHIFT + FBITS;
parameter MAX_FRACTION_SHIFT = FBITS_ACCUM - FBITS;//(1 << ES) * (NBITS - 2); // 240
parameter ABITS_ACCUM = FBITS_ACCUM + 4; // 256

parameter POSIT_SERIALIZED_WIDTH_ES3 = 1+9+FBITS+1+1;
parameter POSIT_SERIALIZED_WIDTH_SUM_ES3 = 1+9+ABITS+1+1;
parameter POSIT_SERIALIZED_WIDTH_PRODUCT_ES3 = 1+10+MBITS+1+1;
parameter POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_ES3 = 1+10+AMBITS+1+1;
parameter POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_SUM_ES3 = 1+10+AAMBITS+1+1;
parameter POSIT_SERIALIZED_WIDTH_PRODUCT_SUM_PRODUCT_SUM_ES3 = 1+11+AAMMBITS+1+1;
parameter POSIT_SERIALIZED_WIDTH_ACCUM_ES3 = 1+9+252+1+1;
parameter POSIT_SERIALIZED_WIDTH_ACCUM_PROD_ES3 = 1+10+252+1+1;

typedef struct {
    logic sgn;                  // 1
    logic signed [8:0] scale;   // 9
    logic [FBITS-1:0] fraction; // 26
    logic inf;                  // 1
    logic zero;                 // 1
} value; // 38

typedef struct {
    logic sgn;                  // 1
    logic signed [9:0] scale;   // 10
    logic [MBITS-1:0] fraction; // 54
    logic inf;                  // 1
    logic zero;                 // 1
} value_product; // 67

typedef struct {
    logic sgn;                  // 1
    logic signed [8:0] scale;   // 9
    logic [ABITS-1:0] fraction; // 30
    logic inf;                  // 1
    logic zero;                 // 1
} value_sum; // 42

typedef struct {
    logic sgn;                   // 1
    logic signed [9:0] scale;    // 10
    logic [AMBITS-1:0] fraction;  // 58
    logic inf;                   // 1
    logic zero;                  // 1
} value_prod_sum; // 71

typedef struct {
    logic sgn;                   // 1
    logic signed [9:0] scale;    // 10
    logic [AAMBITS-1:0] fraction;  // 62
    logic inf;                   // 1
    logic zero;                  // 1
} value_prod_sum_sum; // 75

typedef struct {
    logic sgn;                         // 1
    logic signed [10:0] scale;          // 11
    logic [AAMMBITS-1:0] fraction;    // 126
    logic inf;                         // 1
    logic zero;                        // 1
} value_product_prod_sum_sum; // 140

typedef struct {
    logic sgn;                        // 1
    logic signed [8:0] scale;         // 9
    logic [FBITS_ACCUM-1:0] fraction; // 252
    logic inf;                        // 1
    logic zero;                       // 1
} value_accum;

typedef struct {
    logic sgn;                        // 1
    logic signed [9:0] scale;         // 10
    logic [FBITS_ACCUM-1:0] fraction; // 252
    logic inf;                        // 1
    logic zero;                       // 1
} value_accum_prod;

endpackage : posit_defines_es3
