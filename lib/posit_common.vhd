---------------------------------------------------------------------------------------------------
-- Common Posit components
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

package posit_common is

  constant POSIT_SERIALIZED_WIDTH_ES2             : natural := 1+8+27+1+1;
  constant POSIT_SERIALIZED_WIDTH_SUM_ES2         : natural := 1+8+31+1+1;
  constant POSIT_SERIALIZED_WIDTH_PRODUCT_ES2     : natural := 1+9+56+1+1;
  constant POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_ES2 : natural := 1+9+60+1+1;
  constant POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_SUM_ES2 : natural := 1+9+64+1+1;
  constant POSIT_SERIALIZED_WIDTH_PRODUCT_SUM_PRODUCT_SUM_ES2 : natural := 1+10+130+1+1;
  constant POSIT_SERIALIZED_WIDTH_ACCUM_ES2       : natural := 1+8+147+1+1;
  constant POSIT_SERIALIZED_WIDTH_ACCUM_PROD_ES2  : natural := 1+9+147+1+1;

  constant POSIT_SERIALIZED_WIDTH_ES3             : natural := 1+9+26+1+1;
  constant POSIT_SERIALIZED_WIDTH_SUM_ES3         : natural := 1+9+30+1+1;
  constant POSIT_SERIALIZED_WIDTH_PRODUCT_ES3     : natural := 1+10+54+1+1;
  constant POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_ES3 : natural := 1+10+58+1+1;
  constant POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_SUM_ES3 : natural := 1+10+62+1+1;
  constant POSIT_SERIALIZED_WIDTH_PRODUCT_SUM_PRODUCT_SUM_ES3 : natural := 1+11+126+1+1;
  constant POSIT_SERIALIZED_WIDTH_ACCUM_ES3       : natural := 1+9+252+1+1;
  constant POSIT_SERIALIZED_WIDTH_ACCUM_PROD_ES3  : natural := 1+10+252+1+1;

  component posit_extract_raw
    port (
      in1      : in  std_logic_vector(31 downto 0);
      absolute : out std_logic_vector(30 downto 0);
      result   : out std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0)
      );
  end component;

  component positadd_4_raw
    port (
      clk       : in  std_logic;
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
      in2       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
      start     : in  std_logic;
      result    : out std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_ES2-1 downto 0);
      done      : out std_logic;
      truncated : out std_logic
      );
  end component;

  component positadd_4_truncated_raw
    port (
      clk           : in  std_logic;
      in1           : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
      in1_truncated : in  std_logic;
      in2           : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
      in2_truncated : in  std_logic;
      start         : in  std_logic;
      result        : out std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_ES2-1 downto 0);
      done          : out std_logic;
      truncated     : out std_logic
      );
  end component;

  component positadd_4_truncated_prodsum_raw
    port (
      clk           : in  std_logic;
      in1           : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_ES2-1 downto 0);
      in1_truncated : in  std_logic;
      in2           : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_ES2-1 downto 0);
      in2_truncated : in  std_logic;
      start         : in  std_logic;
      result        : out std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_SUM_ES2-1 downto 0);
      done          : out std_logic;
      truncated     : out std_logic
      );
  end component;

  component positadd_prod_4_raw
    port (
      clk       : in  std_logic;
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES2-1 downto 0);
      in2       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES2-1 downto 0);
      start     : in  std_logic;
      result    : out std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_ES2-1 downto 0);
      done      : out std_logic;
      truncated : out std_logic
      );
  end component;

  component positadd_prod_8_raw
    port (
      clk       : in  std_logic;
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES2-1 downto 0);
      in2       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES2-1 downto 0);
      start     : in  std_logic;
      result    : out std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_ES2-1 downto 0);
      done      : out std_logic;
      truncated : out std_logic
      );
  end component;

  component posit_normalize
    port (
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
      truncated : in  std_logic;
      result    : out std_logic_vector(31 downto 0);
      inf       : out std_logic;
      zero      : out std_logic
      );
  end component;

  component posit_normalize_prod_sum
    port (
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_ES2-1 downto 0);
      truncated : in  std_logic;
      result    : out std_logic_vector(31 downto 0);
      inf       : out std_logic;
      zero      : out std_logic
      );
  end component;

  component posit_normalize_product_prod_sum_sum
    port (
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_SUM_PRODUCT_SUM_ES2-1 downto 0);
      truncated : in  std_logic;
      result    : out std_logic_vector(31 downto 0);
      inf       : out std_logic;
      zero      : out std_logic
      );
  end component;

  component posit_normalize_sum
    port (
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_ES2-1 downto 0);
      truncated : in  std_logic;
      result    : out std_logic_vector(31 downto 0);
      inf       : out std_logic;
      zero      : out std_logic
      );
  end component;

  component posit_normalize_accum
    port (
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ACCUM_ES2-1 downto 0);
      truncated : in  std_logic;
      result    : out std_logic_vector(31 downto 0);
      inf       : out std_logic;
      zero      : out std_logic
      );
  end component;

  component posit_normalize_prod
    port (
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES2-1 downto 0);
      truncated : in  std_logic;
      result    : out std_logic_vector(31 downto 0);
      inf       : out std_logic;
      zero      : out std_logic
      );
  end component;

  component posit_normalize_accum_prod
    port (
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ACCUM_PROD_ES2-1 downto 0);
      truncated : in  std_logic;
      result    : out std_logic_vector(31 downto 0);
      inf       : out std_logic;
      zero      : out std_logic
      );
  end component;

  component positadd_8_raw
    port (
      clk       : in  std_logic;
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
      in2       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
      start     : in  std_logic;
      result    : out std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_ES2-1 downto 0);
      done      : out std_logic;
      truncated : out std_logic
      );
  end component;

  component positmult_4_raw
    port (
      clk    : in  std_logic;
      in1    : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
      in2    : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
      start  : in  std_logic;
      result : out std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES2-1 downto 0);
      done   : out std_logic
      );
  end component;

  component positmult_4_raw_sumval
    port (
      clk    : in  std_logic;
      in1    : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_ES2-1 downto 0);
      in2    : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
      start  : in  std_logic;
      result : out std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES2-1 downto 0);
      done   : out std_logic
      );
  end component;

  component positmult_4_truncated_raw_sumval
    port (
      clk           : in  std_logic;
      in1           : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_ES2-1 downto 0);
      in1_truncated : in  std_logic;
      in2           : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
      in2_truncated : in  std_logic;
      start         : in  std_logic;
      result        : out std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES2-1 downto 0);
      done          : out std_logic;
      truncated     : out std_logic
      );
  end component;

  component positmult_4_truncated_raw_prodsumsum
    port (
      clk           : in  std_logic;
      in1           : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_SUM_ES2-1 downto 0);
      in1_truncated : in  std_logic;
      in2           : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_SUM_ES2-1 downto 0);
      in2_truncated : in  std_logic;
      start         : in  std_logic;
      result        : out std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_SUM_PRODUCT_SUM_ES2-1 downto 0);
      done          : out std_logic;
      truncated     : out std_logic
      );
  end component;

  component positadd_4
    port (
      clk    : in  std_logic;
      in1    : in  std_logic_vector(31 downto 0);
      in2    : in  std_logic_vector(31 downto 0);
      start  : in  std_logic;
      result : out std_logic_vector(31 downto 0);
      inf    : out std_logic;
      zero   : out std_logic;
      done   : out std_logic
      );
  end component;

  component positadd_8
    port (
      clk    : in  std_logic;
      in1    : in  std_logic_vector(31 downto 0);
      in2    : in  std_logic_vector(31 downto 0);
      start  : in  std_logic;
      result : out std_logic_vector(31 downto 0);
      inf    : out std_logic;
      zero   : out std_logic;
      done   : out std_logic
      );
  end component;

  component positmult_4
    port (
      clk    : in  std_logic;
      in1    : in  std_logic_vector(31 downto 0);
      in2    : in  std_logic_vector(31 downto 0);
      start  : in  std_logic;
      result : out std_logic_vector(31 downto 0);
      inf    : out std_logic;
      zero   : out std_logic;
      done   : out std_logic
      );
  end component;

  component positaccum_16
    port (
      clk    : in  std_logic;
      rst    : in  std_logic;
      in1    : in  std_logic_vector(31 downto 0);
      start  : in  std_logic;
      result : out std_logic_vector(31 downto 0);
      inf    : out std_logic;
      zero   : out std_logic;
      done   : out std_logic
      );
  end component;

  component positaccum_16_raw
    port (
      clk    : in  std_logic;
      rst    : in  std_logic;
      in1    : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
      start  : in  std_logic;
      result : out std_logic_vector(POSIT_SERIALIZED_WIDTH_ACCUM_ES2-1 downto 0);
      done   : out std_logic
      );
  end component;

  component positaccum_prod_16_raw
    port (
      clk       : in  std_logic;
      rst       : in  std_logic;
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES2-1 downto 0);
      start     : in  std_logic;
      result    : out std_logic_vector(POSIT_SERIALIZED_WIDTH_ACCUM_PROD_ES2-1 downto 0);
      done      : out std_logic;
      truncated : out std_logic
      );
  end component;

  component positaccum_accum_16_raw
    port (
      clk       : in  std_logic;
      rst       : in  std_logic;
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ACCUM_ES2-1 downto 0);
      start     : in  std_logic;
      result    : out std_logic_vector(POSIT_SERIALIZED_WIDTH_ACCUM_ES2-1 downto 0);
      done      : out std_logic;
      truncated : out std_logic
      );
  end component;

  component positaccum_accumprod_16_raw
    port (
      clk       : in  std_logic;
      rst       : in  std_logic;
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ACCUM_PROD_ES2-1 downto 0);
      start     : in  std_logic;
      result    : out std_logic_vector(POSIT_SERIALIZED_WIDTH_ACCUM_PROD_ES2-1 downto 0);
      done      : out std_logic;
      truncated : out std_logic
      );
  end component;

  component posit_normalize_sum_es3
    port (
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_ES3-1 downto 0);
      truncated : in std_logic;
      result    : out std_logic_vector(31 downto 0);
      inf       : out std_logic;
      zero      : out std_logic
      );
  end component;

  component posit_normalize_prod_sum_es3
    port (
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_ES3-1 downto 0);
      truncated : in  std_logic;
      result    : out std_logic_vector(31 downto 0);
      inf       : out std_logic;
      zero      : out std_logic
      );
  end component;

  component posit_normalize_product_prod_sum_sum_es3
    port (
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_SUM_PRODUCT_SUM_ES3-1 downto 0);
      truncated : in  std_logic;
      result    : out std_logic_vector(31 downto 0);
      inf       : out std_logic;
      zero      : out std_logic
      );
  end component;

  component posit_extract_raw_es3
    port (
      in1      : in  std_logic_vector(31 downto 0);
      absolute : out std_logic_vector(30 downto 0);
      result   : out std_logic_vector(POSIT_SERIALIZED_WIDTH_ES3-1 downto 0)
      );
  end component;

  component positadd_4_raw_es3
    port (
      clk       : in  std_logic;
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES3-1 downto 0);
      in2       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES3-1 downto 0);
      start     : in  std_logic;
      result    : out std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_ES3-1 downto 0);
      done      : out std_logic;
      truncated : out std_logic
      );
  end component;

  component positadd_4_truncated_raw_es3
    port (
      clk           : in  std_logic;
      in1           : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES3-1 downto 0);
      in1_truncated : in  std_logic;
      in2           : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES3-1 downto 0);
      in2_truncated : in  std_logic;
      start         : in  std_logic;
      result        : out std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_ES3-1 downto 0);
      done          : out std_logic;
      truncated     : out std_logic
      );
  end component;

  component positadd_4_truncated_prodsum_raw_es3
    port (
      clk           : in  std_logic;
      in1           : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_ES3-1 downto 0);
      in1_truncated : in  std_logic;
      in2           : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_ES3-1 downto 0);
      in2_truncated : in  std_logic;
      start         : in  std_logic;
      result        : out std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_SUM_ES3-1 downto 0);
      done          : out std_logic;
      truncated     : out std_logic
      );
  end component;

  component positadd_prod_4_raw_es3
    port (
      clk       : in  std_logic;
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES3-1 downto 0);
      in2       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES3-1 downto 0);
      start     : in  std_logic;
      result    : out std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_ES3-1 downto 0);
      done      : out std_logic;
      truncated : out std_logic
      );
  end component;

  component positadd_prod_8_raw_es3
    port (
      clk       : in  std_logic;
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES3-1 downto 0);
      in2       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES3-1 downto 0);
      start     : in  std_logic;
      result    : out std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_ES3-1 downto 0);
      done      : out std_logic;
      truncated : out std_logic
      );
  end component;

  component posit_normalize_es3
    port (
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES3-1 downto 0);
      truncated : in  std_logic;
      result    : out std_logic_vector(31 downto 0);
      inf       : out std_logic;
      zero      : out std_logic
      );
  end component;

  component posit_normalize_accum_es3
    port (
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ACCUM_ES3-1 downto 0);
      truncated : in  std_logic;
      result    : out std_logic_vector(31 downto 0);
      inf       : out std_logic;
      zero      : out std_logic
      );
  end component;

  component posit_normalize_prod_es3
    port (
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES3-1 downto 0);
      truncated : in  std_logic;
      result    : out std_logic_vector(31 downto 0);
      inf       : out std_logic;
      zero      : out std_logic
      );
  end component;

  component posit_normalize_accum_prod_es3
    port (
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ACCUM_PROD_ES3-1 downto 0);
      truncated : in  std_logic;
      result    : out std_logic_vector(31 downto 0);
      inf       : out std_logic;
      zero      : out std_logic
      );
  end component;

  component positadd_8_raw_es3
    port (
      clk       : in  std_logic;
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES3-1 downto 0);
      in2       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES3-1 downto 0);
      start     : in  std_logic;
      result    : out std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_ES3-1 downto 0);
      done      : out std_logic;
      truncated : out std_logic
      );
  end component;

  component positmult_4_raw_es3
    port (
      clk    : in  std_logic;
      in1    : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES3-1 downto 0);
      in2    : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES3-1 downto 0);
      start  : in  std_logic;
      result : out std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES3-1 downto 0);
      done   : out std_logic
      );
  end component;

  component positmult_4_raw_sumval_es3
    port (
      clk    : in  std_logic;
      in1    : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_ES3-1 downto 0);
      in2    : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES3-1 downto 0);
      start  : in  std_logic;
      result : out std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES3-1 downto 0);
      done   : out std_logic
      );
  end component;

  component positmult_4_truncated_raw_sumval_es3
    port (
      clk           : in  std_logic;
      in1           : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_ES3-1 downto 0);
      in1_truncated : in  std_logic;
      in2           : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES3-1 downto 0);
      in2_truncated : in  std_logic;
      start         : in  std_logic;
      result        : out std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES3-1 downto 0);
      done          : out std_logic;
      truncated     : out std_logic
      );
  end component;

  component positmult_4_truncated_raw_prodsumsum_es3
    port (
      clk           : in  std_logic;
      in1           : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_SUM_ES3-1 downto 0);
      in1_truncated : in  std_logic;
      in2           : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_PRODUCT_SUM_ES3-1 downto 0);
      in2_truncated : in  std_logic;
      start         : in  std_logic;
      result        : out std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_SUM_PRODUCT_SUM_ES3-1 downto 0);
      done          : out std_logic;
      truncated     : out std_logic
      );
  end component;

  component positadd_4_es3
    port (
      clk    : in  std_logic;
      in1    : in  std_logic_vector(31 downto 0);
      in2    : in  std_logic_vector(31 downto 0);
      start  : in  std_logic;
      result : out std_logic_vector(31 downto 0);
      inf    : out std_logic;
      zero   : out std_logic;
      done   : out std_logic
      );
  end component;

  component positadd_8_es3
    port (
      clk    : in  std_logic;
      in1    : in  std_logic_vector(31 downto 0);
      in2    : in  std_logic_vector(31 downto 0);
      start  : in  std_logic;
      result : out std_logic_vector(31 downto 0);
      inf    : out std_logic;
      zero   : out std_logic;
      done   : out std_logic
      );
  end component;

  component positmult_4_es3
    port (
      clk    : in  std_logic;
      in1    : in  std_logic_vector(31 downto 0);
      in2    : in  std_logic_vector(31 downto 0);
      start  : in  std_logic;
      result : out std_logic_vector(31 downto 0);
      inf    : out std_logic;
      zero   : out std_logic;
      done   : out std_logic
      );
  end component;

  component positaccum_16_es3
    port (
      clk    : in  std_logic;
      rst    : in  std_logic;
      in1    : in  std_logic_vector(31 downto 0);
      start  : in  std_logic;
      result : out std_logic_vector(31 downto 0);
      inf    : out std_logic;
      zero   : out std_logic;
      done   : out std_logic
      );
  end component;

  component positaccum_16_raw_es3
    port (
      clk    : in  std_logic;
      rst    : in  std_logic;
      in1    : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ES3-1 downto 0);
      start  : in  std_logic;
      result : out std_logic_vector(POSIT_SERIALIZED_WIDTH_ACCUM_ES3-1 downto 0);
      done   : out std_logic
      );
  end component;

  component positaccum_prod_16_raw_es3
    port (
      clk       : in  std_logic;
      rst       : in  std_logic;
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES3-1 downto 0);
      start     : in  std_logic;
      result    : out std_logic_vector(POSIT_SERIALIZED_WIDTH_ACCUM_PROD_ES3-1 downto 0);
      done      : out std_logic;
      truncated : out std_logic
      );
  end component;

  component positaccum_accum_16_raw_es3
    port (
      clk       : in  std_logic;
      rst       : in  std_logic;
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ACCUM_ES3-1 downto 0);
      start     : in  std_logic;
      result    : out std_logic_vector(POSIT_SERIALIZED_WIDTH_ACCUM_ES3-1 downto 0);
      done      : out std_logic;
      truncated : out std_logic
      );
  end component;

  component positaccum_accumprod_16_raw_es3
    port (
      clk       : in  std_logic;
      rst       : in  std_logic;
      in1       : in  std_logic_vector(POSIT_SERIALIZED_WIDTH_ACCUM_PROD_ES3-1 downto 0);
      start     : in  std_logic;
      result    : out std_logic_vector(POSIT_SERIALIZED_WIDTH_ACCUM_PROD_ES3-1 downto 0);
      done      : out std_logic;
      truncated : out std_logic
      );
  end component;

end package;

package body posit_common is

end package body;
