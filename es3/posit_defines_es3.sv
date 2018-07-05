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


parameter POSIT_SERIALIZED_WIDTH_ES3 = 1+9+FBITS+1+1;
parameter POSIT_SERIALIZED_WIDTH_SUM_ES3 = 1+9+ABITS+1+1;
parameter POSIT_SERIALIZED_WIDTH_PRODUCT_ES3 = 1+10+MBITS+1+1;

typedef struct {
    logic sgn;
    logic signed [8:0] scale;
    logic [FBITS-1:0] fraction;
    logic inf;
    logic zero;
} value;

typedef struct {
    logic sgn;
    logic signed [9:0] scale;
    logic [MBITS-1:0] fraction;
    logic inf;
    logic zero;
} value_product;

typedef struct {
    logic sgn;
    logic signed [8:0] scale;
    logic [ABITS-1:0] fraction;
    logic inf;
    logic zero;
} value_sum;

typedef struct {
    logic sgn;
    logic signed [8:0] scale;
    logic [FBITS_ACCUM-1:0] fraction; // 256
    logic inf;
    logic zero;
} value_accum;

function logic [POSIT_SERIALIZED_WIDTH_ES3-1:0] serialize(value val);
    return val.sgn & val.scale & val.fraction & val.inf & val.zero;
endfunction : serialize

function logic [POSIT_SERIALIZED_WIDTH_PRODUCT_ES3-1:0] serialize_prod(value_product val);
    return val.sgn & val.scale & val.fraction & val.inf & val.zero;
endfunction : serialize_prod

function logic [POSIT_SERIALIZED_WIDTH_SUM_ES3-1:0] serialize_sum(value_sum val);
    return val.sgn & val.scale & val.fraction & val.inf & val.zero;
endfunction : serialize_sum


function value deserialize(logic [POSIT_SERIALIZED_WIDTH_ES3-1:0] val);
    value tmp;
begin
    tmp.sgn = val[37];
    tmp.scale = val[36:28];
    tmp.fraction = val[27:2];
    tmp.inf = val[1];
    tmp.zero = val[0];
    return tmp;
end
endfunction : deserialize

function value_product deserialize_prod(logic [POSIT_SERIALIZED_WIDTH_PRODUCT_ES3-1:0] val);
    value_product tmp;
begin
    tmp.sgn = val[66];
    tmp.scale = val[65:56];
    tmp.fraction = val[55:2];
    tmp.inf = val[1];
    tmp.zero = val[0];
    return tmp;
end
endfunction : deserialize_prod

function value_sum deserialize_sum(logic [POSIT_SERIALIZED_WIDTH_SUM_ES3-1:0] val);
    value_sum tmp;
begin
    tmp.sgn = val[41];
    tmp.scale = val[40:32];
    tmp.fraction = val[31:2];
    tmp.inf = val[1];
    tmp.zero = val[0];
    return tmp;
end
endfunction : deserialize_sum

endpackage : posit_defines_es3
